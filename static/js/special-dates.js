/**
 * Special Dates Management
 * Handles working weekends, bank holidays, hiatus periods, and other special dates
 */

// Create a global variable for project select to fix scope issues
let projectSelect;

document.addEventListener('DOMContentLoaded', function() {
    console.log("DOM loaded for special dates");
    
    // DOM elements
    projectSelect = document.getElementById('project-select');
    const regenerateBtn = document.getElementById('regenerate-calendar-btn');
    const addWeekendBtn = document.getElementById('add-weekend-btn');
    
    console.log("Key elements found:", {
        projectSelect: !!projectSelect,
        regenerateBtn: !!regenerateBtn,
        addWeekendBtn: !!addWeekendBtn
    });
    
    // Initialize the page
    initializePage();
    
    /**
     * Initialize the page
     */
    function initializePage() {
        console.log("Initializing page...");
        
        // Add event listeners
        if (projectSelect) {
            console.log("Adding event listener to project select");
            projectSelect.addEventListener('change', function() {
                console.log("Project selected:", this.value);
                if (this.value) {
                    window.location.href = `/admin/dates/${this.value}`;
                } else {
                    window.location.href = '/admin/dates';
                }
            });
        } else {
            console.error("Project select element not found");
        }
        
        // Init modal handlers
        initializeModals();
        
        // Initialize working weekends functionality
        const weekendsModule = initializeWorkingWeekends();
        
          // Initialize bank holidays functionality
        const holidaysModule = initializeBankHolidays();
        
        // Load data if project is selected
        const projectId = projectSelect ? projectSelect.value : null;
        console.log("Project ID:", projectId);
        
        if (projectId) {
            // Load data for each section
            console.log("Loading working weekends for project:", projectId);
            weekendsModule.loadWorkingWeekends(projectId);
            
            console.log("Loading bank holidays for project:", projectId);
            holidaysModule.loadBankHolidays(projectId);
            
            // Add regenerate button handler
            if (regenerateBtn) {
                console.log("Adding regenerate button handler");
                regenerateBtn.addEventListener('click', function() {
                    if (confirm('Are you sure you want to regenerate the calendar? This will update all shoot day numbers based on special dates.')) {
                        regenerateCalendar(projectId);
                    }
                });
            } else {
                console.error("Regenerate button not found");
            }
        }
    }
    
    /**
     * Initialize all modals
     */
    function initializeModals() {
        console.log("Initializing modals...");
        
        // Close modal buttons
        const closeButtons = document.querySelectorAll('[data-close-modal]');
        console.log("Found close buttons:", closeButtons.length);
        
        closeButtons.forEach(button => {
            button.addEventListener('click', function() {
                const modalId = this.getAttribute('data-close-modal');
                console.log("Closing modal:", modalId);
                closeModal(modalId);
            });
        });
        
        // Link holiday working day checkbox to shoot day checkbox
        const holidayIsWorking = document.getElementById('holiday-is-working');
        const holidayIsShootDay = document.getElementById('holiday-is-shoot-day');
        
        if (holidayIsWorking && holidayIsShootDay) {
            console.log("Setting up holiday checkbox relationship");
            holidayIsWorking.addEventListener('change', function() {
                if (!this.checked) {
                    holidayIsShootDay.checked = false;
                    holidayIsShootDay.disabled = true;
                } else {
                    holidayIsShootDay.disabled = false;
                }
            });
            
            // Initialize state
            if (!holidayIsWorking.checked) {
                holidayIsShootDay.checked = false;
                holidayIsShootDay.disabled = true;
            }
        } else {
            console.log("Holiday checkboxes not found", {
                holidayIsWorking: !!holidayIsWorking,
                holidayIsShootDay: !!holidayIsShootDay
            });
        }
    }
    
    /**
     * Open modal with specified ID
     */
    function openModal(modalId) {
        console.log("Opening modal:", modalId);
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.add('active');
            console.log("Modal opened:", modalId);
        } else {
            console.error("Modal not found:", modalId);
        }
    }
    
    /**
     * Close modal with specified ID
     */
    function closeModal(modalId) {
        console.log("Closing modal:", modalId);
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('active');
        } else {
            console.error("Modal not found:", modalId);
        }
    }
    
    /**
     * Regenerate calendar
     */
    function regenerateCalendar(projectId) {
        console.log("Regenerating calendar for project:", projectId);
        
        // Show loading state
        document.body.classList.add('loading');
        
        fetch(`/api/projects/${projectId}/calendar/generate`, {
            method: 'POST'
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Failed to regenerate calendar');
            }
            return response.json();
        })
        .then(data => {
            console.log("Calendar regenerated successfully:", data);
            
            // Show success message
            showNotification('Calendar has been regenerated successfully!', 'success');
            
            // Hide loading state
            document.body.classList.remove('loading');
        })
        .catch(error => {
            console.error('Error regenerating calendar:', error);
            alert('Error regenerating calendar: ' + error.message);
            
            // Hide loading state
            document.body.classList.remove('loading');
        });
    }
});

