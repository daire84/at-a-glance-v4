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
 * FIXED: Added proper mode parameter and error checking
 */
function moveShootDay(projectId, fromDate, toDate) {
  const url = `/api/projects/${projectId}/calendar/move-day`;
  
  // Check if dates are valid
  if (!fromDate || !toDate) {
    console.error("Invalid date parameters", { fromDate, toDate });
    alert("Error: Could not move day - invalid date parameters");
    return;
  }
  
  console.log(`Moving day from ${fromDate} to ${toDate}`);
  
  // Create a spinner or loading indicator
  const loadingOverlay = document.createElement('div');
  loadingOverlay.className = 'loading-overlay';
  loadingOverlay.innerHTML = '<div class="spinner"></div>';
  document.body.appendChild(loadingOverlay);
  
  // Add the mode parameter to make it work properly
  fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      fromDate: fromDate,
      toDate: toDate,
      mode: 'swap'  // Add the mode parameter
    })
  })
  .then(response => {
    if (!response.ok) {
      throw new Error('Failed to move shoot day');
    }
    return response.json();
  })
  .then(data => {
    console.log("Move day response:", data);
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
                        const brightness = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
                        tag.style.color = brightness > 128 ? '#000000' : '#ffffff';
                    }
                }
            });
        } catch (e) {
            console.error('Error parsing department colors:', e);
        }
    }
    initializeFilters();
});

// =======================================
// Calendar Filtering Functionality
// =======================================

// 1. First define all the functions
function toggleRowType(rowType, isVisible) {
  console.log(`Toggling row type ${rowType} to ${isVisible ? 'visible' : 'hidden'}`);
  const rows = document.querySelectorAll(`.calendar-row.${rowType}`);
  rows.forEach(row => {
      if (isVisible) {
          row.classList.remove('filtered-hidden');
      } else {
          row.classList.add('filtered-hidden');
      }
  });
  
  // Update counter stats
  updateFilterStats();
}

function toggleColumnVisibility(colName, isVisible) {
  console.log(`Toggling column ${colName} to ${isVisible ? 'visible' : 'hidden'}`);
  
  // Try direct style approach for more reliable column hiding
  const headers = document.querySelectorAll(`.${colName}-col`);
  const cells = document.querySelectorAll(`.${colName}-cell`);
  
  const displayValue = isVisible ? '' : 'none';
  
  headers.forEach(header => {
      header.style.display = displayValue;
  });
  
  cells.forEach(cell => {
      cell.style.display = displayValue;
  });
  
  // Also update the class for CSS approach
  const calendarContainer = document.querySelector('.calendar-container');
  if (calendarContainer) {
      if (isVisible) {
          calendarContainer.classList.remove(`hide-col-${colName}`);
      } else {
          calendarContainer.classList.add(`hide-col-${colName}`);
      }
  }
}

function loadFilterPreferences() {
  try {
      const preferences = JSON.parse(localStorage.getItem('calendarFilterPrefs') || '{}');
      
      // Day types
      const weekendToggle = document.getElementById('filter-weekends');
      const prepToggle = document.getElementById('filter-prep');
      const holidayToggle = document.getElementById('filter-holidays');
      const hiatusToggle = document.getElementById('filter-hiatus');
      const shootToggle = document.getElementById('filter-shoot');
      
      if (weekendToggle && preferences.hideWeekends !== undefined) {
          weekendToggle.checked = !preferences.hideWeekends;
      }
      if (prepToggle && preferences.hidePrep !== undefined) {
          prepToggle.checked = !preferences.hidePrep;
      }
      if (holidayToggle && preferences.hideHolidays !== undefined) {
          holidayToggle.checked = !preferences.hideHolidays;
      }
      if (hiatusToggle && preferences.hideHiatus !== undefined) {
          hiatusToggle.checked = !preferences.hideHiatus;
      }
      if (shootToggle && preferences.hideShoot !== undefined) {
          shootToggle.checked = !preferences.hideShoot;
      }
      
      // Column visibility
      const sequenceColToggle = document.getElementById('filter-col-sequence');
      const secondUnitColToggle = document.getElementById('filter-col-second-unit');
      
      if (sequenceColToggle && preferences.hideColSequence !== undefined) {
          sequenceColToggle.checked = !preferences.hideColSequence;
      }
      
      if (secondUnitColToggle && preferences.hideColSecondUnit !== undefined) {
          secondUnitColToggle.checked = !preferences.hideColSecondUnit;
      }
  } catch (error) {
      console.error("Error loading filter preferences:", error);
  }
}

