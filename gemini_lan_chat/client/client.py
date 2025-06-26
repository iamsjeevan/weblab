import requests # This will work after running install_deps_client.py
import json

# --- CONFIGURATION ---
# !!! IMPORTANT: SET YOUR SERVER'S IP ADDRESS HERE !!!
SERVER_IP = input("Enter the server IP address (e.g., 192.168.1.100 or localhost): ").strip()  # Example: "192.168.1.100"
# --- END CONFIGURATION ---

SERVER_URL_BASE = f"http://{SERVER_IP}:5000"
CHAT_ENDPOINT = f"{SERVER_URL_BASE}/chat"
RESET_ENDPOINT = f"{SERVER_URL_BASE}/reset_chat"

def main():
    if not SERVER_IP or SERVER_IP == "YOUR_SERVER_IP_HERE":
        print("ERROR: Please set the SERVER_IP variable in this script to your server's local IP address.")
        return

    print("Gemini LAN Client")
    print(f"Connecting to server at: {SERVER_IP}")
    print("Type 'exit' to quit, 'reset' to start a new conversation.")
    print("-" * 30)

    # Client-side history for display purposes. The server manages the actual Gemini session.
    conversation_log = []

    while True:
        try:
            prompt = input("You: ")
        except EOFError: # Handle Ctrl+D
            print("\nExiting...")
            break
        except KeyboardInterrupt: # Handle Ctrl+C
            print("\nExiting...")
            break


        if prompt.lower() == 'exit':
            print("Exiting...")
            break
        
        if prompt.lower() == 'reset':
            try:
                response = requests.post(RESET_ENDPOINT)
                response.raise_for_status() # Raise an exception for HTTP errors
                print(f"System: {response.json().get('message', 'Chat reset acknowledged by server.')}")
                conversation_log = [] # Clear local log too
                print("-" * 30)
            except requests.exceptions.RequestException as e:
                print(f"Error resetting chat: {e}")
            continue # Go to next input prompt

        if not prompt:
            continue

        payload = {"prompt": prompt}
        
        try:
            response = requests.post(CHAT_ENDPOINT, json=payload, timeout=60) # 60 second timeout
            response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)
            
            response_data = response.json()
            if "response" in response_data:
                ai_response = response_data["response"]
                print(f"Gemini: {ai_response}")
                conversation_log.append({"role": "user", "text": prompt})
                conversation_log.append({"role": "model", "text": ai_response})
            elif "error" in response_data:
                print(f"Server Error: {response_data['error']}")
            else:
                print("Server: Received an unexpected response format.")

        except requests.exceptions.ConnectionError:
            print(f"Error: Could not connect to the server at {SERVER_IP}. Is it running?")
        except requests.exceptions.Timeout:
            print("Error: The request to the server timed out.")
        except requests.exceptions.HTTPError as e:
            print(f"HTTP Error: {e.response.status_code} - {e.response.text}")
        except requests.exceptions.RequestException as e:
            print(f"An unexpected error occurred: {e}")
        except json.JSONDecodeError:
            print("Error: Could not decode JSON response from server. Raw response:")
            print(response.text)

if __name__ == "__main__":
    main()