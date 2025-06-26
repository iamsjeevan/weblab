import urllib.request
import zipfile
import subprocess
import os
import sys
import shutil # For robustly removing directory

# --- CONFIGURATION ---
# !!! IMPORTANT: SET YOUR SERVER'S IP ADDRESS HERE !!!
SERVER_IP = input("Enter the server IP address (e.g., 192.168.1.100 or localhost): ").strip()  # Example: "192.168.1.100"
# --- END CONFIGURATION ---

SERVER_URL_BASE = f"http://{SERVER_IP}:5000"
DOWNLOAD_URL = f"{SERVER_URL_BASE}/download_dependencies"
DOWNLOAD_DIR = "downloaded_dependencies_temp" # Temporary directory for downloads
ZIP_FILE_NAME = "requests_bundle.zip"
ZIP_FILE_PATH = os.path.join(DOWNLOAD_DIR, ZIP_FILE_NAME)

def main():
    if not SERVER_IP or SERVER_IP == "YOUR_SERVER_IP_HERE":
        print("ERROR: Please set the SERVER_IP variable in this script to your server's local IP address.")
        return

    print(f"Attempting to download dependencies from: {DOWNLOAD_URL}")

    # Create or clean the download directory
    if os.path.exists(DOWNLOAD_DIR):
        print(f"Cleaning up existing directory: {DOWNLOAD_DIR}")
        shutil.rmtree(DOWNLOAD_DIR) # More robust than os.rmdir for non-empty dirs
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    print(f"Created directory: {DOWNLOAD_DIR}")

    try:
        print(f"Downloading {ZIP_FILE_NAME}...")
        urllib.request.urlretrieve(DOWNLOAD_URL, ZIP_FILE_PATH)
        print(f"{ZIP_FILE_NAME} downloaded successfully to {ZIP_FILE_PATH}")
    except Exception as e:
        print(f"ERROR: Could not download dependencies: {e}")
        print(f"Please ensure the server is running at {SERVER_IP}:5000 and firewall allows connections.")
        return

    try:
        print(f"Unzipping {ZIP_FILE_PATH} into {DOWNLOAD_DIR}...")
        with zipfile.ZipFile(ZIP_FILE_PATH, 'r') as zip_ref:
            zip_ref.extractall(DOWNLOAD_DIR)
        print("Unzipping complete.")
    except Exception as e:
        print(f"ERROR: Could not unzip dependencies: {e}")
        return

    # Find all .whl files within the unzipped 'requests_packages' directory
    # The structure after unzipping is DOWNLOAD_DIR/requests_packages/*.whl
    extracted_packages_dir = os.path.join(DOWNLOAD_DIR, 'requests_packages')
    if not os.path.isdir(extracted_packages_dir):
        print(f"ERROR: Expected directory 'requests_packages' not found in the zip archive at {extracted_packages_dir}")
        return
        
    wheel_files = [
        os.path.join(extracted_packages_dir, f) 
        for f in os.listdir(extracted_packages_dir) 
        if f.endswith(".whl")
    ]

    if not wheel_files:
        print("ERROR: No .whl files found in the 'requests_packages' directory within the archive.")
        return

    print(f"Found wheel files: {', '.join(os.path.basename(f) for f in wheel_files)}")
    print("Attempting to install packages using pip...")

    try:
        # Use pip to install the wheels, telling it not to look online (--no-index)
        # and where to find the local files (--find-links)
        # We need to provide the full path to the directory containing the wheels.
        pip_command = [
            sys.executable, "-m", "pip", "install"
        ] + wheel_files + [
            "--no-index",
            f"--find-links=file://{os.path.abspath(extracted_packages_dir)}"
        ]
        
        print(f"Executing pip command: {' '.join(pip_command)}")
        subprocess.check_call(pip_command)
        print("\nSUCCESS: 'requests' and its dependencies should now be installed.")
        print("You can now try running client.py.")
    except subprocess.CalledProcessError as e:
        print(f"ERROR: pip installation failed: {e}")
        print("Make sure you have pip installed and it's in your system's PATH.")
        print("You might need to run this script with administrator/sudo privileges if installing globally.")
    except FileNotFoundError:
        print("ERROR: 'pip' command not found. Ensure Python and pip are correctly installed and in your PATH.")
    finally:
        # Clean up downloaded files and directory
        print(f"Cleaning up temporary directory: {DOWNLOAD_DIR}")
        shutil.rmtree(DOWNLOAD_DIR)
        print("Cleanup complete.")

if __name__ == "__main__":
    main()