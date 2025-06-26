import sys
import os
# We leave 'json' out for now as it will be imported later with the others.

# --- Robust Dependency Check ---
# Get the absolute path of the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Define the libs directory path relative to the script's location
LIBS_DIR = os.path.join(SCRIPT_DIR, "libs")

# Check if the libs directory exists
if not os.path.isdir(LIBS_DIR):
    print(f"ERROR: The '{LIBS_DIR}' directory was not found.")
    print("Please run 'start_client.sh' or 'start_client.bat' to install dependencies.")
    sys.exit(1)

# Add the libs directory to the Python path. THIS IS THE CRITICAL STEP.
sys.path.insert(0, LIBS_DIR)
# --- End Dependency Check ---


# --- NOW it is safe to import everything from the libs folder ---
try:
    import json
    import warnings
    import urllib3
    import requests
    # Suppress the specific OpenSSL warning, as it's not an error for this app
    warnings.filterwarnings("ignore", category=urllib3.exceptions.NotOpenSSLWarning)
except ImportError as e:
    # This will catch if any of the libraries are missing
    print(f"ERROR: A required library is missing: {e}")
    print(f"The 'libs' directory might be corrupted. Please delete it and run the start script again.")
    sys.exit(1)


def main():
    # The Python script now asks for the IP address every time.
    server_ip = input("Enter the server IP address: ").strip()
    if not server_ip:
        print("ERROR: Server IP cannot be empty.")
        return

    print("Gemini LAN Client")
    print(f"Connecting to server at: {server_ip}")
    print("Type 'exit' to quit, 'reset' to start a new conversation.")
    print("-" * 30)

    chat_endpoint = f"http://{server_ip}:5000/chat"
    reset_endpoint = f"http://{server_ip}:5000/reset_chat"

    while True:
        try:
            prompt = input("You: ")
        except (EOFError, KeyboardInterrupt):
            print("\nExiting...")
            break

        if not prompt:
            continue
        
        if prompt.lower() == 'exit':
            break
        
        if prompt.lower() == 'reset':
            try:
                response = requests.post(reset_endpoint)
                response.raise_for_status()
                print(f"System: {response.json().get('message', 'Chat reset.')}")
            except requests.RequestException as e:
                print(f"Error resetting chat: {e}")
            continue

        try:
            response = requests.post(chat_endpoint, json={"prompt": prompt}, timeout=90)
            response.raise_for_status()
            data = response.json()
            if "response" in data:
                print(f"Gemini: {data['response']}")
            elif "error" in data:
                print(f"Server Error: {data['error']}")
        except requests.exceptions.RequestException as e:
            print(f"An error occurred: {e}")
        except json.JSONDecodeError:
            print(f"Error decoding server response: {response.text}")

if __name__ == "__main__":
    main()