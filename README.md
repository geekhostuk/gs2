# Liftoff Bot Servers

Two headless Docker containers running Liftoff (Steam App ID 732990) as bot servers with NVIDIA GPU passthrough, VirtualGL rendering, and BepInEx mod support.

## Prerequisites

- Ubuntu Server 22.04 LTS
- NVIDIA GPU (tested with RTX 4070)
- Two Steam accounts, each owning Liftoff
- [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) installed on your local machine (free)

## Project Files

| File | Purpose |
|---|---|
| `host-setup.sh` | Installs NVIDIA drivers, Docker, and nvidia-container-toolkit on the host |
| `Dockerfile` | Builds the container image (Ubuntu 22.04 + Steam + VirtualGL + VNC) |
| `docker-compose.yml` | Defines bot1 and bot2 containers with GPU, ports, and volumes |
| `start.sh` | Container entrypoint: starts Xvfb, VNC, and Steam |
| `launch-liftoff.sh` | Launches Liftoff inside a running container |
| `setup-bepinex.sh` | Installs BepInEx 5.4.23.5 mod framework into Liftoff |

## Step 1: Clone the Repo on the Server

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/geekhostuk/gs2.git
cd gs2
```

## Step 2: Run Host Setup

This installs NVIDIA drivers, Docker Engine, and nvidia-container-toolkit:

```bash
chmod +x host-setup.sh
sudo ./host-setup.sh
```

Reboot after (required for NVIDIA drivers to load):

```bash
sudo reboot
```

After reboot, verify the GPU is detected:

```bash
nvidia-smi
```

You should see your GPU listed (e.g. `NVIDIA GeForce RTX 4070`). If not, the driver did not install correctly.

## Step 3: Build the Docker Image

```bash
cd ~/gs2
docker compose build
```

First build takes several minutes. Subsequent builds use Docker's layer cache and are faster.

## Step 4: Start the Containers

```bash
docker compose up -d
```

Verify both containers are running:

```bash
docker compose ps
```

Expected output:

```
NAME      IMAGE                COMMAND                  SERVICE   STATUS         PORTS
bot1      liftoff-bot:latest   "/usr/local/bin/star…"   bot1      Up             0.0.0.0:31264->5900/tcp
bot2      liftoff-bot:latest   "/usr/local/bin/star…"   bot2      Up             0.0.0.0:31265->5900/tcp
```

## Step 5: Log in to Steam via VNC

Open RealVNC Viewer and connect to each container:

| Container | VNC Address |
|---|---|
| bot1 | `<your-server-ip>:31264` |
| bot2 | `<your-server-ip>:31265` |

**Important:** Use a VNC client (RealVNC Viewer, TigerVNC), not a web browser. VNC is not HTTP.

In each VNC session:

1. Steam will be open with a login screen
2. Enter the bot account's username and password
3. Complete Steam Guard verification (enter the code from email or mobile app)
4. Once logged in, go to **Library**
5. Find **Liftoff** and click **Install**
6. Wait for the download to complete (~5-10 GB)

You only need to do this once per container. Steam login and game files persist in Docker volumes across restarts and rebuilds.

## Step 6: Install BepInEx (Optional)

After Liftoff is installed in both containers, install BepInEx:

```bash
docker exec -it bot1 /usr/local/bin/setup-bepinex.sh
docker exec -it bot2 /usr/local/bin/setup-bepinex.sh
```

This downloads BepInEx 5.4.23.5 and extracts it into the Liftoff game directory.

**Adding plugins:** Copy `.dll` plugin files into the container:

```bash
docker cp MyPlugin.dll bot1:/home/botuser/.local/share/Steam/steamapps/common/Liftoff/BepInEx/plugins/
docker cp MyPlugin.dll bot2:/home/botuser/.local/share/Steam/steamapps/common/Liftoff/BepInEx/plugins/
```

Plugin config files are generated in `BepInEx/config/` on first launch.

## Step 7: Launch Liftoff

```bash
docker exec -it bot1 /usr/local/bin/launch-liftoff.sh
docker exec -it bot2 /usr/local/bin/launch-liftoff.sh
```

The script auto-detects BepInEx and enables it if installed. The game launches windowed at 800x600 inside the 1280x720 virtual desktop.

Connect via VNC to verify the game is running correctly.

## Day-to-Day Operations

### Restart containers

Steam stays logged in and the game stays installed (persistent volumes):

```bash
docker compose restart
```

### View container logs

```bash
docker compose logs -f bot1
docker compose logs -f bot2
```

### Stop containers

```bash
docker compose down
```

### Pull updates and rebuild

```bash
cd ~/gs2
git pull
docker compose down
docker compose build --no-cache
docker compose up -d
```

**Note:** After a rebuild, the updated scripts are baked into the new image. If you only changed `docker-compose.yml` (no Dockerfile changes), you can skip the build:

```bash
git pull
docker compose down
docker compose up -d
```

### Check GPU access inside a container

```bash
docker exec bot1 nvidia-smi
```

### Check VirtualGL is working

```bash
docker exec bot1 vglrun glxinfo | grep "OpenGL renderer"
```

Should show the NVIDIA GPU name, not `llvmpipe` (software renderer).

### Open a shell inside a container

```bash
docker exec -it bot1 bash
```

## Port Mapping

| Container | Internal Port | Host Port | Protocol |
|---|---|---|---|
| bot1 | 5900 (VNC) | 31264 | TCP |
| bot2 | 5900 (VNC) | 31265 | TCP |

## Volume Mapping

All Steam data persists in named Docker volumes:

| Volume | Mount Point | Contents |
|---|---|---|
| `bot1-steam` | `/home/botuser/.steam` | Steam client metadata, login tokens |
| `bot1-steamlocal` | `/home/botuser/.local/share/Steam` | Game files, downloads, shader cache |
| `bot2-steam` | `/home/botuser/.steam` | Steam client metadata, login tokens |
| `bot2-steamlocal` | `/home/botuser/.local/share/Steam` | Game files, downloads, shader cache |

### Backup a volume

```bash
docker run --rm -v bot1-steamlocal:/data -v "$(pwd)":/backup ubuntu \
    tar czf /backup/bot1-steamlocal-backup.tar.gz -C /data .
