#!/bin/bash

# =============================================================================
# Minecraft 1.21.11 Fabric Server — DigitalOcean User Data Script
# Paste this into the "User Data" field when creating a Droplet.
# Everything including mods will be ready by the time the droplet boots.
# =============================================================================

MC_VERSION="1.21.11"
FABRIC_INSTALLER_VERSION="1.0.1"
SERVER_DIR="/root/minecraft"
REPO="https://raw.githubusercontent.com/IanLeung12/lockoutserver/main"

MODS=(
    "fabric-api-0.141.3+1.21.11.jar"
    "lithium-fabric-0.21.4+mc1.21.11.jar"
    "lockout-fabric-0.12.2.jar"
)

# --- Logging — all output goes to /var/log/mc-setup.log ---
exec > /var/log/mc-setup.log 2>&1
set -e

export DEBIAN_FRONTEND=noninteractive

echo "[$(date)] Starting Minecraft server setup..."

# =============================================================================
# 1. System update & dependencies
# =============================================================================
echo "[$(date)] Installing dependencies..."
apt update && apt upgrade -y -o Dpkg::Options::="--force-confold"
apt install openjdk-21-jre-headless screen wget -y

# =============================================================================
# 2. Create server directory
# =============================================================================
echo "[$(date)] Creating server directory..."
mkdir -p "$SERVER_DIR"
cd "$SERVER_DIR"

# =============================================================================
# 3. Download & run Fabric installer
# =============================================================================
echo "[$(date)] Downloading Fabric installer..."
INSTALLER_URL="https://maven.fabricmc.net/net/fabricmc/fabric-installer/${FABRIC_INSTALLER_VERSION}/fabric-installer-${FABRIC_INSTALLER_VERSION}.jar"
wget "$INSTALLER_URL" -O fabric-installer.jar

echo "[$(date)] Running Fabric installer for Minecraft ${MC_VERSION}..."
java -jar fabric-installer.jar server -mcversion "$MC_VERSION" -downloadMinecraft

# =============================================================================
# 4. Accept EULA
# =============================================================================
echo "[$(date)] Accepting EULA..."
echo "eula=true" > eula.txt

# =============================================================================
# 5. Download mods from GitHub
# =============================================================================
echo "[$(date)] Downloading mods..."
mkdir -p mods
for MOD in "${MODS[@]}"; do
    ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$MOD', safe=''))")
    echo "[$(date)] Downloading $MOD..."
    wget "${REPO}/mods/${ENCODED}" -O "mods/${MOD}"
done
echo "[$(date)] All mods downloaded."

# =============================================================================
# 6. Download scripts from GitHub
# =============================================================================
echo "[$(date)] Downloading scripts..."
wget "${REPO}/scripts/start.sh" -O "$SERVER_DIR/start.sh"
wget "${REPO}/scripts/newworld.sh" -O "$SERVER_DIR/newworld.sh"
chmod +x "$SERVER_DIR/start.sh" "$SERVER_DIR/newworld.sh"
echo "[$(date)] Scripts downloaded."

# =============================================================================
# 7. Done
# =============================================================================
echo "[$(date)] Setup complete! Run: bash /root/minecraft/start.sh"