#!/usr/bin/env bash
# Conservative cleanup. Does not delete volumes or all unused images.
set -euo pipefail
command -v podman >/dev/null || { echo "Podman is not installed" >&2; exit 1; }
echo "Current container disk usage:"
podman system df
echo
read -r -p "Remove dangling Podman images only? [y/N] " answer
case "$answer" in
  y|Y|yes|YES) podman image prune; podman system df ;;
  *) echo "No changes made." ;;
esac
