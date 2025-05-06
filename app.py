# app.py - Main Application File (Refactored)

import os
import logging
from datetime import timedelta
from flask import Flask, request, render_template, send_from_directory # Keep render_template for error handlers
from dotenv import load_dotenv

# Load environment variables first
load_dotenv()

# --- Logging Setup ---
# Configure logging early
LOG_DIR_MAIN = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs')
os.makedirs(LOG_DIR_MAIN, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(LOG_DIR_MAIN, 'app.log')),
        logging.StreamHandler()
    ]
)
# You can get specific loggers later using logging.getLogger(__name__) in other modules

# --- Flask App Initialization & Config ---
app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['SESSION_PERMANENT'] = True
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=7) # Example: 1 week

# --- Import and Register Blueprints ---
# Imports must come *after* app = Flask(...) if blueprints need 'app',
# but here they only need helpers/decorators from utils.
from routes.main import main_bp
from routes.auth import auth_bp
from routes.admin import admin_bp
from routes.api import api_bp

app.register_blueprint(main_bp)
app.register_blueprint(auth_bp)
app.register_blueprint(admin_bp) # url_prefix='/admin' is set in routes/admin.py
app.register_blueprint(api_bp)   # url_prefix='/api' is set in routes/api.py


# --- Global Routes (Static files, Error Handlers) ---

# Static files route (kept global)
@app.route('/static/<path:path>')
def serve_static(path):
    # Use Flask's built-in static handling if possible, otherwise use this
    return send_from_directory('static', path)

# Error handlers (kept global)
@app.errorhandler(404)
def page_not_found(e):
    # Log the error or path attempted
    logging.warning(f"404 Not Found: {request.path} - {e}") # Added request path logging
    return render_template('404.html', error=e), 404

@app.errorhandler(500)
def server_error(e):
    # Log the full exception trace
    logging.exception("An internal server error occurred", exc_info=e)
    return render_template('500.html', error=e), 500

# --- Run the App ---
if __name__ == '__main__':
    # Use debug=False in production! Set host/port as needed.
    # Debug mode should be controlled by environment variable ideally.
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    app.run(host='0.0.0.0', port=5000, debug=debug_mode)