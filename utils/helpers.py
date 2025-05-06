# utils/helpers.py
import os
import json
import uuid
import logging
from datetime import datetime
# Import necessary functions from calendar_generator directly
# Adjust based on actual functions needed by these helpers
from .calendar_generator import generate_calendar_days, calculate_department_counts

# Define Constants relative to this file's location
UTILS_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(UTILS_DIR) # Project root (/app)
DATA_DIR = os.path.join(BASE_DIR, 'data')
PROJECTS_DIR = os.path.join(DATA_DIR, 'projects')
LOG_DIR = os.path.join(BASE_DIR, 'logs')

# Setup logger for helpers
logger = logging.getLogger(__name__)

# --- Helper Functions ---

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
                        try:
                            with open(main_file, 'r', encoding='utf-8') as f:
                                project = json.load(f)
                                projects.append(project)
                        except json.JSONDecodeError:
                            logger.error(f"Error decoding JSON for project {project_id}")
                        except Exception as inner_e:
                             logger.error(f"Error reading main.json for project {project_id}: {str(inner_e)}")

        return sorted(projects, key=lambda x: x.get('updated', ''), reverse=True)
    except Exception as e:
        logger.error(f"Error listing projects directory: {str(e)}")
        return []

def get_project(project_id):
    """Get a specific project"""
    if not project_id or project_id == 'new': # Handle 'new' case explicitly
        return None
    try:
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        main_file = os.path.join(project_dir, 'main.json')
        if os.path.exists(main_file):
            with open(main_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        logger.warning(f"Project main.json not found for ID: {project_id}")
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

        # Basic validation/sanitization (expand as needed)
        project_id = str(project_id).strip() # Ensure it's a string and remove whitespace
        if not project_id or '/' in project_id or '\\' in project_id or '.' in project_id:
             logger.error(f"Invalid project ID generated or provided: {project_id}")
             raise ValueError("Invalid project ID")


        project_dir = os.path.join(PROJECTS_DIR, project_id)
        os.makedirs(project_dir, exist_ok=True)

        now = datetime.utcnow().isoformat() + 'Z'
        if 'created' not in project or not project['created']:
            project['created'] = now
        project['updated'] = now

        main_file = os.path.join(project_dir, 'main.json')
        with open(main_file, 'w', encoding='utf-8') as f:
            json.dump(project, f, indent=2, ensure_ascii=False)

        logger.info(f"Project {project_id} saved successfully")
        return project
    except Exception as e:
        logger.error(f"Error saving project {project.get('id', 'N/A')}: {str(e)}")
        raise # Re-raise the exception so route can handle it

def get_project_calendar(project_id):
    """Get calendar data for a project"""
    if not project_id: return {"days": []}
    try:
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        calendar_file = os.path.join(project_dir, 'calendar.json')

        if os.path.exists(calendar_file):
            with open(calendar_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {"days": []} # Return empty structure if no file
    except Exception as e:
        logger.error(f"Error getting calendar for project {project_id}: {str(e)}")
        return {"days": []}

def save_project_calendar(project_id, calendar_data):
    """Save calendar data for a project"""
    if not project_id: raise ValueError("Project ID is required to save calendar")
    try:
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        os.makedirs(project_dir, exist_ok=True) # Ensure directory exists
        calendar_file = os.path.join(project_dir, 'calendar.json')

        with open(calendar_file, 'w', encoding='utf-8') as f:
            json.dump(calendar_data, f, indent=2, ensure_ascii=False)

        logger.info(f"Calendar data for project {project_id} saved successfully")
        return calendar_data # Return the saved data
    except Exception as e:
        logger.error(f"Error saving calendar data for project {project_id}: {str(e)}")
        raise

def generate_calendar(project):
    """Generate calendar days based on project dates, preserving existing data"""
    if not project or not project.get('id'):
        logger.error("Cannot generate calendar, invalid project data provided.")
        return {"days": [], "error": "Invalid project data"}
    try:
        project_id = project['id']
        existing_calendar = get_project_calendar(project_id)
        # generate_calendar_days is imported from .calendar_generator
        calendar_data = generate_calendar_days(project, existing_calendar)
        # Todo: Enhance generate_calendar_days to robustly merge/update area info
        return save_project_calendar(project_id, calendar_data)
    except Exception as e:
        logger.error(f"Error generating calendar for project {project.get('id', 'N/A')}: {str(e)}")
        return {"days": [], "error": f"Failed to generate calendar: {str(e)}"}


def update_day_from_form(day, form_data):
    """
    Update a day object with data from the submitted form (used by admin_day route)
    """
    if not isinstance(day, dict) or not isinstance(form_data, dict):
         logger.error("Invalid input for update_day_from_form")
         return day # Or raise error

    try:
        # Update string fields safely using .get()
        for field in ['mainUnit', 'sequence', 'location', 'locationArea', 'notes', 'secondUnit', 'secondUnitLocation']:
            day[field] = form_data.get(field, day.get(field)) # Keep old value if not in form

        # Handle numeric fields safely
        for field in ['extras', 'featuredExtras']:
            value_str = form_data.get(field)
            if value_str is not None: # Check if key exists in form
                 try:
                      day[field] = int(value_str) if value_str else 0
                 except (ValueError, TypeError):
                      day[field] = 0 # Default to 0 if conversion fails
                      logger.warning(f"Could not convert {field} value '{value_str}' to int.")

        # Handle departments list
        if 'departments' in form_data:
            dept_str = form_data.get('departments', '')
            if isinstance(dept_str, str):
                day['departments'] = [d.strip() for d in dept_str.split(',') if d.strip()]
            elif isinstance(dept_str, list): # Already a list?
                 day['departments'] = [str(d).strip() for d in dept_str if str(d).strip()]
            else:
                 day['departments'] = []
        # Only update if key doesn't exist, otherwise keep current
        elif 'departments' not in day:
             day['departments'] = []


        # Add locationAreaId if it was calculated in the route
        # Use .get() to avoid KeyError if not passed
        day['locationAreaId'] = form_data.get('locationAreaId', day.get('locationAreaId'))

        return day

    except Exception as e:
        logger.error(f"Error updating day object from form: {str(e)}")
        return day # Return original day on error


def save_day_changes(project_id, date, form_data):
    """
    Save changes to a calendar day - DEPRECATED?
    Logic seems covered by admin_day route which calls save_project_calendar
    """
    logger.warning("save_day_changes helper function called - check if necessary.")
    try:
        calendar_data = get_project_calendar(project_id)
        day_index = next((i for i, d in enumerate(calendar_data.get('days', [])) if d.get('date') == date), None)
        if day_index is None:
            logger.error(f"Day not found for saving via helper: {date}")
            return False
        # Assume day object was already updated before calling this
        save_project_calendar(project_id, calendar_data)
        return True
    except Exception as e:
        logger.error(f"Error in save_day_changes helper for {date}: {str(e)}")
        return False

def recalculate_shoot_days(days):
    """
    Recalculate shoot day numbers based on chronological order
    """
    if not isinstance(days, list): return [] # Handle invalid input
    try:
        # Ensure dates are valid before sorting
        valid_days = []
        for d in days:
            if d.get('date'):
                 try:
                      datetime.strptime(d['date'], '%Y-%m-%d') # Validate format
                      valid_days.append(d)
                 except ValueError:
                      logger.warning(f"Invalid date format skipped in recalculate_shoot_days: {d.get('date')}")
            else:
                 logger.warning("Day missing date skipped in recalculate_shoot_days")

        valid_days.sort(key=lambda d: d['date'])

        shoot_day = 0
        for day in valid_days:
            # Ensure isShootDay exists and is boolean-like
            is_shoot = day.get('isShootDay', False)
            if is_shoot: # Check for truthiness
                shoot_day += 1
                day['shootDay'] = shoot_day
            else:
                day['shootDay'] = None # Use None instead of empty string or 0

        return valid_days # Return the sorted, updated list
    except Exception as e:
        logger.error(f"Error recalculating shoot days: {str(e)}")
        return days # Return original list on error

def update_all_projects_department_counts():
    """Update department counts in all project calendars"""
    try:
        projects = get_projects()
        for project in projects:
            project_id = project.get('id')
            if project_id:
                calendar_data = get_project_calendar(project_id)
                if calendar_data and 'days' in calendar_data:
                    # calculate_department_counts is imported from .calendar_generator
                    calendar_data = calculate_department_counts(calendar_data)
                    save_project_calendar(project_id, calendar_data)
                    logger.info(f"Updated department counts for project {project_id}")
    except Exception as e:
        logger.error(f"Error updating all department counts: {str(e)}")

# --- Global Data Loaders (Example for locations/areas/departments) ---
# Consider placing these here or in a dedicated data_loader util file

def load_global_data(filename, default=[]):
    """Helper to load global JSON data like areas.json, locations.json"""
    filepath = os.path.join(DATA_DIR, filename)
    if os.path.exists(filepath):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Error loading global data file {filename}: {e}")
    return default

def save_global_data(filename, data):
    """Helper to save global JSON data"""
    filepath = os.path.join(DATA_DIR, filename)
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        logger.info(f"Global data file {filename} saved successfully.")
    except Exception as e:
        logger.error(f"Error saving global data file {filename}: {e}")
        raise # Re-raise exception