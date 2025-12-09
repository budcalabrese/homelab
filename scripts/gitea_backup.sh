#!/usr/bin/env bash

# Gitea Backup Script
# Backs up Gitea database and repositories
# Works around SMB corruption issues by directly backing up what matters

# Exit immediately if any command fails
set -e

# Create backup directories if they don't exist
mkdir -p /Volumes/backups/gitea
mkdir -p /Volumes/backups/gitea-repo-backup

# Generate timestamp for backup filename
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "========================================"
echo "Gitea Backup - ${TIMESTAMP}"
echo "========================================"

# Backup database directly using sqlite3
echo "[1/3] Backing up Gitea database..."
docker exec gitea sqlite3 /data/gitea/gitea.db ".backup '/tmp/gitea-db-backup.db'"
docker cp "gitea:/tmp/gitea-db-backup.db" "/Volumes/backups/gitea/gitea-db-${TIMESTAMP}.db"
docker exec gitea rm /tmp/gitea-db-backup.db
echo "✅ Database backup complete"

# Stop Gitea for consistent repository backup
echo "[2/3] Stopping Gitea for repository backup..."
docker stop gitea

# Clean up SMB artifacts before zipping
echo "Cleaning up SMB artifacts..."
find /Volumes/docker/container_configs/gitea/git/repositories -name '.smbdelete*' -delete 2>/dev/null || true

# Create zip archive of repositories (excluding problematic files)
echo "Creating repository archive..."
cd /Volumes/docker/container_configs/gitea/git
zip -r "/Volumes/backups/gitea-repo-backup/gitea-repos-${TIMESTAMP}.zip" repositories -x '*.smbdelete*' -x '*testing' 2>/dev/null || true
echo "✅ Repository backup complete"

# Start Gitea back up
echo "[3/3] Starting Gitea..."
docker start gitea
echo "✅ Gitea started"

echo "========================================"
echo "Backup Complete!"
echo "Database: /Volumes/backups/gitea/gitea-db-${TIMESTAMP}.db"
echo "Repos: /Volumes/backups/gitea-repo-backup/gitea-repos-${TIMESTAMP}.zip"
echo "========================================"
