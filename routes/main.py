# routes/main.py
import os
import json
from flask import Blueprint, render_template, redirect, url_for, flash, send_from_directory # <-- Add this line back

from utils.decorators import viewer_required # Absolute import
from utils.helpers import get_project, get_project_calendar, DATA_DIR, logger, get_projects # Absolute import
from utils.calendar_generator import calculate_department_counts, calculate_location_counts # Absolute import

main_bp = Blueprint('main', __name__)

@main_bp.route('/')
@viewer_required
def index():
    """Home page - Project selection"""
    projects = get_projects()
    return render_template('index.html', projects=projects)

@main_bp.route('/viewer/<project_id>')
# @viewer_required # Apply decorator if viewer needs to be logged in
def viewer(project_id):
    """Calendar viewer"""
    project = get_project(project_id)
    if not project:
        flash('Project not found', 'error')
        return redirect(url_for('main.index')) # Use blueprint name

    calendar_data = get_project_calendar(project_id)

    # --- Load supporting data ---
    departments = []
    departments_file = os.path.join(DATA_DIR, 'departments.json')
    if os.path.exists(departments_file):
        try:
            with open(departments_file, 'r') as f:
                departments = json.load(f)
        except Exception as e:
            logger.error(f"Error loading departments: {str(e)}")

    locations = []
    locations_file = os.path.join(DATA_DIR, 'locations.json')
    if os.path.exists(locations_file):
        try:
            with open(locations_file, 'r') as f:
                locations = json.load(f)
        except Exception as e:
            logger.error(f"Error loading locations: {str(e)}")

    areas = []
    areas_file = os.path.join(DATA_DIR, 'areas.json')
    if os.path.exists(areas_file):
        try:
            with open(areas_file, 'r') as f:
                areas = json.load(f)
        except Exception as e:
            logger.error(f"Error loading areas in viewer route: {str(e)}")
    # --- End Load supporting data ---

    # Ensure the latest supporting data is available in the calendar_data object
    calendar_data['departments'] = departments
    calendar_data['locationAreas'] = areas # Add/overwrite with the fresh list

    # Calculate counts
    calendar_data = calculate_department_counts(calendar_data)
    calendar_data = calculate_location_counts(calendar_data)

    # Note: Avoid saving calendar data here just for viewing
    # save_project_calendar(project_id, calendar_data)

    return render_template('viewer.html', project=project, calendar=calendar_data, locations=locations)

@main_bp.route('/health')
# @viewer_required # Apply if needed
def health():
    """Health check endpoint"""
    # This route might not belong in 'main', consider a separate 'utility' blueprint later
    from flask import jsonify # Import jsonify locally if only used here
    return jsonify({"status": "ok", "version": "1.0.0"}), 200

# Static files route - can stay in app.py or move here if preferred
# If moved here, change url_for('static', ...) to url_for('main.serve_static', ...)
# @main_bp.route('/static/<path:path>')
# def serve_static(path):
#    return send_from_directory('static', path) # Adjust path if needed ('../static')