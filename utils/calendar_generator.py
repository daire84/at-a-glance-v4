import os
import json
import logging
from datetime import datetime, timedelta
from dateutil import parser
from dateutil.relativedelta import relativedelta

logger = logging.getLogger(__name__)

def generate_calendar_days(project, existing_calendar=None):
    """
    Generate calendar days for a project based on dates
    
    Args:
        project (dict): Project data including prepStartDate and shootStartDate
        existing_calendar (dict, optional): Existing calendar data to preserve
        
    Returns:
        dict: Calendar data with days array
    """
    try:
        # Validate required fields
        if not project.get('prepStartDate') or not project.get('shootStartDate'):
            logger.error("Missing required dates for calendar generation")
            return {"days": []}
        
        # Parse dates
        prep_start = parser.parse(project['prepStartDate'])
        shoot_start = parser.parse(project['shootStartDate'])
        
        # Calculate wrap date
        if project.get('wrapDate'):
            wrap_date = parser.parse(project['wrapDate'])
        else:
            # If no wrap date provided, default to 4 weeks after shoot start
            wrap_date = shoot_start + relativedelta(weeks=4)
        
        # Load special dates (bank holidays, working weekends, hiatus periods)
        holidays = load_bank_holidays(project.get('id'))
        working_weekends = load_working_weekends(project.get('id'))
        hiatus_periods = load_hiatus_periods(project.get('id'))
        special_dates = load_special_dates(project.get('id'))
        
        # Create a map of existing days by date for quick lookup
        existing_days_map = {}
        if existing_calendar and 'days' in existing_calendar:
            for day in existing_calendar['days']:
                if 'date' in day:
                    existing_days_map[day['date']] = day
        
        # Generate all dates in range
        current_date = prep_start
        calendar_days = []
        shoot_day = 0
        
        while current_date <= wrap_date:
            date_str = current_date.strftime("%Y-%m-%d")
            
            # Check if date is a holiday
            is_holiday = is_bank_holiday(date_str, holidays)
            holiday_data = get_holiday_data(date_str, holidays)
            
            # Check if date is in a hiatus period
            is_hiatus = is_in_hiatus(date_str, hiatus_periods)
            hiatus_data = get_hiatus_data(date_str, hiatus_periods)
            
            # Determine if it's a weekend
            is_weekend = current_date.weekday() >= 5  # 5=Saturday, 6=Sunday
            
            # Check if it's a working weekend
            is_working_weekend = is_weekend and is_working_weekend_date(date_str, working_weekends)
            working_weekend_data = get_working_weekend_data(date_str, working_weekends)
            
            # Determine if it's a shoot day
            is_shoot_period = current_date >= shoot_start
            
            # Logic for determining shoot day:
            # - Must be in shoot period
            # - Must not be a weekend UNLESS it's a working weekend
            # - Must not be a holiday UNLESS it's a working holiday
            # - Must not be in a hiatus period
            is_shoot_day = (
                is_shoot_period and 
                (not is_weekend or is_working_weekend) and
                (not is_holiday or (is_holiday and holiday_data and holiday_data.get('isWorking', False) and holiday_data.get('isShootDay', False))) and
                not is_hiatus and
                # Add check for special dates - if it exists and is marked as non-working, it's not a shoot day
                not (special_date_data and not special_date_data.get('isWorking', True))
            )
            
            # Increment shoot day count for actual shoot days
            if is_shoot_day:
                shoot_day += 1
            
            # Get day type and color based on conditions
            day_type = get_day_type(
                is_prep=current_date < shoot_start,
                is_shoot_day=is_shoot_day,
                is_weekend=is_weekend,
                is_holiday=is_holiday,
                is_hiatus=is_hiatus,
                is_working_weekend=is_working_weekend
            )
            
            # Check if we have existing data for this date
            if date_str in existing_days_map:
                # Start with the existing day data
                day = existing_days_map[date_str].copy()
                
                # Update only the date-related properties and shoot day number
                day.update({
                    "isPrep": current_date < shoot_start,
                    "isShootDay": is_shoot_day,
                    "isWeekend": is_weekend,
                    "isHoliday": is_holiday,
                    "isHiatus": is_hiatus,
                    "isWorkingWeekend": is_working_weekend,
                    "dayType": day_type,
                    "shootDay": shoot_day if is_shoot_day else None
                })
            else:
                # Create a new day entry
                day = {
                    "date": date_str,
                    "dayOfWeek": current_date.strftime("%A"),
                    "monthName": current_date.strftime("%B"),
                    "day": current_date.day,
                    "month": current_date.month,
                    "year": current_date.year,
                    "isPrep": current_date < shoot_start,
                    "isShootDay": is_shoot_day,
                    "isWeekend": is_weekend,
                    "isHoliday": is_holiday,
                    "isHiatus": is_hiatus,
                    "isWorkingWeekend": is_working_weekend,
                    "dayType": day_type,
                    "shootDay": shoot_day if is_shoot_day else None,
                    "mainUnit": "",
                    "extras": 0,
                    "featuredExtras": 0,
                    "location": "",
                    "locationArea": "",
                    "sequence": "",
                    "departments": [],
                    "notes": ""
                }
            
            # Add special date info to notes ONLY if notes are empty or already contain special date info
            special_date_data = get_special_date(date_str, special_dates)
            notes_contains_special_info = False
            
            if day.get("notes"):
                # Check if notes already contain any of these keywords
                special_keywords = ["BANK HOLIDAY:", "HIATUS:", "WORKING WEEKEND:", "Travel Day:", "Meeting:", "Rehearsal:", "Special Date:"]
                notes_contains_special_info = any(keyword in day["notes"] for keyword in special_keywords)
            
            # Only update notes if they're empty or already have special date info
            if not day.get("notes") or notes_contains_special_info:
                if is_holiday and holiday_data:
                    day["notes"] = f"BANK HOLIDAY: {holiday_data.get('name', '')}"
                    
                if is_hiatus and hiatus_data:
                    day["notes"] = f"HIATUS: {hiatus_data.get('name', '')}"
                    
                if is_working_weekend and working_weekend_data:
                    if working_weekend_data.get('description'):
                        day["notes"] = f"WORKING WEEKEND: {working_weekend_data.get('description', '')}"
                    else:
                        day["notes"] = "WORKING WEEKEND"
                
                if special_date_data:
                    type_display = {
                        'travel': 'Travel Day',
                        'meeting': 'Meeting',
                        'rehearsal': 'Rehearsal',
                        'other': 'Special Date'
                    }.get(special_date_data.get('type', 'other'), 'Special Date')
                    
                    day["notes"] = f"{type_display}: {special_date_data.get('name', '')}"
                    if special_date_data.get('description'):
                        day["notes"] += f" - {special_date_data.get('description')}"
            
            calendar_days.append(day)
            current_date += timedelta(days=1)
        
        # Load location areas for reference
        location_areas = load_location_areas()
        
        # Create calendar data
        calendar_data = {
            "projectId": project.get('id', ''),
            "days": calendar_days,
            "departmentCounts": calculate_department_counts({"days": calendar_days}),
            "locationAreas": location_areas,
            "lastUpdated": datetime.utcnow().isoformat() + 'Z'
        }
        
        calendar_data = calculate_location_counts(calendar_data)
        
        # Keep any additional properties from the existing calendar
        if existing_calendar:
            for key, value in existing_calendar.items():
                if key not in calendar_data and key != "days":
                    calendar_data[key] = value
        
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error generating calendar: {str(e)}")
        return {"days": []}

