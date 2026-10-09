#!/usr/bin/env bash
# Read-only report for Ubuntu, WSL, VM and EC2.
set -euo pipefail
echo "== Environment =="
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo "Platform: WSL"
elif [[ -f /sys/hypervisor/uuid ]] && grep -qi '^ec2' /sys/hypervisor/uuid; then
  echo "Platform: EC2"
else
  echo "Platform: Linux"
fi
echo
echo "== Memory and disk =="
free -h
df -h "$HOME"
echo
echo "== Developer storage =="
for path in "$HOME/projects" "$HOME/.cache" "$HOME/.terraform.d/plugin-cache" "$HOME/.local/share/containers"; do
  [[ -e "$path" ]] && du -sh "$path" 2>/dev/null || true
done
echo
echo "== Podman usage =="
if command -v podman >/dev/null 2>&1; then
  podman system df || echo "Podman is installed but unavailable to current user."
else
  echo "Podman not installed"
fi
echo
echo "== Watch limits =="
for key in max_user_watches max_user_instances max_queued_events; do
  [[ -r "/proc/sys/fs/inotify/$key" ]] && printf '%s: %s\n' "$key" "$(cat "/proc/sys/fs/inotify/$key")"
done
echo
echo "No files changed."
