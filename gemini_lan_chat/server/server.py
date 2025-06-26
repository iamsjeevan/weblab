import os
import flask
from flask import Flask, request, jsonify, send_from_directory
import google.generativeai as genai
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure Flask app
app = Flask(__name__)
STATIC_DIR = 'static_files'
app.config['STATIC_DIR'] = os.path.join(os.path.dirname(os.path.abspath(__file__)), STATIC_DIR)

# Configure Gemini API
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY not found in .env file or environment variables.")
genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-1.5-flash') # Or your preferred model

# In-memory storage for conversations, keyed by client IP
active_chats = {}

@app.route('/chat', methods=['POST'])
def chat_handler():
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 400

    data = request.get_json()
    prompt = data.get('prompt')
    client_id = request.remote_addr

    if not prompt:
        return jsonify({"error": "Missing 'prompt' in request"}), 400

    print(f"Received prompt from {client_id}: {prompt}")

    if client_id not in active_chats:
        print(f"Starting new chat session for {client_id}")
        active_chats[client_id] = model.start_chat(history=[])
    
    chat_session = active_chats[client_id]

    try:
        response = chat_session.send_message(prompt)
        print(f"Gemini response for {client_id}: {response.text}")
        return jsonify({"response": response.text})
    except Exception as e:
        print(f"Error communicating with Gemini API: {e}")
        return jsonify({"error": f"Gemini API error: {str(e)}"}), 500

@app.route('/reset_chat', methods=['POST'])
def reset_chat_handler():
    client_id = request.remote_addr
    if client_id in active_chats:
        del active_chats[client_id]
        print(f"Chat session reset for {client_id}")
        return jsonify({"message": "Chat session reset successfully"}), 200
    return jsonify({"message": "No active chat session to reset"}), 200

@app.route('/download_dependencies')
def download_dependencies():
    """Serves the universal requests_bundle.zip file."""
    try:
        print(f"Serving requests_bundle.zip from {app.config['STATIC_DIR']}")
        return send_from_directory(
            app.config['STATIC_DIR'],
            'requests_bundle.zip',
            as_attachment=True
        )
    except FileNotFoundError:
        return jsonify({"error": "requests_bundle.zip not found on server."}), 404
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Create the static files directory if it doesn't exist
    if not os.path.exists(app.config['STATIC_DIR']):
        os.makedirs(app.config['STATIC_DIR'])

    print("Starting Flask server for Gemini AI...")
    print(f"Make sure 'requests_bundle.zip' is in the '{app.config['STATIC_DIR']}' directory.")
    app.run(host='0.0.0.0', port=5000) # Use debug=False in production