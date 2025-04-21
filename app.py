import os
import json
import uuid
import logging
from datetime import datetime, timedelta
from flask import Flask, render_template, request, jsonify, redirect, url_for, send_from_directory, flash, session
from utils.calendar_generator import generate_calendar_days, calculate_department_counts, update_calendar_with_location_areas
from functools import wraps  # Add this for decorators
from dotenv import load_dotenv
load_dotenv()  # This will load variables from .env file into os.environ

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

# Debug: Check if environment variables are loaded
logger.info(f"VIEWER_PASSWORD is {'set' if 'VIEWER_PASSWORD' in os.environ else 'NOT set'}")
logger.info(f"ADMIN_PASSWORD is {'set' if 'ADMIN_PASSWORD' in os.environ else 'NOT set'}")

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
# Add permanent session configuration
app.config['SESSION_PERMANENT'] = True
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=7)  # Adjust as needed

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
    """Generate calendar days based on project dates, preserving existing data"""
    try:
        # Get existing calendar data first
        existing_calendar = get_project_calendar(project['id'])
        
        # Generate new calendar while preserving existing data
        calendar_data = generate_calendar_days(project, existing_calendar)
        
        return save_project_calendar(project['id'], calendar_data)
    except Exception as e:
        logger.error(f"Error generating calendar: {str(e)}")
        return {"days": []}

def update_day_from_form(day, form_data):
    """
    Update a day object with data from the submitted form
    
    Args:
        day (dict): The day object to update
        form_data (dict): Form data from request
        
    Returns:
        dict: The updated day object
    """
    try:
        # Update basic fields
        for field in ['mainUnit', 'sequence', 'location', 'locationArea', 'notes', 'secondUnit', 'secondUnitLocation']:
            if field in form_data:
                day[field] = form_data[field]
        
        # Handle numeric fields
        for field in ['extras', 'featuredExtras']:
            if field in form_data:
                day[field] = int(form_data[field]) if form_data[field] else 0
        
        # Handle departments (now comes as comma-separated string)
        if 'departments' in form_data:
            if form_data['departments']:
                # Split by comma and remove any empty entries
                departments = [d.strip() for d in form_data['departments'].split(',') if d.strip()]
                day['departments'] = departments
            else:
                day['departments'] = []
        
        return day
    
    except Exception as e:
        logger.error(f"Error updating day from form: {str(e)}")
        return day

