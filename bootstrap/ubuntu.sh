#!/usr/bin/env bash
# Full-stack Ubuntu bootstrap: shell look-and-feel + CLI toolchain.
# No Cursor/VS Code install. Never overwrites company *.local.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../lib/dotfiles.sh
source "$ROOT/lib/dotfiles.sh"

echo "=== Ubuntu full-stack bootstrap ==="
echo "dotfiles: $ROOT  os=$OS"

if [[ "$OS" != "linux" && "$OS" != "wsl" ]]; then
  echo "WARN: expected linux/wsl, got $OS — continuing anyway"
fi

chmod +x "$ROOT/install.sh" "$ROOT/doctor.sh" "$ROOT/dry-run.sh" "$ROOT/harvest.sh" "$ROOT/uninstall.sh" 2>/dev/null || true

echo "--- shell / git links ---"
"$ROOT/install.sh"

echo "--- apt packages ---"
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git curl vim unzip ca-certificates fzf bash-completion \
    || true
fi

have() { command -v "$1" >/dev/null 2>&1; }

echo "--- toolchain (skip if already present) ---"

if ! have kubectl; then
  echo "install kubectl"
  curl -fsSLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/kubectl
fi

if ! have helm; then
  echo "install helm"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

if ! have terraform && command -v apt-get >/dev/null 2>&1; then
  echo "install terraform"
  wget -O- https://apt.releases.hashicorp.com/gpg 2>/dev/null | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg || true
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null || true
  sudo apt-get update -y && sudo apt-get install -y terraform || true
fi

if ! have tofu; then
  echo "install opentofu"
  curl -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
  chmod +x /tmp/install-opentofu.sh
  /tmp/install-opentofu.sh --install-method standalone --skip-verify || true
  rm -f /tmp/install-opentofu.sh
fi

if ! have terragrunt; then
  echo "install terragrunt"
  curl -fsSL https://docs.terragrunt.com/install | bash || true
fi

if ! have aws; then
  echo "install awscliv2"
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -qo /tmp/awscliv2.zip -d /tmp
  sudo /tmp/aws/install || true
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

if ! have starship; then
  echo "install starship"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y || true
fi

if ! have docker && ! have podman; then
  echo "install docker.io"
  sudo apt-get install -y docker.io || sudo apt-get install -y podman || true
fi

if ! have gh; then
  echo "install gh"
  (type -p wget >/dev/null && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null \
    && sudo apt-get update && sudo apt-get install -y gh) || true
fi

if ! have glab; then
  echo "install glab (snap or binary)"
  sudo snap install glab 2>/dev/null || true
fi

echo
echo "Interactive auth (tokens stay local):"
echo "  gh auth login"
echo "  glab auth login"
echo "Company overlay: never modified. Run: $ROOT/company/verify-company.sh"
echo "Done."
