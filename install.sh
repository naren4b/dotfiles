#!/usr/bin/env bash
set -euo pipefail

# Native Windows symlinks so Cursor/VS Code edits write back into this repo.
export MSYS="${MSYS:+$MSYS }winsymlinks:nativestrict"

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/dotfiles.sh
source "$ROOT/lib/dotfiles.sh"

echo "dotfiles: $DOTFILES_ROOT"
echo "os: $OS"
echo

preserve_existing_as_local "$HOME/.bashrc" "$HOME/.bashrc.local"
preserve_existing_as_local "$HOME/.gitconfig" "$HOME/.gitconfig.local"

ensure_local_from_example "$HOME/.bashrc.local" "$DOTFILES_ROOT/config/shell/bashrc.local.example"
ensure_local_from_example "$HOME/.gitconfig.local" "$DOTFILES_ROOT/config/git/gitconfig.local.example"

link_file "$DOTFILES_ROOT/config/shell/bashrc" "$HOME/.bashrc"
link_file "$DOTFILES_ROOT/config/shell/bash_aliases" "$HOME/.bash_aliases"
link_file "$DOTFILES_ROOT/config/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_ROOT/config/shell/vimrc" "$HOME/.vimrc"
link_file "$DOTFILES_ROOT/config/git/gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_ROOT/config/git/gitmessage" "$HOME/.gitmessage"

if [[ "$OS" == "windows" ]]; then
  link_file "$DOTFILES_ROOT/config/shell/minttyrc" "$HOME/.minttyrc"
fi

mkdir -p "$HOME/.config"
link_file "$DOTFILES_ROOT/config/starship/starship.toml" "$HOME/.config/starship.toml"

# IDE links: Windows (and macOS) only. WSL/Linux use Windows Cursor.
if [[ "$OS" == "windows" || "$OS" == "macos" ]]; then
  cursor_dir="$(cursor_user_dir)"
  vscode_dir="$(vscode_user_dir)"
  mkdir -p "$cursor_dir" "$vscode_dir"
  link_file "$DOTFILES_ROOT/config/cursor/settings.json" "$cursor_dir/settings.json"
  link_file "$DOTFILES_ROOT/config/cursor/keybindings.json" "$cursor_dir/keybindings.json"
  link_file "$DOTFILES_ROOT/config/vscode/settings.json" "$vscode_dir/settings.json"
  link_file "$DOTFILES_ROOT/config/vscode/keybindings.json" "$vscode_dir/keybindings.json"
else
  echo "skip editors on $OS (IDE lives on Windows; see cursor-system-setup.md)"
fi

merge_windows_terminal_scheme || true

echo
echo "Done. Company/secrets stay in ~/.bashrc.local and ~/.gitconfig.local (never overwritten if present)."
echo "Dry-run: $ROOT/dry-run.sh"
echo "Company verify (read-only): $ROOT/company/verify-company.sh"
echo "Full Windows stack: powershell -File bootstrap/windows.ps1"
echo "Full Ubuntu stack:  ./bootstrap/ubuntu.sh"
