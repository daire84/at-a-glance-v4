#!/bin/bash
# Fix project delete button visibility

# Create backup
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)_delete_fix"
mkdir -p "${BACKUP_PATH}"
cp -r /mnt/user/appdata/film-scheduler-v4/templates/admin/dashboard.html "${BACKUP_PATH}/"

# Add a more visible delete button with guaranteed placement
sed -i '/<div class="project-actions">/a \
                            <button class="button small danger delete-project" data-id="{{ project.id }}" data-title="{{ project.title }}" style="margin-left: 5px; background-color: #f44336;">Delete</button>' /mnt/user/appdata/film-scheduler-v4/templates/admin/dashboard.html

echo "Delete button placement fixed."
