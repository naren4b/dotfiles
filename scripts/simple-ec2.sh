#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT/.env" ]] || { echo "ERROR: Copy .env.example to .env and configure it." >&2; exit 2; }
set -a; source "$ROOT/.env"; set +a
AWS_REGION="${AWS_REGION:-ap-south-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"
EC2_TYPE="${EC2_TYPE:-t3.medium}"
EC2_DISK_GB="${EC2_DISK_GB:-30}"
LAB_HOURS="${LAB_HOURS:-4}"
[[ "$LAB_HOURS" =~ ^[1-9][0-9]?$ ]] || { echo "ERROR: LAB_HOURS must be an integer from 1 to 99" >&2; exit 2; }
LAB_MINUTES="$((LAB_HOURS * 60))"
TAG=dotfiles-ubuntu-lab
action="${1:-}"; name="${2:-}"
[[ "$action" =~ ^(launch|ssh|delete)$ && "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]{0,62}$ ]] || { echo "Usage: $0 launch|ssh|delete <name>" >&2; exit 2; }
command -v aws >/dev/null || { echo "ERROR: AWS CLI missing" >&2; exit 2; }
SSH_KEY_PATH="${SSH_KEY_PATH:-~/my-ec2}"
SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"
[[ -f "$SSH_KEY_PATH" ]] || { echo "ERROR: Private key missing: $SSH_KEY_PATH (set SSH_KEY_PATH in .env)" >&2; exit 2; }
[[ -n "${AWS_KEY_NAME:-}" ]] || { echo "ERROR: Set AWS_KEY_NAME to the matching EC2 key pair name" >&2; exit 2; }
awsx() { aws --profile "$AWS_PROFILE" --region "$AWS_REGION" "$@"; }
ids="$(awsx ec2 describe-instances --filters "Name=tag:Name,Values=$name" "Name=tag:ManagedBy,Values=$TAG" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query 'Reservations[].Instances[].InstanceId' --output text)"
[[ "$ids" != *$'\t'* && "$ids" != *' '* ]] || { echo "ERROR: More than one matching instance exists: $ids" >&2; exit 1; }
if [[ "$action" == launch && -n "$ids" && "$ids" != None ]]; then
  echo "EXISTS: $name ($ids). No changes made."
  exit 0
fi
if [[ "$action" != launch ]]; then
  [[ -n "$ids" && "$ids" != None ]] || { echo "ERROR: No $name instance found. Run make launch-ec2 NAME=$name" >&2; exit 1; }
  if [[ "$action" == delete ]]; then
    awsx ec2 terminate-instances --instance-ids "$ids" >/dev/null
    echo "Termination requested: $ids"
    exit 0
  fi
  state="$(awsx ec2 describe-instances --instance-ids "$ids" --query 'Reservations[0].Instances[0].State.Name' --output text)"
  [[ "$state" == running ]] || { echo "ERROR: Instance $ids is $state" >&2; exit 1; }
  ip="$(awsx ec2 describe-instances --instance-ids "$ids" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)"
  [[ -n "$ip" && "$ip" != None ]] || { echo "ERROR: No public IP for $ids" >&2; exit 1; }
  exec ssh -o StrictHostKeyChecking=accept-new -i "$SSH_KEY_PATH" "ubuntu@$ip"
fi
[[ -n "${SSH_CIDR:-}" ]] || { echo "ERROR: Set SSH_CIDR in .env (your public IP /32)" >&2; exit 2; }
[[ "$SSH_CIDR" =~ ^[0-9.]+/32$ ]] || { echo "ERROR: SSH_CIDR must be an IPv4 /32" >&2; exit 2; }
awsx ec2 describe-key-pairs --key-names "$AWS_KEY_NAME" >/dev/null
vpc="$(awsx ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId' --output text)"
[[ "$vpc" != None ]] || { echo "ERROR: Default VPC not found" >&2; exit 1; }
subnet="$(awsx ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" Name=default-for-az,Values=true --query 'Subnets[0].SubnetId' --output text)"
[[ "$subnet" != None ]] || { echo "ERROR: Default subnet not found" >&2; exit 1; }
sgname="dotfiles-lab-ssh-${name}"
sg="$(awsx ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" "Name=group-name,Values=$sgname" --query 'SecurityGroups[0].GroupId' --output text)"
if [[ "$sg" == None ]]; then
  sg="$(awsx ec2 create-security-group --group-name "$sgname" --description "Restricted SSH for dotfiles learning labs" --vpc-id "$vpc" --query GroupId --output text)"
fi
# Fail closed when the existing SG contains unexpected ingress. Do not widen shared rules.
rules="$(awsx ec2 describe-security-groups --group-ids "$sg" --query 'SecurityGroups[0].IpPermissions' --output json)"
if [[ "$rules" != '[]' ]]; then
  echo "ERROR: Existing $sgname has ingress rules. Use a fresh, audited SG before launching." >&2
  exit 1
fi
awsx ec2 authorize-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr "$SSH_CIDR" >/dev/null
# Canonical public SSM parameter for Ubuntu 24.04 LTS amd64.
ami="$(awsx ssm get-parameter --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id --query Parameter.Value --output text)"
[[ "$ami" == ami-* ]] || { echo "ERROR: Ubuntu AMI lookup failed" >&2; exit 1; }
userdata="$(mktemp)"; trap 'rm -f "$userdata"' EXIT
cat >"$userdata" <<'CLOUD'
#!/bin/bash
set -euxo pipefail
# Best-effort OS shutdown, with EC2 shutdown behavior terminate.
systemd-run --unit=dotfiles-expiry --on-active=__LAB_MINUTES__m /usr/sbin/shutdown -h now
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y git docker.io make
systemctl enable --now docker
touch /var/log/dotfiles-host-ready
CLOUD
sed -i "s/__LAB_MINUTES__/$LAB_MINUTES/" "$userdata"
id="$(awsx ec2 run-instances --image-id "$ami" --instance-type "$EC2_TYPE" --count 1 --subnet-id "$subnet" --security-group-ids "$sg" --associate-public-ip-address --key-name "$AWS_KEY_NAME" --instance-initiated-shutdown-behavior terminate --metadata-options HttpTokens=required,HttpEndpoint=enabled --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=$EC2_DISK_GB,VolumeType=gp3,Encrypted=true,DeleteOnTermination=true}" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name},{Key=ManagedBy,Value=$TAG}]" --user-data "file://$userdata" --query 'Instances[0].InstanceId' --output text)"
echo "LAUNCHED: $name ($id), region $AWS_REGION. Run make ssh-ec2 NAME=$name when ready."
echo "NOTE: Shutdown after $LAB_HOURS hour(s) is OS-based, not AWS-enforced expiry."
