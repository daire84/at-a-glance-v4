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

# Add these routes to app.py after the existing routes

# Location and Area Management
@app.route('/admin/locations')
def admin_locations():
    """Location management page"""
    return render_template('admin/locations.html')

# API Routes for Locations
@app.route('/api/locations', methods=['GET', 'POST'])
def api_locations():
    """List or create locations"""
    locations_file = os.path.join(DATA_DIR, 'locations.json')
    
    if request.method == 'GET':
        # Get all locations
        if os.path.exists(locations_file):
            with open(locations_file, 'r') as f:
                locations = json.load(f)
        else:
            locations = []
        return jsonify(locations)
    
    elif request.method == 'POST':
        # Create new location
        location_data = request.get_json()
        
        # Add ID if not present
        if 'id' not in location_data:
            location_data['id'] = str(uuid.uuid4())
        
        # Read existing locations
        if os.path.exists(locations_file):
            with open(locations_file, 'r') as f:
                locations = json.load(f)
        else:
            locations = []
        
        # Add new location
        locations.append(location_data)
        
        # Save locations
        with open(locations_file, 'w') as f:
            json.dump(locations, f, indent=2)
        
        return jsonify(location_data), 201

@app.route('/api/locations/<location_id>', methods=['GET', 'PUT', 'DELETE'])
def api_location(location_id):
    """Get, update or delete a location"""
    locations_file = os.path.join(DATA_DIR, 'locations.json')
    
    # Check if locations file exists
    if not os.path.exists(locations_file):
        return jsonify({'error': 'Locations file not found'}), 404
    
    # Read locations
    with open(locations_file, 'r') as f:
        locations = json.load(f)
    
    # Find location
    location_index = next((i for i, loc in enumerate(locations) if loc.get('id') == location_id), None)
    
    if location_index is None:
        return jsonify({'error': 'Location not found'}), 404
    
    if request.method == 'GET':
        return jsonify(locations[location_index])
    
    elif request.method == 'PUT':
        # Update location
        location_data = request.get_json()
        location_data['id'] = location_id  # Ensure ID matches
        locations[location_index] = location_data
        
        # Save locations
        with open(locations_file, 'w') as f:
            json.dump(locations, f, indent=2)
        
        return jsonify(location_data)
    
    elif request.method == 'DELETE':
        # Delete location
        del locations[location_index]
        
        # Save locations
        with open(locations_file, 'w') as f:
            json.dump(locations, f, indent=2)
        
        return jsonify({'success': True})

# API Routes for Location Areas
@app.route('/api/areas', methods=['GET', 'POST'])
def api_areas():
    """List or create location areas"""
    areas_file = os.path.join(DATA_DIR, 'areas.json')
    
    if request.method == 'GET':
        # Get all areas
        if os.path.exists(areas_file):
            with open(areas_file, 'r') as f:
                areas = json.load(f)
        else:
            areas = []
        return jsonify(areas)
    
    elif request.method == 'POST':
        # Create new area
        area_data = request.get_json()
        
        # Add ID if not present
        if 'id' not in area_data:
            area_data['id'] = str(uuid.uuid4())
        
        # Read existing areas
        if os.path.exists(areas_file):
            with open(areas_file, 'r') as f:
                areas = json.load(f)
        else:
            areas = []
        
        # Add new area
        areas.append(area_data)
        
        # Save areas
        with open(areas_file, 'w') as f:
            json.dump(areas, f, indent=2)
        
        return jsonify(area_data), 201

@app.route('/api/areas/<area_id>', methods=['GET', 'PUT', 'DELETE'])
def api_area(area_id):
    """Get, update or delete a location area"""
    areas_file = os.path.join(DATA_DIR, 'areas.json')
    
    # Check if areas file exists
    if not os.path.exists(areas_file):
        return jsonify({'error': 'Areas file not found'}), 404
    
    # Read areas
    with open(areas_file, 'r') as f:
        areas = json.load(f)
    
    # Find area
    area_index = next((i for i, area in enumerate(areas) if area.get('id') == area_id), None)
    
    if area_index is None:
        return jsonify({'error': 'Area not found'}), 404
    
    if request.method == 'GET':
        return jsonify(areas[area_index])
    
    elif request.method == 'PUT':
        # Update area
        area_data = request.get_json()
        area_data['id'] = area_id  # Ensure ID matches
        areas[area_index] = area_data
        
        # Save areas
        with open(areas_file, 'w') as f:
            json.dump(areas, f, indent=2)
        
        return jsonify(area_data)
    
    elif request.method == 'DELETE':
        # Delete area
        del areas[area_index]
        
        # Save areas
        with open(areas_file, 'w') as f:
            json.dump(areas, f, indent=2)
        
        return jsonify({'success': True})

