#!/usr/bin/env bash
# dry-run.sh — compare this machine to the local repo, and the local repo to GitHub.
# Makes no changes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/dotfiles.sh
source "$ROOT/lib/dotfiles.sh"

DIFFS=0
MISSING=0
SAME=0

echo "=== dry-run (no changes) ==="
echo "dotfiles: $DOTFILES_ROOT"
echo "os:       $OS"
echo

normalize_text() {
  local kind="${1:-}"
  if [[ "$kind" == "bashrc" ]]; then
    sed -E 's/\r$//; s/[[:space:]]+$//' \
      | grep -Ev '^[[:space:]]*export[[:space:]]+[A-Za-z0-9_]*(PASSWORD|SECRET|TOKEN|API_KEY)[A-Za-z0-9_]*[[:space:]]*=' \
      || true
  else
    sed -E 's/\r$//; s/[[:space:]]+$//'
  fi
}

compare_pair() {
  local label="$1" live="$2" repo="$3" kind="${4:-}"
  printf "%-28s " "$label"

  if [[ ! -e "$live" && ! -L "$live" ]]; then
    echo "LIVE_MISSING  $live"
    MISSING=$((MISSING + 1))
    return
  fi
  if [[ ! -e "$repo" ]]; then
    echo "REPO_MISSING  $repo"
    MISSING=$((MISSING + 1))
    return
  fi

  if [[ -L "$live" ]]; then
    local target want
    target="$(readlink "$live" 2>/dev/null || true)"
    want="$(abs_path "$repo")"
    if [[ "$target" == "$want" ]]; then
      echo "LINKED_OK     $live -> $target"
      SAME=$((SAME + 1))
      return
    fi
    echo "LINK_DIFF     $live -> $target (expected $want)"
    DIFFS=$((DIFFS + 1))
    return
  fi

  local tmp_live tmp_repo
  tmp_live="$(mktemp)"
  tmp_repo="$(mktemp)"
  normalize_text "$kind" <"$live" >"$tmp_live"
  normalize_text "$kind" <"$repo" >"$tmp_repo"

  if cmp -s "$tmp_live" "$tmp_repo"; then
    echo "SAME          $live"
    SAME=$((SAME + 1))
  else
    echo "DIFF          $live  vs  $repo"
    DIFFS=$((DIFFS + 1))
    if command -v diff >/dev/null 2>&1; then
      diff -u "$tmp_repo" "$tmp_live" | head -n 30 | sed 's/^/    /' || true
    fi
  fi
  rm -f "$tmp_live" "$tmp_repo"
}

echo "--- live system vs local repo ---"
compare_pair "bashrc" "$HOME/.bashrc" "$DOTFILES_ROOT/config/shell/bashrc" bashrc
compare_pair "bash_aliases" "$HOME/.bash_aliases" "$DOTFILES_ROOT/config/shell/bash_aliases"
compare_pair "tmux.conf" "$HOME/.tmux.conf" "$DOTFILES_ROOT/config/tmux/tmux.conf"
compare_pair "vimrc" "$HOME/.vimrc" "$DOTFILES_ROOT/config/shell/vimrc"
compare_pair "gitconfig" "$HOME/.gitconfig" "$DOTFILES_ROOT/config/git/gitconfig"
compare_pair "gitmessage" "$HOME/.gitmessage" "$DOTFILES_ROOT/config/git/gitmessage"
compare_pair "starship.toml" "$HOME/.config/starship.toml" "$DOTFILES_ROOT/config/starship/starship.toml"

if [[ "$OS" == "windows" ]]; then
  compare_pair "minttyrc" "$HOME/.minttyrc" "$DOTFILES_ROOT/config/shell/minttyrc"
fi

if [[ -d "$(cursor_user_dir)" || -d "$(vscode_user_dir)" ]]; then
  compare_pair "cursor/settings" "$(cursor_user_dir)/settings.json" "$DOTFILES_ROOT/config/cursor/settings.json"
  compare_pair "cursor/keybindings" "$(cursor_user_dir)/keybindings.json" "$DOTFILES_ROOT/config/cursor/keybindings.json"
  compare_pair "vscode/settings" "$(vscode_user_dir)/settings.json" "$DOTFILES_ROOT/config/vscode/settings.json"
  compare_pair "vscode/keybindings" "$(vscode_user_dir)/keybindings.json" "$DOTFILES_ROOT/config/vscode/keybindings.json"
fi

echo
echo "--- local-only (expected; not in GitHub) ---"
for f in "$HOME/.bashrc.local" "$HOME/.gitconfig.local"; do
  if [[ -e "$f" ]]; then
    echo "ok   $f"
  else
    echo "miss $f"
  fi
done

echo
echo "--- local repo vs GitHub (origin/main) ---"
cd "$DOTFILES_ROOT"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git fetch origin --quiet 2>/dev/null || true
  if git rev-parse origin/main >/dev/null 2>&1; then
    ahead="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)"
    behind="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo 0)"
    echo "branch: $(git rev-parse --abbrev-ref HEAD)"
    echo "ahead of origin/main:  $ahead"
    echo "behind origin/main:    $behind"
    echo
    git status -sb
    echo
    if git ls-tree -r --name-only origin/main | grep -qE '^(config/|install\.sh|doctor\.sh|dry-run\.sh)'; then
      echo "portable paths present on origin/main"
    else
      echo "portable baseline NOT on GitHub yet (need commit + push)"
      DIFFS=$((DIFFS + 1))
    fi
  else
    echo "WARN  origin/main not found"
  fi
fi

echo
echo "=== summary: same=$SAME diff=$DIFFS missing=$MISSING ==="
echo "No files were changed."
[[ "$DIFFS" -eq 0 && "$MISSING" -eq 0 ]]
