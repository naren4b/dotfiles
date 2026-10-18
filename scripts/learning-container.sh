#!/usr/bin/env bash
# On-host lab container runner, invoked as the SSM session user.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE=localhost/my-learning:local
WORKSPACE="$HOME/projects"
mkdir -p "$WORKSPACE"
if ! command -v podman >/dev/null 2>&1; then
  echo "ERROR: Podman missing. Run sudo cloud-init status --wait" >&2
  exit 1
fi
if ! podman image exists "$IMAGE"; then
  echo "[INFO] Building learning container from dotfiles. This can take several minutes."
  podman build --tag "$IMAGE" -f "$ROOT/containers/learning/Containerfile" "$ROOT/containers/learning"
fi
echo "[INFO] Starting unprivileged learning shell in $WORKSPACE"
exec podman run --rm -it --name "my-learning-$$" \
  --security-opt no-new-privileges --cap-drop=ALL \
  --userns=keep-id --user "$(id -u):$(id -g)" \
  --volume "$WORKSPACE:/workspace:Z" --workdir /workspace \
  "$IMAGE" /bin/bash
