#!/usr/bin/env bash
# Minimal Amazon Linux 2023 host for Docker-based learning labs.
set -Eeuo pipefail
echo "[INFO] Preparing EC2 Docker host"
# shellcheck disable=SC1091
source /etc/os-release
[[ "$ID" == amzn ]] || { echo "[ERROR] Expected Amazon Linux" >&2; exit 1; }
dnf install -y git make docker
# Amazon Linux provides curl-minimal by default. Do not install conflicting curl.
command -v curl >/dev/null || dnf install -y curl-minimal
systemctl enable --now docker
for tool in git curl make docker; do
  command -v "$tool" >/dev/null || { echo "[ERROR] Missing $tool" >&2; exit 1; }
done
docker info >/dev/null
echo "[INFO] Docker daemon ready; no user added to root-equivalent docker group"
