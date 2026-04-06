#!/bin/bash
# Run this inside a running container to launch Liftoff:
#   docker exec -it bot1 /usr/local/bin/launch-liftoff.sh
#   docker exec -it bot2 /usr/local/bin/launch-liftoff.sh

set -e

if command -v vglrun &>/dev/null; then
    LAUNCH_CMD="vglrun steam -applaunch 732990 -windowed -w 800 -h 600"
else
    LAUNCH_CMD="steam -applaunch 732990 -windowed -w 800 -h 600"
fi

echo "Launching Liftoff (App ID 732990)..."
su -s /bin/bash botuser -c "export DISPLAY=:1 VGL_DISPLAY=egl HOME=/home/botuser; $LAUNCH_CMD"
