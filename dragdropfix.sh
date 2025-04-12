#!/bin/bash
# Script to restore the calendar drag and drop functionality

# Create backup directory
BACKUP_DATE=$(date +%Y%m%d)
BACKUP_DIR="/mnt/user/backups/film-scheduler-v4/$BACKUP_DATE-js-fix"
mkdir -p "$BACKUP_DIR"

# Backup existing JS file if it exists
if [ -f /mnt/user/appdata/film-scheduler-v4/static/js/calendar-dragdrop.js ]; then
    echo "Backing up existing calendar-dragdrop.js..."
    cp /mnt/user/appdata/film-scheduler-v4/static/js/calendar-dragdrop.js "$BACKUP_DIR/"
fi

# Create the directory if it doesn't exist
mkdir -p /mnt/user/appdata/film-scheduler-v4/static/js

# Create the calendar-dragdrop.js file with proper content
echo "Creating calendar-dragdrop.js file..."
cat > /mnt/user/appdata/film-scheduler-v4/static/js/calendar-dragdrop.js << 'EOF'
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
                sourceDate: sourceDate,
                targetDate: targetDate,
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

# Create/update the calendar-move.js file
echo "Creating calendar-move.js file..."
cat > /mnt/user/appdata/film-scheduler-v4/static/js/calendar-move.js << 'EOF'
/**
 * Calendar shoot day move functionality using modals
 */
