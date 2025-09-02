#!/usr/bin/env bash
set -e

# === CONFIG ===
QDRANT_VERSION="v1.13.4"   # change if needed
QDRANT_URL="https://github.com/qdrant/qdrant/releases/download/${QDRANT_VERSION}/qdrant-${QDRANT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
QDRANT_DIR="$HOME/qdrant"
MEMOIR_DIR="$HOME/Memoir"
OOBABOOGA_DIR="$HOME/text-generation-webui"

# === FUNCTIONS ===
install_docker() {
    echo "[*] Installing Docker Desktop..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sh
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        echo "[*] Docker already installed."
    fi
}

install_qdrant_binary() {
    echo "[*] Installing Qdrant binary..."
    mkdir -p "$QDRANT_DIR"
    cd "$QDRANT_DIR"
    curl -L "$QDRANT_URL" -o qdrant.tar.gz
    tar -xvzf qdrant.tar.gz --strip-components=1
    chmod +x qdrant
    echo "[*] Qdrant installed at $QDRANT_DIR/qdrant"
}

launch_qdrant() {
    echo "[*] Launching Qdrant in background..."
    cd "$QDRANT_DIR"
    if pgrep -x "qdrant" > /dev/null; then
        echo "[*] Qdrant already running."
    else
        nohup ./qdrant > qdrant.log 2>&1 &
        sleep 3
        echo "[*] Qdrant started (check qdrant.log for output)."
    fi
}

patch_memoir_script() {
    echo "[*] Patching Memoir script.py to disable Docker loads..."
    SCRIPT="$MEMOIR_DIR/script.py"
    if [ -f "$SCRIPT" ]; then
        sed -i 's/^\(\s*\)docker/#\1docker/' "$SCRIPT"
        echo "[*] Patched $SCRIPT"
    else
        echo "[!] $SCRIPT not found, skipping."
    fi
}

run_memoir_in_venv() {
    echo "[*] Running Memoir inside Oobabooga venv..."
    cd "$OOBABOOGA_DIR"
    source venv/bin/activate
    cd "$MEMOIR_DIR"
    python script.py
}

# === MAIN ===
install_docker
install_qdrant_binary
launch_qdrant
patch_memoir_script
run_memoir_in_venv
