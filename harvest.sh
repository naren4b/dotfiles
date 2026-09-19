#!/usr/bin/env bash
# harvest.sh — copy THIS machine's live configs into the repo (source of truth).
# Strips secrets and absolute Temp paths. Does not overwrite existing *.local.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/dotfiles.sh
source "$ROOT/lib/dotfiles.sh"

if command -v py >/dev/null 2>&1; then
  PY=(py -3)
elif command -v python3 >/dev/null 2>&1; then
  PY=(python3)
elif command -v python >/dev/null 2>&1; then
  PY=(python)
else
  echo "ERROR: need py -3 or python3 to harvest JSON settings"
  exit 1
fi

echo "harvest into: $DOTFILES_ROOT (os=$OS)"

"${PY[@]}" - "$DOTFILES_ROOT" "$(cursor_user_dir)" "$(vscode_user_dir)" <<'PY'
import json, re, sys
from pathlib import Path

repo = Path(sys.argv[1])
cursor_dir = Path(sys.argv[2])
vscode_dir = Path(sys.argv[3])

def strip_abs(settings: dict) -> dict:
    loc = settings.get("chat.instructionsFilesLocations")
    if isinstance(loc, dict):
        keep = {}
        for k, v in loc.items():
            if re.match(r"^[A-Za-z]:\\", k) or "AppData\\Local\\Temp" in k or "AppData/Local/Temp" in k:
                continue
            keep[k] = v
        settings["chat.instructionsFilesLocations"] = keep
    settings.pop("azureTerraform.survey", None)
    settings.pop("redhat.telemetry.enabled", None)
    settings.pop("json.schemas", None)
    return settings

def harvest_editor(name: str, user_dir: Path):
    if not user_dir.is_dir():
        print(f"skip {name}: no dir {user_dir}")
        return
    out = repo / "config" / name
    out.mkdir(parents=True, exist_ok=True)
    kb = user_dir / "keybindings.json"
    st = user_dir / "settings.json"
    if kb.exists():
        text = kb.read_text(encoding="utf-8")
        if name == "vscode" and "workbench.action.terminal.sendSequence" not in text and "ctrl+l" not in text.lower():
            ctrl = '''    {
        "key": "ctrl+l",
        "command": "workbench.action.terminal.sendSequence",
        "args": { "text": "\\u000c" },
        "when": "terminalFocus"
    },
'''
            text = text.replace("[\n", "[\n" + ctrl, 1)
        (out / "keybindings.json").write_text(text, encoding="utf-8", newline="\n")
        print(f"ok  {name}/keybindings.json")
    if st.exists():
        data = strip_abs(json.loads(st.read_text(encoding="utf-8")))
        (out / "settings.json").write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8", newline="\n")
        print(f"ok  {name}/settings.json ({len(data)} keys)")

harvest_editor("cursor", cursor_dir)
harvest_editor("vscode", vscode_dir)
PY

if [[ -f "$HOME/.minttyrc" ]]; then
  cp "$HOME/.minttyrc" "$DOTFILES_ROOT/config/shell/minttyrc"
  echo "ok  minttyrc"
fi

if [[ -f "$HOME/.bashrc" ]]; then
  grep -Ev '^[[:space:]]*export[[:space:]]+[A-Za-z0-9_]*(PASSWORD|SECRET|TOKEN|API_KEY)[A-Za-z0-9_]*[[:space:]]*=' \
    "$HOME/.bashrc" >"$DOTFILES_ROOT/config/shell/bashrc.tmp" || true
  {
    cat "$DOTFILES_ROOT/config/shell/bashrc.tmp"
    echo
    echo '# Machine-only secrets/env (never committed)'
    echo 'if [ -f "$HOME/.bashrc.local" ]; then'
    echo '    . "$HOME/.bashrc.local"'
    echo 'fi'
  } >"$DOTFILES_ROOT/config/shell/bashrc"
  rm -f "$DOTFILES_ROOT/config/shell/bashrc.tmp"
  echo "ok  bashrc (secrets stripped)"

  if [[ ! -f "$HOME/.bashrc.local" ]]; then
    grep -E '^[[:space:]]*export[[:space:]]+[A-Za-z0-9_]*(PASSWORD|SECRET|TOKEN|API_KEY)[A-Za-z0-9_]*[[:space:]]*=' \
      "$HOME/.bashrc" >"$HOME/.bashrc.local" || true
    echo "created ~/.bashrc.local from harvested secrets"
  else
    echo "keep ~/.bashrc.local"
  fi
fi

if [[ -f "$HOME/.gitconfig" && ! -f "$HOME/.gitconfig.local" ]]; then
  cp "$HOME/.gitconfig" "$HOME/.gitconfig.local"
  echo "created ~/.gitconfig.local from live gitconfig"
else
  echo "keep ~/.gitconfig.local"
fi

if command -v cursor >/dev/null 2>&1; then
  cursor --list-extensions >"$DOTFILES_ROOT/config/extensions-cursor.txt" 2>/dev/null || true
  echo "ok  extensions-cursor.txt"
fi

cat >"$DOTFILES_ROOT/config/extensions-vscode.txt" <<'EOF'
sdras.night-owl
vscode-icons-team.vscode-icons
esbenp.prettier-vscode
foxundermoon.shell-format
ms-python.black-formatter
hashicorp.terraform
hediet.vscode-drawio
eamodio.gitlens
redhat.vscode-yaml
ms-vscode-remote.remote-wsl
ms-azuretools.vscode-docker
ms-kubernetes-tools.vscode-kubernetes-tools
golang.go
ms-python.python
EOF
echo "ok  extensions-vscode.txt"

if [[ -f "$DOTFILES_ROOT/config/extensions-cursor.txt" ]]; then
  cp "$DOTFILES_ROOT/config/extensions-cursor.txt" "$DOTFILES_ROOT/config/extensions.txt"
fi

echo
echo "Harvest done. Secrets stay in ~/.bashrc.local / ~/.gitconfig.local."
