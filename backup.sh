#!/bin/bash

# Make sure we're in the right directory
cd /mnt/user/appdata/film-scheduler-v4

# Set backup directory
BACKUP_DIR="/mnt/user/backups/film-scheduler-v4/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup data
echo "Creating backup of Film Production Scheduler data..."
cp -r data/* "$BACKUP_DIR/"

# Create archive
echo "Creating archive..."
tar -czf "$BACKUP_DIR.tar.gz" -C "$BACKUP_DIR" .

# Cleanup temporary directory
rm -rf "$BACKUP_DIR"

echo "Backup completed successfully."
echo "Backup location: $BACKUP_DIR.tar.gz"

# Manage backup retention (keep last 10 backups)
echo "Managing backup retention (keeping last 10 backups)..."
ls -tp /mnt/user/backups/film-scheduler-v4/*.tar.gz | grep -v '/$' | tail -n +11 | xargs -I {} rm -- {}

echo "Backup process completed."
