#!/usr/bin/env bash
# Run an unprivileged learning container. Docker on EC2; Podman elsewhere.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE=localhost/my-learning:local
WORKSPACE="$HOME/projects"
mkdir -p "$WORKSPACE"
# Clone on the host before entering Docker so credentials never enter the image.
REPOSITORY_URL="https://github.com/naren4b/learn-aws.git"
REPOSITORY_DIR="$WORKSPACE/learn-aws"
if [[ ! -d "$REPOSITORY_DIR/.git" ]]; then
  echo "[INFO] Cloning learn-aws into $REPOSITORY_DIR"
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    askpass="$(mktemp)"
    cleanup_git() { rm -f "$askpass"; }
    trap cleanup_git EXIT
    cat > "$askpass" <<'ASKPASS'
#!/bin/sh
case "$1" in
  *Username*) printf '%s\\n' 'x-access-token' ;;
  *Password*) printf '%s\\n' "$GITHUB_TOKEN" ;;
esac
ASKPASS
    chmod 700 "$askpass"
    GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0 \
      git -c credential.helper= clone "$REPOSITORY_URL" "$REPOSITORY_DIR"
    cleanup_git
    trap - EXIT
  else
    echo "[INFO] No GITHUB_TOKEN set; attempting public clone without credentials"
    GIT_TERMINAL_PROMPT=0 git -c credential.helper= clone "$REPOSITORY_URL" "$REPOSITORY_DIR" || {
      echo "[ERROR] Clone failed. Export GITHUB_TOKEN before make lab-local." >&2
      exit 1
    }
  fi
else
  echo "[INFO] Reusing existing $REPOSITORY_DIR (no automatic pull)"
fi
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
