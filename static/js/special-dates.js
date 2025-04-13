/**
 * Special Dates Management
 * Handles working weekends, bank holidays, hiatus periods, and other special dates
 */

document.addEventListener('DOMContentLoaded', function() {
    // DOM elements
    const projectSelect = document.getElementById('project-select');
    const regenerateBtn = document.getElementById('regenerate-calendar-btn');
    
    // Form elements
    const weekendForm = document.getElementById('weekend-form');
    const holidayForm = document.getElementById('holiday-form');
    const hiatusForm = document.getElementById('hiatus-form');
    const specialForm = document.getElementById('special-form');
    
    // Button elements
    const addWeekendBtn = document.getElementById('add-weekend-btn');
    const addHolidayBtn = document.getElementById('add-holiday-btn');
    const addHiatusBtn = document.getElementById('add-hiatus-btn');
    const addSpecialBtn = document.getElementById('add-special-btn');
    
    // Initialize the page
    initializePage();
    
    /**
     * Initialize the page
     */
    function initializePage() {
        // Add event listeners
        if (projectSelect) {
            projectSelect.addEventListener('change', function() {
                if (this.value) {
                    window.location.href = `/admin/dates/${this.value}`;
                } else {
                    window.location.href = '/admin/dates';
                }
            });
        }
        
        // Init modal handlers
        initializeModals();
        
        // Load data if project is selected
        const projectId = projectSelect ? projectSelect.value : null;
        if (projectId) {
            // Load data for each section
            loadWorkingWeekends(projectId);
            loadBankHolidays(projectId);
            loadHiatusPeriods(projectId);
            
            // Add regenerate button handler
            if (regenerateBtn) {
                regenerateBtn.addEventListener('click', function() {
                    if (confirm('Are you sure you want to regenerate the calendar? This will update all shoot day numbers based on special dates.')) {
                        regenerateCalendar(projectId);
                    }
                });
            }
        }
    }
    
    /**
     * Initialize all modals
     */
    function initializeModals() {
        // Close modal buttons
        document.querySelectorAll('[data-close-modal]').forEach(button => {
            button.addEventListener('click', function() {
                const modalId = this.getAttribute('data-close-modal');
                closeModal(modalId);
            });
        });
        
        // Add button handlers
        if (addWeekendBtn) {
            addWeekendBtn.addEventListener('click', function() {
                openWeekendModal();
            });
        }
        
        if (addHolidayBtn) {
            addHolidayBtn.addEventListener('click', function() {
                openHolidayModal();
            });
        }
        
        if (addHiatusBtn) {
            addHiatusBtn.addEventListener('click', function() {
                openHiatusModal();
            });
        }
        
        if (addSpecialBtn) {
            addSpecialBtn.addEventListener('click', function() {
                openSpecialModal();
            });
        }
        
        // Save button handlers
        document.getElementById('save-weekend-btn')?.addEventListener('click', saveWorkingWeekend);
        document.getElementById('save-holiday-btn')?.addEventListener('click', saveBankHoliday);
        document.getElementById('save-hiatus-btn')?.addEventListener('click', saveHiatusPeriod);
        document.getElementById('save-special-btn')?.addEventListener('click', saveSpecialDate);
        
        // Link holiday working day checkbox to shoot day checkbox
        const holidayIsWorking = document.getElementById('holiday-is-working');
        const holidayIsShootDay = document.getElementById('holiday-is-shoot-day');
        
        if (holidayIsWorking && holidayIsShootDay) {
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
        }
    }
    
    /**
     * Open modal with specified ID
     */
    function openModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.add('active');
        }
    }
    
    /**
     * Close modal with specified ID
     */
    function closeModal(modalId) {
        const modal = document.getElementById(modalId);
        if (modal) {
            modal.classList.remove('active');
        }
    }
    
    /**
     * Open working weekend modal
     */
    function openWeekendModal(weekend = null) {
        if (weekendForm) {
            weekendForm.reset();
            
            document.getElementById('weekend-id').value = weekend ? weekend.id : '';
            document.getElementById('weekend-modal-title').textContent = weekend ? 'Edit Working Weekend' : 'Add Working Weekend';
            
            if (weekend) {
                document.getElementById('weekend-date').value = weekend.date;
                document.getElementById('weekend-description').value = weekend.description || '';
                document.getElementById('weekend-is-shoot-day').checked = weekend.isShootDay;
            } else {
                // Set default values
                document.getElementById('weekend-is-shoot-day').checked = true;
                
                // Set date to next weekend
                const now = new Date();
                const daysUntilSaturday = (6 - now.getDay() + 7) % 7; // Days until next Saturday
                const nextSaturday = new Date(now);
                nextSaturday.setDate(now.getDate() + daysUntilSaturday);
                
                document.getElementById('weekend-date').value = formatDateForInput(nextSaturday);
            }
            
            openModal('weekend-modal');
        }
    }
    
    /**
     * Open bank holiday modal
     */
    function openHolidayModal(holiday = null) {
        if (holidayForm) {
            holidayForm.reset();
            
            document.getElementById('holiday-id').value = holiday ? holiday.id : '';
            document.getElementById('holiday-modal-title').textContent = holiday ? 'Edit Bank Holiday' : 'Add Bank Holiday';
            
            if (holiday) {
                document.getElementById('holiday-date').value = holiday.date;
                document.getElementById('holiday-name').value = holiday.name;
                document.getElementById('holiday-is-working').checked = holiday.isWorking;
                document.getElementById('holiday-is-shoot-day').checked = holiday.isShootDay;
                
                // Update shoot day checkbox state
                if (!holiday.isWorking) {
                    document.getElementById('holiday-is-shoot-day').disabled = true;
                }
            } else {
                // Set default values
                document.getElementById('holiday-is-working').checked = false;
                document.getElementById('holiday-is-shoot-day').checked = false;
                document.getElementById('holiday-is-shoot-day').disabled = true;
            }
            
            openModal('holiday-modal');
        }
    }
    
    /**
     * Open hiatus period modal
     */
    function openHiatusModal(hiatus = null) {
        if (hiatusForm) {
            hiatusForm.reset();
            
            document.getElementById('hiatus-id').value = hiatus ? hiatus.id : '';
            document.getElementById('hiatus-modal-title').textContent = hiatus ? 'Edit Hiatus Period' : 'Add Hiatus Period';
            
            if (hiatus) {
                document.getElementById('hiatus-name').value = hiatus.name;
                document.getElementById('hiatus-start-date').value = hiatus.startDate;
                document.getElementById('hiatus-end-date').value = hiatus.endDate;
                document.getElementById('hiatus-description').value = hiatus.description || '';
                document.getElementById('hiatus-is-visible').checked = hiatus.isVisible;
            } else {
                // Set default values
                document.getElementById('hiatus-is-visible').checked = true;
            }
            
            openModal('hiatus-modal');
        }
    }
    
    /**
     * Open special date modal
     */
    function openSpecialModal(specialDate = null) {
        if (specialForm) {
            specialForm.reset();
            
            document.getElementById('special-id').value = specialDate ? specialDate.id : '';
            document.getElementById('special-modal-title').textContent = specialDate ? 'Edit Special Date' : 'Add Special Date';
            
            if (specialDate) {
                document.getElementById('special-date').value = specialDate.date;
                document.getElementById('special-name').value = specialDate.name;
                document.getElementById('special-type').value = specialDate.type;
                document.getElementById('special-description').value = specialDate.description || '';
                document.getElementById('special-is-working').checked = specialDate.isWorking;
            } else {
                // Set default values
                document.getElementById('special-is-working').checked = true;
                document.getElementById('special-type').value = 'travel';
            }
            
            openModal('special-modal');
        }
    }
    
    /**
     * Load working weekends for a project
     */
    function loadWorkingWeekends(projectId) {
        fetch(`/api/projects/${projectId}/weekends`)
            .then(response => {
                if (!response.ok) {
                    // This may be a 404 if no weekends exist yet, which is fine
                    if (response.status === 404) {
                        return [];
                    }
                    throw new Error('Error loading working weekends');
                }
                return response.json();
            })
            .then(data => {
                renderWorkingWeekends(data);
            })
            .catch(error => {
                console.error('Error loading working weekends:', error);
                renderWorkingWeekends([]);
            });
    }
    
    /**
     * Load bank holidays for a project
     */
    function loadBankHolidays(projectId) {
        fetch(`/api/projects/${projectId}/holidays`)
            .then(response => {
                if (!response.ok) {
                    if (response.status === 404) {
                        return [];
                    }
                    throw new Error('Error loading bank holidays');
                }
                return response.json();
            })
            .then(data => {
                renderBankHolidays(data);
            })
            .catch(error => {
                console.error('Error loading bank holidays:', error);
                renderBankHolidays([]);
            });
    }
    
    /**
     * Load hiatus periods for a project
     */
    function loadHiatusPeriods(projectId) {
        fetch(`/api/projects/${projectId}/hiatus`)
            .then(response => {
                if (!response.ok) {
                    if (response.status === 404) {
                        return [];
                    }
                    throw new Error('Error loading hiatus periods');
                }
                return response.json();
            })
            .then(data => {
                renderHiatusPeriods(data);
            })
            .catch(error => {
                console.error('Error loading hiatus periods:', error);
                renderHiatusPeriods([]);
            });
    }
    
    /**
     * Render working weekends list
     */
    function renderWorkingWeekends(weekends) {
        const weekendList = document.getElementById('weekend-list');
        const noWeekends = document.getElementById('no-weekends');
        
        if (!weekendList || !noWeekends) return;
        
        if (!weekends || weekends.length === 0) {
            weekendList.style.display = 'none';
            noWeekends.style.display = 'block';
            return;
        }
        
        weekendList.style.display = 'block';
        noWeekends.style.display = 'none';
        
        weekendList.innerHTML = '';
        
        weekends.forEach(weekend => {
            const dateItem = document.createElement('div');
            dateItem.className = 'date-item';
            
            const dateInfo = document.createElement('div');
            dateInfo.className = 'date-info';
            
            const dateDisplay = document.createElement('div');
            dateDisplay.className = 'date-display';
            dateDisplay.textContent = formatDate(weekend.date);
            
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
    
    /**
     * Render bank holidays list
     */
    function renderBankHolidays(holidays) {
        const holidayList = document.getElementById('holiday-list');
        const noHolidays = document.getElementById('no-holidays');
        
        if (!holidayList || !noHolidays) return;
        
        if (!holidays || holidays.length === 0) {
            holidayList.style.display = 'none';
            noHolidays.style.display = 'block';
            return;
        }
        
        holidayList.style.display = 'block';
        noHolidays.style.display = 'none';
        
        holidayList.innerHTML = '';
        
        holidays.forEach(holiday => {
            const dateItem = document.createElement('div');
            dateItem.className = 'date-item';
            
            const dateInfo = document.createElement('div');
            dateInfo.className = 'date-info';
            
            const dateDisplay = document.createElement('div');
            dateDisplay.className = 'date-display';
            dateDisplay.textContent = `${formatDate(holiday.date)} - ${holiday.name}`;
            
            const dateDescription = document.createElement('div');
            dateDescription.className = 'date-description';
            dateDescription.textContent = holiday.isWorking ? 'Working day' + (holiday.isShootDay ? ' (counts as shoot day)' : '') : 'Non-working holiday';
            
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
    
    /**
     * Render hiatus periods list
     */
    function renderHiatusPeriods(hiatusPeriods) {
        const hiatusList = document.getElementById('hiatus-list');
        const noHiatus = document.getElementById('no-hiatus');
        
        if (!hiatusList || !noHiatus) return;
        
        if (!hiatusPeriods || hiatusPeriods.length === 0) {
            hiatusList.style.display = 'none';
            noHiatus.style.display = 'block';
            return;
        }
        
        hiatusList.style.display = 'block';
        noHiatus.style.display = 'none';
        
        hiatusList.innerHTML = '';
        
        hiatusPeriods.forEach(hiatus => {
            const hiatusItem = document.createElement('div');
            hiatusItem.className = 'hiatus-period';
            
            const hiatusInfo = document.createElement('div');
            hiatusInfo.className = 'hiatus-dates';
            
            const hiatusLabel = document.createElement('div');
            hiatusLabel.className = 'hiatus-label';
            hiatusLabel.textContent = hiatus.name;
            
            const hiatusRange = document.createElement('div');
            hiatusRange.className = 'hiatus-range';
            hiatusRange.textContent = `${formatDate(hiatus.startDate)} to ${formatDate(hiatus.endDate)}`;
            
            const hiatusVisibility = document.createElement('div');
            hiatusVisibility.className = 'hiatus-visibility';
            hiatusVisibility.innerHTML = hiatus.isVisible ? '<span style="color: var(--success-color);">●</span> Visible on calendar' : '<span style="color: var(--text-light);">○</span> Hidden on calendar';
            
            hiatusInfo.appendChild(hiatusLabel);
            hiatusInfo.appendChild(hiatusRange);
            hiatusInfo.appendChild(hiatusVisibility);
            
            const hiatusAction = document.createElement('div');
            hiatusAction.className = 'date-action';
            
            const editButton = document.createElement('button');
            editButton.className = 'button small';
            editButton.textContent = 'Edit';
            editButton.addEventListener('click', function() {
                openHiatusModal(hiatus);
            });
            
            const deleteButton = document.createElement('button');
            deleteButton.className = 'button small danger';
            deleteButton.textContent = 'Delete';
            deleteButton.addEventListener('click', function() {
                deleteHiatusPeriod(hiatus.id);
            });
            
            hiatusAction.appendChild(editButton);
            hiatusAction.appendChild(deleteButton);
            
            hiatusItem.appendChild(hiatusInfo);
            hiatusItem.appendChild(hiatusAction);
            
            hiatusList.appendChild(hiatusItem);
        });
    }
    
    /**
     * Save working weekend
     */
    function saveWorkingWeekend() {
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        const weekendId = document.getElementById('weekend-id').value;
        const weekendData = {
            date: document.getElementById('weekend-date').value,
            description: document.getElementById('weekend-description').value,
            isShootDay: document.getElementById('weekend-is-shoot-day').checked
        };
        
        // Validate date is a weekend (Saturday or Sunday)
        const date = new Date(weekendData.date);
        const dayOfWeek = date.getDay(); // 0 is Sunday, 6 is Saturday
        
        if (dayOfWeek !== 0 && dayOfWeek !== 6) {
            alert('Please select a Saturday or Sunday date for working weekend.');
            return;
        }
        
        if (weekendId) {
            // Update existing
            weekendData.id = weekendId;
            fetch(`/api/projects/${projectId}/weekends/${weekendId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(weekendData)
            })
            .then(response => response.json())
            .then(data => {
                closeModal('weekend-modal');
                loadWorkingWeekends(projectId);
            })
            .catch(error => {
                console.error('Error updating working weekend:', error);
                alert('Error updating working weekend');
            });
        } else {
            // Create new
            fetch(`/api/projects/${projectId}/weekends`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(weekendData)
            })
            .then(response => response.json())
            .then(data => {
                closeModal('weekend-modal');
                loadWorkingWeekends(projectId);
            })
            .catch(error => {
                console.error('Error creating working weekend:', error);
                alert('Error creating working weekend');
            });
        }
    }
    
    /**
     * Save bank holiday
     */
    function saveBankHoliday() {
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        const holidayId = document.getElementById('holiday-id').value;
        const holidayData = {
            date: document.getElementById('holiday-date').value,
            name: document.getElementById('holiday-name').value,
            isWorking: document.getElementById('holiday-is-working').checked,
            isShootDay: document.getElementById('holiday-is-shoot-day').checked
        };
        
        // Validate form
        if (!holidayData.date || !holidayData.name) {
            alert('Please fill out all required fields.');
            return;
        }
        
        if (holidayId) {
            // Update existing
            holidayData.id = holidayId;
            fetch(`/api/projects/${projectId}/holidays/${holidayId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(holidayData)
            })
            .then(response => response.json())
            .then(data => {
                closeModal('holiday-modal');
                loadBankHolidays(projectId);
            })
            .catch(error => {
                console.error('Error updating bank holiday:', error);
                alert('Error updating bank holiday');
            });
        } else {
            // Create new
            fetch(`/api/projects/${projectId}/holidays`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(holidayData)
            })
            .then(response => response.json())
            .then(data => {
                closeModal('holiday-modal');
                loadBankHolidays(projectId);
            })
            .catch(error => {
                console.error('Error creating bank holiday:', error);
                alert('Error creating bank holiday');
            });
        }
    }
    
    /**
     * Save hiatus period
     */
    function saveHiatusPeriod() {
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        const hiatusId = document.getElementById('hiatus-id').value;
        const hiatusData = {
            name: document.getElementById('hiatus-name').value,
            startDate: document.getElementById('hiatus-start-date').value,
            endDate: document.getElementById('hiatus-end-date').value,
            description: document.getElementById('hiatus-description').value,
            isVisible: document.getElementById('hiatus-is-visible').checked
        };
        
        // Validate form
        if (!hiatusData.name || !hiatusData.startDate || !hiatusData.endDate) {
            alert('Please fill out all required fields.');
            return;
        }
        
        // Validate date range
        const startDate = new Date(hiatusData.startDate);
        const endDate = new Date(hiatusData.endDate);
        
        if (startDate > endDate) {
            alert('End date cannot be before start date.');
            return;
        }
        
        if (hiatusId) {
            // Update existing
            hiatusData.id = hiatusId;
            fetch(`/api/projects/${projectId}/hiatus/${hiatusId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(hiatusData)
            })
            .then(response => response.json())
            .then(data => {
                closeModal('hiatus-modal');
                loadHiatusPeriods(projectId);
            })
            .catch(error => {
                console.error('Error updating hiatus period:', error);
                alert('Error updating hiatus period');
            });
        } else {
            // Create new
            fetch(`/api/projects/${projectId}/hiatus`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(hiatusData)
            })
            .then(response => response.json())
            .then(data => {
                closeModal('hiatus-modal');
                loadHiatusPeriods(projectId);
            })
            .catch(error => {
                console.error('Error creating hiatus period:', error);
                alert('Error creating hiatus period');
            });
        }
    }
    
    /**
     * Save special date
     */
    function saveSpecialDate() {
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        const specialId = document.getElementById('special-id').value;
        const specialData = {
            date: document.getElementById('special-date').value,
            name: document.getElementById('special-name').value,
            type: document.getElementById('special-type').value,
            description: document.getElementById('special-description').value,
            isWorking: document.getElementById('special-is-working').checked
        };
        
        // Validate form
        if (!specialData.date || !specialData.name || !specialData.type) {
            alert('Please fill out all required fields.');
            return;
        }
        
        if (specialId) {
            // Update existing
            specialData.id = specialId;
            fetch(`/api/projects/${projectId}/special-dates/${specialId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(specialData)
            })
            .then(response => response.json())
            .then(data => {
                closeModal('special-modal');
                loadSpecialDates(projectId);
            })
            .catch(error => {
                console.error('Error updating special date:', error);
                alert('Error updating special date');
            });
        } else {
            // Create new
            fetch(`/api/projects/${projectId}/special-dates`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(specialData)
            })
            .then(response => response.json())
            .then(data => {
                closeModal('special-modal');
                loadSpecialDates(projectId);
            })
            .catch(error => {
                console.error('Error creating special date:', error);
                alert('Error creating special date');
            });
        }
    }
    
    /**
     * Delete working weekend
     */
    function deleteWorkingWeekend(weekendId) {
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        if (confirm('Are you sure you want to delete this working weekend?')) {
            fetch(`/api/projects/${projectId}/weekends/${weekendId}`, {
                method: 'DELETE'
            })
            .then(response => {
                if (response.ok) {
                    loadWorkingWeekends(projectId);
                } else {
                    throw new Error('Error deleting working weekend');
                }
            })
            .catch(error => {
                console.error('Error deleting working weekend:', error);
                alert('Error deleting working weekend');
            });
        }
    }
    
    /**
     * Delete bank holiday
     */
    function deleteBankHoliday(holidayId) {
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        if (confirm('Are you sure you want to delete this bank holiday?')) {
            fetch(`/api/projects/${projectId}/holidays/${holidayId}`, {
                method: 'DELETE'
            })
            .then(response => {
                if (response.ok) {
                    loadBankHolidays(projectId);
                } else {
                    throw new Error('Error deleting bank holiday');
                }
            })
            .catch(error => {
                console.error('Error deleting bank holiday:', error);
                alert('Error deleting bank holiday');
            });
        }
    }
    
    /**
     * Delete hiatus period
     */
    function deleteHiatusPeriod(hiatusId) {
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        if (confirm('Are you sure you want to delete this hiatus period?')) {
            fetch(`/api/projects/${projectId}/hiatus/${hiatusId}`, {
                method: 'DELETE'
            })
            .then(response => {
                if (response.ok) {
                    loadHiatusPeriods(projectId);
                } else {
                    throw new Error('Error deleting hiatus period');
                }
            })
            .catch(error => {
                console.error('Error deleting hiatus period:', error);
                alert('Error deleting hiatus period');
            });
        }
    }
    
    /**
     * Delete special date
     */
    function deleteSpecialDate(specialId) {
        const projectId = projectSelect.value;
        if (!projectId) return;
        
        if (confirm('Are you sure you want to delete this special date?')) {
            fetch(`/api/projects/${projectId}/special-dates/${specialId}`, {
                method: 'DELETE'
            })
            .then(response => {
                if (response.ok) {
                    loadSpecialDates(projectId);
                } else {
                    throw new Error('Error deleting special date');
                }
            })
            .catch(error => {
                console.error('Error deleting special date:', error);
                alert('Error deleting special date');
            });
        }
    }
    
    /**
     * Regenerate calendar
     */
    function regenerateCalendar(projectId) {
        fetch(`/api/projects/${projectId}/calendar/generate`, {
            method: 'POST'
        })
        .then(response => response.json())
        .then(data => {
            alert('Calendar has been regenerated successfully!');
        })
        .catch(error => {
            console.error('Error regenerating calendar:', error);
            alert('Error regenerating calendar');
        });
    }
    
    /**
     * Format date for display
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
     * Format date for input field
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
});
