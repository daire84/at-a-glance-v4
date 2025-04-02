/**
 * Calendar utility functions
 */

document.addEventListener('DOMContentLoaded', function() {
  // Get all location areas from the calendar container
  const locationAreas = getLocationAreas();
  
  // Apply location area colors to rows
  applyLocationAreaColors(locationAreas);
  
  // Apply department tag colors
  applyDepartmentTagColors();
});

/**
 * Get location areas from calendar data
 */
function getLocationAreas() {
  const areaElements = document.querySelectorAll('.area-tag');
  const areas = {};
  
  areaElements.forEach(el => {
    const areaName = el.textContent;
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
      row.style.backgroundColor = areas[areaAttribute];
      return;
    }
    
    // Otherwise try to find location in the row
    if (locationCell) {
      const locationText = locationCell.textContent.trim();
      
      // Find area that matches this location
      for (const areaName in areas) {
        if (locationText.includes(areaName)) {
          row.style.backgroundColor = areas[areaName];
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
  // We need to implement this based on your actual department data structure
  // This is just a placeholder for now
  const departmentColors = {
    "SFX": "#ffd8e6",
    "STN": "#ffecd8",
    "CR": "#d8fff2",
    "ST": "#f2d8ff",
    "PR": "#d8fdff",
    "LL": "#e6ffd8",
    "VFX": "#d8e5ff",
    "ANI": "#ffedd8",
    "UW": "#d8f8ff"
  };
  
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
