# Alpine Utility Scripts

This directory contains utility scripts that run inside the alpine-utility container.

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
  # Scripts (git-tracked, live updates)
  - /Users/bud/home_space/homelab/alpine-utility/scripts:/scripts

  # Config (persistent data)
  - /Volumes/docker/container_configs/alpine-utility:/config

  # Budget data (read-only)
  - /Volumes/docker/container_configs/budget-dashboard/app-data:/mnt/budget-dashboard:ro
  - /Volumes/docker/container_configs/budget-dashboard-gf/app-data:/mnt/budget-dashboard-gf:ro

  # Backup destination (read-write)
  - /Volumes/backups/budget-dashboard:/mnt/backups/budget-dashboard
```

**Important:** Scripts are mounted from the git repo, so any edits to files in `/Users/bud/home_space/homelab/alpine-utility/scripts/` are immediately available in the container. Always commit changes to git!

## N8N Workflows

Import these workflows into n8n:
- `/Users/bud/home_space/homelab/n8n-workflows/budget-export-main.json`
- `/Users/bud/home_space/homelab/n8n-workflows/budget-export-gf.json`

Both workflows:
1. Trigger on days 28-31 of each month (11:55 PM and 11:57 PM respectively)
2. Execute the export script via SSH to alpine-utility container
3. Check exit code for success/failure
4. Send notification (optional - replace noOp nodes with Discord/Slack/etc.)

**Technical Details:**
- Uses SSH node (`n8n-nodes-base.ssh`) to connect to alpine-utility
- SSH credentials: "SSH Password account" (pre-configured in n8n)
- Scripts execute from `/scripts/` directory in container

See [n8n Workflows README](../../n8n-workflows/README.md) for full documentation.

## Dependencies

These scripts require:
- `jq` - JSON processor (already installed in alpine-utility)
- `bc` - Basic calculator (already installed in alpine-utility)

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
