#!/usr/bin/env bash
# Minimal EC2 host dependencies. Development tools belong in learning container.
set -Eeuo pipefail
echo "[INFO] Preparing EC2 container host"
source /etc/os-release
[[ "$ID" == amzn ]] || { echo "[ERROR] Expected Amazon Linux" >&2; exit 1; }
dnf install -y git curl make podman shadow-utils
for tool in git curl make podman; do
  command -v "$tool" >/dev/null || { echo "[ERROR] Missing $tool" >&2; exit 1; }
done
echo "[INFO] EC2 container host ready"
