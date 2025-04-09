#!/bin/bash
# Center location area legend

# Create backup
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)_legend_fix"
mkdir -p "${BACKUP_PATH}"
cp -r /mnt/user/appdata/film-scheduler-v4/static/css/calendar.css "${BACKUP_PATH}/"

# Add CSS to center the location areas display
cat >> /mnt/user/appdata/film-scheduler-v4/static/css/calendar.css << 'EOCSS'
/* Center location area legend */
.location-areas {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
}

.area-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  justify-content: center;
}
EOCSS

echo "Centered location area legend."
