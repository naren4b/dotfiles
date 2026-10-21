#!/usr/bin/env bash
# Profile dispatcher. Reuse existing bootstraps and preserve company settings.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
profile="${1:-}"
action="${2:-check}"

case "$profile:$action" in
  personal-wsl:check|personal-wsl:install)
    exec bash "$root/bootstrap/personal-wsl.sh" "$action"
    ;;
  ofc-wsl:check)
    if ! grep -qi microsoft /proc/version /proc/sys/kernel/osrelease 2>/dev/null; then
      echo "ERROR: ofc-wsl requires WSL" >&2
      exit 2
    fi
    exec bash "$root/company/verify-company.sh"
    ;;
  ofc-wsl:install)
    echo "ERROR: ofc-wsl is read-only; corporate installation needs separate approval" >&2
    exit 2
    ;;
  ec2-apt:install)
    if ! command -v apt-get >/dev/null 2>&1; then
      echo "ERROR: ec2-apt requires apt" >&2
      exit 2
    fi
    exec bash "$root/bootstrap/ubuntu-minimal.sh"
    ;;
  ec2-yum:install)
    if ! command -v dnf >/dev/null 2>&1; then
      echo "ERROR: ec2-yum requires Amazon Linux with dnf" >&2
      exit 2
    fi
    exec bash "$root/bootstrap/amazon-linux-ec2.sh"
    ;;
  ec2-apt:check|ec2-yum:check)
    echo "Profile: $profile (read-only command availability)"
    for cmd in git curl make python3 aws terraform podman docker; do
      if command -v "$cmd" >/dev/null 2>&1; then
        printf 'ok: %s\n' "$cmd"
      else
        printf 'missing: %s\n' "$cmd"
      fi
    done
    ;;
  *)
    echo "Usage: make profile-{check,install} PROFILE={personal-wsl,ofc-wsl,ec2-apt,ec2-yum}" >&2
    exit 2
    ;;
esac
