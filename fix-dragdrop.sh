#!/bin/bash
# Script to fix parameter names in calendar-dragdrop.js

# Define file paths
FILE_PATH="/mnt/user/appdata/film-scheduler-v4/static/js/calendar-dragdrop.js"
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/calendar-dragdrop-${BACKUP_DATE}.js"

# Create backup directory if it doesn't exist
mkdir -p "/mnt/user/backups/film-scheduler-v4"

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: $FILE_PATH does not exist!"
    exit 1
fi

# Create backup
echo "Creating backup at $BACKUP_PATH"
cp "$FILE_PATH" "$BACKUP_PATH"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create backup!"
    exit 1
fi

# Change parameter names from sourceDate/targetDate to fromDate/toDate
echo "Updating parameter names in $FILE_PATH"
sed -i 's/sourceDate: sourceDate/fromDate: sourceDate/g' "$FILE_PATH"
sed -i 's/targetDate: targetDate/toDate: targetDate/g' "$FILE_PATH"

# Verify changes
grep -n "fromDate\|toDate" "$FILE_PATH"

echo "Done! The calendar-dragdrop.js file has been updated."
echo "If you need to restore the original file, you can use: cp $BACKUP_PATH $FILE_PATH"

# Reminder to restart container
echo "Remember to restart your Docker container for changes to take effect:"
echo "docker restart film-scheduler-v4"
