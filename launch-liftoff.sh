#!/bin/bash
# Run this inside a running container to launch Liftoff:
#   docker exec -it bot1 /usr/local/bin/launch-liftoff.sh
#   docker exec -it bot2 /usr/local/bin/launch-liftoff.sh

set -e

echo "Launching Liftoff (App ID 732990)..."
su -p -s /bin/bash botuser -c "vglrun steam -applaunch 732990 -windowed -w 800 -h 600"
