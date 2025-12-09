# Quick Start: Karakeep Podcast Automation

This guide will get your automated bookmark-to-podcast system running in 15 minutes.

## Prerequisites

✅ Docker and Docker Compose running
✅ Homelab services deployed (Open Notebook, Karakeep, n8n, OpenEDAI Speech)
✅ Ollama with Qwen2.5:7b and nomic-embed-text models

## Step 1: Verify Services (2 minutes)

Check all required services are running:

```bash
cd /Users/bud/home_space/homelab
docker compose ps
```

Should see:
- ✅ `open-notebook` - Running
- ✅ `openedai-speech` - Running
- ✅ `karakeep` - Running
- ✅ `n8n` - Running

If any are missing:
```bash
docker compose up -d open-notebook openedai-speech karakeep n8n
```

## Step 2: Configure Open Notebook (5 minutes)

### 2.1 Configure Models in UI

1. Open Open Notebook: http://localhost:8503
2. Go to Settings → Models
3. Configure three models:

**Language Model**:
- Provider: `ollama`
- Model: `gemma3`

**Text-to-Speech**:
- Provider: `openai-compatible`
- Model: `tts-1`

**Embedding**:
- Provider: `ollama`
- Model: `nomic-embed-text`

### 2.2 Create Custom Profiles via API

Open terminal and run these curl commands:

**Create Speaker Profile**:
```bash
curl -X POST http://localhost:5055/api/speaker-profiles \
  -H "Content-Type: application/json" \
  -d '{
  "name": "tech_experts_local",
  "description": "Two technical experts using local models",
  "tts_provider": "openai-compatible",
  "tts_model": "tts-1",
  "speakers": [
    {
      "name": "Dr. Alex Chen",
      "voice_id": "nova",
      "backstory": "Senior AI researcher and former tech lead at major companies.",
      "personality": "Analytical, clear communicator"
    },
    {
      "name": "Jamie Rodriguez",
      "voice_id": "alloy",
      "backstory": "Full-stack engineer and tech entrepreneur.",
      "personality": "Enthusiastic, practical-minded"
    }
  ]
}'
```

**Create Episode Profile**:
```bash
curl -X POST http://localhost:5055/api/episode-profiles \
  -H "Content-Type: application/json" \
  -d '{
  "name": "tech_discussion_qwen",
  "description": "Technical discussion using Qwen2.5",
  "speaker_config": "tech_experts_local",
  "outline_provider": "ollama",
  "outline_model": "qwen2.5:7b",
  "transcript_provider": "ollama",
  "transcript_model": "qwen2.5:7b",
  "default_briefing": "Create an engaging technical discussion about the provided content.",
  "num_segments": 5
}'
```

## Step 3: Get Karakeep API Token (2 minutes)

1. Open Karakeep: http://localhost:3000
2. Log in (or create account if first time)
3. Go to Settings → API Tokens
4. Click "Create New Token"
5. Name: `n8n Automation`
6. Copy the token (save it somewhere!)

## Step 4: Import n8n Workflows (3 minutes)

### 4.1 Add Karakeep Credential

1. Open n8n: http://localhost:5678
2. Go to Settings (gear icon) → Credentials
3. Click "+ Add Credential"
4. Search for "Header Auth"
5. Fill in:
   - **Credential Name**: `Karakeep API`
   - **Name**: `Authorization`
   - **Value**: `Bearer YOUR_TOKEN_FROM_STEP_3`
6. Click "Save"

### 4.2 Import Workflows

1. Click "+ Add workflow" → "Import from File"
2. Select `n8n-workflows/karakeep-daily-podcast.json`
3. Click "Import"
4. **Assign credentials**: Click on any node that shows "Select Credential"
5. Choose "Karakeep API" from dropdown
6. Click "Save" (top-right)

Repeat for cleanup workflow:
1. Import `n8n-workflows/karakeep-bookmark-cleanup.json`
2. Assign "Karakeep API" credential
3. Save

## Step 5: Test Podcast Generation (3 minutes)

