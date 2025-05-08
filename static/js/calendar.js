/**
 * =============================================================================
 * Calendar Functionality (calendar.js)
 * =============================================================================
 *
 * Handles various features for the calendar view:
 * - Color coding for location areas and department tags.
 * - Admin-specific event handling (row clicks, drag-and-drop).
 * - Calendar filtering (rows and columns).
 * - Mobile menu toggle functionality.
 * - Scrollable table detection and touch interactions.
 * - Zoom controls for mobile view.
 *
 * Structure:
 * - Helper Functions (e.g., hexToRgb, ensureTextContrast)
 * - Feature Initialization Functions (e.g., initializeFilters, setupMobileMenu)
 * - Main Consolidated DOMContentLoaded Listener
 */

// =======================================
// Helper Functions
// =======================================

/**
 * Convert hex color to RGB object.
 * @param {string} hex - The hex color string (e.g., "#RRGGBB").
 * @returns {object|null} RGB object {r, g, b} or null if invalid hex.
 */
function hexToRgb(hex) {
    if (!hex) return null;
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

/**
 * Ensure text has proper contrast against its background color.
 * Sets element's color style to black or white based on brightness.
 * @param {HTMLElement} element - The element to check contrast for.
 */
function ensureTextContrast(element) {
    const bgColor = window.getComputedStyle(element).backgroundColor;
    const rgbMatch = bgColor.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*[\d.]+)?\)/);
    if (rgbMatch) {
        const r = parseInt(rgbMatch[1]);
        const g = parseInt(rgbMatch[2]);
        const b = parseInt(rgbMatch[3]);
        // Calculate brightness (YIQ formula)
        const brightness = (r * 299 + g * 587 + b * 114) / 1000;
        // Set text color based on background brightness threshold (128 is common)
        element.style.color = brightness > 128 ? '#000000' : '#ffffff';
    }
}

/**
 * Checks if calendar table wrappers are scrollable and adds/removes a class.
 * Needs to be accessible by zoom controls, hence defined globally here.
 */
function checkIfScrollable() {
    const tableWrappers = document.querySelectorAll('.calendar-table-wrapper');
    tableWrappers.forEach(wrapper => {
        const table = wrapper.querySelector('.calendar-table');
        if (!table) return;
        // Check if the table's content width exceeds the wrapper's visible width
        if (table.scrollWidth > wrapper.clientWidth + 1) { // Add 1px tolerance
            wrapper.classList.add('scrollable');
        } else {
            wrapper.classList.remove('scrollable');
        }
    });
}

/**
 * Enhance location counters with proper color coding from location data
 */
function enhanceLocationCounters() {
    console.log("Enhancing location counters with proper colors");
    
    // Get all counter items in the location counter section
    const locationCounters = document.querySelectorAll('.location-counters .counter-item');
    const areaCounters = document.querySelectorAll('.location-areas .area-tag');
    
    // Update location counter colors
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
    
    // Update area counter colors
    areaCounters.forEach(counter => {
      // Ensure text contrast is appropriate for the background color
      ensureTextContrast(counter);
    });
}

// =======================================
// Feature Initialization Functions
// =======================================

/**
 * Get location areas and their colors from data attributes or elements.
 * @returns {object} An object mapping area names to color strings.
 */
function getLocationAreas() {
    const areas = {};
    // Try getting from dedicated area tags first
    const areaElements = document.querySelectorAll('.location-areas .area-tag');
    if (areaElements.length > 0) {
        areaElements.forEach(el => {
            // Extract name cleanly, excluding count if present
            const nameElement = el.cloneNode(true);
            const countElement = nameElement.querySelector('.area-count');
            if (countElement) {
                nameElement.removeChild(countElement);
            }
            const areaName = nameElement.textContent.trim();
            const backgroundColor = el.style.backgroundColor;
            if (areaName && backgroundColor) {
                areas[areaName] = backgroundColor;
            }
        });
    } else {
        // Fallback or alternative method if needed
        console.warn("Could not find .location-areas .area-tag elements.");
    }
    console.log("Detected Location Areas:", areas);
    return areas;
}
// Make it available globally for other scripts
window.getLocationAreas = getLocationAreas;

