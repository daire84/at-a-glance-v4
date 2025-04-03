#!/bin/bash

# Film Production Scheduler v4 - Update Script
# This script installs new components and updates existing ones

# Configuration
APP_DIR="/mnt/user/appdata/film-scheduler-v4"
BACKUP_DIR="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)"

echo "Film Production Scheduler v4 - Update Script"
echo "----------------------------------------"
echo "Creating backup before applying changes..."

# Backup current files
mkdir -p "$BACKUP_DIR"
cp -r "$APP_DIR/static" "$APP_DIR/templates" "$APP_DIR/app.py" "$BACKUP_DIR/"
echo "Backup created at $BACKUP_DIR"

echo "Updating files..."

# Create departments.html template if it doesn't exist
echo "Updating departments template..."
cat > "$APP_DIR/templates/admin/departments.html" << 'EOF'
{% extends "base.html" %}

{% block title %}Department Management - Schedule, At a Glance!{% endblock %}

{% block styles %}
<link rel="stylesheet" href="/static/css/forms.css">
<style>
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

# Update or create the calendar drag-and-drop JavaScript file
echo "Adding calendar drag-and-drop functionality..."
mkdir -p "$APP_DIR/static/js"
cat > "$APP_DIR/static/js/calendar-dragdrop.js" << 'EOF'
/**
 * Calendar drag and drop functionality
 * Allows reorganizing of shoot days with automatic date recalculation
 */

