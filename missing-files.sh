#!/bin/bash

# Film Production Scheduler v4 - Installation Script
# This script installs missing files and updates existing ones

# Configuration
APP_DIR="/mnt/user/appdata/film-scheduler-v4"
DATA_DIR="$APP_DIR/data"
STATIC_DIR="$APP_DIR/static"
TEMPLATE_DIR="$APP_DIR/templates"
UTILS_DIR="$APP_DIR/utils"

echo "Film Production Scheduler v4 - Installation Script"
echo "----------------------------------------"
echo "Installing missing files and updating existing files..."
echo ""

# Make sure data directory exists
mkdir -p "$DATA_DIR"

# Create CSS directories if they don't exist
mkdir -p "$STATIC_DIR/css"
mkdir -p "$STATIC_DIR/js"
mkdir -p "$STATIC_DIR/images"

# Install CSS files
echo "Installing CSS files..."
cat > "$STATIC_DIR/css/style.css" << 'EOF'
:root {
  --primary-color: #546e7a;
  --primary-light: #607d8b;
  --primary-dark: #455a64;
  --accent-color: #1e88e5;
  --accent-light: #42a5f5;
  --accent-dark: #1565c0;
  --text-color: #37474f;
  --text-light: #78909c;
  --background-color: #f5f7f8;
  --border-color: #cfd8dc;
  --success-color: #4caf50;
  --error-color: #f44336;
  --warning-color: #ff9800;
}

/* Reset */
*, *::before, *::after {
  box-sizing: border-box;
}

body, h1, h2, h3, h4, h5, h6, p, ul, ol {
  margin: 0;
  padding: 0;
}

/* Base styles */
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  line-height: 1.6;
  color: var(--text-color);
  background-color: var(--background-color);
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

/* Header */
.main-header {
  background-color: var(--primary-color);
  color: white;
  padding: 1rem 0;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.main-header .container {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.main-header h1 {
  font-size: 1.5rem;
  font-weight: 500;
}

.main-header nav ul {
  display: flex;
  list-style: none;
}

.main-header nav a {
  color: white;
  text-decoration: none;
  padding: 0.5rem 1rem;
  transition: background-color 0.3s;
  border-radius: 4px;
}

.main-header nav a:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

/* Main content */
main {
  flex: 1;
  padding: 2rem 0;
}

h2 {
  margin-bottom: 1.5rem;
  color: var(--primary-color);
}

h3 {
  margin-bottom: 1rem;
  color: var(--primary-light);
}

/* Admin Header */
.admin-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.admin-actions {
  display: flex;
  gap: 0.75rem;
}

/* Project list */
.project-list {
  margin-top: 2rem;
}

.project-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
  margin-top: 1rem;
}

.project-card {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  overflow: hidden;
  transition: transform 0.3s, box-shadow 0.3s;
}

.project-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.project-card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background-color: var(--primary-light);
  color: white;
}

.project-card-header h4 {
  margin: 0;
  font-size: 1.2rem;
  font-weight: 500;
}

.version-tag {
  font-size: 0.8rem;
  background-color: rgba(255, 255, 255, 0.2);
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
}

.project-card-body {
  padding: 1rem;
}

.project-card-body p {
  margin-bottom: 0.5rem;
}

.project-card-body .updated-at {
  font-size: 0.85rem;
  color: var(--text-light);
  margin-top: 0.5rem;
}

.project-card-footer {
  padding: 1rem;
  border-top: 1px solid var(--border-color);
  display: flex;
  justify-content: flex-end;
}

.button-group {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

/* Buttons */
.button {
  display: inline-block;
  background-color: var(--accent-color);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  text-decoration: none;
  border: none;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background-color 0.3s;
}

.button:hover {
  background-color: var(--accent-dark);
}

.button.secondary {
  background-color: var(--primary-light);
}

.button.secondary:hover {
  background-color: var(--primary-dark);
}

.button.danger {
  background-color: var(--error-color);
}

.button.danger:hover {
  background-color: #d32f2f;
}

.button.small {
  padding: 0.25rem 0.5rem;
  font-size: 0.85rem;
}

.print-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background-color: var(--primary-light);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  text-decoration: none;
  border: none;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background-color 0.3s;
}

.print-button:hover {
  background-color: var(--primary-dark);
}

.print-button svg {
  width: 18px;
  height: 18px;
}

/* Empty state */
.empty-state {
  background-color: #f8f9fa;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  margin: 1.5rem 0;
}