/**
 * Apply location area colors as CSS variables to calendar rows.
 * @param {object} areas - Object mapping area names to colors (from getLocationAreas).
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
        // Also set the data-color attribute for better print support
        row.setAttribute('data-color', areas[areaAttribute]);
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
            // Also set the data-color attribute for better print support
            row.setAttribute('data-color', areas[areaName]);
            break;
          }
        }
      }
    });
}

// Make it available globally for other scripts
window.applyLocationAreaColors = applyLocationAreaColors;

/**
 * Apply colors to department tags based on embedded or default data.
 */
function applyDepartmentTagColors() {
    console.log("Applying department tag colors...");
    let departmentColors = {};
    const departmentDataElement = document.getElementById('department-data');

    const fallbackColors = { // Keep fallback just in case
        "SFX": "#ffd8e6", "STN": "#ffecd8", "CR": "#d8fff2", "ST": "#f2d8ff",
        "PR": "#d8fdff", "LL": "#e6ffd8", "VFX": "#d8e5ff", "ANI": "#ffedd8",
        "UW": "#d8f8ff", "INCY": "#f542dd", "TEST": "#067bf9"
    };

    if (departmentDataElement) {
        try {
            departmentColors = JSON.parse(departmentDataElement.textContent.trim());
            // console.log("Parsed department colors:", departmentColors);
        } catch (e) {
            console.error('Error parsing department data, using fallbacks:', e);
            departmentColors = fallbackColors;
        }
    } else {
        console.warn("Department data element not found, using fallbacks.");
        departmentColors = fallbackColors;
    }

    const departmentTags = document.querySelectorAll('.department-tag');
    departmentTags.forEach(tag => {
        const deptCode = tag.getAttribute('data-dept-code') || tag.textContent.trim();
        if (departmentColors[deptCode]) {
            tag.style.backgroundColor = departmentColors[deptCode];
            ensureTextContrast(tag); // Ensure text is readable
        } else {
            // console.warn(`No color found for department code: ${deptCode}`);
             // Apply a default neutral color?
             tag.style.backgroundColor = '#cccccc';
             ensureTextContrast(tag);
        }
    });
    console.log("Finished applying department tag colors.");
}

/**
 * Toggles visibility of calendar rows based on their type (e.g., 'weekend', 'shoot').
 * @param {string} rowType - The class name identifying the row type.
 * @param {boolean} isVisible - True to show, false to hide.
 */
function toggleRowType(rowType, isVisible) {
    // console.log(`Toggling row type ${rowType} to ${isVisible ? 'visible' : 'hidden'}`);
    const rows = document.querySelectorAll(`.calendar-row.${rowType}`);
    rows.forEach(row => {
        row.classList.toggle('filtered-hidden', !isVisible);
    });
    updateFilterStats(); // Update stats after visibility change
}

/**
 * Toggles visibility of calendar columns (header and cells).
 * @param {string} colName - The identifier for the column (e.g., 'sequence', 'second-unit').
 * @param {boolean} isVisible - True to show, false to hide.
 */
function toggleColumnVisibility(colName, isVisible) {
    // console.log(`Toggling column ${colName} to ${isVisible ? 'visible' : 'hidden'}`);
    const headers = document.querySelectorAll(`.${colName}-col`);
    const cells = document.querySelectorAll(`.${colName}-cell`);
    const displayValue = isVisible ? '' : 'none'; // Use '' to reset to default display

    headers.forEach(header => { header.style.display = displayValue; });
    cells.forEach(cell => { cell.style.display = displayValue; });
}

/**
 * Loads filter preferences from localStorage and updates checkbox states.
 */
