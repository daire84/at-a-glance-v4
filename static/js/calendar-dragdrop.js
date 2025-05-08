/**
 * Enhanced Calendar drag and drop functionality
 * Properly handles day reordering and renumbering
 */

document.addEventListener('DOMContentLoaded', function() {
    console.log("Initializing calendar drag and drop...");
    
    // Only initialize in admin calendar page
    const adminCalendar = document.querySelector('.admin-calendar');
    if (!adminCalendar) {
        console.log("Admin calendar not found, skipping drag and drop initialization");
        return;
    }

    // Add diagnostic class to body for debugging
    document.body.classList.add('drag-drop-initialized');
    console.log("Drag and drop initialization started for admin calendar");

    // Elements
    const calendarRows = document.querySelectorAll('.calendar-row');
    let draggedRow = null;
    
    // Get project ID
    const projectIdElement = document.getElementById('project-id');
    if (!projectIdElement) {
        console.error("Project ID element not found - drag and drop cannot be initialized");
        return;
    }
    const projectId = projectIdElement.value;
    console.log(`Initializing drag and drop for project ID: ${projectId}`);
    
    // Make days with shoot day numbers draggable
    calendarRows.forEach(row => {
        const shootDayCell = row.querySelector('.day-cell');
        const hasShootDay = shootDayCell && shootDayCell.textContent && shootDayCell.textContent.trim() !== '';
        
        // Check if it's a shoot day based on shoot day number presence
        if (hasShootDay) {
            row.setAttribute('draggable', 'true');
            row.classList.add('draggable');
            row.style.cursor = 'grab';
            
            // Drag start
            row.addEventListener('dragstart', function(e) {
                // Prevent default click navigation during drag
                e.stopPropagation();
                
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
                    // Add class to body to signal drag is in progress
                    document.body.classList.add('calendar-dragging');
                }, 0);
                
                console.log('Started dragging:', date, 'with shoot day', shootDay);
            });
            
            // Drag end
            row.addEventListener('dragend', function(e) {
                // Prevent default click navigation during drag
                e.stopPropagation();
                
                this.classList.remove('dragging');
                document.querySelectorAll('.calendar-row').forEach(r => r.classList.remove('drop-target'));
                document.body.classList.remove('calendar-dragging');
                draggedRow = null;
                
                console.log('Ended dragging');
            });
        } else {
            // Ensure non-shoot days aren't draggable
            row.removeAttribute('draggable');
            row.classList.remove('draggable');
            row.style.cursor = '';
        }
    });
    
    // Set up drop zones
    calendarRows.forEach(row => {
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
            // Prevent default behavior
            e.preventDefault();
            e.stopPropagation();
            
            // Remove drop target styling
            this.classList.remove('drop-target');
            
            // Get source day information
            let sourceDate, targetDate;
            
            try {
                // Try to get the detailed JSON data first
                const dayInfo = JSON.parse(e.dataTransfer.getData('application/json'));
                sourceDate = dayInfo.date;
                console.log('Drop with JSON data:', dayInfo);
            } catch (err) {
                // Fallback to simple text
                sourceDate = e.dataTransfer.getData('text/plain');
                console.log('Drop with text data:', sourceDate);
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
    
    // Signal initialization complete
    console.log("Calendar drag and drop initialization complete");
});