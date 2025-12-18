# n8n Workflows

This directory contains all n8n workflow JSON files for homelab automation.

## Workflows

### VictoriaLogs Monitoring

**Files:**
- `victoria-logs-daily-digest.json` - Daily network health and security report

#### Daily Network Health Report

**Schedule**: Daily at 8:00 PM (`0 20 * * *`)

**What it does**:
1. Fetches last 24 hours of logs from VictoriaLogs
2. Analyzes security threats (auth failures, security alerts, errors)
3. Analyzes network health (latency, connection errors, timeouts)
4. Identifies problematic containers (high error rates, restarts)
5. Checks resource warnings (disk space, memory issues)
6. Sends comprehensive analysis to Ollama (Qwen2.5)
7. Generates formatted HTML email digest
8. Sends daily report via email

**Output**:
- Threat Level assessment (Low/Medium/High/Critical)
- Network Health status (Excellent/Good/Fair/Poor/Critical)
- Container health analysis
- Prioritized action items
- Trend observations

**Email includes**:
- 24-hour statistics
- AI-powered security assessment
- Network performance analysis
- Problematic containers requiring attention
- Recommended actions

---

### Karakeep Podcast Automation

**Files:**
- `Karakeep Daily Podcast Generation.json` - Generates podcasts from bookmarks
- `Karakeep Bookmark Cleanup.json` - Cleans up old podcasted bookmarks

**Quick Start**: See [Karakeep Podcast Quick Start Guide](../podcast-automation/README.md)

#### How It Works

**Tagging Strategy (Opt-in Model):**
1. **Save bookmarks normally** → They stay in your Karakeep library forever (95% of your bookmarks)
2. **Add `#consume` tag** → Article gets podcasted and auto-deleted after 7 days (5% of bookmarks)

**Example:**
- Save "How to configure SSH on Mac" → No `#consume` tag → Stays in library permanently
- Save "New GPT-5 announcement" → Add `#consume` tag → Podcasted at 2pm, deleted after 7 days

**Your permanent bookmark library is never touched** - only bookmarks explicitly tagged with `#consume` are processed.

#### Workflow 1: Daily Podcast Generation

**Schedule**: Daily at 2:00 PM (`0 14 * * *`)

**What it does**:
1. Fetches bookmarks from Karakeep tagged with `#consume` (not archived)
2. Groups bookmarks by topic tag (`#ai`, `#finance`, `#hometech`, etc.)
3. For each topic group with 2+ bookmarks:
   - Builds markdown content from bookmark data
   - Generates podcast using Open Notebook with Qwen2.5
   - Copies MP3 and show notes to AudioBookShelf
   - Tags as `#podcasted` and `#podcasted-YYYY-MM-DD`
   - Archives bookmark in Karakeep
4. Triggers AudioBookShelf library scan

**Output**:
- Podcasts in `/Volumes/docker/container_configs/audiobookshelf/podcasts/Daily-Digests/`
- Bookmarks archived and tagged for cleanup
- Permanent library (without `#consume` tag) untouched

#### Workflow 2: Bookmark Cleanup

**Schedule**: Daily at 3:00 AM (`0 3 * * *`)

**What it does**:
1. Fetches archived bookmarks tagged with `#podcasted`
2. Filters for bookmarks older than 7 days
3. Logs bookmarks to be deleted (audit trail)
4. Deletes old podcasted bookmarks
5. Sends notification if >10 bookmarks deleted

**Safety**: Only archived `#podcasted` bookmarks are deleted - never your permanent library

---

### Budget Export Automation

**Files:**
- `budget-export-main.json` - Exports main budget dashboard monthly
- `budget-export-gf.json` - Exports girlfriend's budget dashboard monthly

#### How It Works

Both workflows run monthly on the last day of the month and export budget data to CSV and JSON formats for archival.

#### Workflow 1: Budget Export - Main

**Schedule**: Monthly, last day at 11:55 PM (`55 23 L * *`)

**What it does**:
1. Executes `/config/scripts/export_monthly_snapshot.sh` in alpine-utility container
2. Script reads from `/mnt/budget-dashboard/budget_data.json`
3. Generates CSV export with summary and all categories
4. Backs up raw JSON data
5. Saves to `/mnt/backups/budget-dashboard/`
6. Sends notification on completion or failure

**Output**:
- `budget_snapshot_MM_DD_YYYY.csv` - Formatted CSV with totals
- `budget_data_MM_DD_YYYY.json` - Raw JSON backup

