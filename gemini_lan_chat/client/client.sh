#!/bin/bash

# Get the absolute directory where the script is located
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Define paths relative to the script's location
LIBS_DIR="$SCRIPT_DIR/libs"
CLIENT_SCRIPT="$SCRIPT_DIR/client.py"
BUNDLE_FILENAME="$SCRIPT_DIR/requests_bundle.zip"

# This setup function only runs if the 'libs' directory is missing
run_setup() {
    echo "--- First-time setup: Installing dependencies ---"
    # This prompt is NECESSARY for the one-time download
    read -p "Enter server IP for one-time dependency download: " SETUP_SERVER_IP
    if [ -z "$SETUP_SERVER_IP" ]; then echo "ERROR: IP cannot be empty."; exit 1; fi
    
    BUNDLE_URL="http://${SETUP_SERVER_IP}:5000/download_dependencies"
    echo "Downloading from $SETUP_SERVER_IP..."
    curl -# -L -f -o "$BUNDLE_FILENAME" "$BUNDLE_URL"
    
    if [ $? -ne 0 ]; then echo "ERROR: Download failed. Check server IP and connection."; exit 1; fi

    echo "Unpacking libraries..."
    python3 -c "import os, sys, platform, zipfile, shutil
LIBS_DIR = '$LIBS_DIR'
BUNDLE_FILENAME = '$BUNDLE_FILENAME'
TEMP_EXTRACT_PATH = '$SCRIPT_DIR/temp_bundle_extract'
def get_platform_identifier():
    s, m = platform.system().lower(), platform.machine().lower()
    if s == 'linux': return 'linux_x86_64' if m in ['x86_64', 'amd64'] else 'linux_aarch64'
    if s == 'darwin': return 'macos_arm64' if m == 'arm64' else 'macos_x86_64'
    return None
p_dir = get_platform_identifier()
if not p_dir: sys.exit(f'FATAL: Unsupported OS/Architecture ({platform.system()}/{platform.machine()})')
with zipfile.ZipFile(BUNDLE_FILENAME, 'r') as zf: zf.extractall(TEMP_EXTRACT_PATH)
source_dir = os.path.join(TEMP_EXTRACT_PATH, p_dir)
if not os.path.exists(source_dir): sys.exit(f'FATAL: Bundle missing files for {p_dir}.')
shutil.copytree(source_dir, LIBS_DIR)
shutil.rmtree(TEMP_EXTRACT_PATH)
"
    if [ $? -ne 0 ]; then echo "ERROR: Failed to set up libraries."; rm -f "$BUNDLE_FILENAME"; exit 1; fi
    rm "$BUNDLE_FILENAME"
    echo "--- Setup complete! ---"
}

# --- Main Logic ---
# 1. Check if setup needs to be run.
if [ ! -d "$LIBS_DIR" ]; then
    run_setup
fi

# 2. Launch the client script WITHOUT any arguments
echo "Starting client..."
python3 "$CLIENT_SCRIPT"