#!/usr/bin/env bash
# Toolchain and environment checks for portable baseline (read-only).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../lib/dotfiles.sh
source "$ROOT/lib/dotfiles.sh"

fail=0
warn=0

note_ok() { echo "ok   $*"; }
note_warn() { echo "WARN $*"; warn=$((warn + 1)); }
note_fail() { echo "FAIL $*"; fail=$((fail + 1)); }

platform_label() {
  case "$OS" in
    wsl) echo "WSL2" ;;
    linux)
      if [[ -r /sys/hypervisor/uuid ]] && grep -qi '^ec2' /sys/hypervisor/uuid 2>/dev/null; then
        echo "EC2 (hypervisor hint)"
      elif [[ -r /run/systemd/container ]] && grep -qi ec2 /run/systemd/container 2>/dev/null; then
        echo "EC2 (systemd hint)"
      else
        echo "Linux"
      fi
      ;;
    windows) echo "Windows" ;;
    macos) echo "macOS" ;;
    *) echo "unknown" ;;
  esac
}

check_version() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    local line
    line="$("$@" 2>&1 | head -1 || true)"
    note_ok "$name: ${line:-present}"
  else
    note_fail "$name not on PATH"
  fi
}

echo "== Baseline verify =="
echo "platform: $(platform_label) (detect_os=$OS)"
echo "home: $HOME"
echo

if [[ "$OS" == "wsl" || "$OS" == "linux" ]]; then
  check_version git git --version
  check_version python3 python3 --version
  check_version terraform terraform version
  check_version podman podman --version
  check_version aws aws --version

  if command -v docker >/dev/null 2>&1 && command -v podman >/dev/null 2>&1; then
    note_warn "both docker and podman on PATH — prefer rootless podman only to save disk and avoid duplicate runtimes"
  elif command -v docker >/dev/null 2>&1; then
    note_warn "docker on PATH — portable baseline expects rootless podman (see podman-setup.md)"
  fi

  if command -v aws >/dev/null 2>&1; then
    mapfile -t aws_bins < <(type -a aws 2>/dev/null | sed -n 's/.* is \(.*\)$/\1/p')
    if [[ "${#aws_bins[@]}" -gt 1 ]]; then
      note_warn "multiple aws binaries: ${aws_bins[*]}"
    fi
  fi

  cache_dir="$HOME/.terraform.d/plugin-cache"
  if [[ -d "$cache_dir" ]]; then
    note_ok "terraform plugin cache dir exists: $cache_dir"
  else
    note_warn "missing $cache_dir (ubuntu-minimal creates it)"
  fi

  if [[ -f "$HOME/.terraformrc" ]] && grep -q 'plugin_cache_dir' "$HOME/.terraformrc" 2>/dev/null; then
    note_ok "~/.terraformrc sets plugin_cache_dir"
  elif [[ -f "$HOME/.terraformrc" ]]; then
    note_warn "~/.terraformrc exists but has no plugin_cache_dir (left unchanged by design)"
  else
    note_warn "no ~/.terraformrc — run ubuntu-minimal or set plugin_cache_dir manually"
  fi

  if [[ -d "$HOME/projects" ]]; then
    note_ok "~/projects layout directory exists"
  else
    note_warn "~/projects missing (ubuntu-minimal creates it)"
  fi

  echo
  echo "== inotify (informational) =="
  for key in max_user_watches max_user_instances; do
    if [[ -r "/proc/sys/fs/inotify/$key" ]]; then
      echo "  $key=$(cat "/proc/sys/fs/inotify/$key")"
    fi
  done
else
  note_ok "skipping Linux toolchain checks on os=$OS"
fi

echo
if [[ "$fail" -gt 0 ]]; then
  echo "verify-baseline: $fail failure(s), $warn warning(s)"
  exit 1
fi
if [[ "$warn" -gt 0 ]]; then
  echo "verify-baseline: passed with $warn warning(s)"
  exit 0
fi
echo "verify-baseline: all checks passed"
exit 0