# Add these routes to app.py after the location routes

# Department Management
@app.route('/admin/departments')
def admin_departments():
    """Department management page"""
    return render_template('admin/departments.html')

# API Routes for Departments
@app.route('/api/departments', methods=['GET', 'POST'])
def api_departments():
    """List or create departments"""
    departments_file = os.path.join(DATA_DIR, 'departments.json')
    
    if request.method == 'GET':
        # Get all departments
        if os.path.exists(departments_file):
            with open(departments_file, 'r') as f:
                departments = json.load(f)
        else:
            departments = []
        return jsonify(departments)
    
    elif request.method == 'POST':
        # Create new department
        department_data = request.get_json()
        
        # Add ID if not present
        if 'id' not in department_data:
            department_data['id'] = str(uuid.uuid4())
        
        # Read existing departments
        if os.path.exists(departments_file):
            with open(departments_file, 'r') as f:
                departments = json.load(f)
        else:
            departments = []
        
        # Add new department
        departments.append(department_data)
        
        # Save departments
        with open(departments_file, 'w') as f:
            json.dump(departments, f, indent=2)
        
        return jsonify(department_data), 201

@app.route('/api/departments/<department_id>', methods=['GET', 'PUT', 'DELETE'])
def api_department(department_id):
    """Get, update or delete a department"""
    departments_file = os.path.join(DATA_DIR, 'departments.json')
    
    # Check if departments file exists
    if not os.path.exists(departments_file):
        return jsonify({'error': 'Departments file not found'}), 404
    
    # Read departments
    with open(departments_file, 'r') as f:
        departments = json.load(f)
    
    # Find department
    department_index = next((i for i, dept in enumerate(departments) if dept.get('id') == department_id), None)
    
    if department_index is None:
        return jsonify({'error': 'Department not found'}), 404
    
    if request.method == 'GET':
        return jsonify(departments[department_index])
    
    elif request.method == 'PUT':
        # Update department
        department_data = request.get_json()
        department_data['id'] = department_id  # Ensure ID matches
        departments[department_index] = department_data
        
        # Save departments
        with open(departments_file, 'w') as f:
            json.dump(departments, f, indent=2)
        
        return jsonify(department_data)
    
    elif request.method == 'DELETE':
        # Delete department
        del departments[department_index]
        
        # Save departments
        with open(departments_file, 'w') as f:
            json.dump(departments, f, indent=2)
        
        return jsonify({'success': True})

# Add these routes to app.py after the department routes

# Special Dates Management
@app.route('/admin/dates')
@app.route('/admin/dates/<project_id>')
def admin_dates(project_id=None):
    """Special dates management page"""
    projects = get_projects()
    return render_template('admin/dates.html', projects=projects, project_id=project_id)

# API Routes for Working Weekends
@app.route('/api/projects/<project_id>/weekends', methods=['GET', 'POST'])
def api_weekends(project_id):
    """List or create working weekends for a project"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    weekends_file = os.path.join(project_dir, 'weekends.json')
    
    if not os.path.exists(project_dir):
        return jsonify({'error': 'Project not found'}), 404
    
    if request.method == 'GET':
        # Get all working weekends for the project
        if os.path.exists(weekends_file):
            with open(weekends_file, 'r') as f:
                weekends = json.load(f)
        else:
            weekends = []
        return jsonify(weekends)
    
    elif request.method == 'POST':
        # Create new working weekend
        weekend_data = request.get_json()
        
        # Add ID if not present
        if 'id' not in weekend_data:
            weekend_data['id'] = str(uuid.uuid4())
        
        # Read existing weekends
        if os.path.exists(weekends_file):
            with open(weekends_file, 'r') as f:
                weekends = json.load(f)
        else:
            weekends = []
        
        # Add new weekend
        weekends.append(weekend_data)
        
        # Save weekends
        with open(weekends_file, 'w') as f:
            json.dump(weekends, f, indent=2)
        
        return jsonify(weekend_data), 201

@app.route('/api/projects/<project_id>/weekends/<weekend_id>', methods=['GET', 'PUT', 'DELETE'])
def api_weekend(project_id, weekend_id):
    """Get, update or delete a working weekend"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    weekends_file = os.path.join(project_dir, 'weekends.json')
    
    if not os.path.exists(project_dir):
        return jsonify({'error': 'Project not found'}), 404
    
    if not os.path.exists(weekends_file):
        return jsonify({'error': 'No working weekends found for this project'}), 404
    
    # Read weekends
    with open(weekends_file, 'r') as f:
        weekends = json.load(f)
    
    # Find weekend
    weekend_index = next((i for i, wknd in enumerate(weekends) if wknd.get('id') == weekend_id), None)
    
    if weekend_index is None:
        return jsonify({'error': 'Working weekend not found'}), 404
    
    if request.method == 'GET':
        return jsonify(weekends[weekend_index])
    
    elif request.method == 'PUT':
        # Update weekend
        weekend_data = request.get_json()
        weekend_data['id'] = weekend_id  # Ensure ID matches
        weekends[weekend_index] = weekend_data
        
        # Save weekends
        with open(weekends_file, 'w') as f:
            json.dump(weekends, f, indent=2)
        
        return jsonify(weekend_data)
    
    elif request.method == 'DELETE':
        # Delete weekend
        del weekends[weekend_index]
        
        # Save weekends
        with open(weekends_file, 'w') as f:
            json.dump(weekends, f, indent=2)
        
        return jsonify({'success': True})

