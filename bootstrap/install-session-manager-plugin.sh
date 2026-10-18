#!/usr/bin/env bash
# Install the AWS Session Manager plugin on Debian/Ubuntu when absent.
set -euo pipefail

if command -v session-manager-plugin >/dev/null 2>&1; then
  echo "[INFO] Session Manager plugin already installed"
  exit 0
fi

command -v dpkg >/dev/null 2>&1 || {
  echo "[ERROR] Session Manager plugin installer requires Debian or Ubuntu" >&2
  exit 1
}
command -v curl >/dev/null 2>&1 || {
  echo "[ERROR] curl is required" >&2
  exit 1
}

case "$(dpkg --print-architecture)" in
  amd64) package_arch=ubuntu_64bit ;;
  arm64) package_arch=ubuntu_arm64 ;;
  *) echo "[ERROR] Unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
echo "[INFO] Downloading AWS Session Manager plugin ($package_arch)"
curl --fail --location --silent --show-error --retry 3 \
  "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/$package_arch/session-manager-plugin.deb" \
  --output "$tmpdir/session-manager-plugin.deb"
echo "[INFO] Installing AWS Session Manager plugin"
sudo dpkg -i "$tmpdir/session-manager-plugin.deb"
command -v session-manager-plugin >/dev/null 2>&1 || {
  echo "[ERROR] Plugin installation did not create executable" >&2; exit 1;
}
echo "[INFO] Session Manager plugin is installed"