.empty-state p {
  margin-bottom: 0.75rem;
}

.empty-state p:last-child {
  margin-bottom: 0;
}

/* Flash messages */
.flash-messages {
  margin-bottom: 1.5rem;
}

.flash-message {
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 0.5rem;
  position: relative;
}

.flash-message.success {
  background-color: #e8f5e9;
  color: #2e7d32;
  border-left: 4px solid var(--success-color);
}

.flash-message.error {
  background-color: #ffebee;
  color: #c62828;
  border-left: 4px solid var(--error-color);
}

.flash-message.warning {
  background-color: #fff3e0;
  color: #ef6c00;
  border-left: 4px solid var(--warning-color);
}

.flash-message .close-button {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  background: none;
  border: none;
  font-size: 1.25rem;
  cursor: pointer;
  color: inherit;
  opacity: 0.5;
}

.flash-message .close-button:hover {
  opacity: 1;
}

/* Hero section */
.hero {
  text-align: center;
  margin-bottom: 2.5rem;
}

.hero h2 {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.hero .subtitle {
  font-size: 1.2rem;
  color: var(--text-light);
}

/* Footer */
footer {
  background-color: var(--primary-color);
  color: white;
  padding: 1rem 0;
  text-align: center;
  margin-top: auto;
}

/* Responsive styles */
@media (max-width: 768px) {
  .admin-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }
  
  .admin-actions {
    width: 100%;
    justify-content: flex-start;
    flex-wrap: wrap;
  }
  
  .project-grid {
    grid-template-columns: 1fr;
  }
}

/* Print styles */
@media print {
  .main-header, .admin-actions, footer {
    display: none;
  }
  
  .container {
    width: 100%;
    max-width: none;
    padding: 0;
  }
  
  body {
    background-color: white;
    font-size: 12pt;
  }
  
  .calendar-container {
    page-break-after: always;
  }
  
  .calendar-table {
    font-size: 10pt;
  }
}
EOF

cat > "$STATIC_DIR/css/forms.css" << 'EOF'
/* Form Styles */

