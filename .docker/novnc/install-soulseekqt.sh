#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/config/apps"
APP_IMAGE="$APP_DIR/SoulseekQt.AppImage"
CONFIG_DIR="/config/SoulseekQt"
DOWNLOAD_URL="https://f004.backblazeb2.com/file/SoulseekQt/SoulseekQt-2024-6-30.AppImage"

mkdir -p "$APP_DIR" "$CONFIG_DIR" "$HOME/.config"

# Reject stale, truncated, or HTML error-page downloads instead of treating
# any executable file as a successfully installed AppImage.
is_elf_appimage() {
  [ -f "$1" ] || return 1
  [ "$(head -c 4 "$1" | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]
}

if ! is_elf_appimage "$APP_IMAGE"; then
  rm -f "$APP_IMAGE" "$APP_IMAGE.download"
  echo "Downloading SoulseekQt from the official Soulseek download server..."
  tmp="$APP_IMAGE.download"
  if ! curl -fL --retry 3 --connect-timeout 20 "$DOWNLOAD_URL" -o "$tmp"; then
    rm -f "$tmp"
    echo
    echo "ERROR: Download failed. Check the connection and click the desktop icon again."
    read -r -p "Press Enter to close..."
    exit 1
  fi

  if ! is_elf_appimage "$tmp"; then
    rm -f "$tmp"
    echo
    echo "ERROR: The download was not a valid Linux executable."
    echo "The file has been discarded. Please try again later."
    read -r -p "Press Enter to close..."
    exit 1
  fi

  chmod 0755 "$tmp"
  mv "$tmp" "$APP_IMAGE"
  echo "SoulseekQt downloaded and verified."
else
  echo "SoulseekQt executable already exists and passed the file check."
fi

# Keep SoulseekQt settings and login information with the persisted profile.
if [ ! -e "$HOME/.config/SoulseekQt" ] && [ ! -L "$HOME/.config/SoulseekQt" ]; then
  ln -s "$CONFIG_DIR" "$HOME/.config/SoulseekQt"
fi

echo
echo "Starting SoulseekQt..."
echo "If the client exits, the error message below should help diagnose why."
echo
set +e
"$APP_IMAGE" --appimage-extract-and-run
status=$?
set -e

echo
echo "SoulseekQt exited with status $status."
echo "If no window appeared, copy the error text above for troubleshooting."
read -r -p "Press Enter to close this window..."
exit "$status"
