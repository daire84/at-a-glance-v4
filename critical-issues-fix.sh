#!/bin/bash
# Script to fix critical issues in Film Production Scheduler
# This fixes:
# 1. Data loss when updating project details
# 2. Add confirmation to Regenerate Calendar button
# 3. Fix version number duplication
# 4. Add project delete function

# Define paths (adjust these to match your actual paths)
PROJECT_PATH="/mnt/user/appdata/film-scheduler-v4"
TEMPLATES_PATH="${PROJECT_PATH}/templates"
STATIC_PATH="${PROJECT_PATH}/static"
APP_PATH="${PROJECT_PATH}/app.py"
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)_critical_fix"

# Create backup first
echo "Creating backup at ${BACKUP_PATH}..."
mkdir -p "${BACKUP_PATH}"
cp -r "${PROJECT_PATH}" "${BACKUP_PATH}"
echo "Backup created."

# Fix 1: Prevent data loss when updating project details
echo "Fixing project update handler to prevent data loss..."

# Backup app.py before modifying
cp "${APP_PATH}" "${APP_PATH}.bak"

# Fix the project update handler in app.py
# We need to modify the admin_project route to avoid regenerating the calendar
# when updating project details
sed -i '/def admin_project/,/return redirect/c\
@app.route(\x27/admin/project/<project_id>\x27, methods=[\x27GET\x27, \x27POST\x27])\
def admin_project(project_id):\
    """Project details editor"""\
    if request.method == \x27POST\x27:\
        try:\
            # Handle form submission\
            form_data = request.form.to_dict()\
            \
            # Get existing project or create new\
            if project_id != \x27new\x27:\
                project = get_project(project_id)\
                if not project:\
                    flash(\x27Project not found\x27, \x27error\x27)\
                    return redirect(url_for(\x27admin_dashboard\x27))\
                \
                # Store original dates to check if dates are changed\
                original_dates = {\
                    \x27prepStartDate\x27: project.get(\x27prepStartDate\x27),\
                    \x27shootStartDate\x27: project.get(\x27shootStartDate\x27),\
                    \x27wrapDate\x27: project.get(\x27wrapDate\x27)\
                }\
            else:\
                project = {\x27id\x27: str(uuid.uuid4())}\
                original_dates = {}\
            \
            # Update project with form data\
            for key, value in form_data.items():\
                project[key] = value\
            \
            # Save project\
            save_project(project)\
            \
            # Only generate calendar if this is a new project or if the user explicitly confirmed\
            # they want to regenerate with new dates\
            dates_changed = (\
                project_id == \x27new\x27 or\
                original_dates.get(\x27prepStartDate\x27) != project.get(\x27prepStartDate\x27) or\
                original_dates.get(\x27shootStartDate\x27) != project.get(\x27shootStartDate\x27) or\
                original_dates.get(\x27wrapDate\x27) != project.get(\x27wrapDate\x27)\
            )\
            \
            if project_id == \x27new\x27:\
                # For new projects, always generate the calendar\
                generate_calendar(project)\
                flash(\x27Project created and calendar generated successfully\x27, \x27success\x27)\
            elif dates_changed and request.form.get(\x27regenerate_calendar\x27) == \x27yes\x27:\
                # Only regenerate if dates changed AND user confirmed\
                generate_calendar(project)\
                flash(\x27Project updated and calendar regenerated successfully\x27, \x27success\x27)\
            else:\
                # Otherwise just save the project without regenerating calendar\
                flash(\x27Project updated successfully\x27, \x27success\x27)\
            \
            return redirect(url_for(\x27admin_calendar\x27, project_id=project[\x27id\x27]))\
            \
        except Exception as e:\
            logger.error(f"Error saving project: {str(e)}")\
            flash(f\x27Error saving project: {str(e)}\x27, \x27error\x27)\
    \
    # GET request or form validation failed\
    project = get_project(project_id) if project_id != \x27new\x27 else {}\
    return render_template(\x27admin/project.html\x27, project=project)' "${APP_PATH}"

echo "Fixed project update handler."

# Fix 2: Add confirmation dialog to the Regenerate Calendar button
echo "Adding confirmation dialog to Regenerate Calendar button..."

# Update admin/calendar.html to add confirmation dialog
cp "${TEMPLATES_PATH}/admin/calendar.html" "${TEMPLATES_PATH}/admin/calendar.html.bak"
sed -i 's|<a href="/api/projects/{{ project.id }}/calendar/generate" class="button" id="regenerate-calendar">Regenerate Calendar</a>|<button class="button" id="regenerate-calendar">Regenerate Calendar</button>|g' "${TEMPLATES_PATH}/admin/calendar.html"

