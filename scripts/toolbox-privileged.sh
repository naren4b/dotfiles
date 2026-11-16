#!/usr/bin/env bash
# Opt-in privileged CLI toolbox for trusted, local learning labs.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${TOOLBOX_IMAGE:-lab-toolbox:local}"

command -v docker >/dev/null || { echo "Docker is required on the host" >&2; exit 1; }
docker info >/dev/null || { echo "Docker daemon is not accessible" >&2; exit 1; }

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build -t "$IMAGE" "$ROOT/toolbox"
fi

# Docker daemon socket gives effective host administrator access.
# Only use with trusted projects and trusted images.
args=(
  --rm -it
  --network host
  --user 0:0
  --privileged
  --mount "type=bind,src=$PWD,dst=/work"
  --workdir /work
  --env HOME=/root
)

# Optional access to the host's Docker daemon for KIND and docker CLI.
if [[ -S /var/run/docker.sock ]]; then
  args+=(--mount "type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock")
fi

# Optional Kubernetes and AWS credentials, explicitly enabled.
if [[ "${TOOLBOX_MOUNT_KUBE:-0}" == 1 && -d "$HOME/.kube" ]]; then
  args+=(--mount "type=bind,src=$HOME/.kube,dst=/root/.kube")
fi
if [[ "${TOOLBOX_MOUNT_AWS:-0}" == 1 && -d "$HOME/.aws" ]]; then
  args+=(--mount "type=bind,src=$HOME/.aws,dst=/root/.aws,readonly")
fi

exec docker run "${args[@]}" "$IMAGE" "${@:-bash}"
