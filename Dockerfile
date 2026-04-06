FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu22.04

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all \
    DISPLAY=:1 \
    DEBIAN_FRONTEND=noninteractive \
    STEAM_RUNTIME=1

# Enable 32-bit architecture (required by Steam)
RUN dpkg --add-architecture i386

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Headless Xorg + VNC
    xserver-xorg-core \
    x11vnc \
    xinit \
    # Utilities
    wget \
    curl \
    ca-certificates \
    gnupg2 \
    software-properties-common \
    # X11 / display libraries
    libxtst6 \
    libxrandr2 \
    libglib2.0-0 \
    dbus-x11 \
    xdg-utils \
    python3 \
    # 64-bit GL/Vulkan
    libvulkan1 \
    mesa-vulkan-drivers \
    vulkan-tools \
    libxv1 \
    libglu1-mesa \
    libegl1 \
    libgbm1 \
    # 32-bit GL/Vulkan (Steam/games need these)
    libgl1:i386 \
    libgl1-mesa-dri:i386 \
    libvulkan1:i386 \
    mesa-vulkan-drivers:i386 \
    libegl1:i386 \
    libgbm1:i386 \
    # Audio (Steam expects these)
    libpulse0 \
    libasound2 \
    libasound2:i386 \
    # Fonts and misc
    fonts-liberation \
    sudo \
    policykit-1 \
    unzip \
    # Steam required packages
    libc6:amd64 \
    libc6:i386 \
    libgl1:amd64 \
    libgl1-mesa-dri:amd64 \
    && rm -rf /var/lib/apt/lists/*

# Install Steam and all its runtime dependencies
RUN apt-get update \
    && wget -O /tmp/steam.deb \
       http://media.steampowered.com/client/installer/steam.deb \
    && (dpkg -i /tmp/steam.deb || true) \
    && apt-get install -f -y \
    && apt-get install -y steam-libs-amd64 steam-libs-i386 || true \
    && rm -f /tmp/steam.deb \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with GPU and audio access + passwordless sudo
RUN useradd -m -s /bin/bash -G video,audio,sudo botuser \
    && echo "botuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/botuser \
    && mkdir -p /home/botuser/.steam /home/botuser/.local/share/Steam \
    && chown -R botuser:botuser /home/botuser

# Allow passwordless polkit for botuser
RUN mkdir -p /etc/polkit-1/localauthority/50-local.d \
    && printf '[Allow botuser all]\nIdentity=unix-user:botuser\nAction=*\nResultAny=yes\nResultInactive=yes\nResultActive=yes\n' \
       > /etc/polkit-1/localauthority/50-local.d/botuser-allow.pkla

# Headless Xorg config — uses NVIDIA GPU with a fake connected display
RUN mkdir -p /etc/X11 \
    && printf 'Section "Device"\n\
    Identifier "Device0"\n\
    Driver     "nvidia"\n\
    Option     "AllowEmptyInitialConfiguration" "true"\n\
    Option     "ConnectedMonitor" "DFP-0"\n\
    Option     "CustomEDID" "DFP-0:/etc/X11/edid.bin"\n\
EndSection\n\
\n\
Section "Monitor"\n\
    Identifier "Monitor0"\n\
    Option     "DPMS" "false"\n\
EndSection\n\
\n\
Section "Screen"\n\
    Identifier "Screen0"\n\
    Device     "Device0"\n\
    Monitor    "Monitor0"\n\
    DefaultDepth 24\n\
    Option     "MetaModes" "1280x720 +0+0"\n\
    SubSection "Display"\n\
        Depth 24\n\
        Modes "1280x720"\n\
    EndSubSection\n\
EndSection\n\
\n\
Section "ServerLayout"\n\
    Identifier "Layout0"\n\
    Screen     "Screen0"\n\
    Option     "AllowNVIDIAGPUScreens"\n\
EndSection\n\
\n\
Section "ServerFlags"\n\
    Option "AutoAddGPU" "true"\n\
    Option "AllowMouseOpenFail" "true"\n\
    Option "AllowEmptyInput" "true"\n\
    Option "BlankTime" "0"\n\
    Option "StandbyTime" "0"\n\
    Option "SuspendTime" "0"\n\
    Option "OffTime" "0"\n\
EndSection\n' > /etc/X11/xorg.conf

# Copy EDID for fake display
COPY edid.bin /etc/X11/edid.bin

# Copy scripts
COPY start.sh /usr/local/bin/start.sh
COPY launch-liftoff.sh /usr/local/bin/launch-liftoff.sh
COPY setup-bepinex.sh /usr/local/bin/setup-bepinex.sh
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/launch-liftoff.sh /usr/local/bin/setup-bepinex.sh

ENTRYPOINT ["/usr/local/bin/start.sh"]
