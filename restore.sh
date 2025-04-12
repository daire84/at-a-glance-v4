#!/bin/bash
# Script to restore the calendar-dragdrop.js file

# Define file paths
JS_DIR="/mnt/user/appdata/film-scheduler-v4/static/js"
FILE_PATH="$JS_DIR/calendar-dragdrop.js"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/calendar-dragdrop-${BACKUP_DATE}.js"

# Create backup directory if it doesn't exist
mkdir -p "/mnt/user/backups/film-scheduler-v4"

# Check if file exists and create backup if it does
if [ -f "$FILE_PATH" ]; then
    echo "Creating backup at $BACKUP_PATH"
    cp "$FILE_PATH" "$BACKUP_PATH"
fi

# Create the js directory if it doesn't exist
mkdir -p "$JS_DIR"

# Write the correct JS file with proper parameter names
cat > "$FILE_PATH" << 'EOF'
/**
 * Enhanced Calendar drag and drop functionality
 * Properly handles day reordering and renumbering
 */

document.addEventListener('DOMContentLoaded', function() {
    // Only initialize in admin calendar page
    if (!document.querySelector('.admin-calendar')) {
        return;
    }

    console.log('Initializing enhanced calendar drag and drop functionality');

    // Elements
    const rows = document.querySelectorAll('.calendar-row');
    let draggedRow = null;
    
    // Make days with shoot day numbers draggable
    rows.forEach(row => {
        const shootDayCell = row.querySelector('.day-cell');
        const hasShootDay = shootDayCell && shootDayCell.textContent && shootDayCell.textContent.trim() !== '';
        
        // Check if it's a shoot day based on shoot day number presence
        if (hasShootDay) {
            row.setAttribute('draggable', 'true');
            row.classList.add('draggable');
            row.style.cursor = 'grab';
            
            // Drag start
            row.addEventListener('dragstart', function(e) {
                // Set data transfer
                const date = this.getAttribute('data-date');
                const shootDay = this.querySelector('.day-cell').textContent.trim();
                
                // Store the complete day info in JSON format
                const dayInfo = {
                    date: date,
                    shootDay: shootDay
                };
                
                e.dataTransfer.setData('application/json', JSON.stringify(dayInfo));
                e.dataTransfer.setData('text/plain', date); // Fallback
                
                // Visual feedback
                draggedRow = this;
                setTimeout(() => {
                    this.classList.add('dragging');
                }, 0);
                
                console.log('Started dragging:', date, 'with shoot day', shootDay);
            });
            
            // Drag end
            row.addEventListener('dragend', function() {
                this.classList.remove('dragging');
                rows.forEach(r => r.classList.remove('drop-target'));
                draggedRow = null;
            });
        }
    });
    
    // Set up drop zones
    rows.forEach(row => {
        // Drag over - all rows can be drop targets
        row.addEventListener('dragover', function(e) {
            if (draggedRow && this !== draggedRow) {
                e.preventDefault(); // Allow drop
                this.classList.add('drop-target');
            }
        });
        
        // Drag leave
        row.addEventListener('dragleave', function() {
            this.classList.remove('drop-target');
        });
        
        // Drop
        row.addEventListener('drop', function(e) {
            e.preventDefault();
            this.classList.remove('drop-target');
            
            // Get source day information
            let sourceDate, targetDate;
            
            try {
                // Try to get the detailed JSON data first
                const dayInfo = JSON.parse(e.dataTransfer.getData('application/json'));
                sourceDate = dayInfo.date;
            } catch (err) {
                // Fallback to simple text
                sourceDate = e.dataTransfer.getData('text/plain');
            }
            
            targetDate = this.getAttribute('data-date');
            
            // Validate
            if (!sourceDate || !targetDate || sourceDate === targetDate) {
                console.log('Invalid drop: missing data or same position');
                return;
            }
            
            // Get additional info about the target
            const isWeekend = this.classList.contains('weekend');
            const isHoliday = this.classList.contains('holiday');
            const isHiatus = this.classList.contains('hiatus');
            const isWorkingWeekend = this.classList.contains('working-weekend');
            
            // Basic validation before sending API request
            if (isWeekend && !isWorkingWeekend) {
                alert('Cannot move to a non-working weekend. Please mark the weekend as working first.');
                return;
            }
            
            if (isHoliday) {
                alert('Cannot move to a holiday. Please mark the holiday as working first.');
                return;
            }
            
            if (isHiatus) {
                alert('Cannot move to a hiatus period.');
                return;
            }
            
            console.log('Moving day from', sourceDate, 'to', targetDate);
            moveDay(sourceDate, targetDate);
        });
    });
    
    /**
     * Send improved move request to server
     */
    function moveDay(sourceDate, targetDate) {
        // Show loading overlay
        showLoading('Moving shoot day...');
        
        // Get project ID from URL
        const pathParts = window.location.pathname.split('/');
        const projectId = pathParts[pathParts.length - 1];
        
        // Send API request
        fetch(`/api/projects/${projectId}/calendar/move-day`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                fromDate: sourceDate,
                toDate: targetDate,
                mode: 'swap' // Tell backend to use swap mode
            })
        })
        .then(response => {
            return response.json().then(data => {
                if (!response.ok) {
                    throw new Error(data.error || 'Failed to move day');
                }
                return data;
            });
        })
        .then(data => {
            console.log('Move successful:', data);
            // Reload page to show updated calendar
            window.location.reload();
        })
        .catch(error => {
            console.error('Error moving day:', error);
            hideLoading();
            alert(error.message || 'An error occurred while moving the day');
        });
    }
    
    /**
     * Show loading overlay
     */
    function showLoading(message) {
        // Add styles if needed
        if (!document.querySelector('#drag-drop-styles')) {
            const style = document.createElement('style');
            style.id = 'drag-drop-styles';
            style.textContent = `
                .loading-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(255,255,255,0.8);
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    z-index: 9999;
                }
                .spinner {
                    width: 40px;
                    height: 40px;
                    border: 4px solid #f3f3f3;
                    border-top: 4px solid var(--accent-color, #3498db);
                    border-radius: 50%;
                    animation: spin 1s linear infinite;
                    margin-bottom: 10px;
                }
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
                .calendar-row.draggable {
                    position: relative;
                }
                .calendar-row.draggable::before {
                    content: '⋮⋮';
                    position: absolute;
                    left: -15px;
                    top: 50%;
                    transform: translateY(-50%);
                    opacity: 0.3;
                    cursor: grab;
                }
                .calendar-row.draggable:hover::before {
                    opacity: 0.7;
                }
                .calendar-row.dragging {
                    opacity: 0.5;
                    cursor: grabbing;
                }
                .calendar-row.drop-target {
                    border: 2px dashed var(--accent-color, #3498db);
                    position: relative;
                }
                .calendar-row.drop-target::after {
                    content: '';
                    position: absolute;
                    left: 0;
                    top: 0;
                    right: 0;
                    bottom: 0;
                    background-color: var(--accent-color, #3498db);
                    opacity: 0.1;
                    pointer-events: none;
                }
            `;
            document.head.appendChild(style);
        }
        
        const overlay = document.createElement('div');
        overlay.className = 'loading-overlay';
        overlay.innerHTML = `
            <div class="spinner"></div>
            <div>${message || 'Loading...'}</div>
        `;
        document.body.appendChild(overlay);
    }
    
    /**
     * Hide loading overlay
     */
    function hideLoading() {
        const overlay = document.querySelector('.loading-overlay');
        if (overlay) {
            document.body.removeChild(overlay);
        }
    }
});
EOF

# Check if the file was created successfully
if [ -f "$FILE_PATH" ]; then
    echo "Successfully restored calendar-dragdrop.js with correct parameter names (fromDate/toDate)"
    echo "File size: $(wc -c < "$FILE_PATH") bytes"
else
    echo "Error: Failed to create the file!"
    exit 1
fi

echo "Done! Remember to restart your Docker container for changes to take effect:"
echo "docker restart film-scheduler-v4"
