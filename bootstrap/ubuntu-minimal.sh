#!/usr/bin/env bash
# Lean baseline for Ubuntu on WSL, VMs and EC2. No IDE or Docker daemon.
set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: Ubuntu/Debian with apt is required. No changes made." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y \
  ca-certificates curl unzip gnupg wget git \
  python3 python3-venv python3-pip podman

if ! command -v terraform >/dev/null 2>&1; then
  sudo install -d -m 0755 /usr/share/keyrings
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  . /etc/os-release
  codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
  if [[ -z "$codename" ]]; then
    echo "ERROR: Could not find distribution codename" >&2
    exit 1
  fi
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $codename main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y terraform
fi

if ! command -v aws >/dev/null 2>&1; then
  case "$(uname -m)" in
    x86_64) aws_arch=x86_64 ;;
    aarch64|arm64) aws_arch=aarch64 ;;
    *) echo "ERROR: AWS CLI architecture unsupported: $(uname -m)" >&2; exit 1 ;;
  esac
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o "$tmpdir/aws.zip"
  unzip -q "$tmpdir/aws.zip" -d "$tmpdir"
  sudo "$tmpdir/aws/install"
fi

# Terraform cache is shared across repositories. Do not duplicate providers.
mkdir -p "$HOME/projects" "$HOME/.terraform.d/plugin-cache"
if [[ ! -e "$HOME/.terraformrc" ]]; then
  printf 'plugin_cache_dir = "%s/.terraform.d/plugin-cache"\n' "$HOME" > "$HOME/.terraformrc"
else
  echo "Keeping existing ~/.terraformrc. Configure plugin_cache_dir manually if needed."
fi

for cmd in git python3 terraform podman aws; do
  command -v "$cmd" >/dev/null || { echo "ERROR: Missing $cmd" >&2; exit 1; }
done
echo "Lean baseline installed. Projects: ~/projects"
echo "Next: ./scripts/storage-report.sh and ./doctor.sh"