```

### Delete all volumes (full reset)

This deletes all Steam logins, game installs, and saves. You will need to redo Steps 5-7.

```bash
docker compose down -v
```

## Troubleshooting

### Black screen in VNC

Check that Xvfb and x11vnc are running:

```bash
docker exec bot1 ps aux
```

Look for `Xvfb` and `x11vnc` in the process list. If missing, check the logs:

```bash
docker compose logs bot1
```

Restart the container:

```bash
docker compose restart bot1
```

### Steam shows "user namespaces" error

The `docker-compose.yml` includes `security_opt` and `cap_add` settings to enable this. If you see this error, make sure you're using the latest `docker-compose.yml`:

```bash
git pull
docker compose down
docker compose up -d
```

### Steam asks for password / polkit authentication

This means Steam is trying to install dependencies. It should resolve automatically with the polkit rules in the image. If it persists, run inside the container:

```bash
docker exec -it bot1 bash
sudo apt-get update && sudo apt-get install -f -y
```

### Steam Guard re-authentication

Steam may invalidate login tokens after extended inactivity (~30 days). Connect via VNC and log in again.

### Container keeps restarting

Check logs for the crash reason:

```bash
docker compose logs --tail=50 bot1
```

### NVIDIA runtime not found

```bash
docker info | grep -i runtime
```

If `nvidia` is not listed, re-run the toolkit setup:

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

## Architecture

```
Host (Ubuntu Server + NVIDIA GPU)
├── Docker + nvidia-container-toolkit
│
├── bot1 container
│   ├── Xvfb :1 (1280x720 virtual display)
│   ├── x11vnc (VNC server → host port 31264)
│   ├── VirtualGL (EGL backend, GPU-accelerated rendering)
│   ├── Steam client (runs as botuser)
│   ├── Liftoff (launched via launch-liftoff.sh)
│   ├── BepInEx (optional, installed via setup-bepinex.sh)
│   └── Volumes: bot1-steam, bot1-steamlocal
│
└── bot2 container
    ├── Xvfb :1 (1280x720 virtual display)
    ├── x11vnc (VNC server → host port 31265)
    ├── VirtualGL (EGL backend, GPU-accelerated rendering)
    ├── Steam client (runs as botuser)
    ├── Liftoff (launched via launch-liftoff.sh)
    ├── BepInEx (optional, installed via setup-bepinex.sh)
    └── Volumes: bot2-steam, bot2-steamlocal
```
