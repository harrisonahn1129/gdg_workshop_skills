#!/usr/bin/env bash
# Checks that gcloud is installed and shows which Google account it is signed in as.
# Usage: preflight.sh
# Output (key=value lines): GCLOUD_INSTALLED, GCLOUD_VERSION, ACTIVE_ACCOUNT, OS, ARCH
set -uo pipefail

os="$(uname -s)"
arch="$(uname -m)"
echo "OS=$os"
echo "ARCH=$arch"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "GCLOUD_INSTALLED=no"
  exit 0
fi

echo "GCLOUD_INSTALLED=yes"
echo "GCLOUD_VERSION=$(gcloud --version 2>/dev/null | head -n1 | awk '{print $NF}')"
account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | head -n1)"
echo "ACTIVE_ACCOUNT=${account:-none}"
