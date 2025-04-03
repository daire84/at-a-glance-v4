document.addEventListener('DOMContentLoaded', function() {
    // Location dropdown functionality
    const locationSelect = document.getElementById('location');
    const locationAreaDisplay = document.getElementById('location-area-display');
    
    if (locationSelect) {
        // Fetch locations from API
        fetchLocations();
        
        // Handle location selection change
        locationSelect.addEventListener('change', function() {
            updateLocationArea(this.value);
        });
    }
    
    // Department tags functionality
    initializeDepartmentTags();
    
    // Function to fetch locations from API
    function fetchLocations() {
        fetch('/api/locations')
            .then(response => response.json())
            .then(locations => {
                populateLocationDropdown(locations);
                
                // If a location is already selected, update the area
                if (locationSelect.value) {
                    updateLocationArea(locationSelect.value);
                }
            })
            .catch(error => {
                console.error('Error fetching locations:', error);
            });
    }
    
    // Function to populate location dropdown
    function populateLocationDropdown(locations) {
        // Save current selection
        const currentSelection = locationSelect.value;
        
        // Clear existing options except the first one (placeholder)
        while (locationSelect.options.length > 1) {
            locationSelect.remove(1);
        }
        
        // Sort locations by name
        locations.sort((a, b) => a.name.localeCompare(b.name));
        
        // Add location options
        locations.forEach(location => {
            const option = document.createElement('option');
            option.value = location.name;
            option.textContent = location.name;
            option.setAttribute('data-area-id', location.areaId || '');
            locationSelect.appendChild(option);
        });
        
        // Restore selection if it exists
        if (currentSelection) {
            locationSelect.value = currentSelection;
        }
    }
    
    // Function to update location area based on selection
    function updateLocationArea(locationName) {
        if (!locationName) {
            locationAreaDisplay.textContent = '';
            document.getElementById('locationArea').value = '';
            return;
        }
        
        // Find the selected option
        const selectedOption = Array.from(locationSelect.options).find(option => option.value === locationName);
        
        if (selectedOption) {
            const areaId = selectedOption.getAttribute('data-area-id');
            
            // If area ID exists, fetch area details
            if (areaId) {
                fetch(`/api/areas/${areaId}`)
                    .then(response => response.json())
                    .then(area => {
                        locationAreaDisplay.textContent = area.name || '';
                        document.getElementById('locationArea').value = area.name || '';
                    })
                    .catch(error => {
                        console.error('Error fetching area details:', error);
                    });
            } else {
                locationAreaDisplay.textContent = '';
                document.getElementById('locationArea').value = '';
            }
        }
    }
});
// Department tag selection functionality
function initializeDepartmentTags() {
    const departmentsInput = document.getElementById('departments');
    const selectedDepartmentsContainer = document.getElementById('selected-departments');
    const departmentTagSelector = document.getElementById('department-tag-selector');
    
    if (!departmentsInput || !selectedDepartmentsContainer || !departmentTagSelector) {
        return;
    }
    
    let selectedDepartments = departmentsInput.value ? departmentsInput.value.split(',') : [];
    
    // Fetch departments
    fetch('/api/departments')
        .then(response => response.json())
        .then(departments => {
            // Populate department tag selector
            populateDepartmentTags(departments);
            
            // Display currently selected departments
            updateSelectedDepartments();
        })
        .catch(error => {
            console.error('Error fetching departments:', error);
        });
    
    // Function to populate department tags
    function populateDepartmentTags(departments) {
        // Sort departments by name
        departments.sort((a, b) => a.name.localeCompare(b.name));
        
        // Create department tag options
        departments.forEach(department => {
            const tagOption = document.createElement('div');
            tagOption.className = 'department-tag-option';
            tagOption.dataset.code = department.code;
            tagOption.style.backgroundColor = department.color;
            tagOption.textContent = department.code;
            
            // Set text color based on background brightness
            const rgb = hexToRgb(department.color);
            if (rgb) {
                const brightness = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
                tagOption.style.color = brightness > 128 ? '#000000' : '#ffffff';
            }
            
            // Mark as selected if already in the list
            if (selectedDepartments.includes(department.code)) {
                tagOption.classList.add('selected');
            }
            
            // Add click event to toggle selection
            tagOption.addEventListener('click', function() {
                toggleDepartment(department.code, department.color);
            });
            
            departmentTagSelector.appendChild(tagOption);
        });
    }
    
    // Function to toggle department selection
    function toggleDepartment(code, color) {
        const index = selectedDepartments.indexOf(code);
        
        if (index === -1) {
            // Add department
            selectedDepartments.push(code);
        } else {
            // Remove department
            selectedDepartments.splice(index, 1);
        }
        
        // Update input value and display
        departmentsInput.value = selectedDepartments.join(',');
        updateSelectedDepartments();
        
        // Update tag selector UI
        const tagOption = departmentTagSelector.querySelector(`[data-code="${code}"]`);
        if (tagOption) {
            tagOption.classList.toggle('selected');
        }
    }
    
    // Function to update selected departments display
    function updateSelectedDepartments() {
        selectedDepartmentsContainer.innerHTML = '';
        
        if (selectedDepartments.length === 0) {
            const emptyText = document.createElement('em');
            emptyText.className = 'text-muted';
            emptyText.textContent = 'No departments selected';
            selectedDepartmentsContainer.appendChild(emptyText);
            return;
        }
        
        // Get department details for selected codes
        fetch('/api/departments')
            .then(response => response.json())
            .then(departments => {
                // Create a map of department codes to details
                const departmentMap = {};
                departments.forEach(dept => {
                    departmentMap[dept.code] = dept;
                });
                
                // Create tag for each selected department
                selectedDepartments.forEach(code => {
                    const dept = departmentMap[code];
                    if (!dept) return;
                    
                    const tag = document.createElement('div');
                    tag.className = 'selected-department';
                    tag.style.backgroundColor = dept.color;
                    
                    // Set text color based on background brightness
                    const rgb = hexToRgb(dept.color);
                    if (rgb) {
                        const brightness = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
                        tag.style.color = brightness > 128 ? '#000000' : '#ffffff';
                    }
                    
                    // Department code
                    const codeSpan = document.createElement('span');
                    codeSpan.textContent = code;
                    tag.appendChild(codeSpan);
                    
                    // Remove button
                    const removeBtn = document.createElement('span');
                    removeBtn.className = 'remove-tag';
                    removeBtn.innerHTML = '&times;';
                    removeBtn.addEventListener('click', function(e) {
                        e.stopPropagation();
                        toggleDepartment(code);
                    });
                    tag.appendChild(removeBtn);
                    
                    selectedDepartmentsContainer.appendChild(tag);
                });
            })
            .catch(error => {
                console.error('Error fetching department details:', error);
            });
    }
}

// Helper function to convert hex color to RGB
function hexToRgb(hex) {
    if (!hex) return null;
    
    const shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
    hex = hex.replace(shorthandRegex, function(m, r, g, b) {
        return r + r + g + g + b + b;
    });
    
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
    } : null;
}

// Initialize form submission
const dayForm = document.querySelector('.day-form');
if (dayForm) {
    dayForm.addEventListener('submit', function(e) {
        // Form is already set up to submit departments as a hidden input
        // We just need to make sure the locationArea is properly set
        
        // If location is selected but locationArea is empty, try to set it
        const locationSelect = document.getElementById('location');
        const locationAreaInput = document.getElementById('locationArea');
        const locationAreaDisplay = document.getElementById('location-area-display');
        
        if (locationSelect.value && !locationAreaInput.value) {
            // Set locationArea to what's displayed, if anything
            locationAreaInput.value = locationAreaDisplay.textContent.trim();
        }
    });
}