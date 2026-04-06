#!/bin/bash
set -e

echo "Starting dbus..."
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true

echo "Starting Xvfb on display :1..."
Xvfb :1 -screen 0 800x600x24 +extension GLX &
sleep 2

echo "Starting x11vnc on display :1 (port 5900)..."
x11vnc -display :1 -forever -nopw -listen 0.0.0.0 -rfbport 5900 -shared &
sleep 1

# Determine launch command — use vglrun if available, fallback to direct
if command -v vglrun &>/dev/null; then
    STEAM_CMD="vglrun steam"
    echo "Starting Steam with VirtualGL..."
else
    STEAM_CMD="steam"
    echo "WARNING: vglrun not found, starting Steam without GPU acceleration."
fi

echo "Starting Steam as botuser..."
su -s /bin/bash botuser -c "export DISPLAY=:1 VGL_DISPLAY=egl HOME=/home/botuser; $STEAM_CMD" &

echo "All services started. Connect via VNC to configure Steam."
wait
