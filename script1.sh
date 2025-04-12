#!/bin/bash
# VERY focused change: Only update the script color display in admin calendar
# This script only modifies one small part of templates/admin/calendar.html

# Backup the specific file we're changing
cd /mnt/user/appdata/film-scheduler-v4
cp templates/admin/calendar.html templates/admin/calendar.html.bak

# Find and replace just the script color section
sed -i 's/<span class="script-color-block" style="background-color:.*$/<span class="script-color-badge" style="background-color:/g' templates/admin/calendar.html
sed -i 's/<\/span>.*{{ project.scriptColor }}.*<\/div>/<\/span>{{ project.scriptColor }}<\/div>/g' templates/admin/calendar.html

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

echo "Script color display updated in admin calendar page"
