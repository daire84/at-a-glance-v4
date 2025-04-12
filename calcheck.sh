#!/bin/bash
# Check and fix the calendar.js file to remove any conflicting drag and drop functionality

cd /mnt/user/appdata/film-scheduler-v4

# First make a backup
if [ -f static/js/calendar.js ]; then
  cp static/js/calendar.js static/js/calendar.js.bak.$(date +%Y%m%d)
  echo "Created backup of current calendar.js"
fi

# Now update the calendar.js file to ensure it doesn't interfere with drag and drop
cat > /mnt/user/appdata/film-scheduler-v4/static/js/calendar.js << 'EOF'
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
  
  // Set up event handlers for calendar rows if in admin mode - commented out to avoid conflict
  // setupAdminEventHandlers();
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
 * Apply department tag colors
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

/**
 * Better department tag color handling
 * Ensures all department tags get their proper colors
 */
document.addEventListener('DOMContentLoaded', function() {
    // Better department tag color handling
    const deptTags = document.querySelectorAll('.department-tag');
    const deptData = document.getElementById('department-data');
    
    if (deptData) {
        try {
            const deptColors = JSON.parse(deptData.textContent.trim());
            
            deptTags.forEach(tag => {
                const deptCode = tag.getAttribute('data-dept-code') || tag.textContent.trim();
                
                if (deptColors[deptCode]) {
                    tag.style.backgroundColor = deptColors[deptCode];
                    
                    // Set text color based on background brightness
                    const rgb = hexToRgb(deptColors[deptCode]);
                    if (rgb) {
                        const brightness = (rgb.r * 299 + rgb.g * 587 + b * 114) / 1000;
                        tag.style.color = brightness > 128 ? '#000000' : '#ffffff';
                    }
                }
            });
        } catch (e) {
            console.error('Error parsing department colors:', e);
        }
    }
});
EOF

echo "Updated calendar.js to avoid conflict with drag and drop functionality"
