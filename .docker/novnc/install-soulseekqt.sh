#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/config/apps"
APP_IMAGE="$APP_DIR/SoulseekQt.AppImage"
CONFIG_DIR="/config/SoulseekQt"
DOWNLOAD_URL="https://soulseek.s3.us-west-2.amazonaws.com/SoulseekQt-2024-6-30.AppImage"

mkdir -p "$APP_DIR" "$CONFIG_DIR" "$HOME/.config"
if [ ! -x "$APP_IMAGE" ]; then
  echo "Downloading the official SoulseekQt Linux AppImage..."
  tmp="$APP_IMAGE.download"
  rm -f "$tmp"
  if ! curl -fL --retry 3 --connect-timeout 20 "$DOWNLOAD_URL" -o "$tmp"; then
    rm -f "$tmp"
    echo "Download failed. Check the connection and click the desktop icon again."
    read -r -p "Press Enter to close..."
    exit 1
  fi
  chmod 0755 "$tmp"
  mv "$tmp" "$APP_IMAGE"
fi

# Keep SoulseekQt settings and login information with the persisted profile.
if [ ! -e "$HOME/.config/SoulseekQt" ] && [ ! -L "$HOME/.config/SoulseekQt" ]; then
  ln -s "$CONFIG_DIR" "$HOME/.config/SoulseekQt"
fi

echo "Starting SoulseekQt..."
# --appimage-extract-and-run avoids requiring FUSE inside the container.
exec "$APP_IMAGE" --appimage-extract-and-run
