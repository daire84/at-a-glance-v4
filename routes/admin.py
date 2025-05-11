# routes/admin.py
import os
import json
from datetime import datetime
from flask import Blueprint, render_template, request, redirect, url_for, flash # Ensure this line is correct

from utils.decorators import admin_required # Absolute import
# --- Corrected helpers import ---
from utils.helpers import get_projects, get_project, save_project, get_project_calendar, save_project_calendar, generate_calendar, DATA_DIR, logger, recalculate_shoot_days
from utils.helpers import update_day_from_form # Absolute import
# --- Corrected calendar_generator import ---
from utils.calendar_generator import calculate_department_counts, calculate_location_counts # Absolute import

# Define Blueprint: Set url_prefix and template_folder
admin_bp = Blueprint('admin', __name__, url_prefix='/admin', template_folder='../templates/admin')

@admin_bp.route('/')
@admin_required
def admin_dashboard():
    """Admin dashboard"""
    projects = get_projects()
    # Renders 'admin/dashboard.html' because of template_folder
    return render_template('dashboard.html', projects=projects)

@admin_bp.route('/project/<project_id>', methods=['GET', 'POST'])
@admin_required
def admin_project(project_id):
    """Project details editor"""
    if request.method == 'POST':
        try:
            form_data = request.form.to_dict()
            if project_id != 'new':
                project = get_project(project_id)
                if not project:
                    flash('Project not found', 'error')
                    return redirect(url_for('admin.admin_dashboard'))
                original_dates = { # Store original dates
                    'prepStartDate': project.get('prepStartDate'),
                    'shootStartDate': project.get('shootStartDate'),
                    'wrapDate': project.get('wrapDate')
                }
            else:
                import uuid # Import uuid locally
                project = {'id': str(uuid.uuid4())}
                original_dates = {}

            for key, value in form_data.items():
                project[key] = value

            save_project(project) # Save the updated project data

            dates_changed = (
                project_id == 'new' or
                original_dates.get('prepStartDate') != project.get('prepStartDate') or
                original_dates.get('shootStartDate') != project.get('shootStartDate') or
                original_dates.get('wrapDate') != project.get('wrapDate')
            )

            if project_id == 'new':
                generate_calendar(project)
                flash('Project created and calendar generated successfully', 'success')
            elif dates_changed and request.form.get('regenerate_calendar') == 'yes':
                generate_calendar(project)
                flash('Project updated and calendar regenerated successfully', 'success')
            else:
                 flash('Project updated successfully', 'success')

            # Redirect to the admin calendar view for this project
            return redirect(url_for('admin.admin_calendar', project_id=project['id']))

        except Exception as e:
            logger.error(f"Error saving project: {str(e)}")
            flash(f'Error saving project: {str(e)}', 'error')
            # Fall through to render the form again

    # GET request or if POST had an error
    project = get_project(project_id) if project_id != 'new' else {}
    # Renders 'admin/project.html'
    return render_template('project.html', project=project)


@admin_bp.route('/calendar/<project_id>')
@admin_required # Apply decorator
def admin_calendar(project_id):
    """Calendar editor"""
    project = get_project(project_id)
    if not project:
        flash('Project not found', 'error')
        return redirect(url_for('admin.admin_dashboard'))

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
            logger.error(f"Error loading areas in admin_calendar route: {str(e)}")
    # --- End Load supporting data ---

    # Ensure the latest supporting data is available in the calendar_data object
    calendar_data['departments'] = departments
    calendar_data['locationAreas'] = areas # Add/overwrite with the fresh list

    # Calculate counts
    calendar_data = calculate_department_counts(calendar_data)
    calendar_data = calculate_location_counts(calendar_data)

    # Renders 'admin/calendar.html'
    return render_template('calendar.html', project=project, calendar=calendar_data, locations=locations)

