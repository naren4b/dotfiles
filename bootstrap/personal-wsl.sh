#!/usr/bin/env bash
# Personal Ubuntu WSL development profile. Does not touch company configuration.
set -euo pipefail

mode="${1:-check}"
workspace="$HOME/ws/personal"
cv_repo="$workspace/my-cv"

if ! grep -qi microsoft /proc/version /proc/sys/kernel/osrelease 2>/dev/null; then
  echo "ERROR: requires Ubuntu WSL" >&2
  exit 2
fi

check() {
  echo "Workspace: $workspace"
  for cmd in git ssh gh python3.12 pipx node npm codex make jq curl aws terraform kubectl helm podman; do
    printf '%-14s ' "$cmd"
    command -v "$cmd" || echo "not installed"
  done
  if [ -d "$cv_repo/.git" ]; then
    echo "Git email: $(git -C "$cv_repo" config user.email || true)"
    if [ -x "$cv_repo/.venv/bin/python" ]; then
      "$cv_repo/.venv/bin/python" -m playwright --version || true
    fi
  fi
}

case "$mode" in
  check) check ;;
  install)
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
      git openssh-client curl wget ca-certificates unzip zip jq make \
      build-essential python3 python3-venv python3-pip pipx gh
    if ! command -v python3.12 >/dev/null 2>&1; then
      echo "ERROR: Python 3.12 required (Ubuntu 24.04 recommended)" >&2
      exit 1
    fi
    export NVM_DIR="$HOME/.nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
      echo "Install nvm from https://github.com/nvm-sh/nvm then rerun" >&2
      exit 1
    fi
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm alias default 'lts/*'
    npm install -g @openai/codex@latest
    mkdir -p "$workspace"
    if [ -d "$cv_repo/.git" ]; then
      python3.12 -m venv "$cv_repo/.venv"
      "$cv_repo/.venv/bin/python" -m pip install -r \
        "$cv_repo/cv-architect-v2/requirements.txt"
      "$cv_repo/.venv/bin/python" -m playwright install --with-deps chromium
    else
      echo "CV repo not cloned: skipping Playwright setup"
    fi
    check
    ;;
  *) echo "Usage: $0 [check|install]" >&2; exit 2 ;;
esac