function loadFilterPreferences() {
    try {
        const preferences = JSON.parse(localStorage.getItem('calendarFilterPrefs') || '{}');
        const mappings = {
            'filter-weekends': 'hideWeekends', 'filter-prep': 'hidePrep',
            'filter-holidays': 'hideHolidays', 'filter-hiatus': 'hideHiatus',
            'filter-shoot': 'hideShoot', 'filter-col-sequence': 'hideColSequence',
            'filter-col-second-unit': 'hideColSecondUnit'
        };

        for (const [elementId, prefKey] of Object.entries(mappings)) {
            const toggle = document.getElementById(elementId);
            if (toggle && preferences[prefKey] !== undefined) {
                toggle.checked = !preferences[prefKey];
            } else if (toggle && preferences[prefKey] === undefined) {
                // If pref not set, ensure checkbox reflects default 'checked' state from HTML
                 toggle.checked = true; // Assuming default is checked
            }
        }
    } catch (error) {
        console.error("Error loading filter preferences:", error);
        // Optionally reset to defaults if parsing fails
    }
}

/**
 * Saves the current state of filter checkboxes to localStorage.
 */
function saveFilterPreferences() {
    const preferences = {};
    const mappings = {
        'filter-weekends': 'hideWeekends', 'filter-prep': 'hidePrep',
        'filter-holidays': 'hideHolidays', 'filter-hiatus': 'hideHiatus',
        'filter-shoot': 'hideShoot', 'filter-col-sequence': 'hideColSequence',
        'filter-col-second-unit': 'hideColSecondUnit'
    };

    for (const [elementId, prefKey] of Object.entries(mappings)) {
        const toggle = document.getElementById(elementId);
        // Store the "hide" state, which is the opposite of the checkbox "checked" state
        preferences[prefKey] = toggle ? !toggle.checked : false;
    }

    localStorage.setItem('calendarFilterPrefs', JSON.stringify(preferences));
    // console.log("Saved Filter Prefs:", preferences);
}

/**
 * Applies all currently selected filters (both row and column).
 */
function applyAllFilters() {
    // console.log("Applying all filters based on checkbox states...");
    // Reset row visibility first
    document.querySelectorAll('.calendar-row').forEach(row => {
        row.classList.remove('filtered-hidden');
    });

    // Apply row filters
    const rowMappings = {
        'filter-weekends': 'weekend', 'filter-prep': 'prep', 'filter-holidays': 'holiday',
        'filter-hiatus': 'hiatus', 'filter-shoot': 'shoot'
    };
    for (const [elementId, rowType] of Object.entries(rowMappings)) {
        const toggle = document.getElementById(elementId);
        if (toggle && !toggle.checked) {
            toggleRowType(rowType, false);
        } else if (toggle && toggle.checked) {
             toggleRowType(rowType, true); // Ensure shown if checked (handles reset case)
        }
    }

    // Apply column filters
    const colMappings = {
        'filter-col-sequence': 'sequence', 'filter-col-second-unit': 'second-unit'
    };
    for (const [elementId, colName] of Object.entries(colMappings)) {
        const toggle = document.getElementById(elementId);
        if (toggle) { // Check if toggle exists before applying
             toggleColumnVisibility(colName, toggle.checked);
        }
    }

    updateFilterStats(); // Update stats after applying all filters
    // console.log("Finished applying all filters.");
}

/**
 * Updates the filter statistics display elements.
 */
function updateFilterStats() {
    const totalRows = document.querySelectorAll('.calendar-row').length;
    // Count only rows that DON'T have the filtered-hidden class
    const visibleRows = document.querySelectorAll('.calendar-row:not(.filtered-hidden)').length;
    const totalShootDays = document.querySelectorAll('.calendar-row.shoot').length;
    const visibleShootDays = document.querySelectorAll('.calendar-row.shoot:not(.filtered-hidden)').length;
    // Add stats for second unit days if needed
    // const totalSecondUnitDays = document.querySelectorAll('.calendar-row .second-unit-cell:not(:empty)').length; // Example criteria
    // const visibleSecondUnitDays = document.querySelectorAll('.calendar-row:not(.filtered-hidden) .second-unit-cell:not(:empty)').length; // Example criteria

    const statsTotal = document.getElementById('filter-stats-total');
    const statsVisible = document.getElementById('filter-stats-visible');
    const statsShootDays = document.getElementById('filter-stats-shoot-days');
    // const statsSecondUnit = document.getElementById('filter-stats-second-unit'); // Get the element

    if (statsTotal) statsTotal.textContent = totalRows;
    if (statsVisible) statsVisible.textContent = visibleRows;
    if (statsShootDays) statsShootDays.textContent = `${visibleShootDays} / ${totalShootDays}`;
    // if (statsSecondUnit) statsSecondUnit.textContent = `${visibleSecondUnitDays} / ${totalSecondUnitDays}`; // Update the display
}

