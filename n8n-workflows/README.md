# n8n Workflows

All automation workflows for the homelab. Import JSON files via n8n UI → Workflows → Import from File.

---

## Workflow Index

| Workflow | File | Schedule | Purpose |
|----------|------|----------|---------|
| Karakeep Daily Podcast Generation | `Karakeep Daily Podcast Generation.json` | 2:00 PM daily | Bookmarks → podcasts |
| Karakeep Bookmark Cleanup | `Karakeep Bookmark Cleanup.json` | 3:00 AM daily | Delete old podcasted bookmarks |
| Karakeep Daily Backup | `Karakeep Daily Backup.json` | 2:00 AM daily | Backup Karakeep data |
| Gitea Daily Backup | `Gitea Daily Backup.json` | 3:00 AM daily | Backup Gitea DB + repos |
| Docker Health Monitor | `Docker Health Monitor.json` | 9 AM + 5 PM daily | Container health alerts |
| VictoriaLogs Daily Digest | `victoria-logs-daily-digest.json` | 8:00 PM daily | Network health email |
| Budget Export - Main | `budget-export-main.json` | Last day of month 11:55 PM | Export budget CSV/JSON |
| Budget Export - GF | `budget-export-gf.json` | Last day of month 11:57 PM | Export GF budget CSV/JSON |
| Youtube Aggregator | `Youtube Aggregator.json` | 12:00 PM daily | YouTube digest email |
| Obsidian Monthly Summary | `Obsidian Monthly Summary Generator.json` | 1st of month 11 PM | AI summary of monthly notes |
| Centralized Error Notification | `Centralized Error Notification.json` | Error trigger | Catch failed workflow runs |
| News Aggregator | `News-Aggregator.json` | TBD | News digest |
| SPYI & QQQI Downloader | `SPYI & QQQI 19a Downloader - Final.json` | TBD | Download SEC 19a filings → Gitea |

---

## Podcast Workflows

### Karakeep Daily Podcast Generation
Converts `#consume`-tagged bookmarks into topic-based podcasts.

**How it works:**
1. Fetches `#consume`-tagged bookmarks from Karakeep
2. Groups by topic tag (`#ai`, `#finance`, `#hometech`, etc.)
3. For each group with 2+ articles: generates podcast via Open Notebook (Qwen2.5), copies MP3 + show notes to AudioBookShelf, triggers library scan
4. Tags bookmarks `#podcasted` + `#podcasted-YYYY-MM-DD`, archives them

**Tagging model**: Only bookmarks you tag `#consume` are processed. Your permanent library is never touched.

**Customization:**
- Minimum articles per group: Edit "Filter and Group by Tag" node → `if (items.length >= 2)`
- Content length: Edit "Build Markdown Content" node → `.substring(0, 500)`
- Schedule: Edit Schedule node cron expression

See [karakeep-podcast-workflow.md](../docs/services/karakeep-podcast-workflow.md) for full details.

### Karakeep Bookmark Cleanup
Deletes archived `#podcasted` bookmarks older than 7 days. Starred bookmarks are never deleted.

**Customization:** Edit "Calculate Cutoff Date" node → `minus({ days: 7 })`

---

## Backup Workflows

### Karakeep Daily Backup
Runs `/scripts/export_karakeep_backup.sh` via SSH to alpine-utility. Keeps last 7 backups. Silent on success, emails on failure.

### Gitea Daily Backup
Runs `/scripts/export_gitea_backup.sh` via SSH to alpine-utility. Stops Gitea, backs up SQLite DB + repos, restarts Gitea. Keeps 30 days. Expects 5–10 min downtime.

See [alpine-utility/scripts/README.md](../alpine-utility/scripts/README.md) for script details.

---

## Monitoring Workflows

### Docker Health Monitor
Runs `/scripts/docker-monitor.sh` via SSH to alpine-utility twice daily. Monitors all container health + Gitea API. Emails on errors only.

### VictoriaLogs Daily Digest
Fetches 24h of logs from VictoriaLogs, analyzes with Ollama (Qwen2.5), sends HTML email with:
- Threat level (Low/Medium/High/Critical)
- Network health status
- Problematic containers
- Recommended actions

**Requires:** VictoriaLogs running + `ollama pull qwen2.5:7b`

---

## Budget Workflows

### Budget Export - Main / GF
Runs monthly export scripts via SSH to alpine-utility. Outputs CSV + JSON to `/Volumes/backups/budget-dashboard/`.

---

## Media Workflows

### Youtube Aggregator
Daily digest of new videos from subscribed channels:
1. Fetches RSS feeds, filters last 48h, removes Shorts
2. Fetches transcripts from local API (`host.docker.internal:5001`)
3. Summarizes with Ollama (Qwen2.5)
4. Sends HTML email with thumbnails, summaries, watch links

**Add/remove channels:** Edit "Edit Fields - YT channelids" node → update channel ID array.

**Requires:** YouTube Transcripts API running + Ollama with qwen2.5:7b

### SPYI & QQQI Downloader
Scrapes SEC EDGAR for 19a filings, downloads PDFs via alpine-utility, commits to `financial-data` Gitea repo.

---

## Knowledge Workflows

### Obsidian Monthly Summary
Runs on the 1st to summarize the previous month's weekly notes:
1. SSH to alpine-utility → lists `Weekly Notes/Week-MM-DD-YY.md` files from last month
2. Reads + combines content
3. Sends to Ollama (Qwen2.5) → generates structured markdown summary
4. Saves to `obsidian-vault/Monthly Summaries/Summary-MM-YY.md`

**Requires:** Weekly notes at `obsidian-vault/Weekly Notes/`, Ollama qwen2.5:7b, alpine-utility SSH credentials

---

## Setup (First Time)

### Credentials needed in n8n

| Credential | Type | Used by |
|------------|------|---------|
| Karakeep API | Header Auth (`Authorization: Bearer TOKEN`) | Podcast + cleanup |
| SSH Password account | SSH | All alpine-utility workflows |
| AudioBookshelf API | Header Auth | Podcast generation |
| SMTP | Email | Monitoring, backups |
| Ollama Chat Model | Ollama | VictoriaLogs, YouTube, Obsidian summary |

### Quick credential setup
1. **Karakeep API token**: Karakeep → Settings → API Tokens → create "n8n Automation"
2. **SSH**: Settings → Credentials → SSH → host: `alpine-utility`, port: `22`, user: `root`, key from setup script
3. Import all JSON workflow files, assign credentials, activate

---

## Troubleshooting

**Karakeep 401 Unauthorized** → verify API token + credential assigned to HTTP nodes

**Episode stuck at "processing"** → check `docker compose ps open-notebook openedai-speech`, verify custom profiles exist

**Budget export "data file not found"** → `docker exec alpine-utility ls /mnt/budget-dashboard/`

**Script not found in alpine-utility** → `docker exec alpine-utility ls /scripts/` — scripts are live-mounted from git repo

**Workflow won't run** → check "Active" toggle is on, check `docker compose logs n8n`

**Obsidian summary finds no notes** → verify weekly note filename format: `Week-MM-DD-YY.md`
