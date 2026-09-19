#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/dotfiles.sh
source "$ROOT/lib/dotfiles.sh"

fail=0

check_link() {
  local dest="$1" src="$2"
  src="$(abs_path "$src")"
  if same_link "$dest" "$src"; then
    echo "ok   $dest -> $src"
  elif [[ -e "$dest" ]]; then
    echo "WARN $dest exists but is not the repo symlink"
    fail=1
  else
    echo "MISS $dest"
    fail=1
  fi
}

check_exists() {
  local dest="$1"
  if [[ -e "$dest" ]]; then
    echo "ok   $dest"
  else
    echo "MISS $dest"
    fail=1
  fi
}

echo "dotfiles: $DOTFILES_ROOT"
echo "os: $OS"
echo

check_link "$HOME/.bashrc" "$DOTFILES_ROOT/config/shell/bashrc"
check_link "$HOME/.bash_aliases" "$DOTFILES_ROOT/config/shell/bash_aliases"
check_link "$HOME/.tmux.conf" "$DOTFILES_ROOT/config/tmux/tmux.conf"
check_link "$HOME/.vimrc" "$DOTFILES_ROOT/config/shell/vimrc"
check_link "$HOME/.gitconfig" "$DOTFILES_ROOT/config/git/gitconfig"
check_link "$HOME/.gitmessage" "$DOTFILES_ROOT/config/git/gitmessage"
check_link "$HOME/.config/starship.toml" "$DOTFILES_ROOT/config/starship/starship.toml"
check_exists "$HOME/.bashrc.local"
check_exists "$HOME/.gitconfig.local"

if [[ "$OS" == "windows" ]]; then
  check_link "$HOME/.minttyrc" "$DOTFILES_ROOT/config/shell/minttyrc"
fi

if should_link_editors; then
  check_link "$(cursor_user_dir)/settings.json" "$DOTFILES_ROOT/config/cursor/settings.json"
  check_link "$(cursor_user_dir)/keybindings.json" "$DOTFILES_ROOT/config/cursor/keybindings.json"
  check_link "$(vscode_user_dir)/settings.json" "$DOTFILES_ROOT/config/vscode/settings.json"
  check_link "$(vscode_user_dir)/keybindings.json" "$DOTFILES_ROOT/config/vscode/keybindings.json"
fi

echo
if grep -R -n -E '(PASSWORD|SECRET|TOKEN|aws_secret_access_key)[[:space:]]*=[[:space:]]*[^[:space:]#]+|BEGIN OPENSSH' \
  --exclude='*.example' \
  "$DOTFILES_ROOT/config" "$DOTFILES_ROOT/install.sh" "$DOTFILES_ROOT/lib" 2>/dev/null; then
  echo "FAIL secret-like string found in tracked files"
  fail=1
else
  echo "ok   no secret-like strings in tracked config"
fi

echo
if [[ "$fail" -eq 0 ]]; then
  echo "doctor: all checks passed"
else
  echo "doctor: problems found"
  exit 1
fi
