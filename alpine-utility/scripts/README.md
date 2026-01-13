# Alpine Utility Scripts

This directory contains utility scripts that run inside the alpine-utility container.

## Backup Scripts

### export_karakeep_backup.sh
Exports daily backups of the Karakeep SQLite database and data directory.

**What it does:**
- Backs up all data from `/mnt/karakeep` (karakeep data directory)
- Creates timestamped backup in `/mnt/backups/karakeep/`
- Keeps last 7 backups automatically
- Outputs backup size and retention count

**Triggered by:** n8n workflow `Karakeep Daily Backup` (daily at 8:00 PM CST / 2:00 AM UTC)

**Manual execution:**
```bash
# From host
docker exec alpine-utility /scripts/export_karakeep_backup.sh

# Or via SSH (from n8n or other containers)
ssh root@alpine-utility /scripts/export_karakeep_backup.sh
```

### export_gitea_backup.sh
Exports daily backups of Gitea database and repositories.

**What it does:**
- Backs up Gitea SQLite database using `sqlite3 .backup` command
- Stops Gitea container for consistent repository backup
- Creates zip archive of all Git repositories
- Automatically restarts Gitea (guaranteed via trap, even if backup fails)
- Keeps last 30 backups automatically
- Outputs backup sizes and retention count

**Triggered by:** n8n workflow `Gitea Daily Backup` (daily at 2:00 AM CST / 8:00 AM UTC)

**Downtime:** Expected 5-10 minutes during backup (Gitea stopped for repository backup)

**Backup locations:**
- Database: `/mnt/backups/gitea/database/gitea-db-YYYY-MM-DD_HH-MM-SS.db`
- Repositories: `/mnt/backups/gitea/repositories/gitea-repos-YYYY-MM-DD_HH-MM-SS.zip`

**Manual execution:**
```bash
# From host
docker exec alpine-utility /scripts/export_gitea_backup.sh

# Or via SSH (from n8n or other containers)
ssh root@alpine-utility /scripts/export_gitea_backup.sh
```

**Important:** This script requires Docker socket access (not read-only) to stop/start the Gitea container.

## Budget Export Scripts

### export_monthly_snapshot.sh
Exports the main budget dashboard data to CSV and JSON formats.

**What it does:**
- Reads budget data from `/mnt/budget-dashboard/budget_data.json`
- Generates CSV export with summary and all categories
- Backs up raw JSON data
- Outputs to `/mnt/backups/budget-dashboard/`

**Triggered by:** n8n workflow `Budget Export - Main` (monthly, days 28-31 at 11:55 PM)

**Manual execution:**
```bash
# From host
docker exec alpine-utility /scripts/export_monthly_snapshot.sh

# Or via SSH (from n8n or other containers)
ssh root@alpine-utility /scripts/export_monthly_snapshot.sh
```

### export_monthly_snapshot_gf.sh
Exports the girlfriend's budget dashboard data to CSV and JSON formats.

**What it does:**
- Reads budget data from `/mnt/budget-dashboard-gf/budget_data.json`
- Generates CSV export with summary and all categories
- Backs up raw JSON data
- Outputs to `/mnt/backups/budget-dashboard/` with `_gf` suffix

**Triggered by:** n8n workflow `Budget Export - GF` (monthly, days 28-31 at 11:57 PM)

**Manual execution:**
```bash
# From host
docker exec alpine-utility /scripts/export_monthly_snapshot_gf.sh

# Or via SSH (from n8n or other containers)
ssh root@alpine-utility /scripts/export_monthly_snapshot_gf.sh
```

## Volume Mounts

The alpine-utility container has these volume mounts:

```yaml
volumes:
  # Docker socket (read-write for container control)
  - /var/run/docker.sock:/var/run/docker.sock

  # Scripts (git-tracked, live updates)
  - /Users/bud/home_space/homelab/alpine-utility/scripts:/scripts

  # Config (persistent data)
  - /Volumes/docker/container_configs/alpine-utility:/config

  # Budget data (read-only)
  - /Volumes/docker/container_configs/budget-dashboard/app-data:/mnt/budget-dashboard:ro
  - /Volumes/docker/container_configs/budget-dashboard-gf/app-data:/mnt/budget-dashboard-gf:ro

  # Karakeep data (read-only)
  - /Volumes/docker/container_configs/karakeep/data:/mnt/karakeep:ro

  # Gitea data (read-only)
  - /Volumes/docker/container_configs/gitea:/mnt/gitea:ro

  # Backup destinations (read-write)
  - /Volumes/backups/budget-dashboard:/mnt/backups/budget-dashboard
  - /Volumes/docker/backups/karakeep:/mnt/backups/karakeep
  - /Volumes/backups/gitea:/mnt/backups/gitea

  # Financial data git repo (read-write)
  - /Users/bud/home_space/financial-data:/mnt/financial-data
```