/**
 * Initializes the filter controls, loads preferences, and attaches event listeners.
 */
function initializeFilters() {
    console.log("Initializing filters...");
    const filterPanel = document.querySelector('.filter-panel');
    // Only initialize if filter panel elements exist on the page
    if (!filterPanel || !document.getElementById('filter-weekends')) {
        console.log("Filter panel/elements not found, skipping filter initialization.");
        return;
    }

    console.log("Filter elements found, setting up event listeners...");

    // Define mappings for easier event listener attachment
    const rowMappings = {
        'filter-weekends': 'weekend', 'filter-prep': 'prep', 'filter-holidays': 'holiday',
        'filter-hiatus': 'hiatus', 'filter-shoot': 'shoot'
    };
    const colMappings = {
        'filter-col-sequence': 'sequence', 'filter-col-second-unit': 'second-unit'
    };

    // Load saved preferences BEFORE applying initial filters
    loadFilterPreferences();

    // Add event listeners to row type toggles
    for (const [elementId, rowType] of Object.entries(rowMappings)) {
        const toggle = document.getElementById(elementId);
        if (toggle) {
            toggle.addEventListener('change', function() {
                toggleRowType(rowType, this.checked);
                saveFilterPreferences(); // Save prefs on change
            });
        }
    }

    // Add event listeners to column visibility toggles
    for (const [elementId, colName] of Object.entries(colMappings)) {
        const toggle = document.getElementById(elementId);
        if (toggle) {
            toggle.addEventListener('change', function() {
                toggleColumnVisibility(colName, this.checked);
                saveFilterPreferences(); // Save prefs on change
            });
        }
    }

    // Reset button functionality
    const resetButton = document.getElementById('reset-filters');
    if (resetButton) {
        resetButton.addEventListener('click', function() {
            console.log("Resetting filters...");
            // Reset all checkboxes to checked (visible) state
            Object.keys(rowMappings).forEach(id => {
                const el = document.getElementById(id);
                if (el) el.checked = true;
            });
            Object.keys(colMappings).forEach(id => {
                const el = document.getElementById(id);
                if (el) el.checked = true;
            });

            applyAllFilters(); // Re-apply filters based on reset state
            saveFilterPreferences(); // Save the reset state
        });
    }

    // Apply initial filter state based on loaded preferences (or defaults)
    applyAllFilters();

    console.log("Filter initialization complete.");
}

/**
 * OLD CODE PLACEHELD FOR RELIC CALLS - Initializes the mobile menu toggle button functionality.
 */
function setupMobileMenu() {
    console.log("Mobile menu setup skipped - handled by mobile-menu.js");
    // Do nothing - mobile menu is now handled by mobile-menu.js
    return;
}

/**
 * Sets up click handlers for calendar rows in admin mode - 
 * IMPORTANT: No longer sets up drag and drop (moved to calendar-dragdrop.js)
 */
function setupAdminEventHandlers() {
    // Check if we're in admin mode (presence of .admin-calendar class)
    const isAdminMode = document.querySelector('.admin-calendar') !== null;
    const projectIdElement = document.getElementById('project-id');

    if (isAdminMode && projectIdElement) {
        console.log("Admin mode detected, setting up admin click handlers...");
        const projectId = projectIdElement.value;
        const calendarRows = document.querySelectorAll('.calendar-row');

        calendarRows.forEach(row => {
            // We only set up click handlers here, not drag and drop
            // Remove existing listener before adding new one to prevent duplicates if called multiple times
            row.removeEventListener('click', handleAdminRowClick); 
            // Add listener for row click navigation
            row.addEventListener('click', handleAdminRowClick);
        });
        
        console.log("Admin event handlers setup complete.");
    } else {
        console.log("Not in admin mode or projectId not found, skipping admin event handlers.");
    }
}

