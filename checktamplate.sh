#!/bin/bash
# Check that the admin/calendar.html template includes the script tags in the right order

cd /mnt/user/appdata/film-scheduler-v4

# Extract the script section from the template
grep -A 10 "{% block scripts %}" templates/admin/calendar.html

# Now make sure all the required scripts are included correctly
SCRIPT_SECTION=$(cat templates/admin/calendar.html | sed -n '/{% block scripts %}/,/{% endblock %}/p')

# Check if both scripts are included
if [[ $SCRIPT_SECTION == *"calendar-dragdrop.js"* && $SCRIPT_SECTION == *"calendar.js"* ]]; then
  echo "Both scripts are included in the template."
else
  echo "WARNING: Missing one or more required scripts in the template."
  
  # Update the script section to ensure both scripts are included
  sed -i '/{% block scripts %}/,/{% endblock %}/c\
{% block scripts %}\
<script src="/static/js/calendar-move.js"></script>\
<script src="/static/js/calendar-dragdrop.js"></script>\
<script src="/static/js/calendar.js"></script>\
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
</script>\
{% endblock %}' templates/admin/calendar.html

  echo "Updated the script section in the template."
fi
