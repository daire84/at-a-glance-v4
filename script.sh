#!/bin/bash
# VERY focused change: Only update the script color display in admin calendar
# This script only modifies one small part of templates/admin/calendar.html

# Backup the specific file we're changing
cd /mnt/user/appdata/film-scheduler-v4
cp templates/admin/calendar.html templates/admin/calendar.html.bak

# Find and replace just the script color section
# First, check if the pattern exists
if grep -q '<span class="script-color-block" style="background-color:' templates/admin/calendar.html; then
  # Use sed to update just the script color section
  sed -i '/<div class="script-label">Color:<\/div>/,/<\/div>/ c\
                <div class="script-label">Color:<\/div>\n                <div class="script-value">\n                    <span class="script-color-badge" style="background-color: \
                        {% if project.scriptColor == '\''White'\'' %}#ffffff\
                        {% elif project.scriptColor == '\''Blue'\'' %}#add8e6\
                        {% elif project.scriptColor == '\''Pink'\'' %}#ffb6c1\
                        {% elif project.scriptColor == '\''Yellow'\'' %}#ffff99\
                        {% elif project.scriptColor == '\''Green'\'' %}#90ee90\
                        {% elif project.scriptColor == '\''Goldenrod'\'' %}#daa520\
                        {% else %}#ffffff{% endif %}">{{ project.scriptColor }}</span>\n                </div>' templates/admin/calendar.html
  echo "Script color display updated in admin calendar page"
else
  echo "Pattern not found - script color section may have changed. Manual update required."
fi

# Make sure we have the CSS class defined for script-color-badge
if ! grep -q ".script-color-badge" static/css/calendar.css; then
  echo "Adding script-color-badge CSS class definition..."
  cat >> static/css/calendar.css << 'EOF'

/* Script color badge styling */
.script-color-badge {
    display: inline-block;
    padding: 0.25rem 0.6rem;
    border-radius: 3px;
    font-size: 0.85rem;
    font-weight: 500;
    border: 1px solid rgba(0,0,0,0.1);
    box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}
EOF
fi
