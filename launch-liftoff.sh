#!/bin/bash
# Run this inside a running container to launch Liftoff:
#   docker exec -it bot1 /usr/local/bin/launch-liftoff.sh
#   docker exec -it bot2 /usr/local/bin/launch-liftoff.sh

GAME_DIR="/home/botuser/.local/share/Steam/steamapps/common/Liftoff"

# Check if BepInEx is installed but launch options may not be set
if [ -f "$GAME_DIR/libdoorstop.so" ]; then
    echo "BepInEx is installed."
    echo "Make sure Steam Launch Options are set (see setup-bepinex.sh output)."
    echo ""
fi

echo "Launching Liftoff (App ID 732990)..."

# Use steam's protocol handler via the running Steam instance
su -s /bin/bash botuser -c 'export DISPLAY=:1 HOME=/home/botuser; steam steam://rungameid/732990' &

echo "Launch command sent to Steam. Check VNC to verify."
