#!/usr/bin/env bash

set -euo pipefail

echo "==> Detecting Ubuntu release"

UBUNTU_CODENAME=$(
    . /etc/os-release
    echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}"
)

DOCKER_CODENAME="$UBUNTU_CODENAME"

case "$UBUNTU_CODENAME" in
    resolute)
        echo "Ubuntu '$UBUNTU_CODENAME' not yet supported by Docker."
        echo "Using Docker packages from 'noble'."
        DOCKER_CODENAME="noble"
        ;;
esac

echo
echo "Ubuntu Codename : $UBUNTU_CODENAME"
echo "Docker Codename : $DOCKER_CODENAME"
echo

echo "==> Removing old Docker repositories"

sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/sources.list.d/docker.sources

echo "==> Removing old Docker keyrings"

sudo rm -f /etc/apt/keyrings/docker.asc
sudo rm -f /etc/apt/keyrings/docker.gpg

echo "==> Removing conflicting packages"

sudo apt-get remove -y \
    docker.io \
    docker-doc \
    docker-compose \
    docker-compose-v2 \
    podman-docker \
    containerd \
    runc \
    || true

echo "==> Installing prerequisites"

sudo apt-get update

sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo "==> Creating keyring directory"

sudo install -m 0755 -d /etc/apt/keyrings

echo "==> Downloading Docker GPG key"

sudo curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "==> Configuring Docker repository"

sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${DOCKER_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

echo "==> Verifying repository"

if ! curl -fsSL \
    "https://download.docker.com/linux/ubuntu/dists/${DOCKER_CODENAME}/Release" \
    >/dev/null
then
    echo
    echo "ERROR: Docker repository for '${DOCKER_CODENAME}' not found."
    exit 1
fi

echo "==> Installing Docker"

sudo apt-get update

sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "==> Enabling Docker"

sudo systemctl enable docker
sudo systemctl start docker

echo "==> Adding current user to docker group"

sudo usermod -aG docker "$USER"

echo "==> Configuring log rotation"

sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  }
}
EOF

sudo systemctl restart docker

echo
echo "Docker Version:"
docker --version || true

echo
echo "Compose Version:"
docker compose version || true

echo
echo "SUCCESS!"
echo
echo "Please log out and log back in to use Docker without sudo."

