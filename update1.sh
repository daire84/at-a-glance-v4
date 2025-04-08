#!/bin/bash

echo "Department Tag and Counting Fix Script"
echo "====================================="
echo

# Make sure we're in the right directory
cd /mnt/user/appdata/film-scheduler-v4

# Create a backup before making changes
echo "Creating backup..."
BACKUP_DIR="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r data/* "$BACKUP_DIR/"
cp -r templates/* "$BACKUP_DIR/templates/"
cp -r static/* "$BACKUP_DIR/static/"
cp -r utils/* "$BACKUP_DIR/utils/"
echo "Backup created at $BACKUP_DIR"

# Update the calculate_department_counts function
echo "Updating the calculate_department_counts function..."

# First check if the file exists in utils/calendar_generator.py
if [ -f "utils/calendar_generator.py" ]; then
    # Create a temporary file with the new function
    cat > /tmp/calculate_department_counts.py << 'EOF'
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
EOF

    # Find the beginning and end of the existing function
    START_LINE=$(grep -n "def calculate_department_counts" utils/calendar_generator.py | head -1 | cut -d':' -f1)
    
    if [ -n "$START_LINE" ]; then
        # Find the next function definition to determine end of current function
        NEXT_FUNC=$(tail -n +$((START_LINE+1)) utils/calendar_generator.py | grep -n "^def " | head -1)
        
        if [ -n "$NEXT_FUNC" ]; then
            END_LINE=$((START_LINE + $(echo $NEXT_FUNC | cut -d':' -f1) - 1))
        else
            # If no next function, assume to end of file
            END_LINE=$(wc -l < utils/calendar_generator.py)
        fi
        
        # Replace the function
        head -n $((START_LINE-1)) utils/calendar_generator.py > /tmp/calendar_generator_new.py
        cat /tmp/calculate_department_counts.py >> /tmp/calendar_generator_new.py
        tail -n +$((END_LINE+1)) utils/calendar_generator.py >> /tmp/calendar_generator_new.py
        
        # Replace the original file
        mv /tmp/calendar_generator_new.py utils/calendar_generator.py
        
        echo "Function updated in utils/calendar_generator.py"
    else
        echo "Warning: Could not find calculate_department_counts function in utils/calendar_generator.py"
        # Append to the end of the file
        cat /tmp/calculate_department_counts.py >> utils/calendar_generator.py
        echo "Added function to end of utils/calendar_generator.py"
    fi
else
    echo "Warning: utils/calendar_generator.py not found"
fi

# Update the applyDepartmentTagColors function in calendar.js
echo "Updating applyDepartmentTagColors in calendar.js..."
cat > static/js/calendar.js << 'EOF'
/**
 * Enhanced Calendar utility functions
 */

document.addEventListener('DOMContentLoaded', function() {
  // Get all location areas from the calendar container
  const locationAreas = getLocationAreas();
  
  // Apply location area colors to rows
  applyLocationAreaColors(locationAreas);
  
  // Apply department tag colors
  applyDepartmentTagColors();
  
  // Set up event handlers for calendar rows if in admin mode
  setupAdminEventHandlers();
});

/**
 * Get location areas from calendar data
 */
function getLocationAreas() {
  const areaElements = document.querySelectorAll('.area-tag');
  const areas = {};
  
  areaElements.forEach(el => {
    const areaName = el.textContent.trim();
    const backgroundColor = el.style.backgroundColor;
    
    if (areaName && backgroundColor) {
      areas[areaName] = backgroundColor;
    }
  });
  
  return areas;
}

/**
 * Apply location area colors to rows
 */
function applyLocationAreaColors(areas) {
  const rows = document.querySelectorAll('.calendar-row');
  
  rows.forEach(row => {
    const locationCell = row.querySelector('.location-cell');
    const areaAttribute = row.getAttribute('data-area');
    
    // If row has area attribute, use that
    if (areaAttribute && areas[areaAttribute]) {
      row.style.setProperty('--row-area-color', areas[areaAttribute]);
      row.classList.add('has-area-color');
      return;
    }
    
    // Otherwise try to find location in the row
    if (locationCell) {
      const locationText = locationCell.textContent.trim();
      
      // Find area that matches this location
      for (const areaName in areas) {
        if (locationText.includes(areaName)) {
          row.style.setProperty('--row-area-color', areas[areaName]);
          row.classList.add('has-area-color');
          break;
        }
      }
    }
  });
}