/**
 * Initialize the working weekend functionality
 */
function initializeWorkingWeekends() {
    console.log("Initializing working weekends...");
    
    // DOM elements
    const weekendList = document.getElementById('weekend-list');
    const noWeekends = document.getElementById('no-weekends');
    const addWeekendBtn = document.getElementById('add-weekend-btn');
    const saveWeekendBtn = document.getElementById('save-weekend-btn');
    const weekendForm = document.getElementById('weekend-form');
    const weekendModal = document.getElementById('weekend-modal');
    
    console.log("Working weekend elements:", {
        weekendList: !!weekendList,
        noWeekends: !!noWeekends,
        addWeekendBtn: !!addWeekendBtn,
        saveWeekendBtn: !!saveWeekendBtn,
        weekendForm: !!weekendForm,
        weekendModal: !!weekendModal
    });
    
    // Add button handlers if elements exist
    if (addWeekendBtn) {
        console.log("Adding click handler to Add Weekend button");
        addWeekendBtn.addEventListener('click', function() {
            console.log("Add Weekend button clicked");
            openWeekendModal();
        });
    } else {
        console.error("Add Weekend button not found");
    }
    
    if (saveWeekendBtn) {
        console.log("Adding click handler to Save Weekend button");
        saveWeekendBtn.addEventListener('click', function() {
            console.log("Save Weekend button clicked");
            saveWorkingWeekend();
        });
    } else {
        console.error("Save Weekend button not found");
    }
    
    /**
     * Open working weekend modal
     */
    function openWeekendModal(weekend = null) {
        console.log("Opening weekend modal", weekend);
        
        if (weekendForm) {
            weekendForm.reset();
            
            const weekendId = document.getElementById('weekend-id');
            const weekendDate = document.getElementById('weekend-date');
            const weekendDescription = document.getElementById('weekend-description');
            const weekendIsShootDay = document.getElementById('weekend-is-shoot-day');
            const weekendModalTitle = document.getElementById('weekend-modal-title');
            
            console.log("Weekend form elements:", {
                weekendId: !!weekendId,
                weekendDate: !!weekendDate,
                weekendDescription: !!weekendDescription,
                weekendIsShootDay: !!weekendIsShootDay,
                weekendModalTitle: !!weekendModalTitle
            });
            
            if (weekendId) weekendId.value = weekend ? weekend.id : '';
            if (weekendModalTitle) weekendModalTitle.textContent = weekend ? 'Edit Working Weekend' : 'Add Working Weekend';
            
            if (weekend) {
                if (weekendDate) weekendDate.value = weekend.date;
                if (weekendDescription) weekendDescription.value = weekend.description || '';
                if (weekendIsShootDay) weekendIsShootDay.checked = weekend.isShootDay !== false; // Default to true if not specified
            } else {
                // Set default values
                if (weekendIsShootDay) weekendIsShootDay.checked = true;
                
                if (weekendDate) {
                    // Set date to next weekend
                    const now = new Date();
                    const daysUntilSaturday = (6 - now.getDay() + 7) % 7; // Days until next Saturday
                    const nextSaturday = new Date(now);
                    nextSaturday.setDate(now.getDate() + daysUntilSaturday);
                    
                    weekendDate.value = formatDateForInput(nextSaturday);
                }
            }
            
            // Global openModal function
            if (typeof window.openModal === 'function') {
                window.openModal('weekend-modal');
            } else {
                console.error("Global openModal function not found, trying local scope");
                // Try to find openModal in local scope
                if (typeof openModal === 'function') {
                    openModal('weekend-modal');
                } else {
                    console.error("No openModal function found, manually opening modal");
                    const modal = document.getElementById('weekend-modal');
                    if (modal) modal.classList.add('active');
                }
            }
        } else {
            console.error("Weekend form not found");
        }
    }
    
    /**
     * Save working weekend
     */
    function saveWorkingWeekend() {
        console.log("Saving working weekend...");
        
        // Use global projectSelect
        if (!projectSelect) {
            console.error("projectSelect is not defined");
            projectSelect = document.getElementById('project-select');
            if (!projectSelect) {
                alert('Cannot find project selector');
                return;
            }
        }
        
        const projectId = projectSelect.value;
        if (!projectId) {
            alert('Please select a project first');
            return;
        }
        
        console.log("Project ID for saving weekend:", projectId);
        
        const weekendId = document.getElementById('weekend-id').value;
        const weekendData = {
            date: document.getElementById('weekend-date').value,
            description: document.getElementById('weekend-description').value,
            isShootDay: document.getElementById('weekend-is-shoot-day').checked
        };
        
        console.log("Weekend data to save:", weekendData);
        
        // Validate date is a weekend (Saturday or Sunday)
        const date = new Date(weekendData.date);
        const dayOfWeek = date.getDay(); // 0 is Sunday, 6 is Saturday
        
        if (dayOfWeek !== 0 && dayOfWeek !== 6) {
            alert('Please select a Saturday or Sunday date for working weekend.');
            return;
        }
        
        // Show loading state
        document.body.classList.add('loading');
        
        if (weekendId) {
            // Update existing
            weekendData.id = weekendId;
            console.log("Updating existing weekend:", weekendId);
            
            fetch(`/api/projects/${projectId}/weekends/${weekendId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(weekendData)
            })
            .then(response => {
                console.log("Update response status:", response.status);
                if (!response.ok) {
                    throw new Error('Failed to update working weekend');
                }
                return response.json();
            })
            .then(data => {
                console.log("Weekend updated successfully:", data);
                
                // Close modal - use global if available
                if (typeof window.closeModal === 'function') {
                    window.closeModal('weekend-modal');
                } else if (typeof closeModal === 'function') {
                    closeModal('weekend-modal');
                } else {
                    const modal = document.getElementById('weekend-modal');
                    if (modal) modal.classList.remove('active');
                }
                
                loadWorkingWeekends(projectId);
                
                // Show success message
                showNotification('Working weekend updated successfully', 'success');
                
                // Hide loading state
                document.body.classList.remove('loading');
            })
            .catch(error => {
                console.error('Error updating working weekend:', error);
                alert('Error updating working weekend: ' + error.message);
                
                // Hide loading state
                document.body.classList.remove('loading');
            });
        } else {
            // Create new
            console.log("Creating new weekend");
            
            fetch(`/api/projects/${projectId}/weekends`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(weekendData)
            })
            .then(response => {
                console.log("Create response status:", response.status);
                if (!response.ok) {
                    throw new Error('Failed to create working weekend');
                }
                return response.json();
            })
            .then(data => {
                console.log("Weekend created successfully:", data);
                
                // Close modal - use global if available
                if (typeof window.closeModal === 'function') {
                    window.closeModal('weekend-modal');
                } else if (typeof closeModal === 'function') {
                    closeModal('weekend-modal');
                } else {
                    const modal = document.getElementById('weekend-modal');
                    if (modal) modal.classList.remove('active');
                }
                
                loadWorkingWeekends(projectId);
                
                // Show success message
                showNotification('Working weekend added successfully', 'success');
                
                // Hide loading state
                document.body.classList.remove('loading');
            })
            .catch(error => {
                console.error('Error creating working weekend:', error);
                alert('Error creating working weekend: ' + error.message);
                
                // Hide loading state
                document.body.classList.remove('loading');
            });
        }
    }
    
    /**
     * Delete working weekend
     */
    function deleteWorkingWeekend(weekendId) {
        // Use global projectSelect
        if (!projectSelect) {
            console.error("projectSelect is not defined");
            projectSelect = document.getElementById('project-select');
            if (!projectSelect) {
                alert('Cannot find project selector');
                return;
            }
        }
        
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        console.log("Deleting weekend:", weekendId, "for project:", projectId);
        
        if (confirm('Are you sure you want to delete this working weekend?')) {
            // Show loading state
            document.body.classList.add('loading');
            
            fetch(`/api/projects/${projectId}/weekends/${weekendId}`, {
                method: 'DELETE'
            })
            .then(response => {
                console.log("Delete response status:", response.status);
                if (!response.ok) {
                    throw new Error('Failed to delete working weekend');
                }
                
                loadWorkingWeekends(projectId);
                
                // Show success message
                showNotification('Working weekend deleted successfully', 'success');
                
                // Hide loading state
                document.body.classList.remove('loading');
            })
            .catch(error => {
                console.error('Error deleting working weekend:', error);
                alert('Error deleting working weekend: ' + error.message);
                
                // Hide loading state
                document.body.classList.remove('loading');
            });
        }
    }
    
    /**
     * Load working weekends for a project
     */
    function loadWorkingWeekends(projectId) {
        console.log("Loading working weekends for project:", projectId);
        
        if (!weekendList || !noWeekends) {
            console.error("Weekend list or no weekends element not found");
            return;
        }
        
        // Show loading state
        weekendList.innerHTML = '<div class="loading-indicator">Loading...</div>';
        
        fetch(`/api/projects/${projectId}/weekends`)
            .then(response => {
                console.log("Load weekends response status:", response.status);
                if (!response.ok) {
                    // This may be a 404 if no weekends exist yet, which is fine
                    if (response.status === 404) {
                        console.log("No weekends found (404)");
                        return [];
                    }
                    throw new Error('Error loading working weekends');
                }
                return response.json();
            })
            .then(data => {
                console.log("Weekends loaded:", data);
                renderWorkingWeekends(data);
            })
            .catch(error => {
                console.error('Error loading working weekends:', error);
                renderWorkingWeekends([]);
                
                // Show error message
                showNotification('Error loading working weekends: ' + error.message, 'error');
            });
    }
    
    /**
     * Render working weekends list
     */
    function renderWorkingWeekends(weekends) {
        console.log("Rendering weekends:", weekends);
        
        if (!weekendList || !noWeekends) {
            console.error("Weekend list or no weekends element not found");
            return;
        }
        
        if (!weekends || weekends.length === 0) {
            console.log("No weekends to render");
            weekendList.style.display = 'none';
            noWeekends.style.display = 'block';
            return;
        }
        
        console.log("Rendering", weekends.length, "weekends");
        weekendList.style.display = 'block';
        noWeekends.style.display = 'none';
        
        weekendList.innerHTML = '';
        
        // Sort weekends by date (newest first)
        weekends.sort((a, b) => new Date(b.date) - new Date(a.date));
        
        weekends.forEach(weekend => {
            const dateItem = document.createElement('div');
            dateItem.className = 'date-item';
            
            const dateInfo = document.createElement('div');
            dateInfo.className = 'date-info';
            
            const dateDisplay = document.createElement('div');
            dateDisplay.className = 'date-display';
            
            // Format date display with day of week
            const weekendDate = new Date(weekend.date);
            const dayOfWeek = weekendDate.toLocaleDateString(undefined, { weekday: 'long' });
            dateDisplay.textContent = `${formatDate(weekend.date)} (${dayOfWeek})`;
            
            const dateDescription = document.createElement('div');
            dateDescription.className = 'date-description';
            dateDescription.textContent = weekend.description || 'Working weekend' + (weekend.isShootDay ? ' (counts as shoot day)' : '');
            
            dateInfo.appendChild(dateDisplay);
            dateInfo.appendChild(dateDescription);
            
            const dateAction = document.createElement('div');
            dateAction.className = 'date-action';
            
            const editButton = document.createElement('button');
            editButton.className = 'button small';
            editButton.textContent = 'Edit';
            editButton.addEventListener('click', function() {
                openWeekendModal(weekend);
            });
            
            const deleteButton = document.createElement('button');
            deleteButton.className = 'button small danger';
            deleteButton.textContent = 'Delete';
            deleteButton.addEventListener('click', function() {
                deleteWorkingWeekend(weekend.id);
            });
            
            dateAction.appendChild(editButton);
            dateAction.appendChild(deleteButton);
            
            dateItem.appendChild(dateInfo);
            dateItem.appendChild(dateAction);
            
            weekendList.appendChild(dateItem);
        });
    }
    
    // Return public methods
    return {
        loadWorkingWeekends,
        openWeekendModal
    };
}

// This would go in static/js/special-dates.js after the working weekends module
function initializeBankHolidays() {
    console.log("Initializing bank holidays...");
    
    // DOM elements
    const holidayList = document.getElementById('holiday-list');
    const noHolidays = document.getElementById('no-holidays');
    const addHolidayBtn = document.getElementById('add-holiday-btn');
    const saveHolidayBtn = document.getElementById('save-holiday-btn');
    const holidayForm = document.getElementById('holiday-form');
    const holidayModal = document.getElementById('holiday-modal');
    
    console.log("Bank holiday elements:", {
        holidayList: !!holidayList,
        noHolidays: !!noHolidays,
        addHolidayBtn: !!addHolidayBtn,
        saveHolidayBtn: !!saveHolidayBtn,
        holidayForm: !!holidayForm,
        holidayModal: !!holidayModal
    });
    
    // Add button handlers if elements exist
    if (addHolidayBtn) {
        console.log("Adding click handler to Add Holiday button");
        addHolidayBtn.addEventListener('click', function() {
            console.log("Add Holiday button clicked");
            openHolidayModal();
        });
    }
    
    if (saveHolidayBtn) {
        console.log("Adding click handler to Save Holiday button");
        saveHolidayBtn.addEventListener('click', function() {
            console.log("Save Holiday button clicked");
            saveBankHoliday();
        });
    }
    
    /**
     * Open bank holiday modal
     */
    function openHolidayModal(holiday = null) {
        console.log("Opening holiday modal", holiday);
        
        if (holidayForm) {
            holidayForm.reset();
            
            const holidayId = document.getElementById('holiday-id');
            const holidayDate = document.getElementById('holiday-date');
            const holidayName = document.getElementById('holiday-name');
            const holidayIsWorking = document.getElementById('holiday-is-working');
            const holidayIsShootDay = document.getElementById('holiday-is-shoot-day');
            const holidayModalTitle = document.getElementById('holiday-modal-title');
            
            console.log("Holiday form elements:", {
                holidayId: !!holidayId,
                holidayDate: !!holidayDate,
                holidayName: !!holidayName,
                holidayIsWorking: !!holidayIsWorking,
                holidayIsShootDay: !!holidayIsShootDay,
                holidayModalTitle: !!holidayModalTitle
            });
            
            if (holidayId) holidayId.value = holiday ? holiday.id : '';
            if (holidayModalTitle) holidayModalTitle.textContent = holiday ? 'Edit Bank Holiday' : 'Add Bank Holiday';
            
            if (holiday) {
                if (holidayDate) holidayDate.value = holiday.date;
                if (holidayName) holidayName.value = holiday.name || '';
                if (holidayIsWorking) holidayIsWorking.checked = holiday.isWorking === true;
                if (holidayIsShootDay) {
                    holidayIsShootDay.checked = holiday.isShootDay === true;
                    holidayIsShootDay.disabled = !holiday.isWorking;
                }
            } else {
                // Set default values for new holiday
                if (holidayIsWorking) holidayIsWorking.checked = false;
                if (holidayIsShootDay) {
                    holidayIsShootDay.checked = false;
                    holidayIsShootDay.disabled = true;
                }
                
                if (holidayDate) {
                    // Set date to today by default
                    const today = new Date();
                    holidayDate.value = formatDateForInput(today);
                }
            }
            
            // Use the global openModal function
            openModal('holiday-modal');
        } else {
            console.error("Holiday form not found");
        }
    }
    
    /**
     * Save bank holiday
     */
    function saveBankHoliday() {
        console.log("Saving bank holiday...");
        
        // Use global projectSelect
        if (!projectSelect) {
            console.error("projectSelect is not defined");
            projectSelect = document.getElementById('project-select');
            if (!projectSelect) {
                alert('Cannot find project selector');
                return;
            }
        }
        
        const projectId = projectSelect.value;
        if (!projectId) {
            alert('Please select a project first');
            return;
        }
        
        console.log("Project ID for saving holiday:", projectId);
        
        const holidayId = document.getElementById('holiday-id').value;
        const holidayData = {
            date: document.getElementById('holiday-date').value,
            name: document.getElementById('holiday-name').value,
            isWorking: document.getElementById('holiday-is-working').checked,
            isShootDay: document.getElementById('holiday-is-shoot-day').checked
        };
        
        console.log("Holiday data to save:", holidayData);
        
        // Validate required fields
        if (!holidayData.date) {
            alert('Please select a date for the holiday');
            return;
        }
        
        if (!holidayData.name) {
            alert('Please enter a name for the holiday');
            return;
        }
        
        // Show loading state
        document.body.classList.add('loading');
        
        if (holidayId) {
            // Update existing
            holidayData.id = holidayId;
            console.log("Updating existing holiday:", holidayId);
            
            fetch(`/api/projects/${projectId}/holidays/${holidayId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(holidayData)
            })
            .then(response => {
                console.log("Update response status:", response.status);
                if (!response.ok) {
                    throw new Error('Failed to update bank holiday');
                }
                return response.json();
            })
            .then(data => {
                console.log("Holiday updated successfully:", data);
                
                // Close modal
                closeModal('holiday-modal');
                
                loadBankHolidays(projectId);
                
                // Show success message
                showNotification('Bank holiday updated successfully', 'success');
                
                // Hide loading state
                document.body.classList.remove('loading');
            })
            .catch(error => {
                console.error('Error updating bank holiday:', error);
                alert('Error updating bank holiday: ' + error.message);
                
                // Hide loading state
                document.body.classList.remove('loading');
            });
        } else {
            // Create new
            console.log("Creating new holiday");
            
            fetch(`/api/projects/${projectId}/holidays`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(holidayData)
            })
            .then(response => {
                console.log("Create response status:", response.status);
                if (!response.ok) {
                    throw new Error('Failed to create bank holiday');
                }
                return response.json();
            })
            .then(data => {
                console.log("Holiday created successfully:", data);
                
                // Close modal
                closeModal('holiday-modal');
                
                loadBankHolidays(projectId);
                
                // Show success message
                showNotification('Bank holiday added successfully', 'success');
                
                // Hide loading state
                document.body.classList.remove('loading');
            })
            .catch(error => {
                console.error('Error creating bank holiday:', error);
                alert('Error creating bank holiday: ' + error.message);
                
                // Hide loading state
                document.body.classList.remove('loading');
            });
        }
    }
    
    /**
     * Delete bank holiday
     */
    function deleteBankHoliday(holidayId) {
        // Use global projectSelect
        if (!projectSelect) {
            console.error("projectSelect is not defined");
            projectSelect = document.getElementById('project-select');
            if (!projectSelect) {
                alert('Cannot find project selector');
                return;
            }
        }
        
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        console.log("Deleting holiday:", holidayId, "for project:", projectId);
        
        if (confirm('Are you sure you want to delete this bank holiday?')) {
            // Show loading state
            document.body.classList.add('loading');
            
            fetch(`/api/projects/${projectId}/holidays/${holidayId}`, {
                method: 'DELETE'
            })
            .then(response => {
                console.log("Delete response status:", response.status);
                if (!response.ok) {
                    throw new Error('Failed to delete bank holiday');
                }
                
                loadBankHolidays(projectId);
                
                // Show success message
                showNotification('Bank holiday deleted successfully', 'success');
                
                // Hide loading state
                document.body.classList.remove('loading');
            })
            .catch(error => {
                console.error('Error deleting bank holiday:', error);
                alert('Error deleting bank holiday: ' + error.message);
                
                // Hide loading state
                document.body.classList.remove('loading');
            });
        }
    }
    
    /**
     * Load bank holidays for a project
     */
    function loadBankHolidays(projectId) {
        console.log("Loading bank holidays for project:", projectId);
        
        if (!holidayList || !noHolidays) {
            console.error("Holiday list or no holidays element not found");
            return;
        }
        
        // Show loading state
        holidayList.innerHTML = '<div class="loading-indicator">Loading...</div>';
        
        fetch(`/api/projects/${projectId}/holidays`)
            .then(response => {
                console.log("Load holidays response status:", response.status);
                if (!response.ok) {
                    // This may be a 404 if no holidays exist yet, which is fine
                    if (response.status === 404) {
                        console.log("No holidays found (404)");
                        return [];
                    }
                    throw new Error('Error loading bank holidays');
                }
                return response.json();
            })
            .then(data => {
                console.log("Holidays loaded:", data);
                renderBankHolidays(data);
            })
            .catch(error => {
                console.error('Error loading bank holidays:', error);
                renderBankHolidays([]);
                
                // Show error message
                showNotification('Error loading bank holidays: ' + error.message, 'error');
            });
    }
    
    /**
     * Render bank holidays list
     */
    function renderBankHolidays(holidays) {
        console.log("Rendering holidays:", holidays);
        
        if (!holidayList || !noHolidays) {
            console.error("Holiday list or no holidays element not found");
            return;
        }
        
        if (!holidays || holidays.length === 0) {
            console.log("No holidays to render");
            holidayList.style.display = 'none';
            noHolidays.style.display = 'block';
            return;
        }
        
        console.log("Rendering", holidays.length, "holidays");
        holidayList.style.display = 'block';
        noHolidays.style.display = 'none';
        
        holidayList.innerHTML = '';
        
        // Sort holidays by date (newest first)
        holidays.sort((a, b) => new Date(a.date) - new Date(b.date));
        
        holidays.forEach(holiday => {
            const dateItem = document.createElement('div');
            dateItem.className = 'date-item';
            
            const dateInfo = document.createElement('div');
            dateInfo.className = 'date-info';
            
            const dateDisplay = document.createElement('div');
            dateDisplay.className = 'date-display';
            
            // Format date display with day of week
            const holidayDate = new Date(holiday.date);
            const dayOfWeek = holidayDate.toLocaleDateString(undefined, { weekday: 'long' });
            dateDisplay.textContent = `${formatDate(holiday.date)} (${dayOfWeek}) - ${holiday.name}`;
            
            const dateDescription = document.createElement('div');
            dateDescription.className = 'date-description';
            dateDescription.textContent = holiday.isWorking ? 
                (holiday.isShootDay ? 'Working holiday (counts as shoot day)' : 'Working holiday (not counted as shoot day)') : 
                'Non-working holiday';
            
            dateInfo.appendChild(dateDisplay);
            dateInfo.appendChild(dateDescription);
            
            const dateAction = document.createElement('div');
            dateAction.className = 'date-action';
            
            const editButton = document.createElement('button');
            editButton.className = 'button small';
            editButton.textContent = 'Edit';
            editButton.addEventListener('click', function() {
                openHolidayModal(holiday);
            });
            
            const deleteButton = document.createElement('button');
            deleteButton.className = 'button small danger';
            deleteButton.textContent = 'Delete';
            deleteButton.addEventListener('click', function() {
                deleteBankHoliday(holiday.id);
            });
            
            dateAction.appendChild(editButton);
            dateAction.appendChild(deleteButton);
            
            dateItem.appendChild(dateInfo);
            dateItem.appendChild(dateAction);
            
            holidayList.appendChild(dateItem);
        });
    }
    
    // Return public methods
    return {
        loadBankHolidays,
        openHolidayModal
    };
}

