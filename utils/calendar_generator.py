import os
import json
import logging
from datetime import datetime, timedelta
from dateutil import parser
from dateutil.relativedelta import relativedelta

logger = logging.getLogger(__name__)

def generate_calendar_days(project):
    """
    Generate calendar days for a project based on dates
    
    Args:
        project (dict): Project data including prepStartDate and shootStartDate
        
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
                not is_hiatus
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
            
            # Create day entry
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
            
            # Add holiday or hiatus info to notes if applicable
            if is_holiday and holiday_data:
                day["notes"] = f"BANK HOLIDAY: {holiday_data.get('name', '')}"
                
            if is_hiatus and hiatus_data:
                day["notes"] = f"HIATUS: {hiatus_data.get('name', '')}"
                
            if is_working_weekend and working_weekend_data:
                if working_weekend_data.get('description'):
                    day["notes"] = f"WORKING WEEKEND: {working_weekend_data.get('description', '')}"
                else:
                    day["notes"] = "WORKING WEEKEND"
            
            calendar_days.append(day)
            current_date += timedelta(days=1)
        
        # Load location areas for reference
        location_areas = load_location_areas()
        
        # Create calendar data
        calendar_data = {
            "projectId": project.get('id', ''),
            "days": calendar_days,
            "departmentCounts": initialize_department_counts(),
            "locationAreas": location_areas,
            "lastUpdated": datetime.utcnow().isoformat() + 'Z'
        }
        
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
    Calculate department counts based on the calendar days
    """
    try:
        days = calendar_data.get('days', [])
        # Initialize with standard counts
        counts = initialize_department_counts()
        
        # Load departments to get code mappings
        data_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')
        departments_file = os.path.join(data_dir, 'departments.json')
        
        dept_map = {}
        departments = []
        if os.path.exists(departments_file):
            try:
                with open(departments_file, 'r') as f:
                    departments = json.load(f)
                
                # Create a mapping from department code to key for counting
                for dept in departments:
                    if 'code' in dept and ('id' in dept or 'name' in dept):
                        code = dept['code']
                        # Use id if available, otherwise use name converted to snake_case
                        id_key = dept.get('id', '').lower()
                        name_key = dept.get('name', '').lower().replace(' ', '_')
                        key = id_key if id_key else name_key
                        
                        if code and key:
                            dept_map[code] = key
                            # Pre-initialize count for this department
                            counts[key] = 0
                            logger.debug(f"Mapped department code {code} to key {key}")
            except Exception as e:
                logger.error(f"Error loading departments: {str(e)}")
        
        # Default mapping for common department codes to count keys
        default_map = {
            "SFX": "sfx",
            "STN": "stunts",
            "CR": "crane",
            "ST": "steadicam",
            "PR": "prosthetics",
            "LL": "lowLoader",
            "VFX": "vfx",
            "ANI": "animals",
            "UW": "underwater",
            "INCY": "intimacy",
            "TEST": "test"
        }
        
        # Combine mappings with dept_map taking precedence
        combined_map = {**default_map, **dept_map}
        
        # Count days for standard metrics
        counts["main"] = sum(1 for d in days if d.get("isShootDay"))
        counts["secondUnit"] = sum(1 for d in days if d.get("secondUnit"))
        
        # Count sixth day (working Saturdays)
        counts["sixthDay"] = sum(
            1 for d in days 
            if d.get("isShootDay") and 
            datetime.strptime(d["date"], "%Y-%m-%d").weekday() == 5  # Saturday
        )
        
        # Count split days (if applicable)
        counts["splitDay"] = sum(
            1 for d in days 
            if d.get("isShootDay") and 
            d.get("isSplitDay", False)
        )
        
        # Count department days
        for day in days:
            for dept_code in day.get("departments", []):
                dept_code = dept_code.strip()  # Clean the code
                
                if not dept_code:
                    continue
                    
                logger.debug(f"Processing department tag: {dept_code}")
                
                # Try to find the key in our combined map
                if dept_code in combined_map:
                    key = combined_map[dept_code]
                    counts[key] = counts.get(key, 0) + 1
                    logger.debug(f"Counted {dept_code} using key {key}, new count: {counts[key]}")
                else:
                    # If we don't have a mapping, use the code directly or a cleaned version
                    key = dept_code.lower().replace(' ', '_')
                    counts[key] = counts.get(key, 0) + 1
                    logger.debug(f"Using direct key {key} for {dept_code}, count: {counts[key]}")
        
        # Store counts in calendar data
        calendar_data["departmentCounts"] = counts
        logger.info(f"Department counts updated: {counts}")
        
        # Make sure departments are included in calendar data
        if departments and 'departments' not in calendar_data:
            calendar_data['departments'] = departments
            logger.info(f"Added {len(departments)} departments to calendar data")
        
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error calculating department counts: {str(e)}")
        return calendar_data
        return calendar_data