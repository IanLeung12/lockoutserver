#!/bin/bash

# =============================================================================
# Minecraft 1.21.11 Fabric Server Startup Script
# =============================================================================

SERVER_DIR="/root/minecraft"
JAR="fabric-server-launch.jar"
# Use all available RAM minus 1GB for the OS
TOTAL_MB=$(free -m | awk '/^Mem:/ {print $2}')
RAM_MB=$((TOTAL_MB - 1024))
RAM="${RAM_MB}M"
SCREEN_NAME="mc"

# --- Colours ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Colour

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Minecraft 1.21.11 Fabric Server${NC}"
echo -e "${GREEN}========================================${NC}"

# Check Java
if ! command -v java &> /dev/null; then
    echo -e "${RED}[ERROR] Java is not installed. Run: apt install openjdk-21-jre-headless -y${NC}"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 21 ]; then
    echo -e "${RED}[ERROR] Java 21+ is required. Found Java ${JAVA_VERSION}.${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Java ${JAVA_VERSION} detected.${NC}"

# Check server directory
if [ ! -d "$SERVER_DIR" ]; then
    echo -e "${RED}[ERROR] Server directory not found: ${SERVER_DIR}${NC}"
    exit 1
fi
cd "$SERVER_DIR"

# Check JAR
if [ ! -f "$JAR" ]; then
    echo -e "${RED}[ERROR] Server JAR not found: ${SERVER_DIR}/${JAR}${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Server JAR found.${NC}"

# Check EULA
if ! grep -q "eula=true" eula.txt 2>/dev/null; then
    echo -e "${YELLOW}[WARN] EULA not accepted. Accepting now...${NC}"
    echo "eula=true" > eula.txt
fi
echo -e "${GREEN}[OK] EULA accepted.${NC}"

# Check if a screen session is already running
if screen -list | grep -q "\.${SCREEN_NAME}"; then
    echo -e "${YELLOW}[WARN] A screen session named '${SCREEN_NAME}' is already running.${NC}"
    echo -e "${YELLOW}       Reattach with: screen -r ${SCREEN_NAME}${NC}"
    echo -e "${YELLOW}       Or kill it with: screen -S ${SCREEN_NAME} -X quit${NC}"
    exit 1
fi

# Launch
echo ""
echo -e "${GREEN}Starting server with ${RAM} RAM in screen session '${SCREEN_NAME}'...${NC}"
echo -e "${GREEN}  Detach : Ctrl+A then D${NC}"
echo -e "${GREEN}  Attach : screen -r ${SCREEN_NAME}${NC}"
echo -e "${GREEN}  Stop   : attach and type 'stop'${NC}"
echo ""

screen -S "$SCREEN_NAME" -dm bash -c "java -Xmx${RAM} -Xms${RAM} -jar ${JAR} nogui; echo -e '${RED}Server stopped. Press Enter to close.${NC}'; read"

sleep 1

if screen -list | grep -q "\.${SCREEN_NAME}"; then
    echo -e "${GREEN}[OK] Server is running! Attach with: screen -r ${SCREEN_NAME}${NC}"
else
    echo -e "${RED}[ERROR] Server failed to start. Check logs in ${SERVER_DIR}/logs/latest.log${NC}"
    exit 1
fi
