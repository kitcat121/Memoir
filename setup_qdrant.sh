#!/usr/bin/env bash
set -e

# === CONFIG ===
QDRANT_DIR="/home/futasharkslut/Desktop/text-generation-webui-3.11/installer_files/env/qdrant"
MEMOIR_DIR="$HOME/Memoir"
OOBABOOGA_DIR="/home/futasharkslut/Desktop/text-generation-webui-3.11"

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
    echo "[*] Installing Qdrant binary into $QDRANT_DIR ..."
    mkdir -p "$QDRANT_DIR"
    cd "$QDRANT_DIR"

    # Fetch latest release JSON and extract correct tarball URL
    LATEST_URL=$(curl -s https://api.github.com/repos/qdrant/qdrant/releases/latest \
        | grep "browser_download_url" \
        | grep "x86_64-unknown-linux-gnu.tar.gz" \
        | cut -d '"' -f 4)

    echo "[*] Downloading Qdrant from: $LATEST_URL"
    curl -L "$LATEST_URL" -o qdrant.tar.gz

    # Extract into temp dir to handle nested folder
    mkdir -p tmp_extract
    tar -xvzf qdrant.tar.gz -C tmp_extract

    # Find binary inside and move it up
    BIN_PATH=$(find tmp_extract -type f -name "qdrant" | head -n 1)
    if [ -z "$BIN_PATH" ]; then
        echo "[!] Could not find qdrant binary inside archive!"
        exit 1
    fi
    mv "$BIN_PATH" "$QDRANT_DIR/qdrant"
    chmod +x "$QDRANT_DIR/qdrant"

    # Cleanup
    rm -rf tmp_extract qdrant.tar.gz
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
        echo "[*] Qdrant started (log: $QDRANT_DIR/qdrant.log)."
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
    source installer_files/env/bin/activate
    cd "$MEMOIR_DIR"
    python script.py
}

# === MAIN ===
install_docker
install_qdrant_binary
launch_qdrant
patch_memoir_script
run_memoir_in_venv