**Important:** Scripts are mounted from the git repo, so any edits to files in `/Users/bud/home_space/homelab/alpine-utility/scripts/` are immediately available in the container. Always commit changes to git!

## Docker Monitoring

### docker-monitor.sh
Monitors health of all Docker containers and Gitea instance.

**What it does:**
- Checks health status of all Docker containers
- Monitors Gitea API health endpoint (`/api/healthz`)
- Scans last 24h logs for errors and warnings
- Outputs JSON format with container and Gitea health
- Reports errors, restarts, and unhealthy containers
- **Maintenance Window**: Skips Gitea monitoring during backup (2:00-2:15 AM CST / 8:00-8:15 AM UTC)

**Triggered by:** n8n workflow `Docker Health Monitor` (every 15 minutes)

**Alert Thresholds:**
- **Restart Loop**: 2+ restarts within last hour
- **Errors**: Any errors found in last 24h logs
- **Health**: Container health check failing
- **Stopped**: Container not running (except during maintenance)

**Manual execution:**
```bash
# From host
docker exec alpine-utility /scripts/docker-monitor.sh
```

## N8N Workflows

Import these workflows into n8n:
- `/Users/bud/home_space/homelab/n8n-workflows/Karakeep Daily Backup.json`
- `/Users/bud/home_space/homelab/n8n-workflows/Gitea Daily Backup.json`
- `/Users/bud/home_space/homelab/n8n-workflows/budget-export-main.json`
- `/Users/bud/home_space/homelab/n8n-workflows/budget-export-gf.json`
- `/Users/bud/home_space/homelab/n8n-workflows/Docker Health Monitor.json`
- `/Users/bud/home_space/homelab/n8n-workflows/SPYI & QQQI 19a Downloader - Final.json`

**Karakeep Daily Backup:**
1. Triggers daily at 2:00 AM
2. Executes backup script via SSH to alpine-utility
3. Sends email alert on failure only

**Gitea Daily Backup:**
1. Triggers daily at 3:00 AM
2. Executes backup script via SSH to alpine-utility
3. Sends email alert on failure only
4. Keeps 30 days of database and repository backups

**Budget Export workflows:**
1. Trigger on days 28-31 of each month (11:55 PM and 11:57 PM respectively)
2. Execute the export script via SSH to alpine-utility container
3. Check exit code for success/failure
4. Send notification (optional - replace noOp nodes with Discord/Slack/etc.)

**Docker Health Monitor:**
1. Triggers every 15 minutes
2. Runs docker-monitor.sh via SSH
3. Sends email alert if any containers or Gitea are unhealthy (skips alerts during 2:00-2:15 AM CST maintenance window)

**SPYI & QQQI 19a Downloader:**
1. Downloads SEC 19a notices for SPYI and QQQI funds
2. Commits PDFs to financial-data git repository
3. Pushes to Gitea automatically

**Technical Details:**
- Uses SSH node (`n8n-nodes-base.ssh`) to connect to alpine-utility
- SSH credentials: "SSH Password account" (pre-configured in n8n)
- Scripts execute from `/scripts/` directory in container

See [n8n Workflows README](../../n8n-workflows/README.md) for full documentation.

## Dependencies

These scripts require:
- `jq` - JSON processor (already installed in alpine-utility)
- `bc` - Basic calculator (already installed in alpine-utility)
- `git` - Version control (already installed in alpine-utility)
- `curl` - HTTP client (already installed in alpine-utility)
- `docker-cli` - Docker command line (already installed in alpine-utility)
- `zip` - Archive utility (already installed in alpine-utility)

## Troubleshooting

**Test script manually:**
```bash
# Check if volumes are mounted correctly
docker exec alpine-utility ls -la /scripts/
docker exec alpine-utility ls -la /mnt/budget-dashboard
docker exec alpine-utility ls -la /mnt/backups/budget-dashboard

# Run export manually
docker exec alpine-utility /scripts/export_monthly_snapshot.sh

# Or via SSH
ssh -p 2223 root@localhost /scripts/export_monthly_snapshot.sh

# Check output
ls -lh /Volumes/backups/budget-dashboard/
```

**Common issues:**
- "Data file not found" - Check volume mounts in compose.yml
- "Permission denied" - Check backup directory permissions
- "Command not found: jq" - Rebuild alpine-utility container

## Output Format

**CSV Files:**
- Summary section with totals
- Individual category sections (bills, debt, expenses, wants, needs, savings)
- Target payment goal if set

**JSON Files:**
- Complete backup of raw budget_data.json
- Useful for restoring data or debugging
