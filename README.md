# Liftoff Bot Servers — Docker Setup

Two headless Docker containers running Liftoff (Steam App ID 732990) with GPU-accelerated rendering via NVIDIA passthrough and VirtualGL.

## Prerequisites

- Ubuntu Server 22.04 LTS
- NVIDIA RTX 4070 GPU (or compatible)
- Two Steam accounts, each owning Liftoff
- A VNC client (e.g., TigerVNC, RealVNC) on your local machine

## 1. Host Setup

Copy this project to the server, then run the host setup script:

```bash
chmod +x host-setup.sh
sudo ./host-setup.sh
```

This installs NVIDIA drivers, Docker Engine, and nvidia-container-toolkit.

**Reboot** if NVIDIA drivers were freshly installed:

```bash
sudo reboot
```

After reboot, verify the GPU is visible:

```bash
nvidia-smi
```

## 2. Build the Docker Image

```bash
docker compose build
```

This takes a few minutes on first build (downloads Ubuntu packages, VirtualGL, Steam).

## 3. Start the Containers

```bash
docker compose up -d
```

Verify both containers are running:

```bash
docker compose ps
```

## 4. First-Run: Steam Login via VNC

Each container exposes a VNC server for initial setup:

| Container | VNC Address          |
|-----------|----------------------|
| bot1      | `<server-ip>:31264`  |
| bot2      | `<server-ip>:31265`  |

Connect with your VNC client. In each session:

1. Steam will launch automatically and show the login screen
2. Log in with the bot's Steam account credentials
3. Complete Steam Guard verification (email/mobile code)
4. Go to **Library > Liftoff** and install it
5. Wait for the download to complete
6. Optionally configure game settings

Steam login tokens persist in Docker volumes, so you only need to do this once.

## 5. Launch Liftoff

After Steam is set up and Liftoff is installed, launch the game:

```bash
docker exec -it bot1 /usr/local/bin/launch-liftoff.sh
docker exec -it bot2 /usr/local/bin/launch-liftoff.sh
```

Monitor via VNC to confirm the game starts correctly.

## 6. Day-to-Day Operations

**Restart containers** (Steam stays logged in via persistent volumes):

```bash
docker compose restart
```

**View logs:**

```bash
docker compose logs -f bot1
docker compose logs -f bot2
```

**Stop everything:**

```bash
docker compose down
```

**Rebuild after Dockerfile changes:**

```bash
docker compose build
docker compose up -d
```

## Persistence

Named Docker volumes store all Steam data:

| Volume            | Contents                              |
|-------------------|---------------------------------------|
| `bot1-steam`      | Bot 1 Steam client metadata, login    |
| `bot1-steamlocal` | Bot 1 game files, downloads, cache    |
| `bot2-steam`      | Bot 2 Steam client metadata, login    |
| `bot2-steamlocal` | Bot 2 game files, downloads, cache    |

Data survives container restarts and rebuilds.

**Backup a volume:**

```bash
docker run --rm -v bot1-steamlocal:/data -v "$(pwd)":/backup ubuntu \
    tar czf /backup/bot1-steamlocal-backup.tar.gz -C /data .
```

**Delete all data** (requires re-login and re-install):

```bash
docker compose down -v
```

## Troubleshooting

**Black VNC screen:**

```bash
docker exec bot1 ps aux | grep Xvfb
# If Xvfb is not running, restart the container
docker compose restart bot1
```

**Steam won't start / GPU errors:**

```bash
docker exec bot1 nvidia-smi
# Should show the RTX 4070. If not, check nvidia-container-toolkit setup.
```

**Verify VirtualGL rendering:**

```bash
docker exec bot1 su -p -s /bin/bash botuser -c "vglrun glxinfo | grep renderer"
# Should show NVIDIA GPU, not llvmpipe
```

**Steam Guard re-authentication:**
If Steam asks to log in again after a long period of inactivity, connect via VNC and log in interactively.

**Container won't start (runtime error):**
Ensure `nvidia` runtime is configured:

```bash
docker info | grep -i runtime
# Should list "nvidia" among the runtimes
```

## Architecture

```
Host (Ubuntu Server + RTX 4070)
├── Docker + nvidia-container-toolkit
├── bot1 container
│   ├── Xvfb :1 (800x600)
│   ├── x11vnc → host:31264
│   ├── VirtualGL (EGL backend)
│   └── Steam → Liftoff
└── bot2 container
    ├── Xvfb :1 (800x600)
    ├── x11vnc → host:31265
    ├── VirtualGL (EGL backend)
    └── Steam → Liftoff
```