/**
 * Apply department tag colors - UPDATED
 */
function applyDepartmentTagColors() {
  // Fetch department colors from the hidden data element if available
  let departmentColors = {};
  const departmentDataElement = document.getElementById('department-data');
  
  if (departmentDataElement) {
    try {
      departmentColors = JSON.parse(departmentDataElement.textContent.trim());
      console.log("Parsed department colors:", departmentColors);
    } catch (e) {
      console.error('Error parsing department data:', e);
      console.log("Raw department data:", departmentDataElement.textContent);
      
      // Fallback to default colors
      departmentColors = {
        "SFX": "#ffd8e6",
        "STN": "#ffecd8",
        "CR": "#d8fff2",
        "ST": "#f2d8ff",
        "PR": "#d8fdff",
        "LL": "#e6ffd8",
        "VFX": "#d8e5ff",
        "ANI": "#ffedd8",
        "UW": "#d8f8ff",
        "INCY": "#f542dd",
        "TEST": "#067bf9"
      };
    }
  } else {
    console.warn("Department data element not found");
    // Fallback to default colors
    departmentColors = {
      "SFX": "#ffd8e6",
      "STN": "#ffecd8",
      "CR": "#d8fff2",
      "ST": "#f2d8ff",
      "PR": "#d8fdff",
      "LL": "#e6ffd8",
      "VFX": "#d8e5ff",
      "ANI": "#ffedd8",
      "UW": "#d8f8ff",
      "INCY": "#f542dd",
      "TEST": "#067bf9"
    };
  }
  
  const departmentTags = document.querySelectorAll('.department-tag');
  
  departmentTags.forEach(tag => {
    const deptCode = tag.textContent.trim();
    
    if (departmentColors[deptCode]) {
      tag.style.backgroundColor = departmentColors[deptCode];
      
      // Set text color based on background brightness
      const rgb = hexToRgb(departmentColors[deptCode]);
      if (rgb) {
        const brightness = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
        tag.style.color = brightness > 128 ? '#000000' : '#ffffff';
      }
    } else {
      console.warn(`No color found for department code: ${deptCode}`);
    }
  });
}

/**
 * Set up event handlers for admin mode calendar
 */
function setupAdminEventHandlers() {
  // Check if we're in admin mode
  const isAdminMode = document.querySelector('.admin-calendar') !== null;
  
  if (isAdminMode) {
    // Add click handlers for calendar rows
    const calendarRows = document.querySelectorAll('.calendar-row');
    calendarRows.forEach(row => {
      row.addEventListener('click', function() {
        const date = this.dataset.date;
        const projectId = document.getElementById('project-id').value;
        if (date && projectId) {
          window.location.href = `/admin/day/${projectId}/${date}`;
        }
      });
    });
    
    // Setup drag and drop functionality
    setupDragAndDrop();
  }
}

/**
 * Setup drag and drop functionality for calendar rows
 */
function setupDragAndDrop() {
  const calendarRows = document.querySelectorAll('.calendar-row[data-date]');
  const tbody = document.querySelector('.calendar-table tbody');
  
  if (!calendarRows.length || !tbody) {
    return;
  }
  
  // Make shoot days draggable
  calendarRows.forEach(row => {
    // Only allow dragging shoot days
    if (row.classList.contains('shoot')) {
      row.setAttribute('draggable', 'true');
      
      row.addEventListener('dragstart', function(e) {
        e.dataTransfer.setData('text/plain', row.getAttribute('data-date'));
        row.classList.add('dragging');
      });
      
      row.addEventListener('dragend', function() {
        row.classList.remove('dragging');
      });
    }
  });
  
  // Make all rows drop targets
  calendarRows.forEach(row => {
    row.addEventListener('dragover', function(e) {
      e.preventDefault();
      const draggingRow = document.querySelector('.dragging');
      if (draggingRow !== row) {
        row.classList.add('drop-target');
      }
    });
    
    row.addEventListener('dragleave', function() {
      row.classList.remove('drop-target');
    });
    
    row.addEventListener('drop', function(e) {
      e.preventDefault();
      row.classList.remove('drop-target');
      
      const fromDate = e.dataTransfer.getData('text/plain');
      const toDate = row.getAttribute('data-date');
      const projectId = document.getElementById('project-id').value;
      
      if (fromDate && toDate && projectId && fromDate !== toDate) {
        moveShootDay(projectId, fromDate, toDate);
      }
    });
  });
}