def initialize_department_counts():
    """Initialize department counts with zeros"""
    return {
        "main": 0,
        "secondUnit": 0,
        "splitDay": 0,
        "sixthDay": 0,
        "steadicam": 0,
        "sfx": 0,
        "stunts": 0,
        "crane": 0,
        "prosthetics": 0,
        "lowLoader": 0
    }

# Update the get_day_type function to better handle working weekends
def get_day_type(is_prep, is_shoot_day, is_weekend, is_holiday, is_hiatus, is_working_weekend):
    """
    Determine the type of day for styling purposes
    
    Args:
        is_prep (bool): Whether the day is a prep day
        is_shoot_day (bool): Whether the day is a shoot day
        is_weekend (bool): Whether the day is a weekend
        is_holiday (bool): Whether the day is a holiday
        is_hiatus (bool): Whether the day is a hiatus day
        is_working_weekend (bool): Whether the day is a working weekend
        
    Returns:
        str: Day type identifier for styling
    """
    if is_hiatus:
        return "hiatus"
    elif is_holiday:
        return "holiday"
    elif is_prep:
        return "prep"
    elif is_shoot_day:
        return "shoot"
    elif is_weekend:
        if is_working_weekend:
            return "working-weekend"
        else:
            return "weekend"
    else:
        return "normal"

