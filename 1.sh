#!/bin/bash
# Create a new Git branch for navigation improvements with correct path

cd /mnt/user/appdata/film-scheduler-v4
git checkout main  # First go back to main branch
git checkout -b feature/navigation-improvements

# Update the departments management page to add consistent tab navigation
cat > /mnt/user/appdata/film-scheduler-v4/templates/admin/departments.html << 'EOF'
{% extends "base.html" %}

{% block title %}Department Management - Schedule, At a Glance!{% endblock %}

{% block styles %}
<link rel="stylesheet" href="/static/css/forms.css">
<style>
  /* Admin navigation tabs */
  .admin-tabs {
    display: flex;
    margin-bottom: 1.5rem;
    border-bottom: 1px solid var(--border-color);
    overflow-x: auto;
  }
  
  .admin-tabs a {
    padding: 0.6rem 1rem;
    color: var(--text-color);
    text-decoration: none;
    border-bottom: 2px solid transparent;
    font-weight: 500;
    font-size: 0.9rem;
    white-space: nowrap;
  }
  
  .admin-tabs a.active,
  .admin-tabs a:hover {
    color: var(--accent-color);
    border-bottom-color: var(--accent-color);
  }

  .department-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 1rem;
    margin-top: 1rem;
  }
  
  .department-card {
    background-color: white;
    border-radius: 6px;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
    overflow: hidden;
  }
  
  .department-header {
    padding: 0.8rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .department-color-bar {
    height: 6px;
  }
  
  .department-content {
    padding: 0.8rem;
  }
  
  .department-name {
    font-size: 1.1rem;
    font-weight: 500;
    margin-bottom: 0.4rem;
  }
  
  .department-code {
    display: inline-block;
    background-color: #f5f5f5;
    padding: 0.2rem 0.4rem;
    border-radius: 3px;
    font-size: 0.85rem;
    font-weight: 500;
    margin-bottom: 0.6rem;
  }
  
  .department-description {
    color: var(--text-light);
    margin-bottom: 0.8rem;
    font-size: 0.9rem;
  }
  
  .department-actions {
    border-top: 1px solid var(--border-color);
    padding: 0.6rem 0.8rem;
    display: flex;
    justify-content: flex-end;
    gap: 0.4rem;
  }
  
  .department-tag-preview {
    display: inline-block;
    padding: 0.15rem 0.4rem;
    border-radius: 3px;
    font-size: 0.8rem;
    font-weight: 500;
    margin-top: 0.4rem;
  }
  
  .modal {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    opacity: 0;
    visibility: hidden;
    transition: opacity 0.3s, visibility 0.3s;
  }
  
  .modal.active {
    opacity: 1;
    visibility: visible;
  }
  
  .modal-content {
    background-color: white;
    border-radius: 6px;
    box-shadow: 0 3px 10px rgba(0, 0, 0, 0.15);
    width: 100%;
    max-width: 480px;
    max-height: 90vh;
    overflow-y: auto;
  }
  
  .modal-header {
    padding: 1rem;
    border-bottom: 1px solid var(--border-color);
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .modal-header h3 {
    margin: 0;
    font-size: 1.1rem;
  }
  
  .modal-body {
    padding: 1rem;
  }
  
  .modal-footer {
    padding: 1rem;
    border-top: 1px solid var(--border-color);
    display: flex;
    justify-content: flex-end;
    gap: 0.6rem;
  }
  
  .tag-preview-label {
    display: block;
    margin-bottom: 0.4rem;
    font-weight: 500;
    font-size: 0.9rem;
  }
</style>
{% endblock %}

{% block content %}
<div class="admin-header">
    <h2>Department Management</h2>
    <div class="admin-actions">
        <button id="add-department-btn" class="button">Add Department</button>
        <a href="/admin" class="button secondary">Back to Dashboard</a>
    </div>
</div>

<!-- Admin Navigation Tabs -->
<div class="admin-tabs">
    <a href="/admin">Projects</a>
    <a href="/admin/locations">Locations</a>
    <a href="/admin/departments" class="active">Departments</a>
    <a href="/admin/dates">Special Dates</a>
</div>

<div class="content-container">
    <p>Manage departments and their tag appearance on the calendar. Department tags allow you to track how many days each department is needed.</p>
    
    <div class="department-grid" id="department-grid">
        <!-- Department cards will be added here dynamically -->
    </div>
    
    <div id="no-departments" class="empty-state">
        <p>No departments have been added yet.</p>
        <p>Click "Add Department" to create your first department.</p>
    </div>
</div>

<!-- Department Modal -->
<div id="department-modal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h3 id="department-modal-title">Add Department</h3>
            <button class="close-button" data-close-modal="department-modal">&times;</button>
        </div>
        <div class="modal-body">
            <form id="department-form">
                <input type="hidden" id="department-id" name="id" value="">
                
                <div class="form-row">
                    <div class="form-group">
                        <label for="department-name">Department Name</label>
                        <input type="text" id="department-name" name="name" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="department-code">Code (2-4 letters)</label>
                        <input type="text" id="department-code" name="code" required maxlength="4" pattern="[A-Za-z]{2,4}">
                        <div class="field-hint">Short code used on calendar (e.g., SFX, STN)</div>
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="department-description">Description (Optional)</label>
                    <textarea id="department-description" name="description" rows="2"></textarea>
                </div>
                
                <div class="form-group">
                    <label for="department-color">Tag Color</label>
                    <input type="color" id="department-color" name="color" value="#d4e9ff">
                </div>
                
                <div class="form-group">
                    <span class="tag-preview-label">Tag Preview:</span>
                    <span class="department-tag-preview" id="tag-preview">TAG</span>
                </div>
            </form>
        </div>
        <div class="modal-footer">
            <button class="button secondary" data-close-modal="department-modal">Cancel</button>
            <button class="button" id="save-department-btn">Save Department</button>
        </div>
    </div>
</div>
{% endblock %}

{% block scripts %}
<script>
document.addEventListener('DOMContentLoaded', function() {
    // DOM elements
    const departmentGrid = document.getElementById('department-grid');
    const noDepartmentsEl = document.getElementById('no-departments');
    
    // Department modal elements
    const departmentModal = document.getElementById('department-modal');
    const departmentModalTitle = document.getElementById('department-modal-title');
    const departmentForm = document.getElementById('department-form');
    const departmentIdInput = document.getElementById('department-id');
    const departmentNameInput = document.getElementById('department-name');
    const departmentCodeInput = document.getElementById('department-code');
    const departmentDescriptionInput = document.getElementById('department-description');
    const departmentColorInput = document.getElementById('department-color');
    const tagPreview = document.getElementById('tag-preview');
    
    // Data storage
    let departments = [];
    
    // Fetch data
    fetchDepartments();
    
    // Button event listeners
    document.getElementById('add-department-btn').addEventListener('click', function() {
        openDepartmentModal();
    });
    
    document.getElementById('save-department-btn').addEventListener('click', function() {
        saveDepartment();
    });
    
    // Close modal buttons
    document.querySelectorAll('[data-close-modal]').forEach(button => {
        button.addEventListener('click', function() {
            const modalId = this.getAttribute('data-close-modal');
            document.getElementById(modalId).classList.remove('active');
        });
    });
    
    // Live preview of department tag
    departmentCodeInput.addEventListener('input', updateTagPreview);
    departmentColorInput.addEventListener('input', updateTagPreview);
    
    function updateTagPreview() {
        tagPreview.textContent = departmentCodeInput.value.toUpperCase();
        tagPreview.style.backgroundColor = departmentColorInput.value;
        
        // Set text color based on background color brightness
        const color = departmentColorInput.value;
        const r = parseInt(color.substr(1, 2), 16);
        const g = parseInt(color.substr(3, 2), 16);
        const b = parseInt(color.substr(5, 2), 16);
        const brightness = (r * 299 + g * 587 + b * 114) / 1000;
        
        tagPreview.style.color = brightness > 128 ? '#000000' : '#ffffff';
    }
    
    // Functions
    
    // Fetch departments from the server
    function fetchDepartments() {
        fetch('/api/departments')
            .then(response => response.json())
            .then(data => {
                departments = data;
                renderDepartments();
            })
            .catch(error => {
                console.error('Error fetching departments:', error);
                alert('Failed to load departments. Please try again.');
            });
    }
    
    // Render department cards
    function renderDepartments() {
        departmentGrid.innerHTML = '';
        
        if (departments.length === 0) {
            departmentGrid.style.display = 'none';
            noDepartmentsEl.style.display = 'block';
            return;
        }
        
        departmentGrid.style.display = 'grid';
        noDepartmentsEl.style.display = 'none';
        
        departments.forEach(department => {
            const departmentCard = document.createElement('div');
            departmentCard.className = 'department-card';
            
            // Set text color based on background color brightness
            const color = department.color;
            const r = parseInt(color.substr(1, 2), 16);
            const g = parseInt(color.substr(3, 2), 16);
            const b = parseInt(color.substr(5, 2), 16);
            const brightness = (r * 299 + g * 587 + b * 114) / 1000;
            const textColor = brightness > 128 ? '#000000' : '#ffffff';
            
            departmentCard.innerHTML = `
                <div class="department-color-bar" style="background-color: ${department.color}"></div>
                <div class="department-header">
                    <h4 class="department-name">${department.name}</h4>
                    <span class="department-tag-preview" style="background-color: ${department.color}; color: ${textColor};">${department.code}</span>
                </div>
                <div class="department-content">
                    <div class="department-description">${department.description || 'No description provided.'}</div>
                </div>
                <div class="department-actions">
                    <button class="button small edit-department" data-id="${department.id}">Edit</button>
                    <button class="button small danger delete-department" data-id="${department.id}">Delete</button>
                </div>
            `;
            
            departmentGrid.appendChild(departmentCard);
        });
        
        // Add event listeners to edit/delete buttons
        document.querySelectorAll('.edit-department').forEach(button => {
            button.addEventListener('click', function() {
                const departmentId = this.getAttribute('data-id');
                editDepartment(departmentId);
            });
        });
        
        document.querySelectorAll('.delete-department').forEach(button => {
            button.addEventListener('click', function() {
                const departmentId = this.getAttribute('data-id');
                deleteDepartment(departmentId);
            });
        });
    }
    
    // Open department modal for adding a new department
    function openDepartmentModal(department = null) {
        departmentModalTitle.textContent = department ? 'Edit Department' : 'Add Department';
        
        // Reset form
        departmentForm.reset();
        
        if (department) {
            // Fill form with department data
            departmentIdInput.value = department.id;
            departmentNameInput.value = department.name;
            departmentCodeInput.value = department.code;
            departmentDescriptionInput.value = department.description || '';
            departmentColorInput.value = department.color;
        } else {
            departmentIdInput.value = '';
            // Set default color
            departmentColorInput.value = '#d4e9ff';
        }
        
        // Update tag preview
        updateTagPreview();
        
        // Show modal
        departmentModal.classList.add('active');
    }
    
    // Edit department
    function editDepartment(departmentId) {
        const department = departments.find(dept => dept.id === departmentId);
        if (department) {
            openDepartmentModal(department);
        }
    }
    
    // Save department
    function saveDepartment() {
        // Validate form
        if (!departmentForm.checkValidity()) {
            departmentForm.reportValidity();
            return;
        }
        
        const departmentData = {
            name: departmentNameInput.value,
            code: departmentCodeInput.value.toUpperCase(),
            description: departmentDescriptionInput.value,
            color: departmentColorInput.value
        };
        
        if (departmentIdInput.value) {
            // Update existing department
            departmentData.id = departmentIdInput.value;
            
            fetch(`/api/departments/${departmentData.id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(departmentData)
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to update department');
                }
                return response.json();
            })
            .then(data => {
                // Update department in array
                const index = departments.findIndex(dept => dept.id === departmentData.id);
                if (index !== -1) {
                    departments[index] = data;
                }
                
                renderDepartments();
                departmentModal.classList.remove('active');
            })
            .catch(error => {
                console.error('Error updating department:', error);
                alert('Failed to update department. Please try again.');
            });
        } else {
            // Create new department
            fetch('/api/departments', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(departmentData)
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Failed to create department');
                }
                return response.json();
            })
            .then(data => {
                // Add new department to array
                departments.push(data);
                
                renderDepartments();
                departmentModal.classList.remove('active');
            })
            .catch(error => {
                console.error('Error creating department:', error);
                alert('Failed to create department. Please try again.');
            });
        }
    }
    
    // Delete department
    function deleteDepartment(departmentId) {
        if (!confirm('Are you sure you want to delete this department?')) {
            return;
        }
        
        fetch(`/api/departments/${departmentId}`, {
            method: 'DELETE'
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Failed to delete department');
            }
            
            // Remove department from array
            departments = departments.filter(dept => dept.id !== departmentId);
            renderDepartments();
        })
        .catch(error => {
            console.error('Error deleting department:', error);
            alert('Failed to delete department. Please try again.');
        });
    }
});
</script>
{% endblock %}
EOF

# Update the admin/day.html template to remove the outdated 'manage' tab
cat > /mnt/user/appdata/film-scheduler-v4/templates/admin/day.html << 'EOF'
{% extends "base.html" %}

{% block title %}Edit Day - {{ day.date }} - Schedule, At a Glance!{% endblock %}

{% block styles %}
<link rel="stylesheet" href="/static/css/forms.css">
<link rel="stylesheet" href="/static/css/calendar.css">
<style>
    .location-area-display {
        font-size: 0.85rem;
        color: var(--text-light);
        margin-top: 0.25rem;
        padding: 0.3rem 0.5rem;
        background-color: var(--background-color);
        border-radius: 3px;
        display: inline-block;
    }
    
    .department-tags-container {
        margin-top: 0.5rem;
    }
    
    .department-tag-selector {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        margin-top: 0.5rem;
        max-height: 150px;
        overflow-y: auto;
        padding: 0.5rem;
        background-color: var(--background-color);
        border-radius: 3px;
        border: 1px solid var(--border-color);
    }
    
    .department-tag-option {
        display: inline-flex;
        align-items: center;
        gap: 0.25rem;
        padding: 0.3rem 0.5rem;
        border-radius: 3px;
        cursor: pointer;
        transition: transform 0.1s;
        font-size: 0.85rem;
        font-weight: 500;
    }
    
    .department-tag-option:hover {
        transform: scale(1.05);
    }
    
    .department-tag-option.selected {
        box-shadow: 0 0 0 1px var(--text-color);
    }
    
    .selected-departments {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        margin-top: 0.5rem;
    }
    
    .selected-department {
        display: inline-flex;
        align-items: center;
        gap: 0.25rem;
        padding: 0.3rem 0.5rem;
        border-radius: 3px;
        font-size: 0.85rem;
        font-weight: 500;
    }
    
    .remove-tag {
        cursor: pointer;
        opacity: 0.7;
        transition: opacity 0.2s;
    }
    
    .remove-tag:hover {
        opacity: 1;
    }

    /* Admin navigation tabs */
    .admin-tabs {
        display: flex;
        margin-bottom: 1.5rem;
        border-bottom: 1px solid var(--border-color);
        overflow-x: auto;
    }
    
    .admin-tabs a {
        padding: 0.6rem 1rem;
        color: var(--text-color);
        text-decoration: none;
        border-bottom: 2px solid transparent;
        font-weight: 500;
        font-size: 0.9rem;
        white-space: nowrap;
    }
    
    .admin-tabs a.active,
    .admin-tabs a:hover {
        color: var(--accent-color);
        border-bottom-color: var(--accent-color);
    }
</style>
{% endblock %}

{% block content %}
<div class="admin-header">
    <h2>
        {% if day.isPrep %}
            Edit Prep Day
        {% else %}
            Edit Shoot Day {{ day.shootDay if day.shootDay }}
        {% endif %}
    </h2>
    <div class="admin-actions">
        <a href="/admin/calendar/{{ project.id }}" class="button secondary">Back to Calendar</a>
    </div>
</div>

<!-- Admin Navigation Tabs -->
<div class="admin-tabs">
    <a href="/admin">Projects</a>
    <a href="/admin/calendar/{{ project.id }}">Calendar</a>
    <a href="/admin/locations">Locations</a>
    <a href="/admin/departments">Departments</a>
    <a href="/admin/dates">Special Dates</a>
</div>

<div class="form-container">
    <div class="day-header">
        <h3>{{ day.dayOfWeek }}, {{ day.date }}</h3>
    </div>
    
    <form method="POST" class="day-form">
        <div class="form-section">
            <h3>Main Unit Details</h3>
            
            <div class="form-row">
                <div class="form-group full-width">
                    <label for="mainUnit">Main Unit Description</label>
                    <input type="text" id="mainUnit" name="mainUnit" value="{{ day.mainUnit or '' }}" placeholder="E.g., JOHN'S HOUSE - KITCHEN">
                </div>
            </div>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="location">Location</label>
                    <select id="location" name="location" class="location-select">
                        <option value="">-- Select Location --</option>
                        <!-- Options will be populated by JavaScript -->
                    </select>
                    <div class="location-area-display" id="location-area-display">
                        {% if day.locationArea %}{{ day.locationArea }}{% endif %}
                    </div>
                    <input type="hidden" id="locationArea" name="locationArea" value="{{ day.locationArea or '' }}">
                </div>
            </div>
        </div>
        
        <div class="form-section">
            <h3>Extras</h3>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="extras">Background Extras</label>
                    <input type="number" id="extras" name="extras" value="{{ day.extras or 0 }}" min="0">
                </div>
                
                <div class="form-group">
                    <label for="featuredExtras">Featured Extras</label>
                    <input type="number" id="featuredExtras" name="featuredExtras" value="{{ day.featuredExtras or 0 }}" min="0">
                </div>
            </div>
        </div>
        
        <div class="form-section">
            <h3>Script Information</h3>
            
            <div class="form-row">
                <div class="form-group full-width">
                    <label for="sequence">Sequence</label>
                    <input type="text" id="sequence" name="sequence" value="{{ day.sequence or '' }}" placeholder="Scene/Sequence numbers">
                </div>
            </div>
        </div>
        
        <div class="form-section">
            <h3>Department Requirements</h3>
            
            <div class="form-row">
                <div class="form-group full-width">
                    <label for="departments">Departments</label>
                    <input type="hidden" id="departments" name="departments" value="{{ day.departments|join(',') if day.departments else '' }}">
                    
                    <div class="department-tags-container">
                        <div class="selected-departments" id="selected-departments">
                            <!-- Selected departments will be displayed here -->
                        </div>
                        
                        <div class="department-tag-selector" id="department-tag-selector">
                            <!-- Department tags will be populated by JavaScript -->
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="form-section">
            <h3>Notes</h3>
            
            <div class="form-row">
                <div class="form-group full-width">
                    <label for="notes">Day Notes</label>
                    <textarea id="notes" name="notes" rows="3">{{ day.notes or '' }}</textarea>
                </div>
            </div>
        </div>
        
        <div class="form-section">
            <h3>Second Unit (if applicable)</h3>
            
            <div class="form-row">
                <div class="form-group">
                    <label for="secondUnit">Second Unit Description</label>
                    <input type="text" id="secondUnit" name="secondUnit" value="{{ day.secondUnit or '' }}" placeholder="Second unit activity">
                </div>
                
                <div class="form-group">
                    <label for="secondUnitLocation">Second Unit Location</label>
                    <input type="text" id="secondUnitLocation" name="secondUnitLocation" value="{{ day.secondUnitLocation or '' }}" placeholder="Second unit location">
                </div>
            </div>
        </div>
        
        <div class="form-actions">
            <a href="/admin/calendar/{{ project.id }}" class="button secondary">Cancel</a>
            <button type="submit" class="button">Save Changes</button>
        </div>
    </form>
</div>
{% endblock %}

{% block scripts %}
<script src="/static/js/day-editor.js"></script>
{% endblock %}
EOF

echo "Updated templates with correct path and added consistent navigation"