/**
 * Move a shoot day from sourceDate to targetDate
 */
function moveShootDay(projectId, fromDate, toDate) {
  const url = `/api/projects/${projectId}/calendar/move-day`;
  
  // Create a spinner or loading indicator
  const loadingOverlay = document.createElement('div');
  loadingOverlay.className = 'loading-overlay';
  loadingOverlay.innerHTML = '<div class="spinner"></div>';
  document.body.appendChild(loadingOverlay);
  
  fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      fromDate: fromDate,
      toDate: toDate
    })
  })
  .then(response => {
    if (!response.ok) {
      throw new Error('Failed to move shoot day');
    }
    return response.json();
  })
  .then(data => {
    // Reload page to show updated calendar
    window.location.reload();
  })
  .catch(error => {
    console.error('Error moving shoot day:', error);
    alert('Error: ' + error.message);
    document.body.removeChild(loadingOverlay);
  });
}

/**
 * Convert hex color to RGB
 */
function hexToRgb(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : null;
}
EOF

echo "Updated calendar.js"

# Update department data script in admin/calendar.html and viewer.html
echo "Adding department data script block to templates..."

# Handle admin/calendar.html
if [ -f "templates/admin/calendar.html" ]; then
    # Look for existing script
    if grep -q "department-data" templates/admin/calendar.html; then
        echo "Department data script already exists in admin/calendar.html"
    else
        # Find the best place to insert the script block (before calendar table)
        CALENDAR_LINE=$(grep -n "calendar-table" templates/admin/calendar.html | head -1 | cut -d':' -f1)
        
        if [ -n "$CALENDAR_LINE" ]; then
            SCRIPT_BLOCK="<!-- Hidden element for department data -->\n    <script id=\"department-data\" type=\"application/json\">\n        {% if calendar.departments %}\n            {\n                {% for dept in calendar.departments %}\n                \"{{ dept.code }}\": \"{{ dept.color }}\"{% if not loop.last %},{% endif %}\n                {% endfor %}\n            }\n        {% else %}\n            {}\n        {% endif %}\n    </script>"
            
            # Insert before the calendar table
            sed -i "${CALENDAR_LINE}i\\${SCRIPT_BLOCK}" templates/admin/calendar.html
            echo "Added department data script to admin/calendar.html"
        else
            echo "Warning: Could not find optimal position in admin/calendar.html"
        fi
    fi
else
    echo "Warning: templates/admin/calendar.html not found"
fi

# Handle viewer.html
if [ -f "templates/viewer.html" ]; then
    # Look for existing script
    if grep -q "department-data" templates/viewer.html; then
        echo "Department data script already exists in viewer.html"
    else
        # Find the best place to insert the script block
        CALENDAR_LINE=$(grep -n "calendar-table" templates/viewer.html | head -1 | cut -d':' -f1)
        
        if [ -n "$CALENDAR_LINE" ]; then
            SCRIPT_BLOCK="<!-- Hidden element for department data -->\n    <script id=\"department-data\" type=\"application/json\">\n        {% if calendar.departments %}\n            {\n                {% for dept in calendar.departments %}\n                \"{{ dept.code }}\": \"{{ dept.color }}\"{% if not loop.last %},{% endif %}\n                {% endfor %}\n            }\n        {% else %}\n            {}\n        {% endif %}\n    </script>"
            
            # Insert before the calendar table
            sed -i "${CALENDAR_LINE}i\\${SCRIPT_BLOCK}" templates/viewer.html
            echo "Added department data script to viewer.html"
        else
            echo "Warning: Could not find optimal position in viewer.html"
        fi
    fi
else
    echo "Warning: templates/viewer.html not found"
fi

# Update admin_calendar and viewer routes in app.py
echo "Updating routes in app.py to include department data..."

# Create temporary file with updated routes
cat > /tmp/updated_routes.py << 'EOF'
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
            with open(departments_file, 'r') as