def load_bank_holidays(project_id):
    """Load bank holidays for a project"""
    if not project_id:
        return []
    
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    holidays_file = os.path.join(data_dir, 'data', 'projects', project_id, 'holidays.json')
    
    if not os.path.exists(holidays_file):
        return []
    
    try:
        with open(holidays_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading bank holidays: {str(e)}")
        return []

def load_working_weekends(project_id):
    """
    Load working weekends for a project
    
    Args:
        project_id (str): Project ID
        
    Returns:
        list: List of working weekend objects
    """
    if not project_id:
        logger.warning("No project_id provided to load_working_weekends")
        return []
    
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    weekends_file = os.path.join(data_dir, 'data', 'projects', project_id, 'weekends.json')
    
    if not os.path.exists(weekends_file):
        logger.info(f"No weekends file exists for project {project_id}")
        return []
    
    try:
        with open(weekends_file, 'r') as f:
            weekends = json.load(f)
        logger.info(f"Loaded {len(weekends)} working weekends for project {project_id}")
        return weekends
    except Exception as e:
        logger.error(f"Error loading working weekends for project {project_id}: {str(e)}")
        return []

def load_hiatus_periods(project_id):
    """Load hiatus periods for a project"""
    if not project_id:
        return []
    
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    hiatus_file = os.path.join(data_dir, 'data', 'projects', project_id, 'hiatus.json')
    
    if not os.path.exists(hiatus_file):
        return []
    
    try:
        with open(hiatus_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading hiatus periods: {str(e)}")
        return []

def load_special_dates(project_id):
    """Load special dates for a project"""
    if not project_id:
        return []
    
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    special_dates_file = os.path.join(data_dir, 'data', 'projects', project_id, 'special_dates.json')
    
    if not os.path.exists(special_dates_file):
        return []
    
    try:
        with open(special_dates_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading special dates: {str(e)}")
        return []

def get_special_date(date_str, special_dates):
    """Get special date data for a specific date"""
    for special_date in special_dates:
        if special_date.get('date') == date_str:
            return special_date
    return None

def load_location_areas():
    """Load location areas with colors"""
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    areas_file = os.path.join(data_dir, 'data', 'areas.json')
    
    if not os.path.exists(areas_file):
        return []
    
    try:
        with open(areas_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading location areas: {str(e)}")
        return []

def is_bank_holiday(date_str, holidays):
    """Check if a date is a bank holiday"""
    return any(h.get('date') == date_str for h in holidays)

def get_holiday_data(date_str, holidays):
    """Get holiday data for a specific date"""
    for holiday in holidays:
        if holiday.get('date') == date_str:
            return holiday
    return None

def is_working_weekend_date(date_str, working_weekends):
    """
    Check if a date is designated as a working weekend
    
    Args:
        date_str (str): Date string in format YYYY-MM-DD
        working_weekends (list): List of working weekend objects
        
    Returns:
        bool: True if the date is a working weekend, False otherwise
    """
    if not date_str or not working_weekends:
        return False
    
    # Check if the date is in the list of working weekends
    for weekend in working_weekends:
        if weekend.get('date') == date_str:
            return True
    
    return False

def get_working_weekend_data(date_str, working_weekends):
    """
    Get working weekend data for a specific date
    
    Args:
        date_str (str): Date string in format YYYY-MM-DD
        working_weekends (list): List of working weekend objects
        
    Returns:
        dict or None: Working weekend data if found, None otherwise
    """
    if not date_str or not working_weekends:
        return None

    # Find the working weekend data for the date
    for weekend in working_weekends:
        if weekend.get('date') == date_str:
            return weekend
    
    return None

def is_in_hiatus(date_str, hiatus_periods):
    """Check if a date falls within a hiatus period"""
    date = parser.parse(date_str).date()
    
    for hiatus in hiatus_periods:
        start_date = parser.parse(hiatus.get('startDate')).date()
        end_date = parser.parse(hiatus.get('endDate')).date()
        
        if start_date <= date <= end_date:
            return True
    
    return False

def get_hiatus_data(date_str, hiatus_periods):
    """Get hiatus data for a specific date"""
    date = parser.parse(date_str).date()
    
    for hiatus in hiatus_periods:
        start_date = parser.parse(hiatus.get('startDate')).date()
        end_date = parser.parse(hiatus.get('endDate')).date()
        
        if start_date <= date <= end_date:
            return hiatus
    
    return None

# Add these improved functions to your calendar_generator.py file

def update_calendar_with_location_areas(calendar_data):
    """
    Update calendar data with location area information for color coding
    """
    try:
        # Load locations with their areas
        data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        locations_file = os.path.join(data_dir, 'data', 'locations.json')
        areas_file = os.path.join(data_dir, 'data', 'areas.json')
        
        if not os.path.exists(locations_file) or not os.path.exists(areas_file):
            return calendar_data
        
        with open(locations_file, 'r') as f:
            locations = json.load(f)
        
        with open(areas_file, 'r') as f:
            areas = json.load(f)
        
        # Create lookup maps
        location_map = {loc['name']: loc for loc in locations}
        area_map = {area['id']: area for area in areas}
        area_name_map = {area['name']: area for area in areas}
        
        # Update days with location area info
        for day in calendar_data.get('days', []):
            location_name = day.get('location', '')
            area_name = day.get('locationArea', '')
            
            # If day already has an area name, make sure it has the corresponding color
            if area_name and area_name in area_name_map:
                # The area exists in our map, keep using it
                continue
            
            # If not, try to find it from the location
            if location_name and location_name in location_map:
                location = location_map[location_name]
                area_id = location.get('areaId')
                
                if area_id and area_id in area_map:
                    day['locationArea'] = area_map[area_id]['name']
        
        # Add location areas to calendar data
        calendar_data['locationAreas'] = areas
        
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error updating calendar with location areas: {str(e)}")
        return calendar_data

def update_calendar_with_departments(calendar_data):
    """
    Update calendar data with department information for tag display
    """
    try:
        # Load departments
        data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        departments_file = os.path.join(data_dir, 'data', 'departments.json')
        
        if not os.path.exists(departments_file):
            return calendar_data
        
        with open(departments_file, 'r') as f:
            departments = json.load(f)
        
        # Create lookup map for department codes
        dept_map = {dept['code']: dept for dept in departments}
        
        # Add department info to calendar data
        calendar_data['departments'] = departments
        
        # Update department counts
        calculate_department_counts(calendar_data)
        
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error updating calendar with departments: {str(e)}")
        return calendar_data

def calculate_department_counts(calendar_data):
    """
    Calculate department counts based on the calendar days, only counting
    currently defined departments.
    """
    try:
        days = calendar_data.get('days', [])
        counts = {} # Start with an empty counts dictionary

        # Load departments to get the current list and code mappings
        data_dir = os.path.dirname(os.path.abspath(__file__)) # Corrected path join
        base_data_dir = os.path.join(data_dir, '..', 'data') # Go up one level then into data
        departments_file = os.path.join(base_data_dir, 'departments.json')

        dept_map = {}
        departments = []
        if os.path.exists(departments_file):
            try:
                with open(departments_file, 'r') as f:
                    departments = json.load(f)

                # Create a mapping from department code to key for counting
                # AND initialize counts to 0 for all currently defined departments
                for dept in departments:
                    if 'code' in dept and ('id' in dept or 'name' in dept):
                        code = dept['code']
                        # Use id if available, otherwise use name converted to snake_case
                        id_key = dept.get('id', '').lower()
                        name_key = dept.get('name', '').lower().replace(' ', '_')
                        key = id_key if id_key else name_key # Prioritize ID as key if available

                        if code and key:
                            dept_map[code] = key
                            counts[key] = 0 # Initialize count for this known department
                            logger.debug(f"Mapped department code {code} to key {key} and initialized count.")

            except Exception as e:
                logger.error(f"Error loading or processing departments.json: {str(e)}")

        # Default mapping for common department codes (if not defined in departments.json)
        default_map = {
            "SFX": "sfx", "STN": "stunts", "CR": "crane", "ST": "steadicam",
            "PR": "prosthetics", "LL": "lowLoader", "VFX": "vfx", "ANI": "animals",
            "UW": "underwater", "INCY": "intimacy"
            # Removed "TEST" - custom departments should come from departments.json
        }

        # Combine mappings - dept_map (from JSON) takes precedence
        combined_map = {**default_map, **dept_map}

        # Pre-initialize counts for default map items if they weren't in departments.json
        for code, key in default_map.items():
            if key not in counts:
                counts[key] = 0
                logger.debug(f"Initialized count for default code {code} with key {key}.")


        # --- Standard Metric Counting (Main Unit, Second Unit, Sixth Day, Split Day) ---
        # Count days for standard metrics (these keys should ideally be predefined or handled separately)
        # Initialize standard counts that are always expected
        counts["main"] = 0
        counts["secondUnit"] = 0
        counts["sixthDay"] = 0
        counts["splitDay"] = 0

        counts["main"] = sum(1 for d in days if d.get("isShootDay"))
        counts["secondUnit"] = sum(1 for d in days if d.get("secondUnit")) # Assuming 'secondUnit' is a boolean or truthy value indicating second unit presence
        counts["sixthDay"] = sum(
            1 for d in days
            if d.get("isShootDay") and
            datetime.strptime(d["date"], "%Y-%m-%d").weekday() == 5  # Saturday
        )
        counts["splitDay"] = sum(
            1 for d in days
            if d.get("isShootDay") and
            d.get("isSplitDay", False) # Check for an explicit 'isSplitDay' flag
        )
        # --- End Standard Metric Counting ---


        # --- Department Tag Counting ---
        # Count specific department days based on tags
        for day in days:
            for dept_code in day.get("departments", []):
                dept_code = dept_code.strip().upper() # Standardize to upper case for matching keys

                if not dept_code:
                    continue

                # ONLY count if the department code is in our map of known departments
                if dept_code in combined_map:
                    key = combined_map[dept_code]
                    # Ensure the key actually exists in counts before incrementing (should always if initialized correctly)
                    if key in counts:
                         counts[key] = counts.get(key, 0) + 1
                         logger.debug(f"Counted known department {dept_code} using key {key}, new count: {counts[key]}")
                    else:
                         # This case should ideally not happen if initialization is correct
                         logger.warning(f"Key '{key}' for code '{dept_code}' was not pre-initialized in counts. Initializing now.")
                         counts[key] = 1
                else:
                    # Log ignored tags for debugging if needed
                    logger.debug(f"Ignoring unknown/deleted department tag: {dept_code} found on date {day.get('date')}")
        # --- End Department Tag Counting ---


        # Store the final counts dict in calendar data
        calendar_data["departmentCounts"] = counts
        logger.info(f"Department counts updated: {counts}")

        # Make sure the current list of departments is included in calendar data for the frontend
        if 'departments' not in calendar_data or calendar_data['departments'] != departments:
             calendar_data['departments'] = departments
             logger.info(f"Updated/Added {len(departments)} departments list to calendar data")

        return calendar_data

    except Exception as e:
        logger.error(f"Error calculating department counts: {str(e)}")
        # Ensure departmentCounts exists even on error, maybe with just initialized values?
        if "departmentCounts" not in calendar_data:
             calendar_data["departmentCounts"] = counts # Return potentially partial counts
        return calendar_data # Always return calendar_data

# This function will calculate how many times each location appears in the calendar
def calculate_location_counts(calendar_data):
    """
    Calculate how many times each location and location area appears in the calendar
    
    Args:
        calendar_data (dict): Calendar data with days array
        
    Returns:
        dict: Updated calendar data with locationCounts and areaCount
    """
    try:
        days = calendar_data.get('days', [])
        location_counts = {}
        area_counts = {}
        
        # Load locations data to get area mappings
        data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        locations_file = os.path.join(data_dir, 'data', 'locations.json')
        
        # Create mapping of location name to area ID
        location_to_area = {}
        if os.path.exists(locations_file):
            try:
                with open(locations_file, 'r') as f:
                    locations = json.load(f)
                    for loc in locations:
                        if 'name' in loc and 'areaId' in loc:
                            location_to_area[loc['name']] = loc['areaId']
            except Exception as e:
                logger.error(f"Error loading locations for area mapping: {str(e)}")
        
        # Count locations and areas
        for day in days:
            location = day.get('location', '')
            if location and location not in ['', 'N/A', None]:
                # Count the location
                location_counts[location] = location_counts.get(location, 0) + 1
                
                # Count the area if we have a mapping
                if location in location_to_area:
                    area_id = location_to_area[location]
                    if area_id:
                        area_counts[area_id] = area_counts.get(area_id, 0) + 1
        
        # Add counts to calendar data
        calendar_data['locationCounts'] = location_counts
        calendar_data['areaCounts'] = area_counts
        
        return calendar_data
    except Exception as e:
        logger.error(f"Error calculating location counts: {str(e)}")
        return calendar_data