.form-container {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.form-section {
  margin-bottom: 2rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid var(--border-color);
}

.form-section:last-child {
  margin-bottom: 0;
  padding-bottom: 0;
  border-bottom: none;
}

.form-section h3 {
  font-size: 1.2rem;
  color: var(--primary-color);
  margin-bottom: 1.25rem;
}

.form-row {
  display: flex;
  gap: 1.5rem;
  margin-bottom: 1.25rem;
}

.form-row:last-child {
  margin-bottom: 0;
}

.form-group {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.form-group.full-width {
  flex: 0 0 100%;
}

label {
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: var(--text-color);
}

input[type="text"],
input[type="number"],
input[type="date"],
input[type="email"],
input[type="password"],
select,
textarea {
  background-color: #f8f9fa;
  border: 1px solid #dee2e6;
  border-radius: 4px;
  padding: 0.75rem;
  font-size: 0.95rem;
  color: var(--text-color);
  transition: border-color 0.3s, box-shadow 0.3s;
}

input[type="text"]:focus,
input[type="number"]:focus,
input[type="date"]:focus,
input[type="email"]:focus,
input[type="password"]:focus,
select:focus,
textarea:focus {
  border-color: var(--accent-color);
  box-shadow: 0 0 0 3px rgba(30, 136, 229, 0.25);
  outline: none;
}

textarea {
  min-height: 100px;
  resize: vertical;
}

input[type="color"] {
  width: 100%;
  height: 40px;
  padding: 2px;
  border: 1px solid #dee2e6;
  border-radius: 4px;
}

.field-hint {
  font-size: 0.85rem;
  color: var(--text-light);
  margin-top: 0.25rem;
}

input:invalid,
select:invalid,
textarea:invalid {
  border-color: var(--error-color);
}

.form-actions {
  margin-top: 2rem;
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.form-check {
  display: flex;
  align-items: center;
  margin-bottom: 0.75rem;
}

.form-check input[type="checkbox"] {
  margin-right: 0.5rem;
}

.day-header {
  margin-bottom: 1.5rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid var(--border-color);
}

.day-header h3 {
  font-size: 1.3rem;
  color: var(--primary-dark);
}

.day-form {
  width: 100%;
}

.location-select {
  width: 100%;
}

.department-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 0.5rem;
}

.department-tag-input {
  margin-bottom: 0.75rem;
}

.tag-item {
  display: inline-flex;
  align-items: center;
  background-color: #e9ecef;
  border-radius: 4px;
  padding: 0.25rem 0.75rem;
  font-size: 0.9rem;
  font-weight: 500;
}

.tag-item .remove-tag {
  margin-left: 0.5rem;
  cursor: pointer;
  font-size: 1.1rem;
  opacity: 0.6;
}

.tag-item .remove-tag:hover {
  opacity: 1;
}

.content-container {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  padding: 1.5rem;
}

.project-selector {
  width: 100%;
  max-width: 400px;
  margin-bottom: 2rem;
}

.action-row {
  margin-top: 2rem;
  display: flex;
  justify-content: center;
}

/* Responsive styles */
@media (max-width: 768px) {
  .form-row {
    flex-direction: column;
    gap: 1rem;
  }
}
EOF

cat > "$STATIC_DIR/css/calendar.css" << 'EOF'
/* Calendar Styles */

.calendar-container {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
  padding: 1.5rem;
  margin-bottom: 2rem;
}

/* Project Info Header */
.project-info-header {
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.project-title {
  font-size: 1.5rem;
  color: var(--primary-color);
  margin-bottom: 1rem;
}

.project-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem;
  margin-bottom: 1rem;
}

.meta-group {
  display: flex;
  flex-direction: column;
}

.meta-label {
  font-size: 0.85rem;
  color: var(--text-light);
  margin-bottom: 0.25rem;
}

.meta-value {
  font-weight: 500;
}

.script-info {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem;
  background-color: #f8f9fa;
  padding: 0.75rem 1rem;
  border-radius: 4px;
  margin-top: 1rem;
}

.script-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.script-label {
  font-weight: 500;
  color: var(--primary-color);
}

.script-value {
  color: var(--text-color);
}

/* Calendar Actions */
.calendar-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.action-buttons {
  display: flex;
  gap: 0.75rem;
}

/* Department Counters */
.department-counters {
  margin-bottom: 1.5rem;
  background-color: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
}

.counter-title {
  font-size: 1.1rem;
  margin-bottom: 0.75rem;
  color: var(--primary-dark);
}

.counter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 0.75rem;
}

.counter-item {
  border-radius: 4px;
  padding: 0.75rem;
  text-align: center;
}

.counter-label {
  font-size: 0.9rem;
  margin-bottom: 0.25rem;
}

.counter-value {
  font-size: 1.5rem;
  font-weight: 600;
}

/* Location Areas */
.location-areas {
  margin-bottom: 1.5rem;
  background-color: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
}

.areas-title {
  font-size: 1.1rem;
  margin-bottom: 0.75rem;
  color: var(--primary-dark);
}

.area-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.area-tag {
  border-radius: 4px;
  padding: 0.5rem 0.75rem;
  font-size: 0.9rem;
  font-weight: 500;
}

/* Calendar Table */
.calendar-table-wrapper {
  overflow-x: auto;
}

.calendar-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid #dee2e6;
}

.calendar-table th,
.calendar-table td {
  border: 1px solid #dee2e6;
  padding: 0.75rem;
  vertical-align: top;
  text-align: left;
}

.calendar-table th {
  background-color: var(--primary-color);
  color: white;
  font-weight: 500;
  position: sticky;
  top: 0;
  z-index: 10;
}

/* Column widths */
.date-col {
  width: 110px;
}

.day-col {
  width: 50px;
  text-align: center;
}

.main-unit-col {
  width: 200px;
}

.extras-col,
.featured-extras-col {
  width: 50px;
  text-align: center;
}

.location-col {
  width: 150px;
}

.sequence-col {
  width: 100px;
}

.departments-col {
  width: 150px;
}

.notes-col {
  width: 200px;
}

/* Row styling */
.calendar-row {
  transition: background-color 0.2s;
}

.calendar-row:hover {
  background-color: rgba(96, 125, 139, 0.05);
}

.calendar-row.weekend {
  background-color: #f8f9fa;
}

.calendar-row.prep {
  background-color: #e3f2fd;
}

.calendar-row.shoot {
  background-color: #e8f5e9;
}

.calendar-row.hiatus {
  background-color: #fff3e0;
}

.calendar-row.holiday {
  background-color: #ffebee;
}

/* Cell styling */
.date-cell {
  font-weight: 500;
}

.date-display {
  margin-bottom: 0.25rem;
}

.date-day {
  font-size: 0.85rem;
  color: var(--text-light);
}