// Make openModal and closeModal available globally
window.openModal = function(modalId) {
    console.log("Global openModal called for:", modalId);
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('active');
    } else {
        console.error("Modal not found in global openModal:", modalId);
    }
};

window.closeModal = function(modalId) {
    console.log("Global closeModal called for:", modalId);
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
    } else {
        console.error("Modal not found in global closeModal:", modalId);
    }
};

/**
 * Helper function to show notification
 */
function showNotification(message, type = 'info') {
    console.log("Showing notification:", message, "type:", type);
    
    // Create notification element if it doesn't exist
    let notification = document.getElementById('notification');
    if (!notification) {
        notification = document.createElement('div');
        notification.id = 'notification';
        notification.className = 'notification';
        document.body.appendChild(notification);
        
        // Add style if not already in the document
        if (!document.getElementById('notification-style')) {
            const style = document.createElement('style');
            style.id = 'notification-style';
            style.textContent = `
                .notification {
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    padding: 15px 20px;
                    border-radius: 4px;
                    color: white;
                    font-weight: 500;
                    z-index: 9999;
                    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
                    opacity: 0;
                    transform: translateY(-20px);
                    transition: opacity 0.3s, transform 0.3s;
                    max-width: 300px;
                }
                .notification.visible {
                    opacity: 1;
                    transform: translateY(0);
                }
                .notification.info {
                    background-color: var(--accent-color, #3498db);
                }
                .notification.success {
                    background-color: var(--success-color, #2ecc71);
                }
                .notification.error {
                    background-color: var(--error-color, #e74c3c);
                }
                .notification.warning {
                    background-color: var(--warning-color, #f39c12);
                }
                .loading .modal-content {
                    opacity: 0.7;
                    pointer-events: none;
                }
                body.loading::after {
                    content: '';
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(255, 255, 255, 0.7);
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    z-index: 9999;
                }
                body.loading::before {
                    content: '';
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    width: 50px;
                    height: 50px;
                    border: 5px solid var(--border-color);
                    border-top-color: var(--accent-color);
                    border-radius: 50%;
                    animation: spin 1s linear infinite;
                    z-index: 10000;
                }
                @keyframes spin {
                    to { transform: translate(-50%, -50%) rotate(360deg); }
                }
            `;
            document.head.appendChild(style);
        }
    }
    
    // Set notification content and type
    notification.textContent = message;
    notification.className = `notification ${type}`;
    
    // Show notification
    setTimeout(() => {
        notification.classList.add('visible');
    }, 10);
    
    // Hide notification after a delay
    setTimeout(() => {
        notification.classList.remove('visible');
    }, 3000);
}

/**
 * Format date for display (DD/MM/YYYY)
 */
function formatDate(dateString) {
    if (!dateString) return '';
    
    const date = new Date(dateString);
    const day = date.getDate().toString().padStart(2, '0');
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const year = date.getFullYear();
    
    return `${day}/${month}/${year}`;
}

/**
 * Format date for input field (YYYY-MM-DD)
 */
function formatDateForInput(date) {
    if (!date) return '';
    
    if (typeof date === 'string') {
        date = new Date(date);
    }
    
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    
    return `${year}-${month}-${day}`;
}

console.log("Special dates JS file loaded completely");
