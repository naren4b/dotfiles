#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a; source "$ROOT/.env"; set +a
fi
command -v docker >/dev/null || { echo "ERROR: Docker missing; cloud-init may still be running." >&2; exit 1; }
mkdir -p "$HOME/projects"
IMAGE="${LAB_IMAGE:-my-learning:local}"
if [[ "$IMAGE" == my-learning:local ]]; then
  sudo docker build -t "$IMAGE" -f "$ROOT/containers/learning/Containerfile" "$ROOT/containers/learning"
fi
args=(--rm -it --network host --cap-drop ALL --security-opt no-new-privileges
  --user "$(id -u):$(id -g)" --mount "type=bind,source=$HOME/projects,target=/workspace"
  --workdir /workspace --stop-timeout 10)
if [[ -n "${LAB_ENV_FILE:-}" ]]; then
  [[ -f "$LAB_ENV_FILE" ]] || { echo "ERROR: LAB_ENV_FILE missing: $LAB_ENV_FILE" >&2; exit 1; }
  args+=(--env-file "$LAB_ENV_FILE")
fi
# The interactive lab is bounded by timeout; EC2 independently shuts down at four hours.
timeout --foreground --signal=TERM --kill-after=10s 4h sudo docker run "${args[@]}" "$IMAGE" /bin/bash
