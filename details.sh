#!/bin/bash
# This script extracts and compares the project info sections from both templates
# So we can see exactly what needs to be aligned

cd /mnt/user/appdata/film-scheduler-v4

# Extract the project info sections from both templates
echo "Extracting project info from admin calendar..."
sed -n '/<div class="project-info-header">/,/<\/div>/p' templates/admin/calendar.html > admin_project_info.txt

echo "Extracting project info from viewer..."
sed -n '/<div class="project-info-header">/,/<\/div>/p' templates/viewer.html > viewer_project_info.txt

# Show the differences
echo "Differences between admin and viewer project info sections:"
diff -u admin_project_info.txt viewer_project_info.txt

# Cleanup
rm admin_project_info.txt viewer_project_info.txt

echo "Run this script to see the exact differences, then we'll create a targeted fix"
