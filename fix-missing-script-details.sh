#!/bin/bash
# Fix missing script details in admin calendar template
# This script restores the script details section that got removed

cd /mnt/user/appdata/film-scheduler-v4

# Create backup if it doesn't exist already
if [ ! -f templates/admin/calendar.html.script-details-bak ]; then
  cp templates/admin/calendar.html templates/admin/calendar.html.script-details-bak
fi

# Extract script details section from backup or viewer
if [ -f templates/admin/calendar.html.project-info-bak ]; then
  echo "Using backup to restore script details..."
  # Extract the script details section from the backup
  SCRIPT_DETAILS=$(sed -n '/{% if project.scriptTitle %}/,/{% endif %}/p' templates/admin/calendar.html.project-info-bak)
else
  echo "Using viewer template to restore script details..."
  # Extract the script details section from the viewer template
  SCRIPT_DETAILS=$(sed -n '/{% if project.scriptTitle %}/,/{% endif %}/p' templates/viewer.html)
fi

# Now we need to add this script details section to the project-meta section in admin template
# First check if the script details section is already there
if ! grep -q "project.scriptTitle" templates/admin/calendar.html; then
  echo "Script details section is missing, adding it..."
  
  # Find the closing div of the project-meta section
  sed -i '/<div class="project-meta">/,/<\/div>/ {
    /<\/div>/a\
        \
        {% if project.scriptTitle %}\
        <div class="script-info">\
            <div class="script-item">\
                <div class="script-label">Script:</div>\
                <div class="script-value">{{ project.scriptTitle }}</div>\
            </div>\
            {% if project.scriptEpisode %}\
            <div class="script-item">\
                <div class="script-label">Episode:</div>\
                <div class="script-value">{{ project.scriptEpisode }}</div>\
            </div>\
            {% endif %}\
            {% if project.scriptDated %}\
            <div class="script-item">\
                <div class="script-label">Dated:</div>\
                <div class="script-value">{{ project.scriptDated }}</div>\
            </div>\
            {% endif %}\
            {% if project.scriptColor %}\
            <div class="script-item">\
                <div class="script-label">Color:</div>\
                <div class="script-value">\
                    <span class="script-color-badge" style="background-color: \
                        {% if project.scriptColor == '"'"'White'"'"' %}#ffffff\
                        {% elif project.scriptColor == '"'"'Blue'"'"' %}#add8e6\
                        {% elif project.scriptColor == '"'"'Pink'"'"' %}#ffb6c1\
                        {% elif project.scriptColor == '"'"'Yellow'"'"' %}#ffff99\
                        {% elif project.scriptColor == '"'"'Green'"'"' %}#90ee90\
                        {% elif project.scriptColor == '"'"'Goldenrod'"'"' %}#daa520\
                        {% else %}#ffffff{% endif %}; \
                        color: {% if project.scriptColor == '"'"'White'"'"' %}#000000\
                        {% elif project.scriptColor == '"'"'Yellow'"'"' %}#000000\
                        {% else %}#ffffff{% endif %};">\
                        {{ project.scriptColor }}\
                    </span>\
                </div>\
            </div>\
            {% endif %}\
        </div>\
        {% endif %}
  }' templates/admin/calendar.html
  
  echo "Script details section has been restored"
else
  echo "Script details section already exists, no changes made"
fi

echo "Fix complete - please check the admin calendar page"
