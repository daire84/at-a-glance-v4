# Create a backup
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)_fix3"
mkdir -p "${BACKUP_PATH}"
cp -r /mnt/user/appdata/film-scheduler-v4/templates/viewer.html "${BACKUP_PATH}/viewer.html"
cp -r /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html "${BACKUP_PATH}/calendar.html"
echo "Backup created at ${BACKUP_PATH}"

# Fix version duplication in viewer.html
sed -i '/<div class="meta-group">/{N;N;N;/Version/d;}' /mnt/user/appdata/film-scheduler-v4/templates/viewer.html

# Fix version duplication in admin/calendar.html
sed -i '/<div class="meta-group">/{N;N;N;/Version/d;}' /mnt/user/appdata/film-scheduler-v4/templates/admin/calendar.html

echo "Fixed version number duplication"
