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

**Triggered by:** n8n workflow `Budget Export - Main` (monthly, last day at 11:55 PM)

**Manual execution:**
```bash
docker exec alpine-utility /bin/sh /config/scripts/export_monthly_snapshot.sh
```

### export_monthly_snapshot_gf.sh
Exports the girlfriend's budget dashboard data to CSV and JSON formats.

**What it does:**
- Reads budget data from `/mnt/budget-dashboard-gf/budget_data.json`
- Generates CSV export with summary and all categories
- Backs up raw JSON data
- Outputs to `/mnt/backups/budget-dashboard/` with `_gf` suffix

**Triggered by:** n8n workflow `Budget Export - GF` (monthly, last day at 11:57 PM)

**Manual execution:**
```bash
docker exec alpine-utility /bin/sh /config/scripts/export_monthly_snapshot_gf.sh
```

## Volume Mounts

The alpine-utility container has these volume mounts for the export scripts:

```yaml
volumes:
  # Budget data (read-only)
  - /Volumes/docker/container_configs/budget-dashboard/app-data:/mnt/budget-dashboard:ro
  - /Volumes/docker/container_configs/budget-dashboard-gf/app-data:/mnt/budget-dashboard-gf:ro

  # Backup destination (read-write)
  - /Volumes/backups/budget-dashboard:/mnt/backups/budget-dashboard
```

## N8N Workflows

Import these workflows into n8n:
- `/Users/bud/home_space/homelab/n8n-workflows/budget-export-main.json`
- `/Users/bud/home_space/homelab/n8n-workflows/budget-export-gf.json`

Both workflows:
1. Trigger on last day of month (11:55 PM and 11:57 PM respectively)
2. Execute the export script via `docker exec`
3. Check exit code for success/failure
4. Send notification (optional - replace noOp nodes with Discord/Slack/etc.)

See [n8n Workflows README](../../n8n-workflows/README.md) for full documentation.

## Dependencies

These scripts require:
- `jq` - JSON processor (already installed in alpine-utility)
- `bc` - Basic calculator (already installed in alpine-utility)

## Troubleshooting

**Test script manually:**
```bash
# Check if volumes are mounted correctly
docker exec alpine-utility ls -la /mnt/budget-dashboard
docker exec alpine-utility ls -la /mnt/backups/budget-dashboard

# Run export manually
docker exec alpine-utility /bin/sh /config/scripts/export_monthly_snapshot.sh

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