# Add the JavaScript for the confirmation dialog to the calendar.html script section
sed -i '/<script>/,/<\/script>/c\
<script>\
    document.addEventListener("DOMContentLoaded", function() {\
        // Add click handler for regenerate calendar button\
        const regenerateBtn = document.getElementById("regenerate-calendar");\
        if (regenerateBtn) {\
            regenerateBtn.addEventListener("click", function(e) {\
                e.preventDefault();\
                \
                // Show confirmation dialog\
                if (confirm("WARNING: Regenerating the calendar will reset all day information to defaults based on project dates. This cannot be undone. Are you sure you want to proceed?")) {\
                    // Show loading state\
                    this.textContent = "Generating...";\
                    this.disabled = true;\
                    \
                    // Call the API to regenerate calendar\
                    fetch("/api/projects/{{ project.id }}/calendar/generate", {\
                        method: "POST",\
                        headers: {\
                            "Content-Type": "application/json",\
                        }\
                    })\
                    .then(response => {\
                        if (!response.ok) {\
                            throw new Error("Failed to regenerate calendar");\
                        }\
                        return response.json();\
                    })\
                    .then(data => {\
                        // Reload page to show updated calendar\
                        window.location.reload();\
                    })\
                    .catch(error => {\
                        alert("Error: " + error.message);\
                        this.textContent = "Regenerate Calendar";\
                        this.disabled = false;\
                    });\
                }\
            });\
        }\
    });\
</script>' "${TEMPLATES_PATH}/admin/calendar.html"

echo "Added confirmation dialog to Regenerate Calendar button."

# Fix 3: Fix version number duplication
echo "Fixing version number duplication..."

# Update admin/calendar.html to remove the old version number
sed -i '/<div class="meta-group">/,/<\/div>/{/<div class="meta-label">Version<\/div>/,/<\/div>/d;}' "${TEMPLATES_PATH}/admin/calendar.html"

# Update viewer.html to remove the old version number
cp "${TEMPLATES_PATH}/viewer.html" "${TEMPLATES_PATH}/viewer.html.bak"
sed -i '/<div class="meta-group">/,/<\/div>/{/<div class="meta-label">Version<\/div>/,/<\/div>/d;}' "${TEMPLATES_PATH}/viewer.html"

echo "Fixed version number duplication."

# Fix 4: Add project delete function
echo "Adding project delete function..."

# Add delete button to admin/dashboard.html
cp "${TEMPLATES_PATH}/admin/dashboard.html" "${TEMPLATES_PATH}/admin/dashboard.html.bak"

# Find the edit/view buttons and add delete button
sed -i 's|<a href="/admin/calendar/{{ project.id }}" class="button small">Edit Calendar</a>[ ]*<a href="/viewer/{{ project.id }}" class="button small secondary">View</a>|<a href="/admin/calendar/{{ project.id }}" class="button small">Edit Calendar</a><a href="/viewer/{{ project.id }}" class="button small secondary">View</a><button class="button small danger delete-project" data-id="{{ project.id }}" data-title="{{ project.title }}">Delete</button>|g' "${TEMPLATES_PATH}/admin/dashboard.html"

# Add JavaScript for project deletion
cat >> "${TEMPLATES_PATH}/admin/dashboard.html" << 'EOF'
{% block scripts %}
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // Set up delete project buttons
        document.querySelectorAll('.delete-project').forEach(button => {
            button.addEventListener('click', function() {
                const projectId = this.getAttribute('data-id');
                const projectTitle = this.getAttribute('data-title') || 'this project';
                
                if (confirm(`WARNING: Are you sure you want to delete "${projectTitle}"? This action cannot be undone.`)) {
                    // Show loading state
                    this.textContent = 'Deleting...';
                    this.disabled = true;
                    
                    // Call delete API
                    fetch(`/api/projects/${projectId}`, {
                        method: 'DELETE'
                    })
                    .then(response => {
                        if (!response.ok) {
                            throw new Error('Failed to delete project');
                        }
                        return response.json();
                    })
                    .then(data => {
                        // Remove the project card from the UI
                        const projectCard = this.closest('.project-card');
                        if (projectCard) {
                            projectCard.remove();
                        }
                        
                        // Refresh if all projects are deleted
                        const remainingProjects = document.querySelectorAll('.project-card');
                        if (remainingProjects.length === 0) {
                            window.location.reload();
                        }
                    })
                    .catch(error => {
                        alert('Error: ' + error.message);
                        this.textContent = 'Delete';
                        this.disabled = false;
                    });
                }
            });
        });
    });
</script>
{% endblock %}
