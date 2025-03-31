import os
import json
import uuid
import logging
from datetime import datetime, timedelta
from flask import Flask, render_template, request, jsonify, redirect, url_for, send_from_directory, flash, session

# Create logger
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')

# Configuration
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
PROJECTS_DIR = os.path.join(DATA_DIR, 'projects')
LOG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs')

# Ensure directories exist
os.makedirs(PROJECTS_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

# Helper functions
def get_projects():
    """Get all projects"""
    projects = []
    try:
        if os.path.exists(PROJECTS_DIR):
            for project_id in os.listdir(PROJECTS_DIR):
                project_dir = os.path.join(PROJECTS_DIR, project_id)
                if os.path.isdir(project_dir):
                    main_file = os.path.join(project_dir, 'main.json')
                    if os.path.exists(main_file):
                        with open(main_file, 'r') as f:
                            project = json.load(f)
                            projects.append(project)
        return sorted(projects, key=lambda x: x.get('updated', ''), reverse=True)
    except Exception as e:
        logger.error(f"Error getting projects: {str(e)}")
        return []

def get_project(project_id):
    """Get a specific project"""
    try:
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        main_file = os.path.join(project_dir, 'main.json')
        if os.path.exists(main_file):
            with open(main_file, 'r') as f:
                return json.load(f)
        return None
    except Exception as e:
        logger.error(f"Error getting project {project_id}: {str(e)}")
        return None

def save_project(project):
    """Save a project"""
    try:
        project_id = project.get('id')
        if not project_id:
            project_id = str(uuid.uuid4())
            project['id'] = project_id
        
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        os.makedirs(project_dir, exist_ok=True)
        
        # Set timestamps
        now = datetime.utcnow().isoformat() + 'Z'
        if 'created' not in project:
            project['created'] = now
        project['updated'] = now
        
        # Save project data
        main_file = os.path.join(project_dir, 'main.json')
        with open(main_file, 'w') as f:
            json.dump(project, f, indent=2)
        
        logger.info(f"Project {project_id} saved successfully")
        return project
    except Exception as e:
        logger.error(f"Error saving project: {str(e)}")
        raise

def get_project_calendar(project_id):
    """Get calendar data for a project"""
    try:
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        calendar_file = os.path.join(project_dir, 'calendar.json')
        
        if os.path.exists(calendar_file):
            with open(calendar_file, 'r') as f:
                return json.load(f)
        
        # If no calendar data exists yet, return empty data
        return {"days": []}
    except Exception as e:
        logger.error(f"Error getting calendar for project {project_id}: {str(e)}")
        return {"days": []}

def save_project_calendar(project_id, calendar_data):
    """Save calendar data for a project"""
    try:
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        calendar_file = os.path.join(project_dir, 'calendar.json')
        
        with open(calendar_file, 'w') as f:
            json.dump(calendar_data, f, indent=2)
        
        logger.info(f"Calendar data for project {project_id} saved successfully")
        return calendar_data
    except Exception as e:
        logger.error(f"Error saving calendar data for project {project_id}: {str(e)}")
        raise

def generate_calendar(project):
    """Generate calendar days based on project dates"""
    try:
        from utils.calendar_generator import generate_calendar_days
        calendar_data = generate_calendar_days(project)
        return save_project_calendar(project['id'], calendar_data)
    except Exception as e:
        logger.error(f"Error generating calendar: {str(e)}")
        return {"days": []}

# Routes
@app.route('/')
def index():
    """Home page - Project selection"""
    projects = get_projects()
    return render_template('index.html', projects=projects)

@app.route('/admin')
def admin_dashboard():
    """Admin dashboard"""
    projects = get_projects()
    return render_template('admin/dashboard.html', projects=projects)

@app.route('/admin/project/<project_id>', methods=['GET', 'POST'])
def admin_project(project_id):
    """Project details editor"""
    if request.method == 'POST':
        try:
            # Handle form submission
            form_data = request.form.to_dict()
            
            # Get existing project or create new
            if project_id != 'new':
                project = get_project(project_id)
                if not project:
                    flash('Project not found', 'error')
                    return redirect(url_for('admin_dashboard'))
            else:
                project = {'id': str(uuid.uuid4())}
            
            # Update project with form data
            for key, value in form_data.items():
                project[key] = value
            
            # Save project
            save_project(project)
            
            # Generate calendar if needed
            if 'prepStartDate' in form_data and 'shootStartDate' in form_data:
                generate_calendar(project)
            
            flash('Project saved successfully', 'success')
            return redirect(url_for('admin_calendar', project_id=project['id']))
            
        except Exception as e:
            logger.error(f"Error saving project: {str(e)}")
            flash(f'Error saving project: {str(e)}', 'error')
    
    # GET request or form validation failed
    project = get_project(project_id) if project_id != 'new' else {}
    return render_template('admin/project.html', project=project)

@app.route('/admin/calendar/<project_id>')
def admin_calendar(project_id):
    """Calendar editor"""
    project = get_project(project_id)
    if not project:
        flash('Project not found', 'error')
        return redirect(url_for('admin_dashboard'))
    
    calendar_data = get_project_calendar(project_id)
    return render_template('admin/calendar.html', project=project, calendar=calendar_data)

@app.route('/admin/day/<project_id>/<date>', methods=['GET', 'POST'])
def admin_day(project_id, date):
    """Day editor"""
    project = get_project(project_id)
    if not project:
        flash('Project not found', 'error')
        return redirect(url_for('admin_dashboard'))
    
    calendar_data = get_project_calendar(project_id)
    
    # Find the day
    day = next((d for d in calendar_data.get('days', []) if d.get('date') == date), None)
    
    if not day:
        flash('Day not found', 'error')
        return redirect(url_for('admin_calendar', project_id=project_id))
    
    if request.method == 'POST':
        try:
            # Update day with form data
            form_data = request.form.to_dict()
            
            # Handle numeric fields
            for field in ['extras', 'featuredExtras']:
                if field in form_data:
                    form_data[field] = int(form_data[field]) if form_data[field] else 0
            
            # Handle array fields
            if 'departments' in form_data:
                form_data['departments'] = [d.strip() for d in form_data['departments'].split(',') if d.strip()]
            
            # Update day data
            for key, value in form_data.items():
                day[key] = value
            
            # Save calendar data
            save_project_calendar(project_id, calendar_data)
            
            flash('Day updated successfully', 'success')
            return redirect(url_for('admin_calendar', project_id=project_id))
            
        except Exception as e:
            logger.error(f"Error updating day: {str(e)}")
            flash(f'Error updating day: {str(e)}', 'error')
    
    return render_template('admin/day.html', project=project, day=day)

@app.route('/viewer/<project_id>')
def viewer(project_id):
    """Calendar viewer"""
    project = get_project(project_id)
    if not project:
        flash('Project not found', 'error')
        return redirect(url_for('index'))
    
    calendar_data = get_project_calendar(project_id)
    return render_template('viewer.html', project=project, calendar=calendar_data)

# API Routes
@app.route('/api/projects', methods=['GET', 'POST'])
def api_projects():
    """List or create projects"""
    if request.method == 'GET':
        return jsonify(get_projects())
    
    elif request.method == 'POST':
        project = request.get_json()
        result = save_project(project)
        return jsonify(result), 201

@app.route('/api/projects/<project_id>', methods=['GET', 'PUT', 'DELETE'])
def api_project(project_id):
    """Get, update or delete a project"""
    if request.method == 'GET':
        project = get_project(project_id)
        if not project:
            return jsonify({'error': 'Project not found'}), 404
        return jsonify(project)
    
    elif request.method == 'PUT':
        project = request.get_json()
        project['id'] = project_id  # Ensure ID matches
        result = save_project(project)
        return jsonify(result)
    
    elif request.method == 'DELETE':
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        if os.path.exists(project_dir):
            import shutil
            shutil.rmtree(project_dir)
            return jsonify({'success': True})
        return jsonify({'error': 'Project not found'}), 404

@app.route('/api/projects/<project_id>/calendar', methods=['GET', 'POST'])
def api_project_calendar(project_id):
    """Get or update project calendar"""
    if request.method == 'GET':
        calendar_data = get_project_calendar(project_id)
        return jsonify(calendar_data)
    
    elif request.method == 'POST':
        calendar_data = request.get_json()
        result = save_project_calendar(project_id, calendar_data)
        return jsonify(result)

@app.route('/api/projects/<project_id>/calendar/generate', methods=['POST'])
def api_generate_calendar(project_id):
    """Generate calendar for project"""
    project = get_project(project_id)
    if not project:
        return jsonify({'error': 'Project not found'}), 404
    
    calendar_data = generate_calendar(project)
    return jsonify(calendar_data)

@app.route('/api/projects/<project_id>/calendar/day/<date>', methods=['GET', 'PUT'])
def api_calendar_day(project_id, date):
    """Get or update a specific calendar day"""
    calendar_data = get_project_calendar(project_id)
    
    # Find the day
    day_index = next((i for i, d in enumerate(calendar_data.get('days', [])) if d.get('date') == date), None)
    
    if request.method == 'GET':
        if day_index is None:
            return jsonify({'error': 'Day not found'}), 404
        return jsonify(calendar_data['days'][day_index])
    
    elif request.method == 'PUT':
        day_data = request.get_json()
        
        if day_index is None:
            return jsonify({'error': 'Day not found'}), 404
        
        # Update day data
        calendar_data['days'][day_index].update(day_data)
        
        # Save calendar data
        save_project_calendar(project_id, calendar_data)
        
        return jsonify(calendar_data['days'][day_index])

# Health check endpoint
@app.route('/health')
def health():
    return jsonify({"status": "ok", "version": "1.0.0"}), 200

# Static files
@app.route('/static/<path:path>')
def serve_static(path):
    return send_from_directory('static', path)

# Error handlers
@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(500)
def server_error(e):
    return render_template('500.html'), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
