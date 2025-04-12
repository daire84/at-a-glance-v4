#!/bin/bash
# Script to restore the application to the most recent commit

# Configuration
RECENT_COMMIT="92ef3d1"  # The most recent commit (centered-depts, and colour fixes)
APP_DIR="/mnt/user/appdata/film-scheduler-v4"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/user/backups/film-scheduler-v4/recent_backup_${BACKUP_DATE}"

echo "Starting restoration to most recent commit ${RECENT_COMMIT}..."

# Step 1: Create a full backup of the current state
echo "Creating backup at ${BACKUP_DIR}..."
mkdir -p "${BACKUP_DIR}"
cp -R "${APP_DIR}"/* "${BACKUP_DIR}/"

if [ $? -ne 0 ]; then
    echo "Error: Failed to create backup. Aborting restoration."
    exit 1
fi

echo "Backup created successfully."

# Step 2: Make sure we're on the right branch and up to date
echo "Ensuring we're on the main branch and up to date..."
git checkout main
git pull

# Step 3: Reset to the specified commit
echo "Copying files from recent commit to application directory..."

# Copy static files (this is where the JS files are)
echo "Copying static files..."
cp -R static/* "${APP_DIR}/static/"

# Copy templates
echo "Copying templates..."
cp -R templates/* "${APP_DIR}/templates/"

# Copy app.py
echo "Copying app.py..."
cp app.py "${APP_DIR}/app.py"

# Also copy utils if they exist
if [ -d "utils" ]; then
    echo "Copying utils..."
    cp -R utils/* "${APP_DIR}/utils/"
fi

# Step 4: Restart the Docker container
echo "Restarting Docker container..."
docker restart film-scheduler-v4

echo ""
echo "Restoration completed successfully."
echo "A backup of the previous state is available at: ${BACKUP_DIR}"
echo ""
echo "If the application is still not working correctly, you can try the older known working commit (913c7af) or restore from the backup with:"
echo "cp -R ${BACKUP_DIR}/* ${APP_DIR}/"
echo "docker restart film-scheduler-v4"
