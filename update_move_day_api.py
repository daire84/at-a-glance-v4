#!/usr/bin/env python3
import sys
import re

# Path to app.py
APP_PY_PATH = 'app.py'

try:
    # Read the current app.py
    with open(APP_PY_PATH, 'r') as f:
        app_content = f.read()
    
    # Look for the move day route
    route_pattern = r'@app\.route\(\'/api/projects/<project_id>/calendar/move-day\', methods=\[\'POST\'\]\)\s*def api_move_calendar_day\(project_id\):[^@]*'
    route_match = re.search(route_pattern, app_content, re.DOTALL)
    
    if not route_match:
        print("Could not find the move-day API route in app.py.")
        sys.exit(1)
    
    # The existing route
    existing_route = route_match.group(0)
    print(f"Found the move-day API route ({len(existing_route)} characters)")
    
    # Check if the route already has mode parameter
    if "mode = move_data.get('mode'" in existing_route:
        print("The route already has the mode parameter. No changes needed.")
        sys.exit(0)
    
    # The updated route
    updated_route = '''@app.route('/api/projects/<project_id>/calendar/move-day', methods=['POST'])
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
        
        # Save the updated calendar
        calendar_data['days'] = days
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
        return jsonify({'error': f'Error moving calendar day: {str(e)}'}), 500'''
    
    # Replace the route in the file content
    updated_content = app_content.replace(existing_route, updated_route)
    
    # Write the updated content back to app.py
    with open(APP_PY_PATH, 'w') as f:
        f.write(updated_content)
    
    print("Successfully updated the move-day API route in app.py.")
    print("Remember to restart your container: docker-compose restart film-scheduler-v4")
    
except Exception as e:
    print(f"Error updating app.py: {str(e)}")
    sys.exit(1)
