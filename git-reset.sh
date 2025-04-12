#!/bin/bash
# Script to restore to a specific commit using git commands

# Configuration
APP_DIR="/mnt/user/appdata/film-scheduler-v4"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/user/backups/film-scheduler-v4/git_backup_${BACKUP_DATE}"

# Check if a commit was provided
if [ -z "$1" ]; then
  echo "No commit specified. Usage: $0 <commit-hash>"
  echo "Available commits:"
  git log --oneline -10
  exit 1
fi

TARGET_COMMIT="$1"
echo "Starting restoration to commit ${TARGET_COMMIT}..."

# Navigate to the application directory
cd "${APP_DIR}"

# Step 1: Create a backup of data files that aren't tracked by git
echo "Creating backup of data files at ${BACKUP_DIR}..."
mkdir -p "${BACKUP_DIR}/data"
if [ -d "data" ]; then
  cp -R data/* "${BACKUP_DIR}/data/"
fi

# Step 2: Save the current git status in case we need to reference it
git status > "${BACKUP_DIR}/git_status.txt"
git diff > "${BACKUP_DIR}/git_diff.txt"

# Step 3: Reset to the specified commit
echo "Resetting to commit ${TARGET_COMMIT}..."
git reset --hard "${TARGET_COMMIT}"

# Step 4: Restore the data directory if it's not tracked by git
if [ -d "${BACKUP_DIR}/data" ]; then
  echo "Restoring data directory..."
  # Create the data directory if it doesn't exist
  mkdir -p data
  # Copy the backed-up data files back
  cp -R "${BACKUP_DIR}/data/"* data/
fi

# Step 5: Restart the Docker container
echo "Restarting Docker container..."
docker restart film-scheduler-v4

echo ""
echo "Restoration completed successfully."
echo "Your application has been reset to commit: ${TARGET_COMMIT}"
echo "A backup of data files is available at: ${BACKUP_DIR}"
echo ""
echo "To return to the latest commit, run:"
echo "cd ${APP_DIR} && git pull"
echo "docker restart film-scheduler-v4"
