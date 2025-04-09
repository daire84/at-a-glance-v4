#!/bin/bash
# Script to apply UI refinements to Film Production Scheduler application
# This script updates the CSS and template files to implement the UI improvements

# Define paths (adjust these to match your actual paths)
PROJECT_PATH="/mnt/user/appdata/film-scheduler-v4"
TEMPLATES_PATH="${PROJECT_PATH}/templates"
STATIC_PATH="${PROJECT_PATH}/static"
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)"

# Create backup first
echo "Creating backup at ${BACKUP_PATH}..."
mkdir -p "${BACKUP_PATH}"
cp -r "${PROJECT_PATH}" "${BACKUP_PATH}"
echo "Backup created."

# Update calendar.css with column width and height adjustments
echo "Updating calendar.css..."
cat >> "${STATIC_PATH}/css/calendar.css" << 'EOCSS'
/* UI Refinements - Added $(date +%Y-%m-%d) */

/* Make the calendar more compact overall */
.calendar-table th,
.calendar-table td {
    padding: 0.4rem;  /* Reduced from 0.5rem */
    font-size: 0.8rem;  /* Slightly smaller font */
}

/* Column width adjustments */
.date-col {
    width: 85px;  /* Reduced from 90px */
}

.day-col {
    width: 35px;  /* Reduced from 40px */
    text-align: center;
}

.extras-col,
.featured-extras-col {
    width: 30px;  /* Reduced from 40px */
    text-align: center;
}

/* Allow main unit to have line breaks */
.main-unit-cell {
    white-space: pre-line;
    line-height: 1.2;
}

/* Reduced notes font size */
.notes-cell {
    font-size: 0.75rem;  /* Reduced from 0.8rem */
    line-height: 1.2;
    white-space: pre-line;
}

/* Reduce row height overall */
.calendar-row {
    max-height: 4.5rem;  /* Limit maximum height */
}

/* Reduced height for department tags */
.department-tag {
    padding: 0.1rem 0.25rem;  /* Reduced from 0.15rem 0.3rem */
    font-size: 0.7rem;  /* Reduced from 0.75rem */
    line-height: 1;
    margin: 0.1rem 0.1rem;
    display: inline-block;
}

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

/* Project header top with version badge */
.project-header-top {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.8rem;
}

.version-badge {
    background-color: var(--accent-color);
    color: white;
    padding: 0.25rem 0.6rem;
    border-radius: 4px;
    font-size: 0.8rem;
    font-weight: 500;
    letter-spacing: 0.02em;
}

/* Fix the double line in department tags box */
.departments-cell {
    display: flex;
    flex-wrap: wrap;
    gap: 0.15rem;  /* Smaller gap instead of margin on individual tags */
    padding: 0.1rem;
    max-height: 3.5rem;  /* Limit max height */
    overflow-y: auto;
}

/* Two-tiered location/area display */
.location-cell {
    display: flex;
    flex-direction: column;
    gap: 0.1rem;
    vertical-align: middle;
}

.location-name {
    font-weight: 500;
    font-size: 0.8rem;
}

.location-area {
    font-size: 0.7rem;
    color: var(--text-light);
    font-style: italic;
    opacity: 0.9;
}

/* Improved department tags display */
.departments-cell {
    display: flex;
    flex-wrap: wrap;
    gap: 0.15rem;
    padding: 0.15rem;
    align-items: flex-start;
    max-height: 3.2rem;
    overflow-y: auto;
}

.department-tag {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 3px;
    padding: 0.1rem 0.3rem;
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    box-shadow: 0 1px 1px rgba(0,0,0,0.05);
    margin: 0;
    border: 1px solid rgba(0,0,0,0.05);
    line-height: 1;
}
EOCSS
echo "calendar.css updated."

# Update viewer.html template to implement script color and version badge changes
echo "Updating viewer.html template..."
cp "${TEMPLATES_PATH}/viewer.html" "${TEMPLATES_PATH}/viewer.html.bak"
sed -i 's|<h3 class="project-title">{{ project.title or '"'"'Untitled Project'"'"' }}</h3>|<div class="project-header-top">\n        <h3 class="project-title">{{ project.title or '"'"'Untitled Project'"'"' }}</h3>\n        <div class="version-badge">{{ project.version or '"'"'V1.0'"'"' }}</div>\n    </div>|g' "${TEMPLATES_PATH}/viewer.html"