// Named function for row click handling
function handleAdminRowClick(event) {
    // Don't navigate if we're in the middle of a drag operation
    if (document.querySelector('.dragging')) {
        console.log('Click ignored during drag operation');
        return;
    }
    
    // Don't navigate if the click was on an interactive element
    if (event.target.closest('button, a')) {
        console.log('Click on interactive element ignored');
        return;
    }
    
    const date = this.dataset.date;
    const projectId = document.getElementById('project-id').value;
    
    if (date && projectId) {
        console.log(`Navigating to admin day view: /admin/day/${projectId}/${date}`);
        window.location.href = `/admin/day/${projectId}/${date}`;
    } else {
        console.warn("Could not navigate: Date or ProjectID missing from row.", {date, projectId});
    }
}

/**
 * Initializes scrollable table detection and touch interactions.
 */
function setupScrollableTables() {
    console.log("Setting up scrollable tables...");
    const tableWrappers = document.querySelectorAll('.calendar-table-wrapper');

    if (!tableWrappers.length) {
        console.log("No table wrappers found, skipping scrollable table setup.");
        return;
    }

    // Initial check and resize listener
    checkIfScrollable(); // Defined globally
    window.addEventListener('resize', checkIfScrollable);

    // Touch interactions for mobile
    tableWrappers.forEach(wrapper => {
        // Swipe/Scroll
        if (window.innerWidth <= 768) { // Check if likely mobile
            let startX, startScrollLeft;
            wrapper.addEventListener('touchstart', (e) => {
                startX = e.touches[0].pageX;
                startScrollLeft = wrapper.scrollLeft;
            }, { passive: true });
            wrapper.addEventListener('touchmove', (e) => {
                const x = e.touches[0].pageX;
                const dist = startX - x;
                wrapper.scrollLeft = startScrollLeft + dist;
            }, { passive: true });
        }

        // Double Tap Zoom/Fit (Optional - consider if needed with pinch zoom)
        let lastTap = 0;
        wrapper.addEventListener('touchend', function(e) {
            const currentTime = new Date().getTime();
            const tapLength = currentTime - lastTap;
            if (tapLength < 300 && tapLength > 0) { // Double tap threshold
                e.preventDefault();
                const table = wrapper.querySelector('.calendar-table');
                if (!table) return;
                // Example toggle: Fit width (consider usability)
                if (table.style.width === '100%') {
                    table.style.width = ''; // Reset width
                    table.style.fontSize = ''; // Reset font size
                    wrapper.classList.remove('fit-content'); // Example class
                } else {
                    table.style.width = '100%'; // Fit width
                    table.style.fontSize = '0.8rem'; // Adjust font size
                     wrapper.classList.add('fit-content'); // Example class
                }
            }
            lastTap = currentTime;
        });
    });
     console.log("Scrollable tables setup finished.");
}

/**
 * Initializes zoom controls for the calendar table.
 */