.day-cell {
  font-size: 1.1rem;
  font-weight: 600;
}

.main-unit-cell {
  font-weight: 500;
}

.extras-cell,
.featured-extras-cell {
  font-weight: 500;
  text-align: center;
}

/* Department tags */
.departments-cell {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}

.department-tag {
  display: inline-block;
  background-color: #e9ecef;
  color: var(--text-color);
  padding: 0.2rem 0.4rem;
  border-radius: 3px;
  font-size: 0.85rem;
  font-weight: 500;
}

/* Notes cell */
.notes-cell {
  font-size: 0.9rem;
  white-space: pre-line;
}

/* Admin mode specific */
.admin-calendar .calendar-row {
  cursor: pointer;
}

/* Viewer mode specific */
.viewer-mode .calendar-table th {
  position: sticky;
  top: 0;
  z-index: 10;
}

/* Print Styles */
@media print {
  .calendar-container {
    box-shadow: none;
    padding: 0;
  }
  
  .project-info-header {
    margin-bottom: 1rem;
  }
  
  .project-title {
    font-size: 1.3rem;
  }
  
  .counter-grid {
    grid-template-columns: repeat(8, 1fr);
  }
  
  .counter-item {
    padding: 0.5rem;
  }
  
  .counter-value {
    font-size: 1.2rem;
  }
  
  .calendar-table {
    font-size: 9pt;
  }
  
  .calendar-table th,
  .calendar-table td {
    padding: 4pt;
  }
  
  .departments-cell {
    gap: 2pt;
  }
  
  .department-tag {
    padding: 1pt 3pt;
    font-size: 8pt;
  }
  
  /* Force page breaks between logical sections */
  .calendar-table {
    page-break-inside: auto;
  }
  
  .calendar-row {
    page-break-inside: avoid;
  }
  
  /* Ensure headers print on each page */
  .calendar-table thead {
    display: table-header-group;
  }
  
  /* Background colors for print */
  .calendar-row.weekend {
    background-color: #f0f0f0 !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  
  .calendar-row.prep {
    background-color: #e0e0ff !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  
  .calendar-row.shoot {
    background-color: #e0ffe0 !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
}

/* Responsive Styles */
@media (max-width: 768px) {
  .project-meta {
    flex-direction: column;
    gap: 0.75rem;
  }
  
  .script-info {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .counter-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
EOF

# Update base.html template with new navigation
echo "Updating base template with enhanced navigation..."
cat > "$TEMPLATE_DIR/base.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Film Production Scheduler{% endblock %}</title>
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
            padding: 0.5rem 1rem;
            color: var(--text-color);
            text-decoration: none;
            transition: background-color 0.2s;
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
            width: 16px;
            height: 16px;
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
            <h1>Film Production Scheduler</h1>
            
            <button class="mobile-menu-toggle" id="mobile-menu-toggle">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="3" y1="12" x2="21" y2="12"></line>
                    <line x1="3" y1="6" x2="21" y2="6"></line>
                    <line x1="3" y1="18" x2="21" y2="18"></line>
                </svg>
            </button>
            
            <nav class="main-nav" id="main-nav">
                <ul>
                    <li><a href="/">Home</a></li>
                    <li><a href="/admin">Dashboard</a></li>
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
            <p>Film Production Scheduler v4</p>
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

# Update calendar_generator.py with enhanced functionality
echo "Updating calendar generator with enhanced functionality..."
cat > "$UTILS_DIR/calendar_generator.py" << 'EOF'
import os
import json
import logging
from datetime import datetime, timedelta
from dateutil import parser
from dateutil.relativedelta import relativedelta

logger = logging.getLogger(__name__)

def generate_calendar_days(project):
    """
    Generate calendar days for a project based on dates
    
    Args:
        project (dict): Project data including prepStartDate and shootStartDate
        
    Returns:
        dict: Calendar data with days array
    """
    try:
        # Validate required fields
        if not project.get('prepStartDate') or not project.get('shootStartDate'):
            logger.error("Missing required dates for calendar generation")
            return {"days": []}
        
        # Parse dates
        prep_start = parser.parse(project['prepStartDate'])
        shoot_start = parser.parse(project['shootStartDate'])
        
        # Calculate wrap date
        if project.get('wrapDate'):
            wrap_date = parser.parse(project['wrapDate'])
        else:
            # If no wrap date provided, default to 4 weeks after shoot start
            wrap_date = shoot_start + relativedelta(weeks=4)
        
        # Load special dates (bank holidays, working weekends, hiatus periods)
        holidays = load_bank_holidays(project.get('id'))
        working_weekends = load_working_weekends(project.get('id'))
        hiatus_periods = load_hiatus_periods(project.get('id'))
        
        # Generate all dates in range
        current_date = prep_start
        calendar_days = []
        shoot_day = 0
        
        while current_date <= wrap_date:
            date_str = current_date.strftime("%Y-%m-%d")
            
            # Check if date is a holiday
            is_holiday = is_bank_holiday(date_str, holidays)
            holiday_data = get_holiday_data(date_str, holidays)
            
            # Check if date is in a hiatus period
            is_hiatus = is_in_hiatus(date_str, hiatus_periods)
            hiatus_data = get_hiatus_data(date_str, hiatus_periods)
            
            # Determine if it's a weekend
            is_weekend = current_date.weekday() >= 5  # 5=Saturday, 6=Sunday
            
            # Check if it's a working weekend
            is_working_weekend = is_weekend and is_working_weekend_date(date_str, working_weekends)
            working_weekend_data = get_working_weekend_data(date_str, working_weekends)
            
            # Determine if it's a shoot day
            is_shoot_period = current_date >= shoot_start
            
            # Logic for determining shoot day:
            # - Must be in shoot period
            # - Must not be a weekend UNLESS it's a working weekend
            # - Must not be a holiday UNLESS it's a working holiday
            # - Must not be in a hiatus period
            is_shoot_day = (
                is_shoot_period and 
                (not is_weekend or is_working_weekend) and
                (not is_holiday or (is_holiday and holiday_data and holiday_data.get('isWorking', False) and holiday_data.get('isShootDay', False))) and
                not is_hiatus
            )
            
            # Increment shoot day count for actual shoot days
            if is_shoot_day:
                shoot_day += 1
            
            # Get day type and color based on conditions
            day_type = get_day_type(
                is_prep=current_date < shoot_start,
                is_shoot_day=is_shoot_day,
                is_weekend=is_weekend,
                is_holiday=is_holiday,
                is_hiatus=is_hiatus,
                is_working_weekend=is_working_weekend
            )
            
            # Create day entry
            day = {
                "date": date_str,
                "dayOfWeek": current_date.strftime("%A"),
                "monthName": current_date.strftime("%B"),
                "day": current_date.day,
                "month": current_date.month,
                "year": current_date.year,
                "isPrep": current_date < shoot_start,
                "isShootDay": is_shoot_day,
                "isWeekend": is_weekend,
                "isHoliday": is_holiday,
                "isHiatus": is_hiatus,
                "isWorkingWeekend": is_working_weekend,
                "dayType": day_type,
                "shootDay": shoot_day if is_shoot_day else None,
                "mainUnit": "",
                "extras": 0,
                "featuredExtras": 0,
                "location": "",
                "locationArea": "",
                "sequence": "",
                "departments": [],
                "notes": ""
            }
            
            # Add holiday or hiatus info to notes if applicable
            if is_holiday and holiday_data:
                day["notes"] = f"BANK HOLIDAY: {holiday_data.get('name', '')}"
                
            if is_hiatus and hiatus_data:
                day["notes"] = f"HIATUS: {hiatus_data.get('name', '')}"
                
            if is_working_weekend and working_weekend_data:
                if working_weekend_data.get('description'):
                    day["notes"] = f"WORKING WEEKEND: {working_weekend_data.get('description', '')}"
                else:
                    day["notes"] = "WORKING WEEKEND"
            
            calendar_days.append(day)
            current_date += timedelta(days=1)
        
        # Load location areas for reference
        location_areas = load_location_areas()
        
        # Create calendar data
        calendar_data = {
            "projectId": project.get('id', ''),
            "days": calendar_days,
            "departmentCounts": initialize_department_counts(),
            "locationAreas": location_areas,
            "lastUpdated": datetime.utcnow().isoformat() + 'Z'
        }
        
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error generating calendar: {str(e)}")
        return {"days": []}

def initialize_department_counts():
    """Initialize department counts with zeros"""
    return {
        "main": 0,
        "secondUnit": 0,
        "splitDay": 0,
        "sixthDay": 0,
        "steadicam": 0,
        "sfx": 0,
        "stunts": 0,
        "crane": 0,
        "prosthetics": 0,
        "lowLoader": 0
    }

def calculate_department_counts(calendar_data):
    """
    Calculate department counts based on the calendar days
    """
    try:
        days = calendar_data.get('days', [])
        counts = initialize_department_counts()
        
        # Map department codes to count keys
        dept_map = {
            "ST": "steadicam",
            "SFX": "sfx",
            "STN": "stunts",
            "CR": "crane",
            "PR": "prosthetics",
            "LL": "lowLoader"
        }
        
        # Count days
        counts["main"] = sum(1 for d in days if d.get("isShootDay"))
        counts["secondUnit"] = sum(1 for d in days if d.get("secondUnit"))
        
        # Count sixth day (working Saturdays)
        counts["sixthDay"] = sum(
            1 for d in days 
            if d.get("isShootDay") and 
            parser.parse(d["date"]).weekday() == 5  # Saturday
        )
        
        # Count split days (if applicable)
        counts["splitDay"] = sum(
            1 for d in days 
            if d.get("isShootDay") and 
            d.get("isSplitDay", False)
        )
        
        # Count department days
        for day in days:
            for dept in day.get("departments", []):
                if dept in dept_map:
                    counts[dept_map[dept]] += 1
        
        calendar_data["departmentCounts"] = counts
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error calculating department counts: {str(e)}")
        return calendar_data

def get_day_type(is_prep, is_shoot_day, is_weekend, is_holiday, is_hiatus, is_working_weekend):
    """Determine the type of day for styling purposes"""
    if is_hiatus:
        return "hiatus"
    elif is_holiday:
        return "holiday"
    elif is_prep:
        return "prep"
    elif is_shoot_day:
        return "shoot"
    elif is_weekend:
        return "weekend"
    else:
        return "normal"

def load_bank_holidays(project_id):
    """Load bank holidays for a project"""
    if not project_id:
        return []
    
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    holidays_file = os.path.join(data_dir, 'data', 'projects', project_id, 'holidays.json')
    
    if not os.path.exists(holidays_file):
        return []
    
    try:
        with open(holidays_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading bank holidays: {str(e)}")
        return []

def load_working_weekends(project_id):
    """Load working weekends for a project"""
    if not project_id:
        return []
    
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    weekends_file = os.path.join(data_dir, 'data', 'projects', project_id, 'weekends.json')
    
    if not os.path.exists(weekends_file):
        return []
    
    try:
        with open(weekends_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading working weekends: {str(e)}")
        return []

def load_hiatus_periods(project_id):
    """Load hiatus periods for a project"""
    if not project_id:
        return []
    
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    hiatus_file = os.path.join(data_dir, 'data', 'projects', project_id, 'hiatus.json')
    
    if not os.path.exists(hiatus_file):
        return []
    
    try:
        with open(hiatus_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading hiatus periods: {str(e)}")
        return []

def load_location_areas():
    """Load location areas with colors"""
    data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    areas_file = os.path.join(data_dir, 'data', 'areas.json')
    
    if not os.path.exists(areas_file):
        return []
    
    try:
        with open(areas_file, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Error loading location areas: {str(e)}")
        return []

def is_bank_holiday(date_str, holidays):
    """Check if a date is a bank holiday"""
    return any(h.get('date') == date_str for h in holidays)

def get_holiday_data(date_str, holidays):
    """Get holiday data for a specific date"""
    for holiday in holidays:
        if holiday.get('date') == date_str:
            return holiday
    return None

def is_working_weekend_date(date_str, working_weekends):
    """Check if a date is a working weekend"""
    return any(w.get('date') == date_str for w in working_weekends)

def get_working_weekend_data(date_str, working_weekends):
    """Get working weekend data for a specific date"""
    for weekend in working_weekends:
        if weekend.get('date') == date_str:
            return weekend
    return None

def is_in_hiatus(date_str, hiatus_periods):
    """Check if a date falls within a hiatus period"""
    date = parser.parse(date_str).date()
    
    for hiatus in hiatus_periods:
        start_date = parser.parse(hiatus.get('startDate')).date()
        end_date = parser.parse(hiatus.get('endDate')).date()
        
        if start_date <= date <= end_date:
            return True
    
    return False

def get_hiatus_data(date_str, hiatus_periods):
    """Get hiatus data for a specific date"""
    date = parser.parse(date_str).date()
    
    for hiatus in hiatus_periods:
        start_date = parser.parse(hiatus.get('startDate')).date()
        end_date = parser.parse(hiatus.get('endDate')).date()
        
        if start_date <= date <= end_date:
            return hiatus
    
    return None

def update_calendar_with_location_areas(calendar_data):
    """
    Update calendar data with location area information for color coding
    """
    try:
        # Load locations with their areas
        data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        locations_file = os.path.join(data_dir, 'data', 'locations.json')
        areas_file = os.path.join(data_dir, 'data', 'areas.json')
        
        if not os.path.exists(locations_file) or not os.path.exists(areas_file):
            return calendar_data
        
        with open(locations_file, 'r') as f:
            locations = json.load(f)
        
        with open(areas_file, 'r') as f:
            areas = json.load(f)
        
        # Create lookup maps
        location_map = {loc['name']: loc for loc in locations}
        area_map = {area['id']: area for area in areas}
        
        # Update days with location area info
        for day in calendar_data.get('days', []):
            location_name = day.get('location', '')
            
            if location_name and location_name in location_map:
                location = location_map[location_name]
                area_id = location.get('areaId')
                
                if area_id and area_id in area_map:
                    day['locationArea'] = area_map[area_id]['name']
        
        # Add location areas to calendar data
        calendar_data['locationAreas'] = areas
        
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error updating calendar with location areas: {str(e)}")
        return calendar_data

def update_calendar_with_departments(calendar_data):
    """
    Update calendar data with department information for tag display
    """
    try:
        # Load departments
        data_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        departments_file = os.path.join(data_dir, 'data', 'departments.json')
        
        if not os.path.exists(departments_file):
            return calendar_data
        
        with open(departments_file, 'r') as f:
            departments = json.load(f)
        
        # Create lookup map for department codes
        dept_map = {dept['code']: dept for dept in departments}
        
        # Add department info to calendar data
        calendar_data['departments'] = departments
        
        # Update department counts
        calculate_department_counts(calendar_data)
        
        return calendar_data
    
    except Exception as e:
        logger.error(f"Error updating calendar with departments: {str(e)}")
        return calendar_data
EOF

# Create default data files
echo "Creating default data files..."
mkdir -p "$DATA_DIR"

# Create departments.json
cat > "$DATA_DIR/departments.json" << 'EOF'
[
  {
    "id": "sfx",
    "name": "Special Effects",
    "code": "SFX",
    "description": "Practical special effects department",
    "color": "#ffd8e6"
  },
  {
    "id": "stn",
    "name": "Stunts",
    "code": "STN",
    "description": "Stunt coordination and performance",
    "color": "#ffecd8"
  },
  {
    "id": "crane",
    "name": "Crane",
    "code": "CR",
    "description": "Camera crane operation",
    "color": "#d8fff2"
  },
  {
    "id": "stead",
    "name": "Steadicam",
    "code": "ST",
    "description": "Steadicam operation",
    "color": "#f2d8ff"
  },
  {
    "id": "pros",
    "name": "Prosthetics",
    "code": "PR",
    "description": "Prosthetic makeup and effects",
    "color": "#d8fdff"
  },
  {
    "id": "ll",
    "name": "Low Loader",
    "code": "LL",
    "description": "Vehicle mounted camera platform",
    "color": "#e6ffd8"
  },
  {
    "id": "vfx",
    "name": "Visual Effects",
    "code": "VFX",
    "description": "On-set visual effects supervision",
    "color": "#d8e5ff"
  },
  {
    "id": "ani",
    "name": "Animals",
    "code": "ANI",
    "description": "Animal handling and wrangling",
    "color": "#ffedd8"
  },
  {
    "id": "uw",
    "name": "Underwater",
    "code": "UW",
    "description": "Underwater cinematography",
    "color": "#d8f8ff"
  }
]
EOF

# Create areas.json
cat > "$DATA_DIR/areas.json" << 'EOF'
[
  {
    "id": "studio",
    "name": "Studio",
    "color": "#fffbc8"
  },
  {
    "id": "north",
    "name": "Dublin North",
    "color": "#d4e9ff"
  },
  {
    "id": "south",
    "name": "Dublin South",
    "color": "#ffd8d8"
  },
  {
    "id": "wicklow",
    "name": "Wicklow",
    "color": "#e6ffd8"
  },
  {
    "id": "ardmore",
    "name": "Ardmore Studios",
    "color": "#f2d8ff"
  },
  {
    "id": "ashford",
    "name": "Ashford Studios",
    "color": "#ffd8e6"
  }
]
EOF

# Create locations.json
cat > "$DATA_DIR/locations.json" << 'EOF'
[
  {
    "id": "studio-a",
    "name": "Studio A",
    "areaId": "studio",
    "address": "Studio Complex, Sound Stage A",
    "notes": "Full sound stage with green screen capability"
  },
  {
    "id": "studio-b",
    "name": "Studio B",
    "areaId": "studio",
    "address": "Studio Complex, Sound Stage B",
    "notes": "Medium sound stage with water tank"
  },
  {
    "id": "ardmore-a",
    "name": "A Stage",
    "areaId": "ardmore",
    "address": "Ardmore Studios, Bray",
    "notes": "Large sound stage"
  },
  {
    "id": "ardmore-d",
    "name": "D Stage",
    "areaId": "ardmore",
    "address": "Ardmore Studios, Bray",
    "notes": "Medium sound stage"
  },
  {
    "id": "mansion",
    "name": "Kilruddery House",
    "areaId": "wicklow",
    "address": "Kilruddery House, Bray",
    "notes": "Historic mansion with extensive grounds"
  },
  {
    "id": "city-hall",
    "name": "Dublin City Hall",
    "areaId": "south",
    "address": "City Hall, Dame Street, Dublin 2",
    "notes": "Historic city hall building"
  },
  {
    "id": "phoenix-park",
    "name": "Phoenix Park",
    "areaId": "north",
    "address": "Phoenix Park, Dublin 8",
    "notes": "Large urban park with various locations"
  }
]
EOF

# Create basic JavaScript file for location area coloring
mkdir -p "$STATIC_DIR/js"
cat > "$STATIC_DIR/js/calendar.js" << 'EOF'
/**
 * Calendar utility functions
 */

document.addEventListener('DOMContentLoaded', function() {
  // Get all location areas from the calendar container
  const locationAreas = getLocationAreas();
  
  // Apply location area colors to rows
  applyLocationAreaColors(locationAreas);
  
  // Apply department tag colors
  applyDepartmentTagColors();
});

/**
 * Get location areas from calendar data
 */
function getLocationAreas() {
  const areaElements = document.querySelectorAll('.area-tag');
  const areas = {};
  
  areaElements.forEach(el => {
    const areaName = el.textContent;
    const backgroundColor = el.style.backgroundColor;
    
    if (areaName && backgroundColor) {
      areas[areaName] = backgroundColor;
    }
  });
  
  return areas;
}

/**
 * Apply location area colors to rows
 */
function applyLocationAreaColors(areas) {
  const rows = document.querySelectorAll('.calendar-row');
  
  rows.forEach(row => {
    const locationCell = row.querySelector('.location-cell');
    const areaAttribute = row.getAttribute('data-area');
    
    // If row has area attribute, use that
    if (areaAttribute && areas[areaAttribute]) {
      row.style.backgroundColor = areas[areaAttribute];
      return;
    }
    
    // Otherwise try to find location in the row
    if (locationCell) {
      const locationText = locationCell.textContent.trim();
      
      // Find area that matches this location
      for (const areaName in areas) {
        if (locationText.includes(areaName)) {
          row.style.backgroundColor = areas[areaName];
          break;
        }
      }
    }
  });
}

/**
 * Apply department tag colors
 */
function applyDepartmentTagColors() {
  // We need to implement this based on your actual department data structure
  // This is just a placeholder for now
  const departmentColors = {
    "SFX": "#ffd8e6",
    "STN": "#ffecd8",
    "CR": "#d8fff2",
    "ST": "#f2d8ff",
    "PR": "#d8fdff",
    "LL": "#e6ffd8",
    "VFX": "#d8e5ff",
    "ANI": "#ffedd8",
    "UW": "#d8f8ff"
  };
  
  const departmentTags = document.querySelectorAll('.department-tag');
  
  departmentTags.forEach(tag => {
    const deptCode = tag.textContent.trim();
    
    if (departmentColors[deptCode]) {
      tag.style.backgroundColor = departmentColors[deptCode];
      
      // Set text color based on background brightness
      const rgb = hexToRgb(departmentColors[deptCode]);
      if (rgb) {
        const brightness = (rgb.r * 299 + rgb.g * 587 + rgb.b * 114) / 1000;
        tag.style.color = brightness > 128 ? '#000000' : '#ffffff';
      }
    }
  });
}

/**
 * Convert hex color to RGB
 */
function hexToRgb(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : null;
}
EOF

echo "----------------------------------------"
echo "Installation complete!"
echo "Restart your application to apply the changes."
echo "----------------------------------------"
