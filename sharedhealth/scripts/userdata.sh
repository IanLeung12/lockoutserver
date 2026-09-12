#!/bin/bash

# =============================================================================
# Minecraft 26.2 Fabric Server (Shared Health) — AWS EC2 User Data Script
# Paste this into "Advanced details -> User data" when launching an instance.
# Everything including mods will be ready by the time the instance boots.
# =============================================================================

MC_VERSION="26.2"
FABRIC_INSTALLER_VERSION="1.1.2"
SERVER_USER="ubuntu"
SERVER_DIR="/home/${SERVER_USER}/minecraft"
REPO="https://raw.githubusercontent.com/IanLeung12/lockoutserver/main/sharedhealth"

MODS=(
    "fabric-api-0.160.0+26.2.jar"
    "lithium-fabric-0.25.3+mc26.2.jar"
    "sharedhealth-1.2.12.jar"
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
apt install screen wget unzip gpg apt-transport-https -y

# Minecraft 26.2 and sharedhealth both require Java 25, which Ubuntu 24.04's
# repos don't carry. Pull Eclipse Temurin 25 from the Adoptium repo instead.
echo "[$(date)] Installing Temurin 25 from Adoptium..."
mkdir -p /etc/apt/keyrings
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg
echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(. /etc/os-release && echo "$VERSION_CODENAME") main" > /etc/apt/sources.list.d/adoptium.list
apt update
apt install temurin-25-jdk -y
java -version

# =============================================================================
# 2. Create server directory
# =============================================================================
echo "[$(date)] Creating server directory at ${SERVER_DIR}..."
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
# 4b. Default server.properties
# =============================================================================
# The server merges these into the full server.properties on first start.
# view-distance is in chunks; 20 is generous and needs a non-burstable
# instance with 8 GB+ (see README). simulation-distance stays at the
# default 10 so far-away chunks are visible but don't tick.
# hardcore=true forces hard difficulty and permadeath; difficulty=hard is
# set explicitly so it stays hard if hardcore is ever turned off.
echo "[$(date)] Writing default server.properties..."
cat > server.properties <<'PROPS'
view-distance=20
simulation-distance=10
hardcore=true
difficulty=hard
PROPS

# =============================================================================
# 5. Download mods from GitHub
# =============================================================================
# GitHub serves the raw path verbatim, so filenames with '+' need no encoding.
# Each jar is verified as a readable zip archive — a 404 or a truncated
# download otherwise lands in mods/ as a file the server silently refuses.
echo "[$(date)] Downloading mods..."
mkdir -p mods
for MOD in "${MODS[@]}"; do
    echo "[$(date)] Downloading $MOD..."
    if ! wget --tries=3 "${REPO}/mods/${MOD}" -O "mods/${MOD}"; then
        echo "[$(date)] ERROR: failed to download ${MOD}."
        rm -f "mods/${MOD}"
        exit 1
    fi

    if ! unzip -tqq "mods/${MOD}" > /dev/null 2>&1; then
        echo "[$(date)] ERROR: ${MOD} is not a valid jar (got $(wc -c < "mods/${MOD}") bytes)."
        echo "[$(date)] First line of what was downloaded:"
        head -c 200 "mods/${MOD}"
        rm -f "mods/${MOD}"
        exit 1
    fi
    echo "[$(date)] Verified ${MOD}."
done
echo "[$(date)] All mods downloaded and verified."

# =============================================================================
# 6. Download scripts from GitHub
# =============================================================================
echo "[$(date)] Downloading scripts..."
wget "${REPO}/scripts/start.sh" -O "$SERVER_DIR/start.sh"
wget "${REPO}/scripts/newworld.sh" -O "$SERVER_DIR/newworld.sh"

# The scripts already default to this path; re-point them anyway so a custom
# SERVER_DIR above stays consistent everywhere.
sed -i "s|^SERVER_DIR=.*|SERVER_DIR=\"${SERVER_DIR}\"|" "$SERVER_DIR/start.sh" "$SERVER_DIR/newworld.sh"
chmod +x "$SERVER_DIR/start.sh" "$SERVER_DIR/newworld.sh"
echo "[$(date)] Scripts downloaded."

# =============================================================================
# 7. Hand the server over to the login user
# =============================================================================
# User data runs as root, so everything above is root-owned. Without this the
# ubuntu user can't write worlds, logs, or configs.
echo "[$(date)] Setting ownership to ${SERVER_USER}..."
chown -R "${SERVER_USER}:${SERVER_USER}" "$SERVER_DIR"

# =============================================================================
# 8. Done
# =============================================================================
echo "[$(date)] Setup complete! Run: bash ${SERVER_DIR}/start.sh"
