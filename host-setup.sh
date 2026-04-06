#!/bin/bash
set -e

echo "=== Liftoff Bot Server - Host Setup ==="
echo ""

# 1. Install NVIDIA drivers
echo "--- Installing NVIDIA drivers ---"
sudo apt-get update
sudo apt-get install -y ubuntu-drivers-common
sudo ubuntu-drivers install
echo "NVIDIA drivers installed."
echo ""

# 2. Install Docker Engine
echo "--- Installing Docker Engine ---"
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add current user to docker group
sudo usermod -aG docker "$USER"
echo "Docker installed. You may need to log out and back in for group changes."
echo ""

# 3. Install nvidia-container-toolkit
echo "--- Installing nvidia-container-toolkit ---"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
echo "nvidia-container-toolkit installed."
echo ""

# 4. Configure Docker for NVIDIA runtime
echo "--- Configuring Docker NVIDIA runtime ---"
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
echo "Docker configured with NVIDIA runtime."
echo ""

# 5. Verify GPU passthrough
echo "--- Verifying GPU passthrough ---"
echo "Running nvidia-smi inside a test container..."
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi

echo ""
echo "=== Host setup complete ==="
echo ""
echo "If NVIDIA drivers were freshly installed, REBOOT before building containers:"
echo "  sudo reboot"
echo ""
echo "After reboot, build and start:"
echo "  cd $(pwd)"
echo "  docker compose build"
echo "  docker compose up -d"
