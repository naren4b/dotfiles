#!/usr/bin/env bash
# verify-company.sh — READ ONLY. Never modifies company settings.
# Reports OK / MISSING / SET for typical company overlay signals.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../lib/dotfiles.sh
source "$ROOT/lib/dotfiles.sh"

echo "=== company verify (read-only) ==="
echo "os=$OS home=$HOME"
echo

check_file() {
  local label="$1" path="$2"
  printf "%-32s " "$label"
  if [[ -e "$path" ]]; then
    echo "OK      $path"
  else
    echo "MISSING $path"
  fi
}

check_env() {
  local name="$1"
  printf "%-32s " "$name"
  if [[ -n "${!name:-}" ]]; then
    echo "SET     (value hidden)"
  else
    echo "UNSET"
  fi
}

check_git_snippet() {
  local label="$1" pattern="$2"
  printf "%-32s " "$label"
  if git config --global --list 2>/dev/null | grep -qiE "$pattern"; then
    echo "OK      (matched in git config)"
  elif [[ -f "$HOME/.gitconfig.local" ]] && grep -qiE "$pattern" "$HOME/.gitconfig.local" 2>/dev/null; then
    echo "OK      (matched in ~/.gitconfig.local)"
  else
    echo "MISSING"
  fi
}

check_file "~/.bashrc.local" "$HOME/.bashrc.local"
check_file "~/.gitconfig.local" "$HOME/.gitconfig.local"
check_file "~/.netrc" "$HOME/.netrc"
check_file "~/.ssh" "$HOME/.ssh"
check_file "~/.kube" "$HOME/.kube"
check_file "~/.aws/credentials" "$HOME/.aws/credentials"
check_file "SSL CA (Git Windows common)" "$HOME/AppData/Local/Programs/Git/mingw64/etc/ssl/certs/ca-bundle.crt"

check_env HTTP_PROXY
check_env HTTPS_PROXY
check_env SSL_CERT_FILE
check_env REQUESTS_CA_BUNDLE
check_env NOKIA_PASSWORD

check_git_snippet "nokia git host" "nokia|gitlab|credential"
check_git_snippet "includeIf worktree" "includeif"

echo
echo "This script never writes files. Company settings stay untouched."
echo "See company/*.example for placeholders only."
