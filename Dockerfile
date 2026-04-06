FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu22.04

ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all \
    VGL_DISPLAY=egl \
    DISPLAY=:1 \
    DEBIAN_FRONTEND=noninteractive

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
    # 32-bit GL/Vulkan (Steam/games need these)
    libgl1:i386 \
    libgl1-mesa-dri:i386 \
    libvulkan1:i386 \
    mesa-vulkan-drivers:i386 \
    # Audio (Steam expects these)
    libpulse0 \
    libasound2 \
    libasound2:i386 \
    # Fonts
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Install VirtualGL (apt-get update needed so -f can resolve deps)
RUN apt-get update \
    && wget -O /tmp/virtualgl.deb \
       https://github.com/VirtualGL/virtualgl/releases/download/3.1.4/virtualgl_3.1.4_amd64.deb \
    && (dpkg -i /tmp/virtualgl.deb || true) \
    && apt-get install -f -y \
    && rm -f /tmp/virtualgl.deb \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /opt/VirtualGL/bin/vglrun /usr/local/bin/vglrun \
    && vglrun --version

# Install Steam
RUN apt-get update \
    && wget -O /tmp/steam.deb \
       http://media.steampowered.com/client/installer/steam.deb \
    && (dpkg -i /tmp/steam.deb || true) \
    && apt-get install -f -y \
    && rm -f /tmp/steam.deb \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with GPU and audio access
RUN useradd -m -s /bin/bash -G video,audio botuser \
    && mkdir -p /home/botuser/.steam /home/botuser/.local/share/Steam \
    && chown -R botuser:botuser /home/botuser

# Copy scripts
COPY start.sh /usr/local/bin/start.sh
COPY launch-liftoff.sh /usr/local/bin/launch-liftoff.sh
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/launch-liftoff.sh

ENTRYPOINT ["/usr/local/bin/start.sh"]
