# Create a backup
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)_fix2"
mkdir -p "${BACKUP_PATH}"
cp -r /mnt/user/appdata/film-scheduler-v4/templates/admin/dashboard.html "${BACKUP_PATH}/"
echo "Backup created at ${BACKUP_PATH}"

# Add the delete button to project cards
sed -i 's|<a href="/admin/calendar/{{ project.id }}" class="button small">Edit Calendar</a>.*<a href="/viewer/{{ project.id }}" class="button small secondary">View</a>|<a href="/admin/calendar/{{ project.id }}" class="button small">Edit Calendar</a> <a href="/viewer/{{ project.id }}" class="button small secondary">View</a> <button class="button small danger delete-project" data-id="{{ project.id }}" data-title="{{ project.title }}">Delete</button>|g' /mnt/user/appdata/film-scheduler-v4/templates/admin/dashboard.html

# Add JavaScript for delete functionality
cat >> /mnt/user/appdata/film-scheduler-v4/templates/admin/dashboard.html << 'EOF'

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
EOF

echo "Added delete project functionality"