@admin_bp.route('/day/<project_id>/<date>', methods=['GET', 'POST'])
@admin_required
def admin_day(project_id, date):
    """Day editor"""
    # Import helper function locally or ensure it's imported from app/utils
    from utils.helpers import update_day_from_form
    # Import update_calendar_with_location_areas if needed
    from utils.calendar_generator import update_calendar_with_location_areas

    project = get_project(project_id)
    if not project:
        flash('Project not found', 'error')
        return redirect(url_for('admin.admin_dashboard'))

    calendar_data = get_project_calendar(project_id)
    day_index = next((i for i, d in enumerate(calendar_data.get('days', [])) if d.get('date') == date), None)

    if day_index is None:
        flash('Day not found', 'error')
        return redirect(url_for('admin.admin_calendar', project_id=project_id))

    day = calendar_data['days'][day_index]

    if request.method == 'POST':
        try:
            form_data = request.form.to_dict()

            # --- Update locationArea based on selected location ---
            if 'location' in form_data and form_data['location']:
                selected_location_name = form_data['location']
                # Load locations and areas to find the area ID and name
                locations_list = []
                loc_file = os.path.join(DATA_DIR, 'locations.json')
                if os.path.exists(loc_file):
                    with open(loc_file, 'r') as f: locations_list = json.load(f)

                areas_list = []
                area_file = os.path.join(DATA_DIR, 'areas.json')
                if os.path.exists(area_file):
                     with open(area_file, 'r') as f: areas_list = json.load(f)

                area_id_found = None
                for loc in locations_list:
                    if loc['name'] == selected_location_name:
                        area_id_found = loc.get('areaId')
                        break

                if area_id_found:
                    area_name_found = None
                    for area in areas_list:
                        if area['id'] == area_id_found:
                            area_name_found = area.get('name')
                            break
                    if area_name_found:
                         form_data['locationArea'] = area_name_found
                         # Also store ID if needed later
                         form_data['locationAreaId'] = area_id_found
                    else:
                         form_data['locationArea'] = None # Area name not found
                         form_data['locationAreaId'] = None
                else:
                     form_data['locationArea'] = None # Area ID not found
                     form_data['locationAreaId'] = None
            else:
                # Clear area if location is cleared
                form_data['locationArea'] = None
                form_data['locationAreaId'] = None
            # --- End Update locationArea ---

            # Update the day object using the helper function
            calendar_data['days'][day_index] = update_day_from_form(day, form_data)
            updated_day = calendar_data['days'][day_index] # Get reference to updated day

            # Check if day type needs updating (e.g., Prep -> Shoot)
            if updated_day.get('isPrep', False) and not updated_day.get('isShootDay', False):
                shoot_start_date = datetime.strptime(project['shootStartDate'], "%Y-%m-%d").date()
                current_day_date = datetime.strptime(updated_day['date'], "%Y-%m-%d").date()
                is_shoot_period = current_day_date >= shoot_start_date

                if is_shoot_period and (updated_day.get('mainUnit') or updated_day.get('sequence')):
                    updated_day['isPrep'] = False
                    updated_day['isShootDay'] = True
                    # Recalculate all shoot day numbers
                    calendar_data['days'] = recalculate_shoot_days(calendar_data['days'])

            # Save the entire updated calendar
            # Consider making save_project_calendar more granular later if performance is an issue
            save_project_calendar(project_id, calendar_data)

            # Recalculate and save counts after saving day changes
            calendar_data = calculate_department_counts(calendar_data)
            calendar_data = calculate_location_counts(calendar_data)
            # update_calendar_with_location_areas might be implicitly covered by calc_loc_counts now
            save_project_calendar(project_id, calendar_data) # Save again with updated counts/areas

            flash('Day updated successfully', 'success')
            return redirect(url_for('admin.admin_calendar', project_id=project_id))

        except Exception as e:
            logger.error(f"Error updating day {date} for project {project_id}: {str(e)}")
            flash(f'Error updating day: {str(e)}', 'error')
            # Fall through to render form again

    # GET request or POST error
    # Renders 'admin/day.html'
    return render_template('day.html', project=project, day=day)


@admin_bp.route('/locations')
@admin_required
def admin_locations():
    """Location management page"""
    # Renders 'admin/locations.html'
    # Data is loaded client-side via API calls in the template's JS
    return render_template('locations.html')

@admin_bp.route('/departments')
@admin_required
def admin_departments():
    """Department management page"""
    # Renders 'admin/departments.html'
    # Data is loaded client-side via API calls in the template's JS
    return render_template('departments.html')

@admin_bp.route('/dates')
@admin_bp.route('/dates/<project_id>')
@admin_required
def admin_dates(project_id=None):
    """Special dates management page"""
    projects = get_projects()
     # Renders 'admin/dates.html'
    return render_template('dates.html', projects=projects, project_id=project_id)