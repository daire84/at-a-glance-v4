#!/bin/bash
# Carefully update the script color styling in admin calendar to match viewer
# This is a very targeted change focusing only on the script color presentation

cd /mnt/user/appdata/film-scheduler-v4
cp templates/admin/calendar.html templates/admin/calendar.html.script-color-bak

# Create the replacement script color section
cat > /tmp/updated_script_color.html << 'EOF'
                <div class="script-label">Color:</div>
                <div class="script-value">
                    <span class="script-color-badge" style="background-color: 
                        {% if project.scriptColor == 'White' %}#ffffff
                        {% elif project.scriptColor == 'Blue' %}#add8e6
                        {% elif project.scriptColor == 'Pink' %}#ffb6c1
                        {% elif project.scriptColor == 'Yellow' %}#ffff99
                        {% elif project.scriptColor == 'Green' %}#90ee90
                        {% elif project.scriptColor == 'Goldenrod' %}#daa520
                        {% else %}#ffffff{% endif %}; 
                        color: {% if project.scriptColor == 'White' %}#000000
                        {% elif project.scriptColor == 'Yellow' %}#000000
                        {% else %}#ffffff{% endif %};">
                        {{ project.scriptColor }}
                    </span>
                </div>
EOF

# Find the script color section in the admin calendar template
SCRIPT_COLOR_START=$(grep -n '<div class="script-label">Color:</div>' templates/admin/calendar.html | cut -d':' -f1)
if [ -n "$SCRIPT_COLOR_START" ]; then
    SCRIPT_COLOR_END=$((SCRIPT_COLOR_START + 7))  # Approximate line count for the whole section
    
    # Create temp files with parts before and after the script color section
    head -n $((SCRIPT_COLOR_START-1)) templates/admin/calendar.html > /tmp/admin_calendar_part1.html
    tail -n +$SCRIPT_COLOR_END templates/admin/calendar.html > /tmp/admin_calendar_part2.html
    
    # Combine all parts
    cat /tmp/admin_calendar_part1.html /tmp/updated_script_color.html /tmp/admin_calendar_part2.html > templates/admin/calendar.html
    
    echo "Script color styling successfully updated"
else
    echo "ERROR: Could not find script color section"
    exit 1
fi

# Cleanup
rm -f /tmp/updated_script_color.html /tmp/admin_calendar_part1.html /tmp/admin_calendar_part2.html

# Ensure we have the CSS class defined
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

echo "Script color styling update complete"