# API Routes for Bank Holidays
@app.route('/api/projects/<project_id>/holidays', methods=['GET', 'POST'])
def api_holidays(project_id):
    """List or create bank holidays for a project"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    holidays_file = os.path.join(project_dir, 'holidays.json')
    
    if not os.path.exists(project_dir):
        return jsonify({'error': 'Project not found'}), 404
    
    if request.method == 'GET':
        # Get all bank holidays for the project
        if os.path.exists(holidays_file):
            with open(holidays_file, 'r') as f:
                holidays = json.load(f)
        else:
            holidays = []
        return jsonify(holidays)
    
    elif request.method == 'POST':
        # Create new bank holiday
        holiday_data = request.get_json()
        
        # Add ID if not present
        if 'id' not in holiday_data:
            holiday_data['id'] = str(uuid.uuid4())
        
        # Read existing holidays
        if os.path.exists(holidays_file):
            with open(holidays_file, 'r') as f:
                holidays = json.load(f)
        else:
            holidays = []
        
        # Add new holiday
        holidays.append(holiday_data)
        
        # Save holidays
        with open(holidays_file, 'w') as f:
            json.dump(holidays, f, indent=2)
        
        return jsonify(holiday_data), 201

@app.route('/api/projects/<project_id>/holidays/<holiday_id>', methods=['GET', 'PUT', 'DELETE'])
def api_holiday(project_id, holiday_id):
    """Get, update or delete a bank holiday"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    holidays_file = os.path.join(project_dir, 'holidays.json')
    
    if not os.path.exists(project_dir):
        return jsonify({'error': 'Project not found'}), 404
    
    if not os.path.exists(holidays_file):
        return jsonify({'error': 'No bank holidays found for this project'}), 404
    
    # Read holidays
    with open(holidays_file, 'r') as f:
        holidays = json.load(f)
    
    # Find holiday
    holiday_index = next((i for i, hol in enumerate(holidays) if hol.get('id') == holiday_id), None)
    
    if holiday_index is None:
        return jsonify({'error': 'Bank holiday not found'}), 404
    
    if request.method == 'GET':
        return jsonify(holidays[holiday_index])
    
    elif request.method == 'PUT':
        # Update holiday
        holiday_data = request.get_json()
        holiday_data['id'] = holiday_id  # Ensure ID matches
        holidays[holiday_index] = holiday_data
        
        # Save holidays
        with open(holidays_file, 'w') as f:
            json.dump(holidays, f, indent=2)
        
        return jsonify(holiday_data)
    
    elif request.method == 'DELETE':
        # Delete holiday
        del holidays[holiday_index]
        
        # Save holidays
        with open(holidays_file, 'w') as f:
            json.dump(holidays, f, indent=2)
        
        return jsonify({'success': True})

