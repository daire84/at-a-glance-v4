import logging
from datetime import datetime, timedelta
from dateutil import parser
from dateutil.relativedelta import relativedelta

logger = logging.getLogger(__name__)

def parse_date(date_string):
    """
    Parse a date string into a datetime object
    """
    try:
        return parser.parse(date_string)
    except Exception as e:
        logger.error(f"Error parsing date {date_string}: {str(e)}")
        return None

def format_date(date, format_string="%Y-%m-%d"):
    """
    Format a date object as a string
    """
    try:
        if isinstance(date, str):
            date = parse_date(date)
        
        return date.strftime(format_string)
    except Exception as e:
        logger.error(f"Error formatting date: {str(e)}")
        return ""

def format_display_date(date_string):
    """
    Format a date for display (e.g., "Mon 24/03")
    """
    try:
        date = parse_date(date_string)
        return date.strftime("%a %d/%m")
    except Exception as e:
        logger.error(f"Error formatting display date: {str(e)}")
        return date_string

def date_range(start_date, end_date):
    """
    Generate a list of dates between start_date and end_date
    """
    try:
        if isinstance(start_date, str):
            start_date = parse_date(start_date)
        
        if isinstance(end_date, str):
            end_date = parse_date(end_date)
        
        delta = (end_date - start_date).days
        return [start_date + timedelta(days=i) for i in range(delta + 1)]
    except Exception as e:
        logger.error(f"Error generating date range: {str(e)}")
        return []

def is_weekend(date):
    """
    Check if a date is a weekend (Saturday or Sunday)
    """
    try:
        if isinstance(date, str):
            date = parse_date(date)
        
        return date.weekday() >= 5  # 5=Saturday, 6=Sunday
    except Exception as e:
        logger.error(f"Error checking if date is weekend: {str(e)}")
        return False

def add_working_days(date, days):
    """
    Add a number of working days to a date (skipping weekends)
    """
    try:
        if isinstance(date, str):
            date = parse_date(date)
        
        result_date = date
        while days > 0:
            result_date += timedelta(days=1)
            if result_date.weekday() < 5:  # 0-4 are weekdays
                days -= 1
        
        return result_date
    except Exception as e:
        logger.error(f"Error adding working days: {str(e)}")
        return date

def get_month_name(date):
    """
    Get the month name from a date
    """
    try:
        if isinstance(date, str):
            date = parse_date(date)
        
        return date.strftime("%B")
    except Exception as e:
        logger.error(f"Error getting month name: {str(e)}")
        return ""

def get_day_of_week(date):
    """
    Get the day of week name from a date
    """
    try:
        if isinstance(date, str):
            date = parse_date(date)
        
        return date.strftime("%A")
    except Exception as e:
        logger.error(f"Error getting day of week: {str(e)}")
        return ""