def save_day_changes(project_id, date, form_data):
    """
    Save changes to a calendar day
    
    Args:
        project_id (str): Project ID
        date (str): Date in YYYY-MM-DD format
        form_data (dict): Form data from request
        
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        project_dir = os.path.join(data_dir, 'data', 'projects', project_id)
        calendar_file = os.path.join(project_dir, 'calendar.json')
        
        # Load calendar data
        if os.path.exists(calendar_file):
            with open(calendar_file, 'r') as f:
                calendar_data = json.load(f)
        else:
            logger.error(f"Calendar file not found for project {project_id}")
            return False
        
        # Find the day
        day_index = next((i for i, d in enumerate(calendar_data.get('days', [])) if d.get('date') == date), None)
        
        if day_index is None:
            logger.error(f"Day not found: {date}")
            return False
        
        # Update day with form data
        calendar_data['days'][day_index] = update_day_from_form(calendar_data['days'][day_index], form_data)
        
        # Save calendar data
        with open(calendar_file, 'w') as f:
            json.dump(calendar_data, f, indent=2)
        
        return True
    
    except Exception as e:
        logger.error(f"Error saving day changes: {str(e)}")
        return False

def recalculate_shoot_days(days):
    """
    Recalculate shoot day numbers based on the chronological order
    
    Args:
        days (list): List of calendar day objects
    """
    try:
        # Sort days by date
        days.sort(key=lambda d: d.get('date', ''))
        
        # Reset shoot day numbers
        shoot_day = 0
        for day in days:
            if day.get('isShootDay', False):
                shoot_day += 1
                day['shootDay'] = shoot_day
            else:
                day['shootDay'] = None
                
        return days
    except Exception as e:
        logger.error(f"Error recalculating shoot days: {str(e)}")
        return days

# -------------------------------------------------------------------------
# PAGE ROUTES
# -------------------------------------------------------------------------

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
                
                # Store original dates to check if dates are changed
                original_dates = {
                    'prepStartDate': project.get('prepStartDate'),
                    'shootStartDate': project.get('shootStartDate'),
                    'wrapDate': project.get('wrapDate')
                }
            else:
                project = {'id': str(uuid.uuid4())}
                original_dates = {}
            
            # Update project with form data
            for key, value in form_data.items():
                project[key] = value
            
            # Save project
            save_project(project)
            
            # Only generate calendar if this is a new project or if the user explicitly confirmed
            # they want to regenerate with new dates
            dates_changed = (
                project_id == 'new' or
                original_dates.get('prepStartDate') != project.get('prepStartDate') or
                original_dates.get('shootStartDate') != project.get('shootStartDate') or
                original_dates.get('wrapDate') != project.get('wrapDate')
            )
            
            if project_id == 'new':
                # For new projects, always generate the calendar
                generate_calendar(project)
                flash('Project created and calendar generated successfully', 'success')
            elif dates_changed and request.form.get('regenerate_calendar') == 'yes':
                # Only regenerate if dates changed AND user confirmed
                generate_calendar(project)
                flash('Project updated and calendar regenerated successfully', 'success')
            else:
                # Otherwise just save the project without regenerating calendar
                flash('Project updated successfully', 'success')
            
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
    
    # Make sure we have department data available in the calendar
    departments = []
    departments_file = os.path.join(DATA_DIR, 'departments.json')
    if os.path.exists(departments_file):
        try:
            with open(departments_file, 'r') as f:
                departments = json.load(f)
        except Exception as e:
            logger.error(f"Error loading departments: {str(e)}")
    
    # Ensure the departments are available in the calendar data
    calendar_data['departments'] = departments
    
    # Make sure department counts are up to date
    calculate_department_counts(calendar_data)
    
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
            
            # Update locationArea from selected location if needed
            if 'location' in form_data and form_data['location']:
                # Try to find location in the database to get its area
                locations_file = os.path.join(DATA_DIR, 'locations.json')
                if os.path.exists(locations_file):
                    with open(locations_file, 'r') as f:
                        locations = json.load(f)
                    
                    location = next((loc for loc in locations if loc['name'] == form_data['location']), None)
                    if location and 'areaId' in location:
                        # Get area name from area ID
                        areas_file = os.path.join(DATA_DIR, 'areas.json')
                        if os.path.exists(areas_file):
                            with open(areas_file, 'r') as f:
                                areas = json.load(f)
                            
                            area = next((a for a in areas if a['id'] == location['areaId']), None)
                            if area:
                                form_data['locationArea'] = area['name']
            
            # Update day data
            for key, value in form_data.items():
                day[key] = value
            
            # Check if this is a prep day being converted to a shoot day
            if day.get('isPrep', False) and not day.get('isShootDay', False):
                is_shoot_period = datetime.strptime(day['date'], "%Y-%m-%d").date() >= datetime.strptime(project['shootStartDate'], "%Y-%m-%d").date()
                
                if is_shoot_period and (day.get('mainUnit') or day.get('sequence')):
                    day['isPrep'] = False
                    day['isShootDay'] = True
                    
                    # Recalculate shoot days
                    calendar_data['days'] = recalculate_shoot_days(calendar_data['days'])
            
            # Save calendar data
            save_project_calendar(project_id, calendar_data)
            
            # Update department counts
            calendar_data = update_calendar_with_location_areas(calendar_data)
            calendar_data = calculate_department_counts(calendar_data)
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
    
    # Make sure we have department data available in the calendar
    departments = []
    departments_file = os.path.join(DATA_DIR, 'departments.json')
    if os.path.exists(departments_file):
        try:
            with open(departments_file, 'r') as f:
                departments = json.load(f)
        except Exception as e:
            logger.error(f"Error loading departments: {str(e)}")
    
    # Ensure the departments are available in the calendar data
    calendar_data['departments'] = departments
    
    # Make sure department counts are up to date
    calculate_department_counts(calendar_data)
    
    return render_template('viewer.html', project=project, calendar=calendar_data)

@app.route('/admin/locations')
def admin_locations():
    """Location management page"""
    return render_template('admin/locations.html')

@app.route('/admin/departments')
def admin_departments():
    """Department management page"""
    return render_template('admin/departments.html')

@app.route('/admin/dates')
@app.route('/admin/dates/<project_id>')
def admin_dates(project_id=None):
    """Special dates management page"""
    projects = get_projects()
    return render_template('admin/dates.html', projects=projects, project_id=project_id)

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({"status": "ok", "version": "1.0.0"}), 200

# -------------------------------------------------------------------------
# AUTHENTICATION ROUTES
# -------------------------------------------------------------------------

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Viewer login page"""
    error = None
    # If already logged in as admin, redirect to admin dashboard
    if session.get('user_role') == 'admin':
        return redirect(url_for('admin_dashboard'))
    # If already logged in as viewer, redirect to home
    if session.get('user_role') == 'viewer':
        return redirect(url_for('index'))
        
    if request.method == 'POST':
        if request.form['password'] == os.environ.get('VIEWER_PASSWORD', 'viewer'):
            session['user_role'] = 'viewer'
            flash('You were successfully logged in', 'success')
            return redirect(url_for('index'))
        else:
            error = 'Invalid password'
    return render_template('login.html', error=error)

