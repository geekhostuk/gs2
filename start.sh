#!/bin/bash
set -e

echo "Starting dbus..."
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true

echo "Cleaning up stale X locks..."
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

echo "Starting headless Xorg on display :1 with NVIDIA GPU..."
Xorg :1 -noreset -config /etc/X11/xorg.conf &
sleep 3

# Verify Xorg started
if [ ! -e /tmp/.X11-unix/X1 ]; then
    echo "ERROR: Xorg failed to start. Falling back to Xvfb..."
    Xvfb :1 -screen 0 1280x720x24 +extension GLX &
    sleep 2
fi

echo "Starting x11vnc on display :1 (port 5900)..."
x11vnc -display :1 -forever -nopw -listen 0.0.0.0 -rfbport 5900 -shared &
sleep 1

echo "Starting Steam as botuser..."
su -s /bin/bash botuser -c "export DISPLAY=:1 HOME=/home/botuser; steam" &

echo "All services started. Connect via VNC to configure Steam."
wait
