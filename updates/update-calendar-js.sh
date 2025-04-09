#!/bin/bash
# Script to update the calendar.js file for improved department tag handling

# Define paths
PROJECT_PATH="/mnt/user/appdata/film-scheduler-v4"
JS_PATH="${PROJECT_PATH}/static/js"
BACKUP_PATH="${PROJECT_PATH}/static/js/calendar.js.bak"

# Create backup
echo "Creating backup of calendar.js..."
cp "${JS_PATH}/calendar.js" "${BACKUP_PATH}"
echo "Backup created at ${BACKUP_PATH}"

# Function to check if a specific code already exists in the file
function code_exists() {
    grep -q "Better department tag color handling" "${JS_PATH}/calendar.js"
    return $?
}

# Add the improved department tag color handling code if it doesn't exist
if code_exists; then
    echo "Department tag color handling code already exists in calendar.js"
else
    echo "Adding improved department tag color handling to calendar.js..."
    cat >> "${JS_PATH}/calendar.js" << 'EOJS'

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
});
EOJS
    echo "calendar.js has been updated!"
fi
