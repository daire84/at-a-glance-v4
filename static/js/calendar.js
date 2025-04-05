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
 * Apply department tag colors
 */
function applyDepartmentTagColors() {
  // Fetch department colors from the hidden data element if available
  let departmentColors = {};
  const departmentDataElement = document.getElementById('department-data');
  
  if (departmentDataElement) {
    try {
      departmentColors = JSON.parse(departmentDataElement.textContent);
    } catch (e) {
      console.error('Error parsing department data:', e);
      
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
        "UW": "#d8f8ff"
      };
    }
  } else {
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
      "UW": "#d8f8ff"
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
      
      const sourceDate = e.dataTransfer.getData('text/plain');
      const targetDate = row.getAttribute('data-date');
      const projectId = document.getElementById('project-id').value;
      
      if (sourceDate && targetDate && projectId && sourceDate !== targetDate) {
        moveShootDay(projectId, sourceDate, targetDate);
      }
    });
  });
}

/**
 * Move a shoot day from sourceDate to targetDate
 */
function moveShootDay(projectId, sourceDate, targetDate) {
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
      sourceDate: sourceDate,
      targetDate: targetDate
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