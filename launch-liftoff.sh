#!/bin/bash
# Run this inside a running container to launch Liftoff:
#   docker exec -it bot1 /usr/local/bin/launch-liftoff.sh
#   docker exec -it bot2 /usr/local/bin/launch-liftoff.sh

set -e

GAME_DIR="/home/botuser/.local/share/Steam/steamapps/common/Liftoff"

# Build launch options
LAUNCH_OPTS="-windowed -w 800 -h 600"

# Enable BepInEx doorstop if installed
DOORSTOP_ENV=""
if [ -f "$GAME_DIR/libdoorstop_x64.so" ]; then
    echo "BepInEx detected — enabling doorstop preloader."
    DOORSTOP_ENV="DOORSTOP_ENABLE=TRUE DOORSTOP_LIB=$GAME_DIR/libdoorstop_x64.so DOORSTOP_LIBS=$GAME_DIR/doorstop_libs DOORSTOP_INVOKE_DLL_PATH=$GAME_DIR/BepInEx/core/BepInEx.Preloader.dll LD_LIBRARY_PATH=$GAME_DIR:\$LD_LIBRARY_PATH LD_PRELOAD=libdoorstop_x64.so:\$LD_PRELOAD"
else
    echo "BepInEx not detected — launching vanilla."
fi

echo "Launching Liftoff (App ID 732990)..."

if command -v vglrun &>/dev/null; then
    RUNNER="vglrun"
else
    RUNNER=""
fi

su -s /bin/bash botuser -c "export DISPLAY=:1 VGL_DISPLAY=egl HOME=/home/botuser $DOORSTOP_ENV; $RUNNER steam -applaunch 732990 $LAUNCH_OPTS"
