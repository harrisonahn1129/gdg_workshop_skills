#!/usr/bin/env bash
# Checks for, installs, or opens the Antigravity 2.0 desktop app on macOS or Linux.
# (Windows: use antigravity.ps1.)
# The 2.0 desktop app (bundle id com.google.antigravity) is NOT the separate
# "Antigravity IDE" (com.google.antigravity-ide); only the former counts as installed.
#
# Usage: antigravity.sh check | install | open
# Output: INSTALLED=yes|no, APP_PATH=..., VERSION=..., PLATFORM=..., STATUS=...
set -uo pipefail

DOWNLOAD_PAGE="https://antigravity.google/download"
# Fallback if the download page can't be parsed (last verified 2026-10-20).
FALLBACK_BASE="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.24.0-5780333019398144"
MAC_BUNDLE_ID="com.google.antigravity"
LINUX_DIR="$HOME/.local/share/Antigravity"

os="$(uname -s)"
case "$(uname -m)" in
  arm64 | aarch64) arch="arm" ;;
  *) arch="x64" ;;
esac

# Picks the newest official installer URL for a platform, e.g. "darwin-arm/Antigravity.dmg".
installer_url() {
  local suffix="$1" url
  url="$(curl -fsSL --compressed "$DOWNLOAD_PAGE" 2>/dev/null |
    grep -oE "https://storage\.googleapis\.com/antigravity-public/antigravity-hub/[0-9][^\"'\\ ]*/${suffix}" |
    sort -V | tail -n1)"
  echo "${url:-$FALLBACK_BASE/$suffix}"
}

mac_app_path() {
  local p
  for p in "/Applications/Antigravity.app" "$HOME/Applications/Antigravity.app"; do
    if [[ -d "$p" && "$(defaults read "$p/Contents/Info" CFBundleIdentifier 2>/dev/null)" == "$MAC_BUNDLE_ID" ]]; then
      echo "$p"
      return
    fi
  done
  mdfind "kMDItemCFBundleIdentifier == '$MAC_BUNDLE_ID'" 2>/dev/null | head -n1
}

linux_app_path() {
  local exe
  exe="$(find "$LINUX_DIR" -maxdepth 3 -type f -name Antigravity -perm -u+x 2>/dev/null | head -n1)"
  [[ -n "$exe" ]] && echo "$exe"
}

check() {
  echo "PLATFORM=$os-$arch"
  local p
  if [[ "$os" == "Darwin" ]]; then
    p="$(mac_app_path)"
    if [[ -n "$p" ]]; then
      echo "INSTALLED=yes"
      echo "APP_PATH=$p"
      echo "VERSION=$(defaults read "$p/Contents/Info" CFBundleShortVersionString 2>/dev/null)"
      return 0
    fi
  elif [[ "$os" == "Linux" ]]; then
    p="$(linux_app_path)"
    if [[ -n "$p" ]]; then
      echo "INSTALLED=yes"
      echo "APP_PATH=$p"
      return 0
    fi
  fi
  echo "INSTALLED=no"
  return 1
}

install_mac() {
  if command -v brew >/dev/null 2>&1; then
    echo "METHOD=homebrew"
    brew install --cask antigravity || return 1
    return 0
  fi
  echo "METHOD=dmg"
  local url tmp mnt
  url="$(installer_url "darwin-$arch/Antigravity.dmg")"
  echo "DOWNLOAD_URL=$url"
  tmp="$(mktemp -d)"
  curl -fL --progress-bar "$url" -o "$tmp/Antigravity.dmg" || return 1
  mnt="$(hdiutil attach -nobrowse -readonly "$tmp/Antigravity.dmg" | awk -F'\t' '/\/Volumes\//{print $NF}' | tail -n1)"
  [[ -d "$mnt/Antigravity.app" ]] || { hdiutil detach "$mnt" -quiet; return 1; }
  rm -rf "/Applications/Antigravity.app"
  cp -R "$mnt/Antigravity.app" /Applications/ || { hdiutil detach "$mnt" -quiet; return 1; }
  hdiutil detach "$mnt" -quiet
  rm -rf "$tmp"
}

install_linux() {
  echo "METHOD=tarball"
  local url tmp exe
  url="$(installer_url "linux-$arch/Antigravity.tar.gz")"
  echo "DOWNLOAD_URL=$url"
  tmp="$(mktemp -d)"
  curl -fL --progress-bar "$url" -o "$tmp/Antigravity.tar.gz" || return 1
  rm -rf "$LINUX_DIR"
  mkdir -p "$LINUX_DIR"
  tar -xzf "$tmp/Antigravity.tar.gz" -C "$LINUX_DIR" || return 1
  rm -rf "$tmp"
  exe="$(linux_app_path)"
  [[ -n "$exe" ]] || return 1
  mkdir -p "$HOME/.local/bin"
  ln -sf "$exe" "$HOME/.local/bin/antigravity-app"
  echo "LAUNCHER=$HOME/.local/bin/antigravity-app"
}

# Cloud Shell is a remote VM, not the attendee's laptop: never install there.
if [[ "${CLOUD_SHELL:-}" == "true" ]]; then
  echo "ENVIRONMENT=cloudshell"
  echo "STATUS=remote_machine"
  echo "HINT=Install Antigravity on your laptop from $DOWNLOAD_PAGE"
  exit 0
fi

case "${1:-check}" in
  check)
    check
    ;;
  install)
    if check >/dev/null; then
      echo "STATUS=already_installed"
      check
      exit 0
    fi
    case "$os" in
      Darwin) install_mac ;;
      Linux) install_linux ;;
      *) echo "STATUS=unsupported_os"; echo "HINT=On Windows run scripts/antigravity.ps1"; exit 1 ;;
    esac
    if check >/dev/null; then
      echo "STATUS=installed"
      check
    else
      echo "STATUS=failed"
      exit 1
    fi
    ;;
  open)
    if [[ "$os" == "Darwin" ]]; then
      open -b "$MAC_BUNDLE_ID" && echo "STATUS=opened"
    else
      exe="$(linux_app_path)"
      [[ -n "$exe" ]] || { echo "STATUS=not_installed"; exit 1; }
      nohup "$exe" >/dev/null 2>&1 &
      echo "STATUS=opened"
    fi
    ;;
  *)
    echo "Usage: $0 check|install|open" >&2
    exit 2
    ;;
esac