function setupZoomControls() {
    console.log("Setting up zoom controls...");
    // Assume controls are outside the wrappers, find them once
    const zoomInBtn = document.querySelector('.zoom-in');
    const zoomOutBtn = document.querySelector('.zoom-out');
    const fitWidthBtn = document.querySelector('.fit-width');
    const zoomLevelDisplay = document.querySelector('.zoom-level');
    const tableWrapper = document.querySelector('.calendar-table-wrapper'); // Assuming one main wrapper for zoom

    if (!zoomInBtn || !zoomOutBtn || !fitWidthBtn || !zoomLevelDisplay || !tableWrapper) {
        console.log("Zoom controls or table wrapper not found, skipping zoom setup.");
        return;
    }

    let currentZoom = 100; // Percentage

    const applyZoom = () => {
        // console.log(`Applying zoom: ${currentZoom}%`);
        zoomLevelDisplay.textContent = currentZoom + '%';
        tableWrapper.classList.remove('fit-width', 'zoom-50', 'zoom-75', 'zoom-125', 'zoom-150'); // Clear old zoom classes

        if (currentZoom !== 100) {
             tableWrapper.classList.add(`zoom-${currentZoom}`); // Use classes for 50, 75, 125, 150 if defined in CSS
        }

        // Check scrollability after zoom might change layout
        setTimeout(checkIfScrollable, 50); // Defined globally
    };

    zoomInBtn.addEventListener('click', () => {
        if (currentZoom < 150) { // Max zoom 150%
            currentZoom += 25;
            tableWrapper.classList.remove('fit-width'); // Ensure fit-width is off when zooming
            applyZoom();
        }
    });

    zoomOutBtn.addEventListener('click', () => {
        if (currentZoom > 50) { // Min zoom 50%
            currentZoom -= 25;
            tableWrapper.classList.remove('fit-width'); // Ensure fit-width is off when zooming
            applyZoom();
        }
    });

    fitWidthBtn.addEventListener('click', () => {
        const willFit = !tableWrapper.classList.contains('fit-width');
        tableWrapper.classList.toggle('fit-width', willFit);
        if (willFit) {
            zoomLevelDisplay.textContent = 'Fit';
             tableWrapper.classList.remove('zoom-50', 'zoom-75', 'zoom-125', 'zoom-150'); // Clear zoom classes
             // Reset direct scale if used
             // const table = tableWrapper.querySelector('.calendar-table');
             // if (table) { table.style.transform = ''; }
        } else {
            // Return to previous zoom level when toggling off
            applyZoom();
        }
         setTimeout(checkIfScrollable, 50); // Check scroll on fit toggle
    });

     // Hide scroll hint after user has scrolled (assuming one global hint)
     const scrollHint = document.querySelector('.scroll-hint');
     if (scrollHint) {
         tableWrapper.addEventListener('scroll', function() {
             if (tableWrapper.scrollLeft > 10) {
                 scrollHint.style.opacity = '0';
                 setTimeout(() => { scrollHint.style.display = 'none'; }, 500); // Hide after fade
             }
         }, { passive: true }); // Use passive listener for scroll
     }
     console.log("Zoom controls setup finished.");
}

// =======================================
// Main Initialization on DOMContentLoaded
// =======================================

document.addEventListener('DOMContentLoaded', function() {
    console.log("DOM fully loaded and parsed. Running initializers...");

    // --- 1. Core Visual Setup ---
    try {
        const locationAreas = getLocationAreas();
        applyLocationAreaColors(locationAreas);
        applyDepartmentTagColors();
        enhanceLocationCounters(); // Ensure contrast/colors for counters
    } catch (error) {
        console.error("Error during core visual setup:", error);
    }

    // --- 2. Filter Setup ---
    try {
        initializeFilters(); // Initializes filter controls and applies initial state
    } catch (error) {
        console.error("Error during filter initialization:", error);
    }

    // --- 3. Mobile Menu Setup ---
    try {
        setupMobileMenu(); // Initializes the hamburger menu toggle
    } catch (error) {
        console.error("Error during mobile menu setup:", error);
    }

    // --- 4. Admin-Specific Features ---
    // This checks internally if it's the admin page
    try {
        setupAdminEventHandlers(); // Sets up row clicks only, not drag/drop
    } catch (error) {
        console.error("Error during admin event handler setup:", error);
    }

    // --- 5. Scrollable Table / Touch Features ---
    try {
        setupScrollableTables(); // Adds scroll indicators and touch interactions
    } catch (error) {
        console.error("Error during scrollable table setup:", error);
    }

    // --- 6. Zoom Controls ---
    try {
        setupZoomControls(); // Initializes zoom buttons
    } catch (error) {
        console.error("Error during zoom control setup:", error);
    }

    // --- 7. Sticky Header Enhancement --- ADD THIS NEW SECTION HERE
    try {
        // Add sticky header effects
        const tableWrappers = document.querySelectorAll('.calendar-table-wrapper');
        
        tableWrappers.forEach(wrapper => {
            // Add shadow to header on scroll
            wrapper.addEventListener('scroll', function() {
                const thead = this.querySelector('thead');
                if (this.scrollTop > 0) {
                    thead.classList.add('scrolled');
                } else {
                    thead.classList.remove('scrolled');
                }
            });
        });
        
        console.log("Sticky header enhancement added");
    } catch (error) {
        console.error("Error setting up sticky header:", error);
    }
    
    console.log("All initializers called.");
});