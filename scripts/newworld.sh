#!/bin/bash

# =============================================================================
# Minecraft — New World Script
# Archives the current world and restarts the server with a fresh one.
# =============================================================================

SERVER_DIR="/root/minecraft"
SCREEN_NAME="mc"
JAR="fabric-server-launch.jar"
# Use all available RAM minus 1GB for the OS
TOTAL_MB=$(free -m | awk '/^Mem:/ {print $2}')
RAM_MB=$((TOTAL_MB - 1024))
RAM="${RAM_MB}M"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd "$SERVER_DIR"

is_server_running() {
    pgrep -f "$JAR" > /dev/null 2>&1
}

is_screen_running() {
    screen -list | grep -q "\.${SCREEN_NAME}"
}

# =============================================================================
# 1. Check server is running
# =============================================================================
if ! is_server_running && ! is_screen_running; then
    echo -e "${YELLOW}[WARN] Server is not running. Starting fresh world anyway...${NC}"
else
    # =============================================================================
    # 2. Stop the server gracefully
    # =============================================================================
    echo -e "${GREEN}==>${NC} Stopping server..."
    if is_screen_running; then
        screen -S "$SCREEN_NAME" -X stuff "say Server restarting for a new world in 5 seconds...$(printf '\r')"
        sleep 5
        screen -S "$SCREEN_NAME" -X stuff "stop$(printf '\r')"
    fi

    # Wait for the Java process to stop (more reliable than watching screen)
    echo -e "${GREEN}==>${NC} Waiting for server to stop..."
    for i in {1..60}; do
        if ! is_server_running; then
            break
        fi
        sleep 1
    done

    if is_server_running; then
        echo -e "${RED}[ERROR] Server didn't stop in time. Kill it manually with: kill \$(pgrep -f ${JAR})${NC}"
        exit 1
    fi

    # Clean up the screen session if it's still lingering
    if is_screen_running; then
        screen -S "$SCREEN_NAME" -X quit
    fi
fi

echo -e "${GREEN}[OK] Server stopped.${NC}"

# =============================================================================
# 3. Archive the current world
# =============================================================================
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -d "world" ]; then
    BACKUP_NAME="world_${TIMESTAMP}"
    echo -e "${GREEN}==>${NC} Archiving current world to ${BACKUP_NAME}..."
    mv world "$BACKUP_NAME"
    [ -d "world_nether" ]  && mv world_nether  "${BACKUP_NAME}_nether"
    [ -d "world_the_end" ] && mv world_the_end "${BACKUP_NAME}_the_end"
    echo -e "${GREEN}[OK] World archived as ${BACKUP_NAME}.${NC}"
else
    echo -e "${YELLOW}[WARN] No existing world folder found. Starting fresh.${NC}"
fi

# =============================================================================
# 4. Start the server with a new world
# =============================================================================
echo -e "${GREEN}==>${NC} Starting server with new world..."
screen -S "$SCREEN_NAME" -dm bash -c "java -Xmx${RAM} -Xms${RAM} -jar ${JAR} nogui; echo 'Server stopped. Press Enter to close.'; read"

sleep 2
if is_screen_running; then
    echo -e "${GREEN}[OK] Server started with a fresh world!${NC}"
    echo -e "${GREEN}     Attach: screen -r ${SCREEN_NAME}${NC}"
else
    echo -e "${RED}[ERROR] Server failed to start. Check logs/latest.log${NC}"
    exit 1
fi

# =============================================================================
# 5. List archived worlds
# =============================================================================
echo ""
echo -e "${GREEN}Archived worlds:${NC}"
ls -d world_* 2>/dev/null | grep -v "_nether\|_the_end" || echo "  (none)"