document.addEventListener('DOMContentLoaded', function() {
    // Only initialize in admin calendar page
    if (!document.querySelector('.admin-calendar')) {
        return;
    }

    console.log('Initializing calendar move functionality');
    
    // Create and add the modal to the page
    const modal = createMoveModal();
    document.body.appendChild(modal);
    
    // Add styles
    addStyles();
    
    // Add move buttons to all shoot days
    addMoveButtons();
    
    /**
     * Create the move modal
     */
    function createMoveModal() {
        const modal = document.createElement('div');
        modal.id = 'move-day-modal';
        modal.className = 'move-modal';
        modal.innerHTML = `
            <div class="move-modal-content">
                <div class="move-modal-header">
                    <h3>Move Shoot Day</h3>
                    <button class="move-modal-close">&times;</button>
                </div>
                <div class="move-modal-body">
                    <p>Moving shoot day <span id="source-day-number"></span> from <span id="source-date"></span></p>
                    <div class="form-group">
                        <label for="target-date">Select new date:</label>
                        <select id="target-date"></select>
                    </div>
                </div>
                <div class="move-modal-footer">
                    <button id="cancel-move" class="button secondary">Cancel</button>
                    <button id="confirm-move" class="button">Move Day</button>
                </div>
            </div>
        `;
        
        // Add event listeners
        modal.querySelector('.move-modal-close').addEventListener('click', closeModal);
        modal.querySelector('#cancel-move').addEventListener('click', closeModal);
        modal.querySelector('#confirm-move').addEventListener('click', confirmMove);
        
        return modal;
    }
    
    /**
     * Add the necessary styles
     */
    function addStyles() {
        const style = document.createElement('style');
        style.textContent = `
            .move-button {
                display: inline-block;
                background-color: var(--accent-color, #3498db);
                color: white;
                border: none;
                border-radius: 3px;
                padding: 2px 5px;
                font-size: 0.7rem;
                cursor: pointer;
                margin-left: 5px;
            }
            
            .move-modal {
                display: none;
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background-color: rgba(0, 0, 0, 0.5);
                z-index: 9999;
                justify-content: center;
                align-items: center;
            }
            
            .move-modal.active {
                display: flex;
            }
            
            .move-modal-content {
                background-color: white;
                border-radius: 5px;
                max-width: 500px;
                width: 100%;
                box-shadow: 0 3px 10px rgba(0, 0, 0, 0.2);
            }
            
            .move-modal-header {
                padding: 10px 15px;
                border-bottom: 1px solid #ddd;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            
            .move-modal-header h3 {
                margin: 0;
                font-size: 1.2rem;
            }
            
            .move-modal-close {
                background: none;
                border: none;
                font-size: 1.5rem;
                cursor: pointer;
            }
            
            .move-modal-body {
                padding: 15px;
            }
            
            .move-modal-footer {
                padding: 10px 15px;
                border-top: 1px solid #ddd;
                display: flex;
                justify-content: flex-end;
                gap: 10px;
            }
            
            .form-group {
                margin-bottom: 15px;
            }
            
            .form-group label {
                display: block;
                margin-bottom: 5px;
                font-weight: 500;
            }
            
            .form-group select {
                width: 100%;
                padding: 8px;
                border: 1px solid #ddd;
                border-radius: 4px;
            }
            
            .loading-overlay {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background-color: rgba(255, 255, 255, 0.8);
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                z-index: 10000;
            }
            
            .loading-spinner {
                width: 40px;
                height: 40px;
                border: 4px solid #f3f3f3;
                border-top: 4px solid #3498db;
                border-radius: 50%;
                animation: spin 1s linear infinite;
                margin-bottom: 10px;
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
        `;
        document.head.appendChild(style);
    }
    
    /**
     * Add move buttons to all shoot days
     */
    function addMoveButtons() {
        const rows = document.querySelectorAll('.calendar-row');
        
        rows.forEach(row => {
            const dayCell = row.querySelector('.day-cell');
            const shootDayNumber = dayCell ? dayCell.textContent.trim() : '';
            
            // Only add to rows with a shoot day number
            if (shootDayNumber && !isNaN(parseInt(shootDayNumber))) {
                const date = row.getAttribute('data-date');
                
                const moveButton = document.createElement('button');
                moveButton.className = 'move-button';
                moveButton.textContent = 'Move';
                moveButton.setAttribute('data-date', date);
                moveButton.setAttribute('data-day', shootDayNumber);
                
                moveButton.addEventListener('click', function(e) {
                    e.stopPropagation(); // Prevent row click if any
                    openMoveModal(date, shootDayNumber);
                });
                
                // Add button to the day cell
                dayCell.appendChild(moveButton);
            }
        });
    }
    
    /**
     * Open the move modal for a shoot day
     */
    function openMoveModal(sourceDate, shootDayNumber) {
        const modal = document.getElementById('move-day-modal');
        const sourceDay = document.getElementById('source-day-number');
        const sourceDateSpan = document.getElementById('source-date');
        const targetDateSelect = document.getElementById('target-date');
        
        // Set source information
        sourceDay.textContent = shootDayNumber;
        sourceDateSpan.textContent = formatDate(sourceDate);
        
        // Clear existing options
        targetDateSelect.innerHTML = '';
        
        // Populate target date options (all dates except source date)
        const rows = document.querySelectorAll('.calendar-row');
        rows.forEach(row => {
            const date = row.getAttribute('data-date');
            const day = row.querySelector('.date-cell');
            const dayOfWeek = day ? day.querySelector('.date-day').textContent : '';
            
            // Skip source date and add all other dates as options
            if (date && date !== sourceDate) {
                const option = document.createElement('option');
                option.value = date;
                option.textContent = `${formatDate(date)} (${dayOfWeek})`;
                
                // Add class for weekends, holidays, etc.
                if (row.classList.contains('weekend')) {
                    option.className = 'weekend-option';
                    if (!row.classList.contains('working-weekend')) {
                        option.textContent += ' - Weekend';
                    }
                } else if (row.classList.contains('holiday')) {
                    option.className = 'holiday-option';
                    option.textContent += ' - Holiday';
                } else if (row.classList.contains('hiatus')) {
                    option.className = 'hiatus-option';
                    option.textContent += ' - Hiatus';
                }
                
                targetDateSelect.appendChild(option);
            }
        });
        
        // Set data attributes for use in confirmMove
        modal.setAttribute('data-source-date', sourceDate);
        
        // Show modal
        modal.classList.add('active');
    }
    
    /**
     * Close the move modal
     */
    function closeModal() {
        const modal = document.getElementById('move-day-modal');
        modal.classList.remove('active');
    }
    
    /**
     * Handle the move confirmation
     */
    function confirmMove() {
        const modal = document.getElementById('move-day-modal');
        const sourceDate = modal.getAttribute('data-source-date');
        const targetDateSelect = document.getElementById('target-date');
        const targetDate = targetDateSelect.value;
        
        if (!sourceDate || !targetDate) {
            alert('Please select a target date');
            return;
        }
        
        // Show loading overlay
        showLoading();
        
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
                sourceDate: sourceDate,
                targetDate: targetDate,
                mode: 'swap' // Add mode param
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
            // Close modal and reload page
            closeModal();
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
    function showLoading() {
        const overlay = document.createElement('div');
        overlay.className = 'loading-overlay';
        overlay.innerHTML = `
            <div class="loading-spinner"></div>
            <div>Moving shoot day...</div>
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
    
    /**
     * Format a date string as DD/MM/YYYY
     */
    function formatDate(dateString) {
        const date = new Date(dateString);
        const day = date.getDate().toString().padStart(2, '0');
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    }
});
EOF

echo "JavaScript files for drag and drop functionality have been restored!"
echo ""
echo "Now restart the Docker container to apply the changes:"
echo "docker-compose -f /mnt/user/appdata/film-scheduler-v4/docker-compose.yml restart"