# API Routes for Hiatus Periods
@app.route('/api/projects/<project_id>/hiatus', methods=['GET', 'POST'])
def api_hiatus_periods(project_id):
    """List or create hiatus periods for a project"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    hiatus_file = os.path.join(project_dir, 'hiatus.json')
    
    if not os.path.exists(project_dir):
        return jsonify({'error': 'Project not found'}), 404
    
    if request.method == 'GET':
        # Get all hiatus periods for the project
        if os.path.exists(hiatus_file):
            with open(hiatus_file, 'r') as f:
                hiatus_periods = json.load(f)
        else:
            hiatus_periods = []
        return jsonify(hiatus_periods)
    
    elif request.method == 'POST':
        # Create new hiatus period
        hiatus_data = request.get_json()
        
        # Add ID if not present
        if 'id' not in hiatus_data:
            hiatus_data['id'] = str(uuid.uuid4())
        
        # Read existing hiatus periods
        if os.path.exists(hiatus_file):
            with open(hiatus_file, 'r') as f:
                hiatus_periods = json.load(f)
        else:
            hiatus_periods = []
        
        # Add new hiatus period
        hiatus_periods.append(hiatus_data)
        
        # Save hiatus periods
        with open(hiatus_file, 'w') as f:
            json.dump(hiatus_periods, f, indent=2)
        
        return jsonify(hiatus_data), 201

@app.route('/api/projects/<project_id>/hiatus/<hiatus_id>', methods=['GET', 'PUT', 'DELETE'])
def api_hiatus_period(project_id, hiatus_id):
    """Get, update or delete a hiatus period"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    hiatus_file = os.path.join(project_dir, 'hiatus.json')
    
    if not os.path.exists(project_dir):
        return jsonify({'error': 'Project not found'}), 404
    
    if not os.path.exists(hiatus_file):
        return jsonify({'error': 'No hiatus periods found for this project'}), 404
    
    # Read hiatus periods
    with open(hiatus_file, 'r') as f:
        hiatus_periods = json.load(f)
    
    # Find hiatus period
    hiatus_index = next((i for i, h in enumerate(hiatus_periods) if h.get('id') == hiatus_id), None)
    
    if hiatus_index is None:
        return jsonify({'error': 'Hiatus period not found'}), 404
    
    if request.method == 'GET':
        return jsonify(hiatus_periods[hiatus_index])
    
    elif request.method == 'PUT':
        # Update hiatus period
        hiatus_data = request.get_json()
        hiatus_data['id'] = hiatus_id  # Ensure ID matches
        hiatus_periods[hiatus_index] = hiatus_data
        
        # Save hiatus periods
        with open(hiatus_file, 'w') as f:
            json.dump(hiatus_periods, f, indent=2)
        
        return jsonify(hiatus_data)
    
    elif request.method == 'DELETE':
        # Delete hiatus period
        del hiatus_periods[hiatus_index]
        
        # Save hiatus periods
        with open(hiatus_file, 'w') as f:
            json.dump(hiatus_periods, f, indent=2)
        
        return jsonify({'success': True})

# API Routes for Special Dates
@app.route('/api/projects/<project_id>/special-dates', methods=['GET', 'POST'])
def api_special_dates(project_id):
    """List or create special dates for a project"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    special_dates_file = os.path.join(project_dir, 'special_dates.json')
    
    if not os.path.exists(project_dir):
        return jsonify({'error': 'Project not found'}), 404
    
    if request.method == 'GET':
        # Get all special dates for the project
        if os.path.exists(special_dates_file):
            with open(special_dates_file, 'r') as f:
                special_dates = json.load(f)
        else:
            special_dates = []
        return jsonify(special_dates)
    
    elif request.method == 'POST':
        # Create new special date
        special_date_data = request.get_json()
        
        # Add ID if not present
        if 'id' not in special_date_data:
            special_date_data['id'] = str(uuid.uuid4())
        
        # Read existing special dates
        if os.path.exists(special_dates_file):
            with open(special_dates_file, 'r') as f:
                special_dates = json.load(f)
        else:
            special_dates = []
        
        # Add new special date
        special_dates.append(special_date_data)
        
        # Save special dates
        with open(special_dates_file, 'w') as f:
            json.dump(special_dates, f, indent=2)
        
        return jsonify(special_date_data), 201

@app.route('/api/projects/<project_id>/special-dates/<special_date_id>', methods=['GET', 'PUT', 'DELETE'])
def api_special_date(project_id, special_date_id):
    """Get, update or delete a special date"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    special_dates_file = os.path.join(project_dir, 'special_dates.json')
    
    if not os.path.exists(project_dir):
        return jsonify({'error': 'Project not found'}), 404
    
    if not os.path.exists(special_dates_file):
        return jsonify({'error': 'No special dates found for this project'}), 404
    
    # Read special dates
    with open(special_dates_file, 'r') as f:
        special_dates = json.load(f)
    
    # Find special date
    special_date_index = next((i for i, sd in enumerate(special_dates) if sd.get('id') == special_date_id), None)
    
    if special_date_index is None:
        return jsonify({'error': 'Special date not found'}), 404
    
    if request.method == 'GET':
        return jsonify(special_dates[special_date_index])
    
    elif request.method == 'PUT':
        # Update special date
        special_date_data = request.get_json()
        special_date_data['id'] = special_date_id  # Ensure ID matches
        special_dates[special_date_index] = special_date_data
        
        # Save special dates
        with open(special_dates_file, 'w') as f:
            json.dump(special_dates, f, indent=2)
        
        return jsonify(special_date_data)
    
    elif request.method == 'DELETE':
        # Delete special date
        del special_dates[special_date_index]
        
        # Save special dates
        with open(special_dates_file, 'w') as f:
            json.dump(special_dates, f, indent=2)
        
        return jsonify({'success': True})