function saveFilterPreferences() {
  const weekendToggle = document.getElementById('filter-weekends');
  const prepToggle = document.getElementById('filter-prep');
  const holidayToggle = document.getElementById('filter-holidays');
  const hiatusToggle = document.getElementById('filter-hiatus');
  const shootToggle = document.getElementById('filter-shoot');
  const sequenceColToggle = document.getElementById('filter-col-sequence');
  const secondUnitColToggle = document.getElementById('filter-col-second-unit');
  
  const preferences = {
      hideWeekends: weekendToggle ? !weekendToggle.checked : false,
      hidePrep: prepToggle ? !prepToggle.checked : false,
      hideHolidays: holidayToggle ? !holidayToggle.checked : false,
      hideHiatus: hiatusToggle ? !hiatusToggle.checked : false,
      hideShoot: shootToggle ? !shootToggle.checked : false,
      hideColSequence: sequenceColToggle ? !sequenceColToggle.checked : false,
      hideColSecondUnit: secondUnitColToggle ? !secondUnitColToggle.checked : false
  };
  
  localStorage.setItem('calendarFilterPrefs', JSON.stringify(preferences));
}

function applyAllFilters() {
  // Reset all rows first
  document.querySelectorAll('.calendar-row').forEach(row => {
      row.classList.remove('filtered-hidden');
  });
  
  const weekendToggle = document.getElementById('filter-weekends');
  const prepToggle = document.getElementById('filter-prep');
  const holidayToggle = document.getElementById('filter-holidays');
  const hiatusToggle = document.getElementById('filter-hiatus');
  const shootToggle = document.getElementById('filter-shoot');
  const sequenceColToggle = document.getElementById('filter-col-sequence');
  const secondUnitColToggle = document.getElementById('filter-col-second-unit');
  
  // Apply row filters
  if (weekendToggle && !weekendToggle.checked) {
      toggleRowType('weekend', false);
  }
  if (prepToggle && !prepToggle.checked) {
      toggleRowType('prep', false);
  }
  if (holidayToggle && !holidayToggle.checked) {
      toggleRowType('holiday', false);
  }
  if (hiatusToggle && !hiatusToggle.checked) {
      toggleRowType('hiatus', false);
  }
  if (shootToggle && !shootToggle.checked) {
      toggleRowType('shoot', false);
  }
  
  // Apply column filters
  if (sequenceColToggle) {
      toggleColumnVisibility('sequence', sequenceColToggle.checked);
  }
  if (secondUnitColToggle) {
      toggleColumnVisibility('second-unit', secondUnitColToggle.checked);
  }
  
  // Update stats
  updateFilterStats();
}

function updateFilterStats() {
  const totalRows = document.querySelectorAll('.calendar-row').length;
  const visibleRows = document.querySelectorAll('.calendar-row:not(.filtered-hidden)').length;
  const totalShootDays = document.querySelectorAll('.calendar-row.shoot').length;
  const visibleShootDays = document.querySelectorAll('.calendar-row.shoot:not(.filtered-hidden)').length;
  
  const statsTotal = document.getElementById('filter-stats-total');
  const statsVisible = document.getElementById('filter-stats-visible');
  const statsShootDays = document.getElementById('filter-stats-shoot-days');
  
  if (statsTotal) statsTotal.textContent = totalRows;
  if (statsVisible) statsVisible.textContent = visibleRows;
  if (statsShootDays) statsShootDays.textContent = `${visibleShootDays} / ${totalShootDays}`;
}

