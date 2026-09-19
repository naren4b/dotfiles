# Shared helpers for install.sh, uninstall.sh, and doctor.sh.
# shellcheck shell=bash

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TS="$(date +%Y%m%d%H%M%S)"

detect_os() {
  local uname_s
  uname_s="$(uname -s 2>/dev/null || echo unknown)"
  case "$uname_s" in
    MINGW*|MSYS*|CYGWIN*) echo windows ;;
    Darwin) echo macos ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo wsl
      else
        echo linux
      fi
      ;;
    *) echo unknown ;;
  esac
}

OS="$(detect_os)"

windows_home() {
  if [[ -n "${USERPROFILE:-}" ]]; then
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -u "$USERPROFILE"
    else
      echo "$USERPROFILE"
    fi
  else
    echo "$HOME"
  fi
}

roaming_appdata() {
  if [[ -n "${APPDATA:-}" ]]; then
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -u "$APPDATA"
    else
      echo "$APPDATA"
    fi
  else
    echo "$(windows_home)/AppData/Roaming"
  fi
}

local_appdata() {
  if [[ -n "${LOCALAPPDATA:-}" ]]; then
    if command -v cygpath >/dev/null 2>&1; then
      cygpath -u "$LOCALAPPDATA"
    else
      echo "$LOCALAPPDATA"
    fi
  else
    echo "$(windows_home)/AppData/Local"
  fi
}

cursor_user_dir() {
  case "$OS" in
    windows) echo "$(roaming_appdata)/Cursor/User" ;;
    macos) echo "$HOME/Library/Application Support/Cursor/User" ;;
    wsl|linux) echo "$HOME/.config/Cursor/User" ;;
    *) echo "$HOME/.config/Cursor/User" ;;
  esac
}

vscode_user_dir() {
  case "$OS" in
    windows) echo "$(roaming_appdata)/Code/User" ;;
    macos) echo "$HOME/Library/Application Support/Code/User" ;;
    wsl|linux) echo "$HOME/.config/Code/User" ;;
    *) echo "$HOME/.config/Code/User" ;;
  esac
}

windows_terminal_settings() {
  local pkg unpackaged
  pkg="$(local_appdata)/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
  unpackaged="$(local_appdata)/Microsoft/Windows Terminal/settings.json"
  if [[ -f "$pkg" ]]; then
    echo "$pkg"
  elif [[ -f "$unpackaged" ]]; then
    echo "$unpackaged"
  else
    echo "$pkg"
  fi
}

abs_path() {
  local dir base
  dir="$(cd "$(dirname "$1")" && pwd)"
  base="$(basename "$1")"
  echo "$dir/$base"
}

same_link() {
  local dest="$1" src="$2"
  [[ -L "$dest" ]] || return 1
  local current
  current="$(readlink "$dest" 2>/dev/null || true)"
  [[ "$current" == "$src" ]]
}

backup_path() {
  local dest="$1"
  echo "${dest}.bak.${TS}"
}

link_file() {
  local src dest
  src="$(abs_path "$1")"
  dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "skip missing source: $src"
    return 1
  fi

  mkdir -p "$(dirname "$dest")"

  if same_link "$dest" "$src"; then
    echo "ok  $dest"
    return 0
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    mv "$dest" "$(backup_path "$dest")"
  fi

  export MSYS="${MSYS:+$MSYS }winsymlinks:nativestrict"
  if ln -sfn "$src" "$dest" 2>/dev/null && [[ -L "$dest" ]]; then
    echo "link $dest"
    return 0
  fi

  if command -v powershell.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
    local wsrc wdest
    wsrc="$(cygpath -w "$src")"
    wdest="$(cygpath -w "$dest")"
    if powershell.exe -NoProfile -Command "New-Item -ItemType SymbolicLink -Force -Path '${wdest}' -Target '${wsrc}' | Out-Null" >/dev/null 2>&1; then
      echo "link $dest"
      return 0
    fi
  fi

  echo "FAIL could not symlink $dest -> $src"
  return 1
}

ensure_local_from_example() {
  local dest="$1" example="$2"
  if [[ -e "$dest" ]]; then
    echo "keep $dest"
    return 0
  fi
  cp "$example" "$dest"
  echo "create $dest (edit this; it is not committed)"
}

preserve_existing_as_local() {
  local current="$1" local_file="$2"
  if [[ -f "$current" && ! -L "$current" && ! -e "$local_file" ]]; then
    cp "$current" "$local_file"
    echo "moved existing $(basename "$current") -> $local_file"
  fi
}

merge_windows_terminal_scheme() {
  local scheme="$DOTFILES_ROOT/config/windows-terminal/scheme.json"
  local settings py
  settings="$(windows_terminal_settings)"
  [[ "$OS" == "windows" ]] || return 0
  [[ -f "$settings" && -f "$scheme" ]] || return 0

  local py_args=()
  if command -v py >/dev/null 2>&1; then
    py_args=(py -3)
  elif command -v python3 >/dev/null 2>&1; then
    py_args=(python3)
  elif command -v python >/dev/null 2>&1; then
    py_args=(python)
  else
    echo "skip Windows Terminal scheme (python not found)"
    return 0
  fi

  "${py_args[@]}" - "$settings" "$scheme" <<'PY'
import json, sys
settings_path, scheme_path = sys.argv[1], sys.argv[2]
with open(settings_path, encoding="utf-8") as f:
    data = json.load(f)
with open(scheme_path, encoding="utf-8") as f:
    scheme = json.load(f)
schemes = data.setdefault("schemes", [])
name = scheme.get("name")
schemes[:] = [s for s in schemes if s.get("name") != name]
schemes.append(scheme)
defaults = data.setdefault("profiles", {}).setdefault("defaults", {})
defaults.setdefault("colorScheme", name)
with open(settings_path, "w", encoding="utf-8", newline="\n") as f:
    json.dump(data, f, indent=4)
    f.write("\n")
print("updated Windows Terminal scheme:", name)
PY
}

should_link_editors() {
  case "$OS" in
    windows|macos) return 0 ;;
    wsl|linux)
      [[ -d "$(cursor_user_dir)" || -d "$(vscode_user_dir)" ]]
      ;;
    *) return 1 ;;
  esac
}