@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    """Admin login page"""
    error = None
    # If already logged in as admin, redirect to admin dashboard
    if session.get('user_role') == 'admin':
        return redirect(url_for('admin_dashboard'))
        
    if request.method == 'POST':
        if request.form['password'] == os.environ.get('ADMIN_PASSWORD', 'admin'):
            session['user_role'] = 'admin'
            flash('You were successfully logged in as admin', 'success')
            return redirect(url_for('admin_dashboard'))
        else:
            error = 'Invalid password'
    return render_template('admin/login.html', error=error)

@app.route('/logout')
def logout():
    """Logout route"""
    session.pop('user_role', None)
    flash('You have been logged out', 'success')
    return redirect(url_for('login'))

# -------------------------------------------------------------------------
# API ROUTES
# -------------------------------------------------------------------------

# Project API Routes
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

# Calendar API Routes
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

@app.route('/api/projects/<project_id>/calendar/move-day', methods=['POST'])
def api_move_calendar_day(project_id):
    """Move a shoot day from one date to another and recalculate the shoot days"""
    try:
        # Get request data
        move_data = request.get_json()
        from_date = move_data.get('fromDate')
        to_date = move_data.get('toDate')
        mode = move_data.get('mode', 'swap')  # Default to 'swap' if not specified
        
        logger.info(f"Move day request: from {from_date} to {to_date} using mode {mode}")
        
        if not from_date or not to_date:
            logger.error("Missing source or target date")
            return jsonify({'error': 'Missing source or target date'}), 400
        
        # Get calendar data
        calendar_data = get_project_calendar(project_id)
        if not calendar_data or not calendar_data.get('days'):
            return jsonify({'error': 'Calendar not found'}), 404
        
        # Find the source and destination days
        days = calendar_data.get('days', [])
        from_day_index = next((i for i, d in enumerate(days) if d.get('date') == from_date), None)
        to_day_index = next((i for i, d in enumerate(days) if d.get('date') == to_date), None)
        
        if from_day_index is None or to_day_index is None:
            return jsonify({'error': 'Source or destination day not found'}), 404
        
        # Get the days to move
        from_day = days[from_day_index]
        to_day = days[to_day_index]
        
        # Only shoot days can be moved
        if not from_day.get('isShootDay', False):
            return jsonify({'error': 'Can only move shoot days'}), 400
        
        # Cannot move to a weekend, holiday, or hiatus day unless it's explicitly marked as a working day
        if ((to_day.get('isWeekend', False) and not to_day.get('isWorkingWeekend', False)) or
            (to_day.get('isHoliday', False) and not to_day.get('isWorking', False)) or
            to_day.get('isHiatus', False)):
            return jsonify({'error': 'Cannot move to a non-working day'}), 400
        
        # Determine the original shoot day numbers
        original_shoot_day = from_day.get('shootDay')
        target_shoot_day = to_day.get('shootDay')
        
        # Handle different move modes
        if mode == 'swap':
            # Swap the day details but keep the dates
            # Save the date and day-specific info for both days
            to_date_info = {
                'date': to_day.get('date'),
                'dayOfWeek': to_day.get('dayOfWeek'),
                'monthName': to_day.get('monthName'),
                'day': to_day.get('day'),
                'month': to_day.get('month'),
                'year': to_day.get('year'),
                'isPrep': to_day.get('isPrep', False),
                'isWeekend': to_day.get('isWeekend', False),
                'isHoliday': to_day.get('isHoliday', False),
                'isHiatus': to_day.get('isHiatus', False),
                'isWorkingWeekend': to_day.get('isWorkingWeekend', False),
                'dayType': to_day.get('dayType')
            }
            
            from_date_info = {
                'date': from_day.get('date'),
                'dayOfWeek': from_day.get('dayOfWeek'),
                'monthName': from_day.get('monthName'),
                'day': from_day.get('day'),
                'month': from_day.get('month'),
                'year': from_day.get('year'),
                'isPrep': from_day.get('isPrep', False),
                'isWeekend': from_day.get('isWeekend', False),
                'isHoliday': from_day.get('isHoliday', False),
                'isHiatus': from_day.get('isHiatus', False),
                'isWorkingWeekend': from_day.get('isWorkingWeekend', False),
                'dayType': from_day.get('dayType')
            }
            
            # Create copies of the days
            new_to_day = from_day.copy()
            new_from_day = to_day.copy()
            
            # Update the date-specific information
            for key, value in to_date_info.items():
                new_to_day[key] = value
            
            for key, value in from_date_info.items():
                new_from_day[key] = value
            
            # Set the shoot day status
            new_to_day['isShootDay'] = True
            if not to_day.get('isShootDay', False):
                new_from_day['isShootDay'] = False
                new_from_day['shootDay'] = None
            
            # Update the calendar
            days[from_day_index] = new_from_day
            days[to_day_index] = new_to_day
        else:
            # Other modes could be implemented here
            return jsonify({'error': 'Unsupported move mode'}), 400
        
        # Now recalculate shoot day numbers
        calendar_data['days'] = recalculate_shoot_days(days)
        
        # Save the updated calendar
        save_project_calendar(project_id, calendar_data)
        
        return jsonify({
            'success': True, 
            'message': 'Day moved successfully',
            'originalDay': original_shoot_day,
            'targetDay': target_shoot_day,
            'mode': mode
        }), 200
    
    except Exception as e:
        logger.error(f"Error moving calendar day: {str(e)}")
        return jsonify({'error': f'Error moving calendar day: {str(e)}'}), 500

