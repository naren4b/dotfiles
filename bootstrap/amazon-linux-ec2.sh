#!/usr/bin/env bash
# Opinionated, reusable Amazon Linux 2023 lab toolchain. No credentials stored.
set -Eeuo pipefail
info() { printf '[INFO] %s\n' "$*"; }
fatal() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
[[ -f /etc/os-release ]] || fatal "Missing /etc/os-release"
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID:-}" == amzn ]] || fatal "Amazon Linux required"
[[ $(id -u) -eq 0 ]] || fatal "Run as root"
case "$(uname -m)" in
  x86_64) arch=amd64; aws_arch=x86_64 ;;
  aarch64) arch=arm64; aws_arch=aarch64 ;;
  *) fatal "Unsupported architecture" ;;
esac
info "Installing core OS packages"
dnf install -y git curl wget unzip tar gzip jq python3 python3-pip vim make findutils podman
info "Checking AWS CLI"
if ! command -v aws >/dev/null 2>&1; then
  temp="$(mktemp -d)"
  trap 'rm -rf "$temp"' EXIT
  curl -fsSL --retry 3 "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o "$temp/aws.zip"
  unzip -q "$temp/aws.zip" -d "$temp"
  "$temp/aws/install"
fi
info "Installing yq"
if ! command -v yq >/dev/null 2>&1; then
  curl -fsSL --retry 3 "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${arch}" -o /usr/local/bin/yq
  chmod 0755 /usr/local/bin/yq
fi
info "Installing kubectl"
if ! command -v kubectl >/dev/null 2>&1; then
  version="$(curl -fsSL --retry 3 https://dl.k8s.io/release/stable.txt)"
  curl -fsSL --retry 3 "https://dl.k8s.io/release/${version}/bin/linux/${arch}/kubectl" -o /usr/local/bin/kubectl
  chmod 0755 /usr/local/bin/kubectl
fi
info "Installing Helm"
if ! command -v helm >/dev/null 2>&1; then
  temp="$(mktemp -d)"
  trap 'rm -rf "$temp"' EXIT
  curl -fsSL --retry 3 https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 -o "$temp/get-helm-3"
  bash "$temp/get-helm-3"
fi
info "Installing Terraform from HashiCorp RPM repository"
if ! command -v terraform >/dev/null 2>&1; then
  dnf install -y dnf-plugins-core
  dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
  dnf install -y terraform
fi
info "Verifying toolchain"
for tool in aws git curl jq yq kubectl helm terraform python3 podman make; do
  command -v "$tool" >/dev/null || fatal "Missing $tool"
  info "Ready: $tool"
done
info "Docker Hub: use podman login docker.io interactively when needed"
info "GitHub: configure git identity or gh auth interactively when needed"
info "AWS: instance role provides SSM only; use explicit least-privilege roles for additional AWS APIs"
info "Base toolchain ready"
