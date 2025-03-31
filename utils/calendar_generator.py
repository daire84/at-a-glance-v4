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
        
        # Generate all dates in range
        current_date = prep_start
        calendar_days = []
        shoot_day = 0
        
        while current_date <= wrap_date:
            # Determine if it's a shoot day (shoot period and not weekend)
            is_shoot_period = current_date >= shoot_start
            is_weekend = current_date.weekday() >= 5  # 5=Saturday, 6=Sunday
            
            if is_shoot_period and not is_weekend:
                shoot_day += 1
            
            # Create day entry
            day = {
                "date": current_date.strftime("%Y-%m-%d"),
                "dayOfWeek": current_date.strftime("%A"),
                "monthName": current_date.strftime("%B"),
                "day": current_date.day,
                "month": current_date.month,
                "year": current_date.year,
                "isPrep": current_date < shoot_start,
                "isShootDay": is_shoot_period and not is_weekend,
                "isWeekend": is_weekend,
                "shootDay": shoot_day if is_shoot_period and not is_weekend else None,
                "mainUnit": "",
                "extras": 0,
                "featuredExtras": 0,
                "location": "",
                "locationArea": "",
                "sequence": "",
                "departments": [],
                "notes": "",
                "secondUnit": "",
                "secondUnitLocation": ""
            }
            
            calendar_days.append(day)
            current_date += timedelta(days=1)
        
        # Create calendar data
        calendar_data = {
            "projectId": project.get('id', ''),
            "days": calendar_days,
            "departmentCounts": {
                "main": sum(1 for d in calendar_days if d["isShootDay"]),
                "secondUnit": 0,
                "splitDay": 0,
                "sixthDay": 0,
                "steadicam": 0,
                "sfx": 0,
                "stunts": 0,
                "crane": 0,
                "prosthetics": 0,
                "lowLoader": 0
            },
            "locationAreas": [],
            "lastUpdated": datetime.utcnow().isoformat() + 'Z'
        }
        
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error generating calendar: {str(e)}")
        return {"days": []}

def calculate_department_counts(calendar_data):
    """
    Calculate department counts based on the calendar days
    """
    try:
        days = calendar_data.get('days', [])
        counts = {
            "main": sum(1 for d in days if d.get("isShootDay")),
            "secondUnit": sum(1 for d in days if d.get("secondUnit")),
            "splitDay": 0,  # Need criteria for split day
            "sixthDay": sum(1 for d in days if d.get("isShootDay") and parser.parse(d["date"]).weekday() == 5),
            "steadicam": sum(1 for d in days if "ST" in d.get("departments", [])),
            "sfx": sum(1 for d in days if "SFX" in d.get("departments", [])),
            "stunts": sum(1 for d in days if "STN" in d.get("departments", [])),
            "crane": sum(1 for d in days if "CR" in d.get("departments", [])),
            "prosthetics": sum(1 for d in days if "PR" in d.get("departments", [])),
            "lowLoader": sum(1 for d in days if "LL" in d.get("departments", []))
        }
        
        calendar_data["departmentCounts"] = counts
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error calculating department counts: {str(e)}")
        return calendar_data