# Location API Routes
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

# Area API Routes
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

# Department API Routes
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

# Special Dates (Weekends) API Routes
# Enhanced Working Weekends API Routes

@app.route('/api/projects/<project_id>/weekends', methods=['GET', 'POST'])
def api_weekends(project_id):
    """List or create working weekends for a project"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    weekends_file = os.path.join(project_dir, 'weekends.json')
    
    if not os.path.exists(project_dir):
        logger.error(f"Project directory not found for project_id: {project_id}")
        return jsonify({'error': 'Project not found'}), 404
    
    if request.method == 'GET':
        # Get all working weekends for the project
        if os.path.exists(weekends_file):
            try:
                with open(weekends_file, 'r') as f:
                    weekends = json.load(f)
                logger.info(f"Retrieved {len(weekends)} working weekends for project {project_id}")
                return jsonify(weekends)
            except Exception as e:
                logger.error(f"Error reading weekends file for project {project_id}: {str(e)}")
                return jsonify({'error': f'Error reading weekends data: {str(e)}'}), 500
        else:
            logger.info(f"No weekends file found for project {project_id}, returning empty list")
            return jsonify([])
    
    elif request.method == 'POST':
        # Create new working weekend
        try:
            weekend_data = request.get_json()
            if not weekend_data:
                logger.error("No data provided in POST request to weekends endpoint")
                return jsonify({'error': 'No data provided'}), 400
            
            # Validate required fields
            if 'date' not in weekend_data:
                logger.error("Required field 'date' missing in weekend data")
                return jsonify({'error': "Required field 'date' missing"}), 400
            
            # Validate date is a weekend (Saturday or Sunday)
            try:
                date = datetime.strptime(weekend_data['date'], "%Y-%m-%d").date()
                if date.weekday() not in [5, 6]:  # 5=Saturday, 6=Sunday
                    logger.warning(f"Date {weekend_data['date']} is not a weekend")
                    return jsonify({'error': 'Selected date is not a weekend (Saturday or Sunday)'}), 400
            except ValueError:
                logger.error(f"Invalid date format: {weekend_data['date']}")
                return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
            
            # Add ID if not present
            if 'id' not in weekend_data:
                weekend_data['id'] = str(uuid.uuid4())
            
            # Default isShootDay to True if not provided
            if 'isShootDay' not in weekend_data:
                weekend_data['isShootDay'] = True
            
            # Read existing weekends
            weekends = []
            if os.path.exists(weekends_file):
                with open(weekends_file, 'r') as f:
                    weekends = json.load(f)
            
            # Check if weekend already exists for the date
            existing_index = next((i for i, w in enumerate(weekends) if w.get('date') == weekend_data['date']), None)
            if existing_index is not None:
                logger.info(f"Working weekend for date {weekend_data['date']} already exists, updating")
                weekends[existing_index] = weekend_data
            else:
                # Add new weekend
                weekends.append(weekend_data)
            
            # Ensure the directory exists
            os.makedirs(os.path.dirname(weekends_file), exist_ok=True)
            
            # Save weekends
            with open(weekends_file, 'w') as f:
                json.dump(weekends, f, indent=2)
            
            logger.info(f"Successfully saved working weekend for {weekend_data['date']} in project {project_id}")
            
            # After adding a working weekend, we may need to regenerate the calendar
            # to update shoot day numbers
            project = get_project(project_id)
            if project:
                try:
                    calendar_data = get_project_calendar(project_id)
                    if calendar_data and 'days' in calendar_data:
                        # Update the calendar days with the new working weekend
                        calendar_data['days'] = recalculate_shoot_days(calendar_data['days'])
                        save_project_calendar(project_id, calendar_data)
                        logger.info(f"Calendar updated with new working weekend for project {project_id}")
                except Exception as e:
                    logger.error(f"Error updating calendar after adding working weekend: {str(e)}")
            
            return jsonify(weekend_data), 201
            
        except Exception as e:
            logger.error(f"Error creating working weekend: {str(e)}")
            return jsonify({'error': f'Error creating working weekend: {str(e)}'}), 500

@app.route('/api/projects/<project_id>/weekends/<weekend_id>', methods=['GET', 'PUT', 'DELETE'])
def api_weekend(project_id, weekend_id):
    """Get, update or delete a working weekend"""
    project_dir = os.path.join(PROJECTS_DIR, project_id)
    weekends_file = os.path.join(project_dir, 'weekends.json')
    
    if not os.path.exists(project_dir):
        logger.error(f"Project directory not found for project_id: {project_id}")
        return jsonify({'error': 'Project not found'}), 404
    
    if not os.path.exists(weekends_file):
        logger.error(f"No working weekends file found for project {project_id}")
        return jsonify({'error': 'No working weekends found for this project'}), 404
    
    try:
        # Read weekends
        with open(weekends_file, 'r') as f:
            weekends = json.load(f)
        
        # Find weekend
        weekend_index = next((i for i, wknd in enumerate(weekends) if wknd.get('id') == weekend_id), None)
        
        if weekend_index is None:
            logger.error(f"Working weekend with id {weekend_id} not found for project {project_id}")
            return jsonify({'error': 'Working weekend not found'}), 404
        
        if request.method == 'GET':
            logger.info(f"Retrieved working weekend {weekend_id} for project {project_id}")
            return jsonify(weekends[weekend_index])
        
        elif request.method == 'PUT':
            try:
                # Update weekend
                weekend_data = request.get_json()
                if not weekend_data:
                    return jsonify({'error': 'No data provided'}), 400
                
                # Validate date is a weekend if provided
                if 'date' in weekend_data:
                    try:
                        date = datetime.strptime(weekend_data['date'], "%Y-%m-%d").date()
                        if date.weekday() not in [5, 6]:  # 5=Saturday, 6=Sunday
                            logger.warning(f"Date {weekend_data['date']} is not a weekend")
                            return jsonify({'error': 'Selected date is not a weekend (Saturday or Sunday)'}), 400
                    except ValueError:
                        logger.error(f"Invalid date format: {weekend_data['date']}")
                        return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
                
                # Ensure ID matches
                weekend_data['id'] = weekend_id
                
                # Update weekend
                weekends[weekend_index] = {**weekends[weekend_index], **weekend_data}
                
                # Save weekends
                with open(weekends_file, 'w') as f:
                    json.dump(weekends, f, indent=2)
                
                logger.info(f"Updated working weekend {weekend_id} for project {project_id}")
                
                # After updating a working weekend, we may need to regenerate the calendar
                project = get_project(project_id)
                if project:
                    try:
                        calendar_data = get_project_calendar(project_id)
                        if calendar_data and 'days' in calendar_data:
                            # Update the calendar days with the updated working weekend
                            calendar_data['days'] = recalculate_shoot_days(calendar_data['days'])
                            save_project_calendar(project_id, calendar_data)
                            logger.info(f"Calendar updated after modifying working weekend for project {project_id}")
                    except Exception as e:
                        logger.error(f"Error updating calendar after modifying working weekend: {str(e)}")
                
                return jsonify(weekends[weekend_index])
                
            except Exception as e:
                logger.error(f"Error updating working weekend: {str(e)}")
                return jsonify({'error': f'Error updating working weekend: {str(e)}'}), 500
        
        elif request.method == 'DELETE':
            try:
                # Store the deleted date for calendar update
                deleted_date = weekends[weekend_index].get('date')
                
                # Delete weekend
                del weekends[weekend_index]
                
                # Save weekends
                with open(weekends_file, 'w') as f:
                    json.dump(weekends, f, indent=2)
                
                logger.info(f"Deleted working weekend {weekend_id} from project {project_id}")
                
                # After deleting a working weekend, we may need to regenerate the calendar
                project = get_project(project_id)
                if project and deleted_date:
                    try:
                        calendar_data = get_project_calendar(project_id)
                        if calendar_data and 'days' in calendar_data:
                            # Update the calendar days without the deleted working weekend
                            calendar_data['days'] = recalculate_shoot_days(calendar_data['days'])
                            save_project_calendar(project_id, calendar_data)
                            logger.info(f"Calendar updated after deleting working weekend for project {project_id}")
                    except Exception as e:
                        logger.error(f"Error updating calendar after deleting working weekend: {str(e)}")
                
                return jsonify({'success': True})
                
            except Exception as e:
                logger.error(f"Error deleting working weekend: {str(e)}")
                return jsonify({'error': f'Error deleting working weekend: {str(e)}'}), 500
                
    except Exception as e:
        logger.error(f"Error processing working weekend request: {str(e)}")
        return jsonify({'error': f'Error processing request: {str(e)}'}), 500

# Special Dates (Holidays) API Routes
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

# Special Dates (Hiatus) API Routes
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

# Special Dates (Other) API Routes
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