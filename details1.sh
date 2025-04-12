#!/bin/bash
# Carefully update the project info section in admin calendar to match viewer
# This script focuses only on the project metadata structure

# Backup the admin calendar template
cd /mnt/user/appdata/film-scheduler-v4
cp templates/admin/calendar.html templates/admin/calendar.html.project-info-bak

# Create a temporary file with the updated project info section
cat > /tmp/updated_project_info.html << 'EOF'
    <div class="project-info-header">
        <div class="project-header-top">
            <h3 class="project-title">{{ project.title or 'Untitled Project' }}</h3>
            <div class="version-badge">{{ project.version or 'V1.0' }}</div>
        </div>
        <div class="project-meta">
            <div class="meta-group">
                <div class="meta-label">Director</div>
                <div class="meta-value">{{ project.director or 'N/A' }}</div>
            </div>
            <div class="meta-group">
                <div class="meta-label">Producer</div>
                <div class="meta-value">{{ project.producer or 'N/A' }}</div>
            </div>
            <div class="meta-group">
                <div class="meta-label">First AD</div>
                <div class="meta-value">{{ project.firstAD or 'N/A' }}</div>
            </div>
            <div class="meta-group">
                <div class="meta-label">Second AD</div>
                <div class="meta-value">{{ project.secondAD or 'N/A' }}</div>
            </div>
        </div>
        
        <div class="project-meta">
            <div class="meta-group">
                <div class="meta-label">Shoot Start</div>
                <div class="meta-value">{{ project.shootStartDate or 'N/A' }}</div>
            </div>
            <div class="meta-group">
                <div class="meta-label">Wrap Date</div>
                <div class="meta-value">{{ project.wrapDate or 'N/A' }}</div>
            </div>
            <div class="meta-group">
                <div class="meta-label">Last Updated</div>
                <div class="meta-value">{{ project.updated.split('T')[0] if project.updated else 'N/A' }}</div>
            </div>
        </div>
EOF

# Very carefully replace just the project info section
# First find the line numbers to replace
START_LINE=$(grep -n '<div class="project-info-header">' templates/admin/calendar.html | cut -d':' -f1)
END_LINE=$(grep -n '<div class="calendar-actions">' templates/admin/calendar.html | cut -d':' -f1)
END_LINE=$((END_LINE - 1))  # Exclude the calendar-actions line

if [ -n "$START_LINE" ] && [ -n "$END_LINE" ]; then
    # Create a temp file with the beginning part
    head -n $((START_LINE-1)) templates/admin/calendar.html > /tmp/admin_calendar_part1.html
    
    # Create a temp file with the ending part
    tail -n +$END_LINE templates/admin/calendar.html > /tmp/admin_calendar_part3.html
    
    # Combine all parts
    cat /tmp/admin_calendar_part1.html /tmp/updated_project_info.html /tmp/admin_calendar_part3.html > templates/admin/calendar.html
    
    echo "Project info section successfully updated"
else
    echo "ERROR: Could not find project info section boundaries"
    exit 1
fi

# Cleanup
rm -f /tmp/updated_project_info.html /tmp/admin_calendar_part1.html /tmp/admin_calendar_part3.html

echo "Project info section update complete"