### 5.1 Add Test Bookmarks

1. Go to Karakeep: http://localhost:3000
2. Add 3 bookmarks with the tag `test`:
   - Click "+ Add Bookmark"
   - Paste URLs (any tech articles)
   - Tag each with `test`
   - Save

### 5.2 Run Workflow

1. In n8n, open "Karakeep Daily Podcast Generation"
2. Click "Execute Workflow" button
3. Watch the nodes execute (should take ~5 minutes total)

### 5.3 Verify Results

1. Check Open Notebook: http://localhost:8503
2. Look for episode: "Daily Digest - test - [today's date]"
3. Click on episode → should see audio player
4. Play audio to verify it works!
5. Go back to Karakeep → check bookmarks have `#podcasted` tag

## Step 6: Enable Automation (1 minute)

Once test succeeds:

1. In n8n, open "Karakeep Daily Podcast Generation"
2. Toggle "Active" switch (top-right) to ON
3. Open "Karakeep Bookmark Cleanup"
4. Toggle "Active" switch to ON

## You're Done! 🎉

Your automation is now live:

- **2:00 PM daily**: Generates podcasts from yesterday's bookmarks
- **3:00 AM daily**: Cleans up bookmarks older than 7 days (except starred)

## Daily Workflow

### Morning Routine
1. Throughout the day: Save bookmarks via Karakeep (web, mobile, extension)
2. Karakeep auto-tags them with topics (AI, finance, hometech, etc.)

### Afternoon (2:00 PM)
3. n8n automatically generates podcasts by topic
4. Bookmarks tagged as `#podcasted`

### Evening
5. Listen to podcasts in AudioBookShelf (or Open Notebook web UI)
6. **Star bookmarks you want to keep permanently**

### Night (3:00 AM)
7. Old unstarred podcasted bookmarks automatically deleted

## Next Steps

### Add More Topics

Karakeep will automatically create podcasts for any tag group with 2+ bookmarks:
- Just ensure bookmarks are tagged correctly
- Common tags: `ai`, `finance`, `hometech`, `cooking`, `travel`, etc.

### Customize Podcast Length

Edit the workflow:
1. Open "Karakeep Daily Podcast Generation" in n8n
2. Find "Build Markdown Content" node
3. Change: `substring(0, 500)` to longer/shorter number
4. Save

### Change Schedule

1. Edit workflow nodes
2. Modify cron expressions:
   - `0 14 * * *` = 2:00 PM
   - `0 9 * * *` = 9:00 AM
   - `0 20 * * *` = 8:00 PM

### Add AudioBookShelf Integration

To automatically move podcasts to AudioBookShelf:

1. Create folder: `/mnt/user-data/audiobookshelf/Daily-Digests/`
2. Add node to workflow to copy MP3 files
3. Trigger AudioBookShelf scan

## Troubleshooting

### Podcast Generation Fails

**Check Open Notebook logs**:
```bash
docker compose logs open-notebook --tail 50
```

**Verify Qwen model is loaded**:
```bash
docker exec -it open-notebook ollama list
```

### No Bookmarks Fetched

**Test Karakeep API**:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/api/v1/bookmarks?limit=1
```

Should return JSON with bookmarks.

### Cleanup Deleted Wrong Bookmarks

**Check execution log** in n8n:
1. Go to "Executions" tab
2. Find cleanup workflow execution
3. Review "Log for Audit" node output

## Documentation

Full documentation available in `docs/`:
- [Open Notebook Setup](docs/open-notebook-setup.md)
- [Karakeep API Reference](docs/karakeep-api-reference.md)
- [Karakeep Podcast Workflow](docs/karakeep-podcast-workflow.md)
- [n8n Workflows README](n8n-workflows/README.md)

## Support

For issues:
1. Check workflow execution logs in n8n
2. Check Docker container logs
3. Review documentation
4. Check [main README](README.md) troubleshooting section

---

**Estimated Setup Time**: 15 minutes
**Last Updated**: December 8, 2024
