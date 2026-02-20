#!/bin/bash

# Gitea Backup Script for Alpine-Utility Container
# This script backs up Gitea database and repositories
# Designed to be triggered by n8n nightly
# Retains 30 days of backups

# Exit immediately if any command fails
set -euo pipefail

# Configuration
# Paths are for alpine-utility container with mounted volumes
BACKUP_DIR="/mnt/backups/gitea"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
RETENTION_DAYS=30
LOCKFILE="/tmp/gitea_backup.lock"

# Mutual exclusion lock - prevent concurrent runs
if ! mkdir "$LOCKFILE" 2>/dev/null; then
    echo "Error: Another Gitea backup is already running (lock exists at $LOCKFILE)"
    exit 1
fi
trap 'rmdir "$LOCKFILE" 2>/dev/null || true' EXIT

# Create backup directories if they don't exist
mkdir -p "${BACKUP_DIR}/database"
mkdir -p "${BACKUP_DIR}/repositories"

# Check available disk space (require at least 5GB free for Gitea backups)
AVAILABLE_MB=$(df -m "$BACKUP_DIR" | awk 'NR==2 {print $4}')
if [ "$AVAILABLE_MB" -lt 5120 ]; then
    echo "Error: Insufficient disk space. Available: ${AVAILABLE_MB}MB, Required: 5120MB"
    exit 1
fi

echo "========================================"
echo "Gitea Backup - ${TIMESTAMP}"
echo "========================================"

# Stop Gitea for consistent backup
# IMPORTANT: We MUST stop Gitea before backing up the database to avoid "database is locked" errors.
# SQLite cannot be reliably backed up while the application is actively writing to it.
# Previous approach (using sqlite3 .backup while Gitea running) failed with lock errors.
# Current approach (stop Gitea, cp database file) is reliable and safe.
echo "[1/3] Stopping Gitea for consistent backup..."
docker stop gitea

# Use a trap to ensure gitea is always restarted, even if backup fails
restart_gitea() {
    echo "[3/3] Starting Gitea..."
    docker start gitea
    echo "✓ Gitea started"
}
trap restart_gitea EXIT

# Backup database using direct file copy (Gitea is stopped, so no lock issues)
echo "[2/3] Backing up Gitea database and repositories..."
cp /mnt/gitea/gitea/gitea.db "${BACKUP_DIR}/database/gitea-db-${TIMESTAMP}.db"
echo "✓ Database backup complete"

# Create zip archive of repositories
echo "Creating repository archive..."
cd /mnt/gitea/git || exit 1
zip -r "${BACKUP_DIR}/repositories/gitea-repos-${TIMESTAMP}.zip" repositories -q
echo "✓ Repository backup complete"

# Gitea will be restarted by the trap on exit

# Calculate backup sizes
DB_SIZE=$(du -sh "${BACKUP_DIR}/database/gitea-db-${TIMESTAMP}.db" | cut -f1)
REPO_SIZE=$(du -sh "${BACKUP_DIR}/repositories/gitea-repos-${TIMESTAMP}.zip" | cut -f1)

echo "========================================"
echo "Backup Complete!"
echo "Database: ${BACKUP_DIR}/database/gitea-db-${TIMESTAMP}.db (${DB_SIZE})"
echo "Repos: ${BACKUP_DIR}/repositories/gitea-repos-${TIMESTAMP}.zip (${REPO_SIZE})"
echo "========================================"

# Clean up old backups (keep last 30 days)
echo "Cleaning up old backups (keeping last ${RETENTION_DAYS})..."

# Clean database backups
cd "${BACKUP_DIR}/database" || exit 1
ls -t gitea-db-*.db 2>/dev/null | tail -n +$((RETENTION_DAYS + 1)) | xargs -r rm -f
DB_REMAINING=$(ls -1 gitea-db-*.db 2>/dev/null | wc -l)

# Clean repository backups
cd "${BACKUP_DIR}/repositories" || exit 1
ls -t gitea-repos-*.zip 2>/dev/null | tail -n +$((RETENTION_DAYS + 1)) | xargs -r rm -f
REPO_REMAINING=$(ls -1 gitea-repos-*.zip 2>/dev/null | wc -l)

echo "✓ Cleanup complete"
echo "  Database backups retained: ${DB_REMAINING}"
echo "  Repository backups retained: ${REPO_REMAINING}"
echo "========================================"

exit 0
