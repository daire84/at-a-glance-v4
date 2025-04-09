# Create a backup
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)_fix4"
mkdir -p "${BACKUP_PATH}"
cp -r /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html "${BACKUP_PATH}/"
echo "Backup created at ${BACKUP_PATH}"

# Change the regenerate button from a link to a button with JavaScript
sed -i 's|<a href="/api/projects/{{ project.id }}/calendar/generate" class="button" id="regenerate-calendar">Regenerate Calendar</a>|<button class="button" id="regenerate-calendar">Regenerate Calendar</button>|g' /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html

# Add JavaScript for the confirmation
cat > /tmp/regenerate-script.html << 'EOF'
<script>
    document.addEventListener("DOMContentLoaded", function() {
        // Add click handler for regenerate calendar button
        const regenerateBtn = document.getElementById("regenerate-calendar");
        if (regenerateBtn) {
            regenerateBtn.addEventListener("click", function(e) {
                e.preventDefault();
                
                // Show confirmation dialog
                if (confirm("WARNING: Regenerating the calendar will reset all day information to defaults based on project dates. This cannot be undone. Are you sure you want to proceed?")) {
                    // Show loading state
                    this.textContent = "Generating...";
                    this.disabled = true;
                    
                    // Call the API to regenerate calendar
                    fetch("/api/projects/{{ project.id }}/calendar/generate", {
                        method: "POST",
                        headers: {
                            "Content-Type": "application/json",
                        }
                    })
                    .then(response => {
                        if (!response.ok) {
                            throw new Error("Failed to regenerate calendar");
                        }
                        return response.json();
                    })
                    .then(data => {
                        // Reload page to show updated calendar
                        window.location.reload();
                    })
                    .catch(error => {
                        alert("Error: " + error.message);
                        this.textContent = "Regenerate Calendar";
                        this.disabled = false;
                    });
                }
            });
        }
    });
</script>
EOF

# Replace or add the script block
if grep -q "<script>" /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html; then
    # Replace existing script block
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
</script>' /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html
else
    # Add new script block at the end of the block content
    sed -i "s|{% endblock %}|<script>\n    document.addEventListener(\"DOMContentLoaded\", function() {\n        // Add click handler for regenerate calendar button\n        const regenerateBtn = document.getElementById(\"regenerate-calendar\");\n        if (regenerateBtn) {\n            regenerateBtn.addEventListener(\"click\", function(e) {\n                e.preventDefault();\n                \n                // Show confirmation dialog\n                if (confirm(\"WARNING: Regenerating the calendar will reset all day information to defaults based on project dates. This cannot be undone. Are you sure you want to proceed?\")) {\n                    // Show loading state\n                    this.textContent = \"Generating...\";\n                    this.disabled = true;\n                    \n                    // Call the API to regenerate calendar\n                    fetch(\"/api/projects/{{ project.id }}/calendar/generate\", {\n                        method: \"POST\",\n                        headers: {\n                            \"Content-Type\": \"application/json\",\n                        }\n                    })\n                    .then(response => {\n                        if (!response.ok) {\n                            throw new Error(\"Failed to regenerate calendar\");\n                        }\n                        return response.json();\n                    })\n                    .then(data => {\n                        // Reload page to show updated calendar\n                        window.location.reload();\n                    })\n                    .catch(error => {\n                        alert(\"Error: \" + error.message);\n                        this.textContent = \"Regenerate Calendar\";\n                        this.disabled = false;\n                    });\n                }\n            });\n        }\n    });\n</script>\n{% endblock %}|" /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html
fi

echo "Added confirmation for Regenerate Calendar button"