#### Workflow 2: Budget Export - GF

**Schedule**: Monthly, last day at 11:57 PM (`57 23 L * *`)

**What it does**:
Same as main export but for girlfriend's budget dashboard.

**Output**:
- `budget_snapshot_gf_MM_DD_YYYY.csv`
- `budget_data_gf_MM_DD_YYYY.json`

#### Dependencies

Budget export scripts require:
- alpine-utility container running
- Volume mounts configured in compose.yml:
  ```yaml
  volumes:
    - /Volumes/docker/container_configs/budget-dashboard/app-data:/mnt/budget-dashboard:ro
    - /Volumes/docker/container_configs/budget-dashboard-gf/app-data:/mnt/budget-dashboard-gf:ro
    - /Volumes/backups/budget-dashboard:/mnt/backups/budget-dashboard
  ```
- Scripts in alpine-utility: `/config/scripts/export_monthly_snapshot*.sh`

---

## Setup Instructions

### Prerequisites

✅ Docker and Docker Compose running
✅ Homelab services deployed
✅ n8n running at http://localhost:5678

### 1. Start VictoriaLogs (For Monitoring Workflows)

VictoriaLogs is already configured in compose.yml. Start it:

```bash
cd /Users/bud/home_space/homelab
docker compose up -d victoria-logs
```

Verify it's running:
```bash
curl http://localhost:9428/health
```

VictoriaLogs will automatically collect logs from Docker containers.

### 2. Import Workflows into n8n

1. **Access n8n**: http://localhost:5678
2. **Import workflows**:
   - Click "+ Add workflow" → "Import from File"
   - Select each `.json` file from this directory
   - Click "Import"

### 3. Configure Credentials

#### Karakeep Workflows

Both podcast workflows require a Karakeep API credential:

1. **Generate Karakeep API Token**:
   - Open Karakeep: http://localhost:3000
   - Go to Settings → API Tokens
   - Create new token: "n8n Automation"
   - Copy the token

2. **Add Credential to n8n**:
   - In n8n, go to Settings → Credentials
   - Click "Add Credential"
   - Select "Header Auth"
   - Name: "Karakeep API"
   - Add header:
     - **Name**: `Authorization`
     - **Value**: `Bearer YOUR_TOKEN_HERE`
   - Save

3. **Assign Credentials**:
   - Open each podcast workflow
   - For nodes that say "Select Credential", choose "Karakeep API"
   - Save workflow

#### Budget Export Workflows

No credentials required - uses docker exec to run scripts.

#### VictoriaLogs Monitoring Workflow

No credentials required - connects to local VictoriaLogs and Ollama.

**Note:** You must have Ollama running locally with qwen2.5:7b model:
```bash
ollama pull qwen2.5:7b
```

**Email Setup (Optional but Recommended):**

Replace the "Send Email (Replace This)" noOp node with an actual email sender:

**Option 1: Gmail (via n8n Gmail node)**
1. Add Gmail credentials in n8n
2. Replace noOp with Gmail node
3. Use `{{ $json.emailSubject }}` for subject
4. Use `{{ $json.emailBody }}` for HTML body

**Option 2: SendGrid/SMTP**
1. Add SMTP credentials
2. Replace noOp with Send Email node
3. Same subject/body variables

### 4. Test Workflows

#### Test Podcast Generation

1. **Add test bookmarks**:
   - Add 3-5 bookmarks in Karakeep
   - Tag 2-3 of them with `#consume` (leave others without it)
   - Ensure Karakeep AI auto-tags them (e.g., `#ai`, `#hometech`)

2. **Run workflow manually**:
   - Open "Karakeep Daily Podcast Generation" workflow
   - Click "Execute Workflow"
   - Watch the execution flow

3. **Verify results**:
   - Check AudioBookShelf: http://localhost:13378
   - Look for episodes: "Daily Digest - AI - MM-DD-YYYY"
   - Check Karakeep - bookmarks with `#consume` are archived with `#podcasted`

#### Test Budget Export

1. **Run workflow manually**:
   - Open "Budget Export - Main" workflow
   - Click "Execute Workflow"
   - Wait for completion

2. **Verify results**:
   ```bash
   ls -lh /Volumes/backups/budget-dashboard/
   ```
   - Should see new CSV and JSON files with today's date
   - Check CSV contains correct budget data

### 4. Enable Workflows

Once tested successfully:

1. **Activate workflows**:
   - Open each workflow
   - Toggle "Active" switch in top-right corner
   - Workflows will now run on schedule

