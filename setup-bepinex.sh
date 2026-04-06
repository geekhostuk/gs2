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
echo "BepInEx installed successfully!"
echo ""
echo "Directories created:"
echo "  $GAME_DIR/BepInEx/plugins/   — drop plugin .dll files here"
echo "  $GAME_DIR/BepInEx/config/    — plugin configs (generated on first run)"
echo ""
echo "To launch Liftoff with BepInEx, use:"
echo "  docker exec -it bot1 /usr/local/bin/launch-liftoff.sh"
echo ""
echo "BepInEx will load automatically via the doorstop preloader."
