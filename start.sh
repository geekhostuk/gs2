#!/bin/bash
set -e

echo "Starting dbus..."
mkdir -p /run/dbus
dbus-daemon --system --fork 2>/dev/null || true

echo "Cleaning up stale X locks..."
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

echo "Starting Xvfb on display :1..."
Xvfb :1 -screen 0 1280x720x24 +extension GLX &
sleep 2

echo "Starting x11vnc on display :1 (port 5900)..."
x11vnc -display :1 -forever -nopw -listen 0.0.0.0 -rfbport 5900 -shared &
sleep 1

# Launch Steam directly — no vglrun needed for the Steam client UI
# vglrun is only needed when launching the game via launch-liftoff.sh
echo "Starting Steam as botuser (with VirtualGL environment)..."
su -s /bin/bash botuser -c "export DISPLAY=:1 HOME=/home/botuser LD_PRELOAD='libvglfaker.so libdlfaker.so' VGL_DISPLAY=egl; steam" &

echo "All services started. Connect via VNC to configure Steam."
wait
