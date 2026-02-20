#!/bin/bash

# Garage Tracker Backup Script for Alpine-Utility Container
# Backs up the garage.db SQLite database
# Triggered nightly by n8n at 4 AM
# Retains 30 days of backups

set -euo pipefail

BACKUP_DIR="/mnt/backups/garage-tracker"
SOURCE_DB="/mnt/garage-tracker/garage.db"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
RETENTION_DAYS=30
LOCKFILE="/tmp/garage_backup.lock"

# Mutual exclusion lock - prevent concurrent runs
if ! mkdir "$LOCKFILE" 2>/dev/null; then
    echo "Error: Another garage backup is already running (lock exists at $LOCKFILE)"
    exit 1
fi
trap 'rmdir "$LOCKFILE" 2>/dev/null || true' EXIT

mkdir -p "${BACKUP_DIR}"

# Check available disk space (require at least 500MB free)
AVAILABLE_MB=$(df -m "$BACKUP_DIR" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_MB" -lt 500 ]; then
    echo "Error: Insufficient disk space. Available: ${AVAILABLE_MB}MB, Required: 500MB"
    exit 1
fi

echo "========================================"
echo "Garage Tracker Backup - ${TIMESTAMP}"
echo "========================================"

# Check source database exists
if [ ! -f "${SOURCE_DB}" ]; then
    echo "ERROR: Database not found at ${SOURCE_DB}"
    echo "Has the garage-tracker container run at least once?"
    exit 1
fi

# Stop garage-tracker for a consistent backup (avoids SQLite lock issues)
echo "[1/3] Stopping garage-tracker for consistent backup..."
docker stop garage-tracker

restart_garage() {
    echo "[3/3] Starting garage-tracker..."
    docker start garage-tracker
    echo "✓ garage-tracker started"
}
trap restart_garage EXIT

# Copy the database file
echo "[2/3] Backing up garage.db..."
cp "${SOURCE_DB}" "${BACKUP_DIR}/garage-${TIMESTAMP}.db"
DB_SIZE=$(du -sh "${BACKUP_DIR}/garage-${TIMESTAMP}.db" | cut -f1)
echo "✓ Backup complete: garage-${TIMESTAMP}.db (${DB_SIZE})"

# garage-tracker restarted by trap on exit

echo "========================================"
echo "Backup Complete!"
echo "File: ${BACKUP_DIR}/garage-${TIMESTAMP}.db (${DB_SIZE})"
echo "========================================"

# Clean up old backups (keep last 30 days)
echo "Cleaning up old backups (keeping last ${RETENTION_DAYS} days)..."
cd "${BACKUP_DIR}" || exit 1
ls -t garage-*.db 2>/dev/null | tail -n +$((RETENTION_DAYS + 1)) | xargs -r rm -f
REMAINING=$(ls -1 garage-*.db 2>/dev/null | wc -l)
echo "✓ Cleanup complete — backups retained: ${REMAINING}"
echo "========================================"

exit 0