document.addEventListener('DOMContentLoaded', function() {
    // Only initialize drag-and-drop in the admin calendar page
    if (!document.querySelector('.admin-calendar')) {
        return;
    }

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
            this.classList.remove('dragging');
            draggedRow = null;
            
            // Remove all drag-over classes
            rows.forEach(row => {
                row.classList.remove('drag-over');
            });
        });
        
        // Drag over
        row.addEventListener('dragover', function(e) {
            e.preventDefault();
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
                throw new Error('Failed to move day');
            }
            return response.json();
        })
        .then(() => {
            // Reload the page to show updated calendar
            window.location.reload();
        })
        .catch(error => {
            hideLoading();
            console.error('Error moving day:', error);
            alert('An error occurred while moving the day. Please try again.');
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
        
        // Add styling
        const style = document.createElement('style');
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
                border-top: 3px solid var(--accent-color);
                border-radius: 50%;
                animation: spin 1s linear infinite;
                margin-bottom: 10px;
            }
            
            .loading-text {
                color: var(--text-color);
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
                border: 2px dashed var(--accent-color);
            }
        `;
        document.head.appendChild(style);
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
EOF

# Update base.html template
echo "Updating base template..."
cat > "$APP_DIR/templates/base.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Schedule, At a Glance!{% endblock %}</title>
    <link rel="stylesheet" href="/static/css/style.css">
    {% block styles %}{% endblock %}
    <style>
        /* Navigation styles */
        .main-header {
            position: relative;
        }
        
        .main-nav {
            display: flex;
            justify-content: flex-end;
        }
        
        .nav-dropdown {
            position: relative;
        }
        
        .nav-dropdown-toggle {
            display: flex;
            align-items: center;
            gap: 0.25rem;
            cursor: pointer;
        }
        
        .nav-dropdown-menu {
            position: absolute;
            top: 100%;
            right: 0;
            background-color: white;
            border-radius: 4px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
            width: 200px;
            z-index: 100;
            opacity: 0;
            visibility: hidden;
            transform: translateY(-10px);
            transition: opacity 0.2s, visibility 0.2s, transform 0.2s;
        }
        
        .nav-dropdown-menu.active {
            opacity: 1;
            visibility: visible;
            transform: translateY(0);
        }
        
        .nav-dropdown-menu ul {
            list-style: none;
            padding: 0.5rem 0;
            margin: 0;
        }
        
        .nav-dropdown-menu li {
            padding: 0;
        }
        
        .nav-dropdown-menu a {
            display: block;
            padding: 0.5rem 0.8rem;
            color: var(--text-color);
            text-decoration: none;
            transition: background-color 0.2s;
            font-size: 0.85rem;
        }
        
        .nav-dropdown-menu a:hover {
            background-color: var(--background-color);
            color: var(--primary-color);
        }
        
        .nav-dropdown-menu .divider {
            height: 1px;
            background-color: var(--border-color);
            margin: 0.5rem 0;
        }
        
        .dropdown-icon {
            width: 14px;
            height: 14px;
            fill: currentColor;
        }

        /* Mobile navigation */
        .mobile-menu-toggle {
            display: none;
            background: none;
            border: none;
            color: white;
            cursor: pointer;
            padding: 0.5rem;
        }
        
        @media (max-width: 768px) {
            .mobile-menu-toggle {
                display: block;
            }
            
            .main-nav {
                position: absolute;
                top: 100%;
                left: 0;
                right: 0;
                background-color: var(--primary-dark);
                flex-direction: column;
                padding: 0.5rem 0;
                display: none;
                z-index: 1000;
            }
            
            .main-nav.active {
                display: flex;
            }
            
            .main-nav ul {
                flex-direction: column;
                width: 100%;
            }
            
            .main-nav a {
                display: block;
                padding: 0.75rem 1rem;
            }
            
            .nav-dropdown {
                width: 100%;
            }
            
            .nav-dropdown-menu {
                position: static;
                box-shadow: none;
                width: 100%;
                background-color: var(--primary-dark);
                padding-left: 1rem;
                transform: none;
            }
            
            .nav-dropdown-menu a {
                color: white;
            }
            
            .nav-dropdown-menu a:hover {
                background-color: rgba(255, 255, 255, 0.1);
                color: white;
            }
            
            .nav-dropdown-menu .divider {
                background-color: rgba(255, 255, 255, 0.1);
            }
        }
    </style>
</head>
<body>
    <header class="main-header">
        <div class="container">
            <h1>Schedule, At a Glance!</h1>
            
            <button class="mobile-menu-toggle" id="mobile-menu-toggle">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="3" y1="12" x2="21" y2="12"></line>
                    <line x1="3" y1="6" x2="21" y2="6"></line>
                    <line x1="3" y1="18" x2="21" y2="18"></line>
                </svg>
            </button>
            
            <nav class="main-nav" id="main-nav">
                <ul>
                    <li><a href="/">Dashboard</a></li>
                    {% if request.path.startswith('/admin') %}
                    <li class="nav-dropdown">
                        <a href="#" class="nav-dropdown-toggle" id="admin-dropdown-toggle">
                            Manage
                            <svg class="dropdown-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="6 9 12 15 18 9"></polyline>
                            </svg>
                        </a>
                        <div class="nav-dropdown-menu" id="admin-dropdown-menu">
                            <ul>
                                <li><a href="/admin/locations">Locations</a></li>
                                <li><a href="/admin/departments">Departments</a></li>
                                <li><a href="/admin/dates">Special Dates</a></li>
                                <li class="divider"></li>
                                <li><a href="/admin/project/new">New Project</a></li>
                            </ul>
                        </div>
                    </li>
                    {% endif %}
                    <li><a href="/admin">Admin</a></li>
                </ul>
            </nav>
        </div>
    </header>
    
    {% if get_flashed_messages() %}
    <div class="flash-messages">
        <div class="container">
            {% for category, message in get_flashed_messages(with_categories=true) %}
            <div class="flash-message {{ category }}">
                {{ message }}
                <button class="close-button">&times;</button>
            </div>
            {% endfor %}
        </div>
    </div>
    {% endif %}
    
    <main>
        <div class="container">
            {% block content %}{% endblock %}
        </div>
    </main>
    
    <footer>
        <div class="container">
            <p>Schedule, At a Glance! v4</p>
        </div>
    </footer>
    
    <script>
        // Close flash messages
        document.addEventListener('DOMContentLoaded', function() {
            // Flash messages
            document.querySelectorAll('.flash-message .close-button').forEach(function(button) {
                button.addEventListener('click', function() {
                    this.parentElement.style.display = 'none';
                });
            });
            
            // Dropdown menu
            const adminDropdownToggle = document.getElementById('admin-dropdown-toggle');
            const adminDropdownMenu = document.getElementById('admin-dropdown-menu');
            
            if (adminDropdownToggle && adminDropdownMenu) {
                adminDropdownToggle.addEventListener('click', function(e) {
                    e.preventDefault();
                    adminDropdownMenu.classList.toggle('active');
                });
                
                // Close dropdown when clicking outside
                document.addEventListener('click', function(e) {
                    if (!e.target.closest('.nav-dropdown') && adminDropdownMenu.classList.contains('active')) {
                        adminDropdownMenu.classList.remove('active');
                    }
                });
            }
            
            // Mobile menu
            const mobileMenuToggle = document.getElementById('mobile-menu-toggle');
            const mainNav = document.getElementById('main-nav');
            
            if (mobileMenuToggle && mainNav) {
                mobileMenuToggle.addEventListener('click', function() {
                    mainNav.classList.toggle('active');
                });
            }
        });
    </script>
    {% block scripts %}{% endblock %}
</body>
</html>
EOF

# Add the move-day endpoint to app.py
echo "Adding move-day endpoint to app.py..."
MOVE_DAY_ENDPOINT="@app.route('/api/projects/<project_id>/calendar/move-day', methods=['POST'])
def api_move_calendar_day(project_id):
    \"\"\"Move a shoot day from one date to another and recalculate the shoot days\"\"\"
    try:
        # Get request data
        move_data = request.get_json()
        from_date = move_data.get('fromDate')
        to_date = move_data.get('toDate')
        
        if not from_date or not to_date:
            return jsonify({'error': 'Missing required parameters'}), 400
        
        # Get calendar data
        calendar_data = get_project_calendar(project_id)
        if not calendar_data or not calendar_data.get('days'):
            return jsonify({'error': 'Calendar not found'}), 404
        
        # Find the source and destination days
        days = calendar_data.get('days', [])
        from_day_index = next((i for i, d in enumerate(days) if d.get('date') == from_date), None)
        to_day_index = next((i for i, d in enumerate(days) if d.get('date') == to_date), None)
        
        if from_day_index is None or to_day_index is None:
            return jsonify({'error': 'Source or destination day not found'}), 404
        
        # Get the days to move
        from_day = days[from_day_index]
        to_day = days[to_day_index]
        
        # Only shoot days can be moved
        if not from_day.get('isShootDay', False):
            return jsonify({'error': 'Can only move shoot days'}), 400
        
        # Cannot move to a weekend, holiday, or hiatus day unless it's explicitly marked as a working day
        if ((to_day.get('isWeekend', False) and not to_day.get('isWorkingWeekend', False)) or
            (to_day.get('isHoliday', False) and not to_day.get('isWorking', False)) or
            to_day.get('isHiatus', False)):
            return jsonify({'error': 'Cannot move to a non-working day'}), 400
        
        # Swap the day details but keep the dates
        # Save the date and day-specific info
        to_date_info = {
            'date': to_day.get('date'),
            'dayOfWeek': to_day.get('dayOfWeek'),
            'monthName': to_day.get('monthName'),
            'day': to_day.get('day'),
            'month': to_day.get('month'),
            'year': to_day.get('year'),
            'isPrep': to_day.get('isPrep', False),
            'isWeekend': to_day.get('isWeekend', False),
            'isHoliday': to_day.get('isHoliday', False),
            'isHiatus': to_day.get('isHiatus', False),
            'isWorkingWeekend': to_day.get('isWorkingWeekend', False),
            'dayType': to_day.get('dayType')
        }
        
        from_date_info = {
            'date': from_day.get('date'),
            'dayOfWeek': from_day.get('dayOfWeek'),
            'monthName': from_day.get('monthName'),
            'day': from_day.get('day'),
            'month': from_day.get('month'),
            'year': from_day.get('year'),
            'isPrep': from_day.get('isPrep', False),
            'isWeekend': from_day.get('isWeekend', False),
            'isHoliday': from_day.get('isHoliday', False),
            'isHiatus': from_day.get('isHiatus', False),
            'isWorkingWeekend': from_day.get('isWorkingWeekend', False),
            'dayType': from_day.get('dayType')
        }
        
        # Create copies of the days
        new_to_day = from_day.copy()
        new_from_day = to_day.copy()
        
        # Update the date-specific information
        for key, value in to_date_info.items():
            new_to_day[key] = value
        
        for key, value in from_date_info.items():
            new_from_day[key] = value
        
        # Set the shoot day status
        new_to_day['isShootDay'] = True
        if not to_day.get('isPrep', False):
            new_from_day['isShootDay'] = False
        
        # Update the calendar
        days[from_day_index] = new_from_day
        days[to_day_index] = new_to_day
        
        # Now recalculate shoot day numbers
        # Sort days by date
        days.sort(key=lambda d: d.get('date', ''))
        
        # Reset shoot day numbers
        shoot_day = 0
        for day in days:
            if day.get('isShootDay', False):
                shoot_day += 1
                day['shootDay'] = shoot_day
            else:
                day['shootDay'] = None
        
        # Save the updated calendar
        calendar_data['days'] = days
        save_project_calendar(project_id, calendar_data)
        
        return jsonify({'success': True}), 200
    
    except Exception as e:
        logger.error(f\"Error moving calendar day: {str(e)}\")
        return jsonify({'error': f'Error moving calendar day: {str(e)}'}), 500"

# Add the move-day endpoint to app.py after the existing calendar endpoints
if grep -q "@app.route('/api/projects/<project_id>/calendar/generate', methods=\['POST'\])" "$APP_DIR/app.py"; then
    # Find the position right after the calendar generation endpoint
    insert_line=$(grep -n "@app.route('/api/projects/<project_id>/calendar/generate', methods=\['POST'\])" "$APP_DIR/app.py" | cut -d: -f1)
    insert_line=$((insert_line + $(grep -A20 "@app.route('/api/projects/<project_id>/calendar/generate', methods=\['POST'\])" "$APP_DIR/app.py" | grep -n "return jsonify" | head -1 | cut -d: -f1)))
    
    # Insert the move-day endpoint
    sed -i "${insert_line}a\\
\\
${MOVE_DAY_ENDPOINT}" "$APP_DIR/app.py"
else
    echo "Warning: Could not find the proper place to insert the move-day endpoint."
    echo "Please add it manually after the calendar generation endpoint in app.py."
fi

# Update calendar template to include the drag-and-drop script
echo "Updating calendar template to include drag-and-drop..."
if grep -q "{% block scripts %}" "$APP_DIR/templates/admin/calendar.html"; then
    # Add the script tag inside the existing scripts block
    sed -i "/{% block scripts %}/a\\
<script src=\"/static/js/calendar-dragdrop.js\"></script>" "$APP_DIR/templates/admin/calendar.html"
    
    # Add the admin-calendar class to the calendar container
    sed -i "s/<div class=\"calendar-container\">/<div class=\"calendar-container admin-calendar\">/" "$APP_DIR/templates/admin/calendar.html"
else
    echo "Warning: Could not find the proper place to add the drag-and-drop script."
    echo "Please add it manually to templates/admin/calendar.html."
fi

echo "----------------------------------------"
echo "Installation completed!"
echo "Restart your application to apply the changes."
echo "----------------------------------------"