2. **Monitor executions**:
   - Go to "Executions" in n8n sidebar
   - View workflow run history
   - Check for errors

---

## Workflow Configuration

### Podcast Generation Customization

**Change schedule**:
- Edit "Schedule Daily at 2PM" node
- Modify cron expression (e.g., `0 9 * * *` for 9 AM)

**Change minimum bookmarks**:
- Edit "Filter and Group by Tag" node
- Line: `if (items.length >= 2)` → change `2` to desired minimum

**Change content length**:
- Edit "Build Markdown Content" node
- Line: `const content = bookmark.content.substring(0, 500);`
- Change `500` to desired character limit

**Change retention period (cleanup)**:
- Edit "Calculate Cutoff Date" node in cleanup workflow
- Change `minus({ days: 7 })` to desired duration

### Budget Export Customization

**Change schedule**:
- Edit "Schedule Trigger" node
- Modify cron expression
- Default: `55 23 L * *` (last day of month at 11:55 PM)

**Change export location**:
- Edit scripts in `alpine-utility/scripts/`
- Update `SNAPSHOT_DIR` variable

---

## Troubleshooting

### Podcast Generation Issues

**Error: "401 Unauthorized" from Karakeep**
- Check API token is valid
- Verify credential is correctly assigned to HTTP Request nodes

**Error: "Episode generation failed"**
- Check Open Notebook is running: `docker compose ps open-notebook`
- Verify custom profiles exist in Open Notebook
- Check Open Notebook logs: `docker compose logs open-notebook`

**Podcast status stuck at "processing"**
- Check Qwen2.5 model is loaded in Open Notebook
- Verify OpenEDAI Speech is running: `docker compose ps openedai-speech`
- Increase wait time in "Wait for Generation" node

### Budget Export Issues

**Error: "Data file not found"**
- Check volume mounts in compose.yml
- Verify alpine-utility container is running
- Check data file exists:
  ```bash
  docker exec alpine-utility ls -la /mnt/budget-dashboard/
  ```

**Error: "Permission denied"**
- Check backup directory permissions:
  ```bash
  ls -la /Volumes/backups/budget-dashboard/
  ```
- Ensure alpine-utility can write to backup location

**Script not found**
- Verify scripts exist in alpine-utility:
  ```bash
  docker exec alpine-utility ls -la /config/scripts/
  ```
- Scripts should be executable: `chmod +x export_monthly_snapshot*.sh`

**Manual test**:
```bash
# Test main export
docker exec alpine-utility /bin/sh /config/scripts/export_monthly_snapshot.sh

# Test GF export
docker exec alpine-utility /bin/sh /config/scripts/export_monthly_snapshot_gf.sh
```

### General Issues

**Workflow doesn't run on schedule**
- Check workflow is "Active"
- Verify n8n container is running
- Check n8n logs: `docker compose logs n8n`

**Execution timeout**
- Increase timeout in workflow settings
- Check for slow API responses

---

## Monitoring

### Key Metrics to Track

**Podcast Generation**:
- Number of podcasts generated per day
- Average generation time
- Failed generations

**Cleanup**:
- Number of bookmarks deleted per run
- Retention of starred bookmarks
- Growth rate of `#podcasted` bookmarks

**Budget Exports**:
- Monthly export success rate
- File sizes
- Failed exports

### Execution History

View in n8n:
- Go to "Executions" tab
- Filter by workflow name
- Check success/failure rates
- Review execution logs

---

## Backup

These workflow JSON files are version-controlled in this repository. To backup:

```bash
# Export from n8n UI
# Workflows → Select workflow → "Download"

# Or use n8n CLI
n8n export:workflow --all --output=/path/to/backup/
```

---

## Related Documentation

### Podcast Automation
- [Karakeep Podcast Quick Start](../podcast-automation/README.md) - Full setup guide
- [Open Notebook Setup](../docs/open-notebook-setup.md) - Podcast generation configuration
- [Karakeep API Reference](../docs/karakeep-api-reference.md) - API documentation
- [Karakeep Podcast Workflow](../docs/karakeep-podcast-workflow.md) - Complete workflow guide

### Budget Export
- [Alpine Utility Scripts](../alpine-utility/scripts/README.md) - Export script documentation
- [Python Budget Tracker](../../coding/python-budget-tracker/README.md) - Budget dashboard documentation

---

**Last Updated:** December 17, 2025
**Workflows:** 4 total (2 podcast, 2 budget)
