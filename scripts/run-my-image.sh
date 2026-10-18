#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then set -a; source "$ROOT/.env"; set +a; fi
command -v docker >/dev/null || { echo "ERROR: Docker not installed"; exit 1; }
sudo docker info >/dev/null || { echo "ERROR: Docker daemon not ready"; exit 1; }
mkdir -p "$HOME/projects"
IMAGE="${LAB_IMAGE:-my-learning:local}"
if [[ "$IMAGE" == my-learning:local ]]; then
  sudo docker build -t "$IMAGE" -f "$ROOT/containers/learning/Containerfile" "$ROOT"
fi
args=(--rm -it --network host --cap-drop ALL --security-opt no-new-privileges
  --user "$(id -u):$(id -g)" --mount "type=bind,source=$HOME/projects,target=/workspace"
  --workdir /workspace --stop-timeout 10)
if [[ -n "${LAB_ENV_FILE:-}" ]]; then
  [[ -f "$LAB_ENV_FILE" ]] || { echo "ERROR: LAB_ENV_FILE missing: $LAB_ENV_FILE" >&2; exit 1; }
  args+=(--env-file "$LAB_ENV_FILE")
fi
# EC2 and container both use a four-hour lifetime cap.
name="my-learning-$$"
(timeout --foreground --signal=TERM --kill-after=15s 4h sudo docker run --name "$name" "${args[@]}" "$IMAGE" /bin/bash) || code=$?
sudo docker stop "$name" >/dev/null 2>&1 || true
exit "${code:-0}"
