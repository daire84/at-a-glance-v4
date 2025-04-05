/**
 * Calendar drag and drop functionality
 * Allows reorganizing of shoot days with automatic date recalculation
 */

document.addEventListener('DOMContentLoaded', function() {
    // Only initialize drag-and-drop in the admin calendar page
    if (!document.querySelector('.admin-calendar')) {
        return;
    }

    console.log('Initializing calendar drag and drop functionality');

    // Elements
    const calendar = document.querySelector('.calendar-table');
    const rows = document.querySelectorAll('.calendar-row');
    let draggedRow = null;
    let originalPosition = null;
    
    // Initialize drag and drop for shoot day rows only
    rows.forEach((row, index) => {
        // Only make shoot days draggable
        if (!row.classList.contains('shoot') || row.classList.contains('weekend') || 
            row.classList.contains('holiday') || row.classList.contains('hiatus')) {
            return;
        }
        
        row.setAttribute('draggable', 'true');
        
        // Drag start
        row.addEventListener('dragstart', function(e) {
            console.log('Drag started for date:', this.getAttribute('data-date'));
            draggedRow = this;
            originalPosition = index;
            
            // Add class for styling
            setTimeout(() => {
                this.classList.add('dragging');
            }, 0);
            
            // Set data transfer
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', this.getAttribute('data-date'));
        });
        
        // Drag end
        row.addEventListener('dragend', function() {
            console.log('Drag ended');
            this.classList.remove('dragging');
            draggedRow = null;
            
            // Remove all drag-over classes
            rows.forEach(row => {
                row.classList.remove('drag-over');
            });
        });
    });
    
    // Add drop zone handlers to all rows
    rows.forEach((row) => {
        // Drag over
        row.addEventListener('dragover', function(e) {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
            return false;
        });
        
        // Drag enter
        row.addEventListener('dragenter', function(e) {
            e.preventDefault();
            if (this !== draggedRow) {
                this.classList.add('drag-over');
            }
        });
        
        // Drag leave
        row.addEventListener('dragleave', function() {
            this.classList.remove('drag-over');
        });
        
        // Drop
        row.addEventListener('drop', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            if (this === draggedRow) {
                return false;
            }
            
            this.classList.remove('drag-over');
            
            const fromDate = e.dataTransfer.getData('text/plain');
            const toDate = this.getAttribute('data-date');
            
            console.log(`Moving day from ${fromDate} to ${toDate}`);
            
            // Handle the drop on the server-side
            moveDay(fromDate, toDate);
            
            return false;
        });
    });
    
    /**
     * Send the move operation to the server and reload the calendar
     */
    function moveDay(fromDate, toDate) {
        // Show loading state
        showLoading();
        
        // Get project ID from the URL
        const pathParts = window.location.pathname.split('/');
        const projectId = pathParts[pathParts.length - 1];
        
        console.log(`Project ID: ${projectId}, Moving from: ${fromDate} to: ${toDate}`);
        
        // Send request to server
        fetch(`/api/projects/${projectId}/calendar/move-day`, {
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
                return response.json().then(err => {
                    throw new Error(`Failed to move day: ${err.error || 'Unknown error'}`);
                });
            }
            return response.json();
        })
        .then((data) => {
            console.log('Move day successful:', data);
            // Reload the page to show updated calendar
            window.location.reload();
        })
        .catch(error => {
            hideLoading();
            console.error('Error moving day:', error);
            alert('An error occurred while moving the day: ' + error.message);
        });
    }
    
    /**
     * Show loading overlay
     */
    function showLoading() {
        const loadingOverlay = document.createElement('div');
        loadingOverlay.className = 'loading-overlay';
        loadingOverlay.innerHTML = `
            <div class="loading-spinner"></div>
            <div class="loading-text">Updating calendar...</div>
        `;
        document.body.appendChild(loadingOverlay);
        
        // Add styling if not already in css
        if (!document.querySelector('style#loading-style')) {
            const style = document.createElement('style');
            style.id = 'loading-style';
            style.textContent = `
                .loading-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background-color: rgba(255, 255, 255, 0.8);
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    z-index: 9999;
                }
                
                .loading-spinner {
                    width: 40px;
                    height: 40px;
                    border: 3px solid #f3f3f3;
                    border-top: 3px solid var(--accent-color, #5d89ba);
                    border-radius: 50%;
                    animation: spin 1s linear infinite;
                    margin-bottom: 10px;
                }
                
                .loading-text {
                    color: var(--text-color, #2d3142);
                    font-size: 14px;
                }
                
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
                
                .calendar-row.dragging {
                    opacity: 0.5;
                }
                
                .calendar-row.drag-over {
                    border: 2px dashed var(--accent-color, #5d89ba);
                }
            `;
            document.head.appendChild(style);
        }
    }
    
    /**
     * Hide loading overlay
     */
    function hideLoading() {
        const loadingOverlay = document.querySelector('.loading-overlay');
        if (loadingOverlay) {
            loadingOverlay.remove();
        }
    }
});