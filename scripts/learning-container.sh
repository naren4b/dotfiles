#!/usr/bin/env bash
# Run an unprivileged learning container. Docker on EC2; Podman elsewhere.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE=localhost/my-learning:local
WORKSPACE="$HOME/projects"
mkdir -p "$WORKSPACE"
if command -v podman >/dev/null 2>&1; then
  ENGINE=(podman)
  EXTRA=(--userns=keep-id)
elif command -v docker >/dev/null 2>&1; then
  ENGINE=(sudo docker)
  EXTRA=()
else
  echo "[ERROR] No container runtime found. Check cloud-init status." >&2
  exit 1
fi
echo "[INFO] Container runtime: ${ENGINE[*]}"
if ! "${ENGINE[@]}" image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[INFO] Building learning image"
  "${ENGINE[@]}" build --tag "$IMAGE" -f "$ROOT/containers/learning/Containerfile" "$ROOT/containers/learning"
fi
echo "[INFO] Opening unprivileged learning shell: $WORKSPACE"
exec "${ENGINE[@]}" run --rm -it --name "my-learning-$$" \
  --security-opt no-new-privileges --cap-drop=ALL \
  "${EXTRA[@]}" --user "$(id -u):$(id -g)" \
  --volume "$WORKSPACE:/workspace" --workdir /workspace \
  "$IMAGE" /bin/bash
