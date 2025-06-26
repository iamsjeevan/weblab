# create_bundle.py
import os
import subprocess
import shutil
import zipfile

# --- Configuration ---
# The libraries you want to bundle. 'requests' is the primary one.
# pip will automatically find all its dependencies.
PACKAGE_TO_BUNDLE = "requests"

# Define the target platforms you want to support.
# Each tuple is: (directory_name, python_platform_tag)
TARGET_PLATFORMS = [
    # Windows 10/11 (64-bit)
    ("windows_amd64", "win_amd64"),
    # macOS (Apple Silicon M1/M2/M3)
    ("macos_arm64", "macosx_11_0_arm64"),
    # macOS (Intel)
    ("macos_x86_64", "macosx_10_9_x86_64"),
    # Linux (Most common distributions like Ubuntu, CentOS on 64-bit Intel/AMD)
    ("linux_x86_64", "manylinux2014_x86_64"),
    # Linux (For ARM-based servers like AWS Graviton)
    ("linux_aarch64", "manylinux2014_aarch64"),
]

# The name of the temporary build directory and final zip file.
BUILD_DIR = "build_temp"
ZIP_FILENAME = "requests_bundle.zip"
# --- End Configuration ---

def create_bundle():
    """
    Downloads and bundles platform-specific wheels for the specified package.
    """
    if os.path.exists(BUILD_DIR):
        print(f"Removing old build directory: {BUILD_DIR}")
        shutil.rmtree(BUILD_DIR)
    
    os.makedirs(BUILD_DIR, exist_ok=True)
    print(f"Created build directory: {BUILD_DIR}")

    for dir_name, platform_tag in TARGET_PLATFORMS:
        target_dir = os.path.join(BUILD_DIR, dir_name)
        os.makedirs(target_dir, exist_ok=True)
        print("\n" + "="*50)
        print(f"Fetching packages for: {dir_name} (platform: {platform_tag})")
        print("="*50)

        # Use pip to download the package and its dependencies for the specific platform
        try:
            subprocess.run(
                [
                    "pip", "download",
                    PACKAGE_TO_BUNDLE,
                    "--platform", platform_tag,
                    "--python-version", "39",
                    "--abi", "cp39",
                    "--only-binary=:all:",
                    "-d", target_dir, # Download to the specific platform directory
                ],
                check=True,
                capture_output=True,
                text=True
            )
            
            # Unzip all the downloaded wheel files into the same directory
            for item in os.listdir(target_dir):
                if item.endswith(".whl"):
                    whl_path = os.path.join(target_dir, item)
                    print(f"Unzipping {item}...")
                    with zipfile.ZipFile(whl_path, 'r') as whl_zip:
                        whl_zip.extractall(target_dir)
                    os.remove(whl_path) # Clean up the .whl file

        except subprocess.CalledProcessError as e:
            print(f"ERROR: Failed to download for {dir_name}.")
            print(f"Pip output:\n{e.stderr}")
            print("\nThis can happen if a pre-compiled wheel is not available for a specific dependency on this platform.")
            print("Skipping this platform...")
            continue
    
    # Create the final zip file
    print("\n" + "="*50)
    print(f"Creating final archive: {ZIP_FILENAME}")
    shutil.make_archive(ZIP_FILENAME.replace('.zip', ''), 'zip', BUILD_DIR)
    print(f"Successfully created {ZIP_FILENAME}")

    # Clean up the build directory
    shutil.rmtree(BUILD_DIR)
    print("Cleaned up temporary build directory.")
    print(f"\nDone! Now, upload '{ZIP_FILENAME}' to your server's 'static_files' directory.")

if __name__ == "__main__":
    create_bundle()