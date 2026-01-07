#!/bin/bash

# Gitea Backup Script for Alpine-Utility Container
# This script backs up Gitea database and repositories
# Designed to be triggered by n8n nightly
# Retains 30 days of backups

# Exit immediately if any command fails
set -e

# Configuration
# Paths are for alpine-utility container with mounted volumes
BACKUP_DIR="/mnt/backups/gitea"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
RETENTION_DAYS=30

# Create backup directories if they don't exist
mkdir -p "${BACKUP_DIR}/database"
mkdir -p "${BACKUP_DIR}/repositories"

echo "========================================"
echo "Gitea Backup - ${TIMESTAMP}"
echo "========================================"

# Backup database directly using sqlite3
echo "[1/3] Backing up Gitea database..."
docker exec gitea sqlite3 /data/gitea/gitea.db ".backup '/tmp/gitea-db-backup.db'"
docker cp "gitea:/tmp/gitea-db-backup.db" "${BACKUP_DIR}/database/gitea-db-${TIMESTAMP}.db"
docker exec gitea rm /tmp/gitea-db-backup.db
echo "✓ Database backup complete"

# Stop Gitea for consistent repository backup
echo "[2/3] Stopping Gitea for repository backup..."
docker stop gitea

# Create zip archive of repositories
# Use a trap to ensure gitea is always restarted, even if backup fails
restart_gitea() {
    echo "[3/3] Starting Gitea..."
    docker start gitea
    echo "✓ Gitea started"
}
trap restart_gitea EXIT

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
