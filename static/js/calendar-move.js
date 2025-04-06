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
            
            .spinner {
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
                targetDate: targetDate
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
            <div class="spinner"></div>
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
