#!/bin/bash

# Karakeep Backup Script
# This script backs up the karakeep SQLite database and data directory
# Designed to be triggered by n8n daily or weekly

# Configuration
# Paths are for alpine-utility container with mounted volumes
DATA_DIR="/mnt/karakeep"
BACKUP_DIR="/mnt/backups/karakeep"
DATE_FORMAT=$(date +%Y-%m-%d_%H-%M-%S)
TIMESTAMP=$(date +%Y-%m-%d)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo "Error: Karakeep data directory not found at $DATA_DIR"
    exit 1
fi

# Create timestamped backup directory
BACKUP_PATH="${BACKUP_DIR}/karakeep_backup_${DATE_FORMAT}"
mkdir -p "$BACKUP_PATH"

echo "Starting Karakeep backup..."
echo "Source: $DATA_DIR"
echo "Destination: $BACKUP_PATH"

# Copy all data files
cp -r "$DATA_DIR"/* "$BACKUP_PATH/" 2>/dev/null

# Check if backup was successful
if [ $? -eq 0 ]; then
    # Calculate backup size
    BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)

    echo "✓ Karakeep backup completed successfully!"
    echo "  Backup Path: $BACKUP_PATH"
    echo "  Backup Size: $BACKUP_SIZE"

    # Keep only last 7 backups (delete older ones)
    echo "Cleaning up old backups (keeping last 7)..."
    cd "$BACKUP_DIR" || exit 1
    ls -t | tail -n +8 | xargs -r rm -rf

    REMAINING=$(ls -1 | wc -l)
    echo "  Backups retained: $REMAINING"

    exit 0
else
    echo "✗ Backup failed"
    rm -rf "$BACKUP_PATH"
    exit 1
fi
