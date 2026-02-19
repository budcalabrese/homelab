# Alpine Utility Scripts

Scripts that run inside the alpine-utility container, called by n8n workflows via SSH.

Scripts are git-tracked and live-mounted at `/scripts/` — edits here are immediately available in the container.

---

## Backup Scripts

### export_karakeep_backup.sh
- Backs up `/mnt/karakeep` → `/mnt/backups/karakeep/`
- Keeps last 7 backups
- **Schedule**: Daily at 8 PM CST (2 AM UTC) via n8n `Karakeep Daily Backup`

```bash
docker exec alpine-utility /scripts/export_karakeep_backup.sh
```

### export_gitea_backup.sh
- Stops Gitea, backs up SQLite DB + all repos, restarts Gitea
- Keeps last 30 backups
- **Expected downtime**: 5-10 minutes
- **Schedule**: Daily at 3 AM CST (9 AM UTC) via n8n `Gitea Daily Backup`
- **Backup locations**: `/mnt/backups/gitea/database/` and `/mnt/backups/gitea/repositories/`

```bash
docker exec alpine-utility /scripts/export_gitea_backup.sh
```

> Requires Docker socket write access to stop/start Gitea. Always stops Gitea before copying the DB — never use `sqlite3 .backup` on a live database.

### export_monthly_snapshot.sh
- Exports main budget data to CSV + JSON
- Reads from `/mnt/budget-dashboard/budget_data.json`
- Outputs to `/mnt/backups/budget-dashboard/`
- **Schedule**: Monthly on days 28-31 at 11:55 PM via n8n `Budget Export - Main`

```bash
docker exec alpine-utility /scripts/export_monthly_snapshot.sh
```

### export_monthly_snapshot_gf.sh
- Same as above for the second budget dashboard instance
- Reads from `/mnt/budget-dashboard-gf/budget_data.json`
- Outputs with `_gf` suffix
- **Schedule**: Monthly on days 28-31 at 11:57 PM via n8n `Budget Export - GF`

```bash
docker exec alpine-utility /scripts/export_monthly_snapshot_gf.sh
```

---

## Monitoring Script

### docker-monitor.sh
- Checks health of all containers + Gitea API
- Scans last 24h logs for errors/warnings
- Outputs JSON
- **Schedule**: Twice daily at 9 AM and 5 PM via n8n `Docker Health Monitor`
- **Maintenance window**: Skips Gitea checks 2:00–2:15 AM CST (during Gitea backup)

**Alert thresholds**: 2+ restarts/hour, any errors in 24h logs, failed health check, container stopped

```bash
docker exec alpine-utility /scripts/docker-monitor.sh
```

---

## Troubleshooting

```bash
# Check volumes are mounted
docker exec alpine-utility ls -la /scripts/
docker exec alpine-utility ls -la /mnt/budget-dashboard

# Permission denied on backup dir
ls -la /Volumes/backups/budget-dashboard/

# "Data file not found" → check volume mounts in compose.yml
# "Command not found: jq" → rebuild alpine-utility container
```
