#!/usr/bin/env bash
# Shared dotfiles setup for Ubuntu EC2 and the Ubuntu learning image.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${SETUP_PACKAGES:-1}" == 1 ]]; then
  command -v apt-get >/dev/null || { echo "ERROR: setup.sh requires Ubuntu/Debian"; exit 1; }
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git curl ca-certificates bash-completion vim unzip jq make python3 python3-pip
fi
bash "$ROOT/install.sh"
echo "[INFO] dotfiles setup complete"
