#!/bin/bash

# Get the absolute directory where the script is located
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Define paths relative to the script's location
LIBS_DIR="$SCRIPT_DIR/libs"
CLIENT_SCRIPT="$SCRIPT_DIR/client.py"
BUNDLE_FILENAME="$SCRIPT_DIR/requests_bundle.zip"
IP_CACHE_FILE="$SCRIPT_DIR/.server_ip_cache"

run_setup() {
    echo "--- First-time setup: Installing dependencies ---"
    read -p "Enter the server's Public IP address: " SERVER_IP
    if [ -z "$SERVER_IP" ]; then echo "ERROR: IP cannot be empty."; exit 1; fi
    
    echo "$SERVER_IP" > "$IP_CACHE_FILE"

    BUNDLE_URL="http://${SERVER_IP}:5000/download_dependencies"
    echo "Downloading from $SERVER_IP..."
    curl -# -L -f -o "$BUNDLE_FILENAME" "$BUNDLE_URL"
    
    if [ $? -ne 0 ]; then echo "ERROR: Download failed. Check server IP and connection."; exit 1; fi

    echo "Unpacking libraries..."
    # Use python3 to perform platform-aware unzipping
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
# Check if the libs directory exists. If not, run setup.
if [ ! -d "$LIBS_DIR" ]; then
    run_setup
fi

# Get the cached server IP
if [ ! -f "$IP_CACHE_FILE" ]; then
    echo "Server IP not configured. Please run the setup again by deleting the 'libs' folder."
    exit 1
else
    SERVER_IP=$(cat "$IP_CACHE_FILE")
fi

echo "Starting client..."
# Run the python client, passing the server IP as an argument
python3 "$CLIENT_SCRIPT" "$SERVER_IP"