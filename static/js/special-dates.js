/**
 * Special Dates Management - Basic functionality
 */
document.addEventListener('DOMContentLoaded', function() {
    // Get the project selector and find the selected project ID
    const projectSelect = document.getElementById('project-select');
    
    // Only proceed if we have a project selector
    if (projectSelect) {
        projectSelect.addEventListener('change', function() {
            if (this.value) {
                window.location.href = `/admin/dates/${this.value}`;
            } else {
                window.location.href = '/admin/dates';
            }
        });
    }

    // Get buttons
    const addWeekendBtn = document.getElementById('add-weekend-btn');
    const addHolidayBtn = document.getElementById('add-holiday-btn');
    const addHiatusBtn = document.getElementById('add-hiatus-btn');
    const addSpecialBtn = document.getElementById('add-special-btn');
    const regenerateBtn = document.getElementById('regenerate-calendar-btn');

    // Add click events for the buttons
    if (addWeekendBtn) {
        addWeekendBtn.addEventListener('click', function() {
            alert('Working Weekend functionality is coming soon!');
        });
    }

    if (addHolidayBtn) {
        addHolidayBtn.addEventListener('click', function() {
            alert('Bank Holiday functionality is coming soon!');
        });
    }

    if (addHiatusBtn) {
        addHiatusBtn.addEventListener('click', function() {
            alert('Hiatus Period functionality is coming soon!');
        });
    }

    if (addSpecialBtn) {
        addSpecialBtn.addEventListener('click', function() {
            alert('Special Date functionality is coming soon!');
        });
    }

    if (regenerateBtn) {
        regenerateBtn.addEventListener('click', function() {
            alert('Calendar regeneration functionality is coming soon!');
        });
    }
});
