#!/bin/bash
# Update color schemes for prep days, shoot days, and weekends

# Create backup
BACKUP_PATH="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)_color_update"
mkdir -p "${BACKUP_PATH}"
cp -r /mnt/user/appdata/film-scheduler-v4/static/css/calendar.css "${BACKUP_PATH}/"

# Update calendar.css with new color scheme
cat >> /mnt/user/appdata/film-scheduler-v4/static/css/calendar.css << 'EOCSS'
/* Updated color scheme as requested - April 2025 */
.calendar-row.prep {
  background-color: color-mix(in srgb, #e0ffe0 75%, var(--row-area-color, white)) !important; /* Green for prep days */
}

.calendar-row.shoot {
  background-color: color-mix(in srgb, #e0f0ff 75%, var(--row-area-color, white)) !important; /* Light/teal blue for shoot days */
}

.calendar-row.weekend {
  background-color: color-mix(in srgb, #f0f0f0 75%, var(--row-area-color, white)) !important; /* Subtle light gray for weekends */
}

/* Ensure print styles match */
@media print {
  .calendar-row.prep {
    background-color: color-mix(in srgb, #e0ffe0 75%, var(--row-area-color, white)) !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  
  .calendar-row.shoot {
    background-color: color-mix(in srgb, #e0f0ff 75%, var(--row-area-color, white)) !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
  
  .calendar-row.weekend {
    background-color: color-mix(in srgb, #f0f0f0 75%, var(--row-area-color, white)) !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }
}
EOCSS

echo "Updated color scheme for prep days, shoot days, and weekends."
