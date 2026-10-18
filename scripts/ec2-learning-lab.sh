#!/usr/bin/env bash
set -Eeuo pipefail
# General purpose disposable EC2 learning host. Constants are intentional.
REGION=ap-south-1
PROFILE=default
TYPE=t3.medium
DISK_GB=30
ROLE=personal-learning-ec2-ssm
SG_NAME=personal-learning-ec2-no-ingress
NAME=personal-learning-lab
NAME="${LAB_NAME:-$NAME}"
export AWS_PAGER=""
log() { printf '[%s] [INFO] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }
warn() { printf '[%s] [WARN] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }
awsx() { aws --profile "$PROFILE" --region "$REGION" "$@"; }
die() { printf "[%s] [ERROR] %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; exit 1; }
require() { command -v "$1" >/dev/null || die "Missing $1"; }
identity() { awsx sts get-caller-identity --query Account --output text; }
tag() { awsx ec2 describe-instances --instance-ids "$1" --query "Reservations[0].Instances[0].Tags[?Key=='ManagedBy'].Value|[0]" --output text; }
verify() {
  [[ "$1" =~ ^i-[0-9a-f]{8,17}$ ]] || die "Bad instance ID"
  [[ "$(tag "$1")" == general-learning-lab ]] || die "Not a managed lab instance"
  local acct
  acct="$(awsx ec2 describe-instances --instance-ids "$1" --query "Reservations[0].Instances[0].Tags[?Key=='OwnerAccount'].Value|[0]" --output text)"
  [[ "$acct" == "$(identity)" ]] || die "Instance account mismatch"
}
validate_name() {
  [[ "$NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]{0,62}$ ]] || die "Invalid lab name: $NAME"
}
find_existing() {
  local entries
  entries="$(awsx ec2 describe-instances --filters "Name=tag:Name,Values=$NAME" "Name=tag:ManagedBy,Values=general-learning-lab" "Name=tag:OwnerAccount,Values=$(identity)" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query 'Reservations[].Instances[].InstanceId' --output text)"
  [[ -n "$entries" && "$entries" != None ]] || return 1
  local ids=()
  read -r -a ids <<< "$entries"
  [[ "${#ids[@]}" -eq 1 ]] || die "Multiple active instances named $NAME; use an instance ID to resolve"
  EXISTING_ID="${ids[0]}"
}
wait_for_ssm() {
  local id="$1" state attempt
  log "Waiting for SSM agent on $id"
  for ((attempt=1; attempt<=18; attempt++)); do
    state="$(awsx ssm describe-instance-information --filters "Key=InstanceIds,Values=$id" --query "InstanceInformationList[0].PingStatus" --output text)"
    if [[ "$state" == Online ]]; then log "SSM agent online"; return 0; fi
    sleep 10
  done
  die "SSM agent did not come online for $id"
}
setup_role() {
  log "Preparing SSM IAM role and instance profile: $ROLE"
  if ! awsx iam get-role --role-name "$ROLE" >/dev/null 2>&1; then
    awsx iam create-role --role-name "$ROLE" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
  fi
  awsx iam attach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
  if ! awsx iam get-instance-profile --instance-profile-name "$ROLE" >/dev/null 2>&1; then
    awsx iam create-instance-profile --instance-profile-name "$ROLE" >/dev/null
  fi
  local attached
  attached="$(awsx iam get-instance-profile --instance-profile-name "$ROLE" --query 'InstanceProfile.Roles[0].RoleName' --output text)"
  if [[ "$attached" == None ]]; then
    awsx iam add-role-to-instance-profile --instance-profile-name "$ROLE" --role-name "$ROLE"
    sleep 15
  elif [[ "$attached" != "$ROLE" ]]; then die "Existing instance profile uses another role"; fi
}
network() {
  log "Discovering default VPC and subnet in $REGION"
  local vpc
  vpc="$(awsx ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)"
  [[ "$vpc" != None ]] || die "No default VPC in $REGION; restore it before launch"
  SUBNET="$(awsx ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" Name=default-for-az,Values=true --query 'sort_by(Subnets[?AvailableIpAddressCount > `5`],&AvailableIpAddressCount)[-1].SubnetId' --output text)"
  [[ "$SUBNET" != None ]] || die "No available default subnet"
  log "Selected VPC=$vpc subnet=$SUBNET"
  SG="$(awsx ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text)"
  if [[ "$SG" == None ]]; then
    SG="$(awsx ec2 create-security-group --group-name "$SG_NAME" --description 'No inbound access for disposable learning EC2' --vpc-id "$vpc" --query GroupId --output text)"
  fi
  local ingress
  ingress="$(awsx ec2 describe-security-groups --group-ids "$SG" --query 'length(SecurityGroups[0].IpPermissions)' --output text)"
  [[ "$ingress" == 0 ]] || die "Security group has inbound rules: $SG"
  log "Security group ready: $SG (no inbound rules)"
}
boot_data() {
  log "Preparing cloud-init for dotfiles and packages"
  USER_DATA="$(mktemp)"
  cat > "$USER_DATA" <<'CLOUD'
#!/bin/bash
set -euxo pipefail
# Ensure cleanup even when the SSM connection is abandoned.
systemd-run --unit=lab-timeout --on-active=240m /usr/sbin/shutdown -h now
echo "[INFO] Installing git for bootstrap"
dnf install -y git
# Session Manager opens as ssm-user, not ec2-user.
# Set up both users with a writable project directory and matching dotfiles.
echo "[INFO] Creating writable learning workspaces"
if ! id ssm-user >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash ssm-user
fi
for lab_user in ssm-user ec2-user; do
  lab_home="$(getent passwd "$lab_user" | cut -d: -f6)"
  install -d -m 0750 -o "$lab_user" -g "$lab_user" "$lab_home/projects"
  if [ ! -d "$lab_home/dotfiles/.git" ]; then
    runuser -u "$lab_user" -- git clone --depth 1 https://github.com/naren4b/dotfiles.git "$lab_home/dotfiles"
  fi
done
echo "[INFO] Installing general-purpose toolchain"
bash /home/ssm-user/dotfiles/bootstrap/amazon-linux-ec2.sh
for lab_user in ssm-user ec2-user; do
  lab_home="$(getent passwd "$lab_user" | cut -d: -f6)"
  echo "[INFO] Installing dotfiles for $lab_user"
  runuser -u "$lab_user" -- env HOME="$lab_home" bash "$lab_home/dotfiles/install.sh"
done
echo "[INFO] Checking base tools"
for tool in git curl make docker; do
  command -v "$tool" >/dev/null || exit 1
done
touch /var/log/personal-lab-ready
echo "[INFO] Lab bootstrap complete"
CLOUD
}
preflight() {
  log "Checking local prerequisites (region=$REGION profile=$PROFILE)"
  require aws
  require session-manager-plugin
  awsx sts get-caller-identity --query Account --output text >/dev/null || die "AWS profile default is not authenticated"
  log "AWS credentials and Session Manager plugin available"
}
start() {
  preflight
  validate_name
  network
  setup_role
  log "IAM and network prerequisites ready"
  boot_data
  local ami id
  ami="$(awsx ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)"
  log "Launching $NAME ($TYPE with ${DISK_GB}GiB gp3) in $REGION"
  id="$(awsx ec2 run-instances --image-id "$ami" --instance-type "$TYPE" --count 1 --subnet-id "$SUBNET" --security-group-ids "$SG" --associate-public-ip-address --iam-instance-profile "Name=$ROLE" --metadata-options 'HttpTokens=required,HttpEndpoint=enabled,HttpPutResponseHopLimit=2' --instance-initiated-shutdown-behavior terminate --block-device-mappings "DeviceName=/dev/xvda,Ebs={VolumeSize=$DISK_GB,VolumeType=gp3,Encrypted=true,DeleteOnTermination=true}" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME},{Key=ManagedBy,Value=general-learning-lab},{Key=OwnerAccount,Value=$(identity)}]" --user-data "file://$USER_DATA" --query 'Instances[0].InstanceId' --output text)"
  rm -f "$USER_DATA"
  LAB_ID="$id"
  echo "INSTANCE_ID=$id"
  log "Waiting for EC2 instance to reach running state: $id"
  awsx ec2 wait instance-running --instance-ids "$id"
  log "Instance running: $id"
  wait_for_ssm "$id"
}
connect() {
  require session-manager-plugin
  log "Connecting to SSM instance $1 (user: ssm-user)"
  log "If bootstrap is still running, inspect: sudo cloud-init status --wait"
  verify "$1"
  awsx ssm start-session --target "$1"
}
end() {
  log "Terminating instance $1"
  verify "$1"
  awsx ec2 terminate-instances --instance-ids "$1" >/dev/null
  awsx ec2 wait instance-terminated --instance-ids "$1"
  log "Instance terminated: $1"
}
ACTION="${1:-lab}"
if [[ "$ACTION" == lab || "$ACTION" == start ]]; then
  NAME="${2:-$NAME}"
fi
case "$ACTION" in
  start) start ;;
  connect) [[ $# -eq 2 ]] || die "Usage: $0 connect i-..."; connect "$2" ;;
  end) [[ $# -eq 2 ]] || die "Usage: $0 end i-..."; end "$2" ;;
  lab)
    preflight
    validate_name
    log "Checking for existing lab: $NAME"
    if find_existing; then
      state="$(awsx ec2 describe-instances --instance-ids "$EXISTING_ID" --query 'Reservations[0].Instances[0].State.Name' --output text)"
      case "$state" in
        running)
          log "Reusing running instance $EXISTING_ID; session exit will leave it running"
          wait_for_ssm "$EXISTING_ID"
          connect "$EXISTING_ID"
          ;;
        pending)
          log "Waiting for existing instance $EXISTING_ID to start"
          awsx ec2 wait instance-running --instance-ids "$EXISTING_ID"
          wait_for_ssm "$EXISTING_ID"
          connect "$EXISTING_ID"
          ;;
        *)
          die "Existing instance $EXISTING_ID is $state. End it explicitly before creating another."
          ;;
      esac
    else
      LAB_ID=""
      cleanup() {
        trap - EXIT INT TERM
        if [[ -n "$LAB_ID" ]]; then
          end "$LAB_ID" || warn "Cleanup failed for $LAB_ID. Terminate it manually."
        fi
      }
      trap cleanup EXIT INT TERM
      start
      log "Created $LAB_ID; session exit will terminate this new instance"
      connect "$LAB_ID"
    fi
    ;;
  *) die "Usage: $0 [lab [NAME]|start [NAME]|connect INSTANCE_ID|end INSTANCE_ID]" ;;
esac
