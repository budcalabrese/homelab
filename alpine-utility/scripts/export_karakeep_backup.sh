#!/bin/bash
set -euo pipefail

# Karakeep Backup Script
# This script backs up the karakeep SQLite database and data directory
# Designed to be triggered by n8n daily or weekly

# Configuration
# Paths are for alpine-utility container with mounted volumes
DATA_DIR="/mnt/karakeep"
BACKUP_DIR="/mnt/backups/karakeep"
DATE_FORMAT=$(date +%Y-%m-%d_%H-%M-%S)
TIMESTAMP=$(date +%Y-%m-%d)
LOCKFILE="/tmp/karakeep_backup.lock"

# Mutual exclusion lock - prevent concurrent runs
if ! mkdir "$LOCKFILE" 2>/dev/null; then
    echo "Error: Another backup is already running (lock exists at $LOCKFILE)"
    exit 1
fi
trap 'rmdir "$LOCKFILE" 2>/dev/null || true' EXIT

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check available disk space (require at least 1GB free)
AVAILABLE_MB=$(df -m "$BACKUP_DIR" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_MB" -lt 1024 ]; then
    echo "Error: Insufficient disk space. Available: ${AVAILABLE_MB}MB, Required: 1024MB"
    exit 1
fi

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

    # Find and delete old backups, handling permission errors gracefully
    # Only match karakeep_backup_* pattern to avoid accidental deletion
    ls -t karakeep_backup_* 2>/dev/null | tail -n +8 | while read -r backup_dir; do
        if [ -d "$backup_dir" ]; then
            # Try to fix permissions first, then remove
            chmod -R u+w "$backup_dir" 2>/dev/null || true
            rm -rf "$backup_dir" 2>/dev/null || {
                echo "  Warning: Could not fully remove $backup_dir (permission issues)"
            }
        fi
    done

    REMAINING=$(ls -1 | wc -l)
    echo "  Backups retained: $REMAINING"

    exit 0
else
    echo "✗ Backup failed"
    rm -rf "$BACKUP_PATH"
    exit 1
fi