# Update script color display
sed -i 's|<div class="script-item">.*Color:.*<\/div>.*<\/div>|<div class="script-item">\n                <div class="script-label">Color:</div>\n                <div class="script-value">\n                    {% if project.scriptColor %}\n                        <span class="script-color-badge" style="background-color: {% if project.scriptColor == '"'"'White'"'"' %}#ffffff{% elif project.scriptColor == '"'"'Blue'"'"' %}#add8e6{% elif project.scriptColor == '"'"'Pink'"'"' %}#ffb6c1{% elif project.scriptColor == '"'"'Yellow'"'"' %}#ffff99{% elif project.scriptColor == '"'"'Green'"'"' %}#90ee90{% elif project.scriptColor == '"'"'Goldenrod'"'"' %}#daa520{% else %}#ffffff{% endif %}; color: {% if project.scriptColor == '"'"'White'"'"' or project.scriptColor == '"'"'Yellow'"'"' %}#333333{% else %}#ffffff{% endif %};">\n                            {{ project.scriptColor }}\n                        </span>\n                    {% else %}\n                        <em>Not specified</em>\n                    {% endif %}\n                </div>\n            </div>|g' "${TEMPLATES_PATH}/viewer.html"

# Update location cell for two-tiered display
sed -i 's|<td class="location-cell">{{ day.location }}</td>|<td class="location-cell">\n                        {% if day.location %}\n                            <div class="location-name">{{ day.location }}</div>\n                            {% if day.locationArea %}\n                                <div class="location-area">{{ day.locationArea }}</div>\n                            {% endif %}\n                        {% endif %}\n                    </td>|g' "${TEMPLATES_PATH}/viewer.html"

# Update department tags cell with improved styling
sed -i 's|<td class="departments-cell">.*for dept in day.departments.*endfor.*</td>|<td class="departments-cell">\n                        {% for dept in day.departments %}\n                        <span class="department-tag" data-dept-code="{{ dept }}">{{ dept }}</span>\n                        {% endfor %}\n                    </td>|g' "${TEMPLATES_PATH}/viewer.html"
echo "viewer.html updated."

# Update admin/calendar.html template as well
echo "Updating admin/calendar.html template..."
cp "${TEMPLATES_PATH}/admin/calendar.html" "${TEMPLATES_PATH}/admin/calendar.html.bak"
sed -i 's|<h3 class="project-title">{{ project.title or '"'"'Untitled Project'"'"' }}</h3>|<div class="project-header-top">\n        <h3 class="project-title">{{ project.title or '"'"'Untitled Project'"'"' }}</h3>\n        <div class="version-badge">{{ project.version or '"'"'V1.0'"'"' }}</div>\n    </div>|g' "${TEMPLATES_PATH}/admin/calendar.html"

# Update script color display
sed -i 's|<div class="script-item">.*Color:.*<\/div>.*<\/div>|<div class="script-item">\n                <div class="script-label">Color:</div>\n                <div class="script-value">\n                    {% if project.scriptColor %}\n                        <span class="script-color-badge" style="background-color: {% if project.scriptColor == '"'"'White'"'"' %}#ffffff{% elif project.scriptColor == '"'"'Blue'"'"' %}#add8e6{% elif project.scriptColor == '"'"'Pink'"'"' %}#ffb6c1{% elif project.scriptColor == '"'"'Yellow'"'"' %}#ffff99{% elif project.scriptColor == '"'"'Green'"'"' %}#90ee90{% elif project.scriptColor == '"'"'Goldenrod'"'"' %}#daa520{% else %}#ffffff{% endif %}; color: {% if project.scriptColor == '"'"'White'"'"' or project.scriptColor == '"'"'Yellow'"'"' %}#333333{% else %}#ffffff{% endif %};">\n                            {{ project.scriptColor }}\n                        </span>\n                    {% else %}\n                        <em>Not specified</em>\n                    {% endif %}\n                </div>\n            </div>|g' "${TEMPLATES_PATH}/admin/calendar.html"

# Update location cell for two-tiered display
sed -i 's|<td class="location-cell">{{ day.location }}</td>|<td class="location-cell">\n                        {% if day.location %}\n                            <div class="location-name">{{ day.location }}</div>\n                            {% if day.locationArea %}\n                                <div class="location-area">{{ day.locationArea }}</div>\n                            {% endif %}\n                        {% endif %}\n                    </td>|g' "${TEMPLATES_PATH}/admin/calendar.html"

# Update department tags cell with improved styling
sed -i 's|<td class="departments-cell">.*for dept in day.departments.*endfor.*</td>|<td class="departments-cell">\n                        {% for dept in day.departments %}\n                        <span class="department-tag" data-dept-code="{{ dept }}">{{ dept }}</span>\n                        {% endfor %}\n                    </td>|g' "${TEMPLATES_PATH}/admin/calendar.html"
echo "admin/calendar.html updated."

# Complete
echo "UI refinements have been applied successfully!"
echo "If you need to revert changes, you can restore from backup at: ${BACKUP_PATH}"
echo "Please restart your application container to see the changes."
