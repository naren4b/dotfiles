#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/dotfiles.sh
source "$ROOT/lib/dotfiles.sh"

restore() {
  local dest="$1"
  if [[ -L "$dest" ]]; then
    rm "$dest"
    echo "removed link $dest"
  fi
  local latest
  latest="$(ls -1dt "$dest".bak.* 2>/dev/null | head -n 1 || true)"
  if [[ -n "$latest" ]]; then
    mv "$latest" "$dest"
    echo "restored $dest from $latest"
  fi
}

restore "$HOME/.bashrc"
restore "$HOME/.bash_aliases"
restore "$HOME/.tmux.conf"
restore "$HOME/.vimrc"
restore "$HOME/.gitconfig"
restore "$HOME/.gitmessage"
restore "$HOME/.minttyrc"
restore "$HOME/.config/starship.toml"

if should_link_editors; then
  restore "$(cursor_user_dir)/settings.json"
  restore "$(cursor_user_dir)/keybindings.json"
  restore "$(vscode_user_dir)/settings.json"
  restore "$(vscode_user_dir)/keybindings.json"
fi

echo "Local files ~/.bashrc.local and ~/.gitconfig.local were left in place."
