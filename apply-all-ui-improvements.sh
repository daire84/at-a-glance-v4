#!/bin/bash
# Script to apply all UI improvements to the Film Production Scheduler
# Run this script from any directory - it uses absolute paths

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define paths
PROJECT_PATH="/mnt/user/appdata/film-scheduler-v4"
CSS_PATH="${PROJECT_PATH}/static/css/calendar.css"
BACKUP_DIR="/mnt/user/backups/film-scheduler-v4"
BACKUP_PATH="${BACKUP_DIR}/calendar-css-$(date +%Y%m%d%H%M%S).bak"

# Check if project path exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project directory not found at $PROJECT_PATH${NC}"
    echo "Please check the path and update the script if necessary."
    exit 1
fi

# Check if CSS file exists
if [ ! -f "$CSS_PATH" ]; then
    echo -e "${RED}Error: Calendar CSS file not found at $CSS_PATH${NC}"
    echo "Please check the path and update the script if necessary."
    exit 1
fi

# Create backup directory if it doesn't exist
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Creating backup directory: $BACKUP_DIR${NC}"
    mkdir -p "$BACKUP_DIR"
fi

# Create a backup of the CSS file
echo -e "${YELLOW}Creating backup of calendar.css at $BACKUP_PATH${NC}"
cp "$CSS_PATH" "$BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Backup created successfully!${NC}"
else
    echo -e "${RED}Failed to create backup. Aborting.${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting UI improvements application...${NC}"

# 1. Update calendar colors
echo -e "${YELLOW}Applying calendar color updates...${NC}"
cat << 'EOF' >> "$CSS_PATH"
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
EOF

# 2. Center location area legend
echo -e "${YELLOW}Applying location area legend centering...${NC}"
cat << 'EOF' >> "$CSS_PATH"
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
EOF

# 3. Improve department counters display
echo -e "${YELLOW}Applying department counters improvements...${NC}"
cat << 'EOF' >> "$CSS_PATH"
/* Department Counters Improvements */
.department-counters {
  margin-bottom: 1.2rem;
  background-color: #f8f9fa;
  padding: 0.8rem;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.counter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(110px, 1fr));
  gap: 0.5rem;
  row-gap: 0.7rem;
}

.counter-item {
  border-radius: 4px;
  padding: 0.4rem 0.3rem;
  text-align: center;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-height: 3rem;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  transition: transform 0.2s ease;
}

.counter-item:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.counter-label {
  font-size: 0.7rem;
  margin-bottom: 0.2rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.counter-value {
  font-size: 1rem;
  font-weight: 600;
}

@media print {
  .counter-grid {
    grid-template-columns: repeat(8, 1fr);
  }
  
  .counter-item {
    min-height: auto;
    padding: 0.2rem;
  }
}
EOF

# 4. Adjust column widths and heights
echo -e "${YELLOW}Applying column width and height adjustments...${NC}"
cat << 'EOF' >> "$CSS_PATH"
/* Further Column Width and Height Adjustments - 25% Reduction */
.calendar-table th,
.calendar-table td {
  padding: 0.3rem;  /* Further reduced from 0.4rem */
  font-size: 0.75rem;  /* Further reduced from 0.8rem */
}

.calendar-row {
  max-height: 3.5rem;  /* Reduced from 4.5rem - approx 25% reduction */
}

/* Refined column widths */
.date-col {
  width: 80px;  /* Reduced from 85px */
}

.day-col {
  width: 30px;  /* Reduced from 35px */
}

.main-unit-col {
  width: 170px;  /* Refined from default */
}

.extras-col,
.featured-extras-col {
  width: 25px;  /* Reduced from 30px */
}

.location-col {
  width: 110px;  /* Reduced from default */
}

.sequence-col {
  width: 70px;  /* Reduced from 80px */
}

.departments-col {
  width: 110px;  /* Reduced from 120px */
}

.notes-col {
  width: 160px;  /* Reduced from 180px */
}

/* Vertical spacing adjustments */
.date-cell .date-display {
  font-size: 0.75rem;  /* Reduced from 0.8rem */
}

.date-cell .date-day {
  font-size: 0.7rem;  /* Reduced from 0.75rem */
}

.day-cell {
  font-size: 0.9rem;  /* Reduced from 1rem */
}

.departments-cell {
  max-height: 2.8rem;  /* Reduced from 3.2rem - approx 25% reduction */
}

/* Even more compact department tags */
.department-tag {
  padding: 0.07rem 0.25rem;  /* Reduced from 0.1rem 0.3rem */
  font-size: 0.65rem;  /* Reduced from 0.7rem */
}

@media print {
  .calendar-table th,
  .calendar-table td {
    padding: 2pt;  /* Reduced for print */
    font-size: 7pt;  /* Reduced for print */
  }
  
  .calendar-row {
    max-height: none;  /* Allow natural height in print */
  }
}
EOF

echo -e "${GREEN}All UI improvements applied successfully!${NC}"
echo ""
echo -e "${YELLOW}To apply changes, restart your Docker container with:${NC}"
echo "docker restart film-scheduler-v4"
echo ""
echo -e "${YELLOW}If you need to revert these changes, you can restore from the backup:${NC}"
echo "cp \"$BACKUP_PATH\" \"$CSS_PATH\""
echo ""
echo -e "${GREEN}UI improvements complete!${NC}"
