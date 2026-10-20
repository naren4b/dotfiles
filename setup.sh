#!/usr/bin/env bash
# Shared dotfiles setup for Ubuntu EC2 and the Ubuntu learning image.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${SETUP_PACKAGES:-1}" == 1 ]]; then
  command -v apt-get >/dev/null || { echo "ERROR: setup.sh requires Ubuntu/Debian"; exit 1; }
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git curl ca-certificates bash-completion vim unzip jq make python3 python3-pip python3-venv tree
fi
# Install official AWS CLI v2, not the potentially older apt awscli package.
if ! command -v aws >/dev/null 2>&1; then
  command -v unzip >/dev/null || { echo "ERROR: unzip is required for AWS CLI" >&2; exit 1; }
  case "$(uname -m)" in
    x86_64) aws_arch=x86_64 ;;
    aarch64) aws_arch=aarch64 ;;
    *) echo "ERROR: Unsupported AWS CLI architecture" >&2; exit 1 ;;
  esac
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --retry 3 "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o "$tmp/awscliv2.zip"
  unzip -q "$tmp/awscliv2.zip" -d "$tmp"
  sudo "$tmp/aws/install" --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli
  rm -rf "$tmp"
  trap - EXIT
fi
aws --version
bash "$ROOT/install.sh"
echo "[INFO] dotfiles setup complete"
