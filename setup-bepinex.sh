#!/bin/bash
# Run this inside a container after Liftoff is installed:
#   docker exec -it bot1 /usr/local/bin/setup-bepinex.sh
#   docker exec -it bot2 /usr/local/bin/setup-bepinex.sh

set -e

BEPINEX_VERSION="5.4.23.5"
GAME_DIR="/home/botuser/.local/share/Steam/steamapps/common/Liftoff"

# Check game is installed
if [ ! -d "$GAME_DIR" ]; then
    echo "ERROR: Liftoff not found at $GAME_DIR"
    echo "Install the game via Steam first, then re-run this script."
    exit 1
fi

echo "Installing BepInEx $BEPINEX_VERSION into $GAME_DIR..."

# Download BepInEx unix release
cd /tmp
wget -O bepinex.zip \
    "https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}/BepInEx_linux_x64_${BEPINEX_VERSION}.zip"

# Extract into game directory
unzip -o bepinex.zip -d "$GAME_DIR"
rm -f bepinex.zip

# Make the run script executable
chmod +x "$GAME_DIR/run_bepinex.sh" 2>/dev/null || true

# Set ownership
chown -R botuser:botuser "$GAME_DIR/BepInEx" "$GAME_DIR/run_bepinex.sh" 2>/dev/null || true
chown botuser:botuser "$GAME_DIR/doorstop_config.ini" 2>/dev/null || true
chown botuser:botuser "$GAME_DIR/libdoorstop.so" 2>/dev/null || true

echo ""
echo "========================================"
echo " BepInEx installed successfully!"
echo "========================================"
echo ""
echo "REQUIRED: Set Steam Launch Options for Liftoff"
echo ""
echo "  1. Connect to the container via VNC"
echo "  2. In Steam, right-click Liftoff > Properties > General"
echo "  3. In 'Launch Options', paste this exactly:"
echo ""
echo "     LD_PRELOAD=\"$GAME_DIR/libdoorstop.so\" DOORSTOP_ENABLE=TRUE DOORSTOP_INVOKE_DLL_PATH=\"$GAME_DIR/BepInEx/core/BepInEx.Preloader.dll\" %command%"
echo ""
echo "  4. Click OK and launch the game"
echo ""
echo "Plugin directory:"
echo "  $GAME_DIR/BepInEx/plugins/   — drop plugin .dll files here"
echo ""
echo "Config directory (generated after first modded launch):"
echo "  $GAME_DIR/BepInEx/config/"
echo ""
echo "Do this for EACH container (bot1 and bot2)."
