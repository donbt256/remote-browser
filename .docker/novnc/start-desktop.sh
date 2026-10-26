#!/usr/bin/env bash
set -euo pipefail

mkdir -p /config /home/browser/.vnc
chown -R browser:browser /config /home/browser

cat > /home/browser/.vnc/xstartup <<'XSTARTUP'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session startxfce4
XSTARTUP
chown browser:browser /home/browser/.vnc/xstartup
chmod 0755 /home/browser/.vnc/xstartup

# VNC is only reachable inside this container. The authenticated host proxy
# exposes the noVNC web client, not the raw VNC port.
su - browser -c 'vncserver :1 -geometry 1600x900 -depth 24 -localhost yes -SecurityTypes None'

websockify --web=/usr/share/novnc 0.0.0.0:6080 127.0.0.1:5901 &
WEBSOCKIFY_PID=$!

# Reuse the Chromium profile folder from the previous LinuxServer-based setup.
mkdir -p /config/Chromium
chown -R browser:browser /config
sleep 2
su - browser -c 'DISPLAY=:1 google-chrome --no-sandbox --disable-dev-shm-usage --user-data-dir=/config/Chromium --no-first-run --no-default-browser-check --start-maximized' &
CHROME_PID=$!

cleanup() {
  kill "$CHROME_PID" "$WEBSOCKIFY_PID" 2>/dev/null || true
  su - browser -c 'vncserver -kill :1' >/dev/null 2>&1 || true
}
trap cleanup EXIT TERM INT

wait "$WEBSOCKIFY_PID"
