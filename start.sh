#!/bin/bash
set -e

echo "Starting Xvfb on display :1..."
Xvfb :1 -screen 0 800x600x24 +extension GLX &
sleep 2

echo "Starting x11vnc on display :1 (port 5900)..."
x11vnc -display :1 -forever -nopw -listen 0.0.0.0 -rfbport 5900 -shared &
sleep 1

echo "Starting Steam as botuser..."
su -p -s /bin/bash botuser -c "vglrun steam" &

echo "All services started. Connect via VNC to configure Steam."
wait
