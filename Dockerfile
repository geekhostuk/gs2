FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu22.04

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all \
    VGL_DISPLAY=egl \
    DISPLAY=:1 \
    DEBIAN_FRONTEND=noninteractive \
    STEAM_RUNTIME=1

# Enable 32-bit architecture (required by Steam)
RUN dpkg --add-architecture i386

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Display and VNC
    xvfb \
    x11vnc \
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
    # 32-bit GL/Vulkan (Steam/games need these)
    libgl1:i386 \
    libgl1-mesa-dri:i386 \
    libvulkan1:i386 \
    mesa-vulkan-drivers:i386 \
    # Audio (Steam expects these)
    libpulse0 \
    libasound2 \
    libasound2:i386 \
    # Fonts and misc
    fonts-liberation \
    sudo \
    policykit-1 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install VirtualGL — force-extract to avoid apt removing it over deps
# Libs install to /usr/lib/, binaries to /usr/bin/ and /opt/VirtualGL/bin/
RUN wget -O /tmp/virtualgl.deb \
       https://github.com/VirtualGL/virtualgl/releases/download/3.1.4/virtualgl_3.1.4_amd64.deb \
    && dpkg -x /tmp/virtualgl.deb / \
    && rm -f /tmp/virtualgl.deb \
    && ldconfig \
    && ls -la /usr/lib/libvglfaker.so /usr/lib/libdlfaker.so /usr/bin/vglrun

# Install Steam and pre-run steamdeps so it doesn't prompt at runtime
RUN apt-get update \
    && wget -O /tmp/steam.deb \
       http://media.steampowered.com/client/installer/steam.deb \
    && (dpkg -i /tmp/steam.deb || true) \
    && apt-get install -f -y \
    && rm -f /tmp/steam.deb \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with GPU and audio access + passwordless sudo
RUN useradd -m -s /bin/bash -G video,audio,sudo botuser \
    && echo "botuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/botuser \
    && mkdir -p /home/botuser/.steam /home/botuser/.local/share/Steam \
    && chown -R botuser:botuser /home/botuser

# Allow passwordless polkit for botuser
RUN mkdir -p /etc/polkit-1/localauthority/50-local.d \
    && echo '[Allow botuser all]\nIdentity=unix-user:botuser\nAction=*\nResultAny=yes\nResultInactive=yes\nResultActive=yes' \
       > /etc/polkit-1/localauthority/50-local.d/botuser-allow.pkla

# Copy scripts
COPY start.sh /usr/local/bin/start.sh
COPY launch-liftoff.sh /usr/local/bin/launch-liftoff.sh
COPY setup-bepinex.sh /usr/local/bin/setup-bepinex.sh
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/launch-liftoff.sh /usr/local/bin/setup-bepinex.sh

ENTRYPOINT ["/usr/local/bin/start.sh"]
