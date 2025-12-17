# n8n Workflows for Karakeep Podcast Automation

This directory contains n8n workflow JSON files for automating the Karakeep-to-Podcast pipeline.

## How It Works

### Tagging Strategy

**The system uses an opt-in model for podcasting:**

1. **Save bookmarks normally** → They stay in your Karakeep library forever (95% of your bookmarks)
2. **Add `#consume` tag** → Article gets podcasted and auto-deleted after 7 days (5% of bookmarks)

**Example workflow:**
- Save "How to configure SSH on Mac" → No `#consume` tag → Stays in library permanently
- Save "New GPT-5 announcement" → Add `#consume` tag → Podcasted at 2pm, deleted after 7 days

**Tag combinations:**
- Karakeep AI auto-tags: `#ai`, `#finance`, `#hometech`, etc.
- You add: `#consume` (if you want it podcasted)
- Result: "Daily Digest - AI" podcast with all AI articles tagged `#consume`

**Your permanent bookmark library is never touched** - only bookmarks explicitly tagged with `#consume` are processed.

## Workflows

### 1. Daily Podcast Generation (`karakeep-daily-podcast.json`)

**Schedule**: Daily at 2:00 PM
**Trigger**: Cron `0 14 * * *`

**What it does**:
1. Fetches bookmarks from Karakeep tagged with `#consume` (not archived)
2. Groups bookmarks by their topic tag (`#ai`, `#finance`, `#hometech`, etc.)
3. For each topic group with 2+ bookmarks:
   - Builds markdown content from bookmark data
   - Generates podcast using Open Notebook with Qwen2.5
   - Waits for podcast generation to complete
   - Copies MP3 and show notes to AudioBookShelf via alpine-utility
   - Removes `#consume` tag, adds `#podcasted` and `#podcasted-YYYY-MM-DD`
   - Archives bookmark in Karakeep
4. Triggers AudioBookShelf library scan
5. Logs summary of generated podcasts

**Output**:
- Podcasts in AudioBookShelf at `/Volumes/docker/container_configs/audiobookshelf/podcasts/Daily-Digests/`
- Bookmarks archived and tagged for future cleanup
- Your permanent bookmark library (without `#consume` tag) remains untouched

### 2. Bookmark Cleanup (`karakeep-bookmark-cleanup.json`)

**Schedule**: Daily at 3:00 AM
**Trigger**: Cron `0 3 * * *`

**What it does**:
1. Fetches archived bookmarks tagged with `#podcasted`
2. Filters for bookmarks older than 7 days
3. Logs bookmarks to be deleted (audit trail)
4. Deletes old podcasted bookmarks
5. Sends notification if more than 10 bookmarks deleted

**Output**:
- Cleanup log in n8n execution history
- Optional notification for large cleanups
- **Your permanent bookmark library (without `#consume` tag) is never touched**

## Setup Instructions

### 1. Import Workflows into n8n

1. **Access n8n**: http://localhost:5678
2. **Import workflows**:
   - Click "+ Add workflow" → "Import from File"
   - Select `karakeep-daily-podcast.json`
   - Repeat for `karakeep-bookmark-cleanup.json`

### 2. Configure Credentials

Both workflows require a Karakeep API credential:

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
   - Open each workflow
   - For nodes that say "Select Credential", choose "Karakeep API"
   - Save workflow

### 3. Test Workflows

#### Test Podcast Generation

1. **Add test bookmarks**:
   - Add 3-5 bookmarks in Karakeep
   - Tag 2-3 of them with `#consume` (leave others without it)
   - Make sure Karakeep AI auto-tags them (e.g., `#ai`, `#hometech`)

2. **Run workflow manually**:
   - Open "Karakeep Daily Podcast Generation" workflow
   - Click "Execute Workflow"
   - Watch the execution flow

3. **Verify results**:
   - Check AudioBookShelf: http://localhost:13378
   - Look for episodes: "Daily Digest - AI - MM-DD-YYYY", etc.
   - Verify MP3 and .txt show notes files exist
   - Check Karakeep:
     - Bookmarks with `#consume` are now archived with `#podcasted` tag
     - Bookmarks without `#consume` are still in your main library untouched

#### Test Cleanup

1. **Create old test bookmarks**:
   - You can't easily simulate 7-day-old bookmarks
   - Alternative: Edit the "Calculate Cutoff Date" node
   - Change `minus({ days: 7 })` to `minus({ hours: 1 })`
   - This will clean up archived podcasted bookmarks older than 1 hour

2. **Run workflow manually**:
   - Open "Karakeep Bookmark Cleanup" workflow
   - Click "Execute Workflow"
   - Check execution log for deleted bookmarks

3. **Verify results**:
   - Check Karakeep - archived `#podcasted` bookmarks should be gone
   - Your permanent bookmarks (without `#consume` tag) should remain untouched

4. **Restore production setting**:
   - Change cutoff back to `minus({ days: 7 })`
   - Save workflow

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

## Workflow Configuration

### Customization Options

#### Podcast Generation

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

**Change podcast profiles**:
- Edit "Generate Podcast" node
- Change `episode_profile` or `speaker_profile` values

#### Cleanup

**Change retention period**:
- Edit "Calculate Cutoff Date" node
- Change `minus({ days: 7 })` to desired duration

**Change notification threshold**:
- Edit "Build Summary" node
- Line: `notify: count > 10` → change `10` to desired threshold

## Troubleshooting

### Podcast Generation Fails

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

### Cleanup Not Working

**No bookmarks deleted**
- Verify bookmarks are older than 7 days
- Check bookmarks have `#podcasted` tag
- Ensure bookmarks are archived

**Wrong bookmarks deleted**
- Check "Filter Old Podcasted" logic
- Review audit log in workflow execution
- Verify cutoff date calculation
- **Important**: Only archived `#podcasted` bookmarks should be deleted, never your permanent library

### General Issues

**Workflow doesn't run on schedule**
- Check workflow is "Active"
- Verify n8n container is running
- Check n8n logs: `docker compose logs n8n`

**Execution timeout**
- Increase timeout in workflow settings
- Check for slow API responses

## Advanced: Adding Notifications

To add Slack/Discord/Email notifications:

1. **Add notification credential** in n8n
2. **Add notification node** to end of workflows:
   - After "Build Summary" in podcast generation
   - After "Should Notify?" in cleanup
3. **Configure message** using `{{ $json.message }}`

Example Slack notification node:
```json
{
  "channel": "#homelab",
  "text": "={{ $json.message }}"
}
```

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

### Execution History

View in n8n:
- Go to "Executions" tab
- Filter by workflow name
- Check success/failure rates
- Review execution logs

## Backup

These workflow JSON files are version-controlled in this repository. To backup:

```bash
# Export from n8n UI
# Workflows → Select workflow → "Download"

# Or use n8n CLI
n8n export:workflow --all --output=/path/to/backup/
```

## Related Documentation

- [Open Notebook Setup](../docs/open-notebook-setup.md) - Podcast generation configuration
- [Karakeep API Reference](../docs/karakeep-api-reference.md) - API documentation
- [Karakeep Podcast Workflow](../docs/karakeep-podcast-workflow.md) - Complete workflow guide

---

**Last Updated:** December 8, 2024
**Version:** 1.0