// 2. Then define the initialization function which will attach event listeners
function initializeFilters() {
  console.log("Initializing filters");
  
  // Get filter toggle elements
  const weekendToggle = document.getElementById('filter-weekends');
  const prepToggle = document.getElementById('filter-prep');
  const holidayToggle = document.getElementById('filter-holidays');
  const hiatusToggle = document.getElementById('filter-hiatus');
  const shootToggle = document.getElementById('filter-shoot');
  const resetButton = document.getElementById('reset-filters');
  
  // Column visibility toggles
  const sequenceColToggle = document.getElementById('filter-col-sequence');
  const secondUnitColToggle = document.getElementById('filter-col-second-unit');
  
  // If filter elements don't exist, we're not on the calendar page
  if (!weekendToggle) {
      console.log("Filter elements not found - not on calendar page");
      return;
  }
  
  console.log("Filter elements found, setting up event listeners");
  
  // Load saved preferences from localStorage
  loadFilterPreferences();
  
  // Add event listeners to toggle controls
  if (weekendToggle) {
      weekendToggle.addEventListener('change', function() {
          toggleRowType('weekend', this.checked);
          saveFilterPreferences();
      });
  }
  
  if (prepToggle) {
      prepToggle.addEventListener('change', function() {
          toggleRowType('prep', this.checked);
          saveFilterPreferences();
      });
  }
  
  if (holidayToggle) {
      holidayToggle.addEventListener('change', function() {
          toggleRowType('holiday', this.checked);
          saveFilterPreferences();
      });
  }
  
  if (hiatusToggle) {
      hiatusToggle.addEventListener('change', function() {
          toggleRowType('hiatus', this.checked);
          saveFilterPreferences();
      });
  }
  
  if (shootToggle) {
      shootToggle.addEventListener('change', function() {
          toggleRowType('shoot', this.checked);
          saveFilterPreferences();
      });
  }
  
  if (sequenceColToggle) {
      sequenceColToggle.addEventListener('change', function() {
          toggleColumnVisibility('sequence', this.checked);
          saveFilterPreferences();
      });
  }
  
  if (secondUnitColToggle) {
      secondUnitColToggle.addEventListener('change', function() {
          toggleColumnVisibility('second-unit', this.checked);
          saveFilterPreferences();
      });
  }
  
  // Reset button
  if (resetButton) {
      resetButton.addEventListener('click', function() {
          if (weekendToggle) weekendToggle.checked = true;
          if (prepToggle) prepToggle.checked = true;
          if (holidayToggle) holidayToggle.checked = true;
          if (hiatusToggle) hiatusToggle.checked = true;
          if (shootToggle) shootToggle.checked = true;
          if (sequenceColToggle) sequenceColToggle.checked = true;
          if (secondUnitColToggle) secondUnitColToggle.checked = true;
          
          applyAllFilters();
          saveFilterPreferences();
      });
  }
  
  // Apply initial filter state
  applyAllFilters();
  
  console.log("Filter initialization complete");
}

/**
 * Enhance location counters with proper color coding from location data
 */
function enhanceLocationCounters() {
  console.log("Enhancing location counters with proper colors");
  
  // Get all counter items in the location counter section
  const locationCounters = document.querySelectorAll('.location-counters .counter-item');
  
  locationCounters.forEach(counter => {
    const locationName = counter.querySelector('.counter-label').textContent.trim();
    
    // Check if counter already has a background color set
    const currentColor = counter.style.backgroundColor;
    if (!currentColor || currentColor === 'transparent' || currentColor === '') {
      // Try to find the color from data attributes
      const areaColor = counter.getAttribute('data-area-color');
      if (areaColor) {
        counter.style.backgroundColor = areaColor;
        
        // Ensure text contrast is appropriate for the background color
        ensureTextContrast(counter);
      }
    }
  });
}

/**
 * Ensure text has proper contrast with background
 * @param {HTMLElement} element - The element to check contrast for
 */
function ensureTextContrast(element) {
  // Get computed background color
  const bgColor = window.getComputedStyle(element).backgroundColor;
  
  // Parse RGB values
  const rgbMatch = bgColor.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*[\d.]+)?\)/);
  if (rgbMatch) {
    const r = parseInt(rgbMatch[1]);
    const g = parseInt(rgbMatch[2]);
    const b = parseInt(rgbMatch[3]);
    
    // Calculate brightness (simple formula)
    const brightness = (r * 299 + g * 587 + b * 114) / 1000;
    
    // Set text color based on background brightness
    if (brightness > 128) {
      element.style.color = '#000000'; // Dark text for light backgrounds
    } else {
      element.style.color = '#ffffff'; // Light text for dark backgrounds
    }
  }
}

// 3. Finally, call the initialization function
document.addEventListener('DOMContentLoaded', function() {
  console.log("Document loaded, calling initializeFilters");
  initializeFilters();
  enhanceLocationCounters();
});