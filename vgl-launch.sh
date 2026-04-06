#!/bin/bash
# Wrapper to enable VirtualGL GPU rendering for any game launched through it.
# Place in the game directory and use as Steam Launch Option:
#   ./vgl-launch.sh %command%
#   ./vgl-launch.sh ./run_bepinex.sh %command%

export LD_PRELOAD="libvglfaker.so libdlfaker.so${LD_PRELOAD:+:$LD_PRELOAD}"
export VGL_DISPLAY=egl
exec "$@"
