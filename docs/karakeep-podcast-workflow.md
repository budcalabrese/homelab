# Karakeep Automated Bookmark Podcast Workflow

## Overview

This workflow automatically converts daily bookmarks into topic-based podcasts with automated cleanup and link management.

---

## System Architecture

### Components
- **Karakeep**: Self-hosted bookmark manager with AI auto-tagging (Ollama)
- **n8n**: Workflow automation and orchestration
- **Open Notebook**: Conversational podcast generation
- **AudioBookShelf**: Podcast library and playback
- **Tailscale**: Secure remote access

### Data Flow
```
iPhone → Karakeep (auto-tag) → n8n (2pm trigger) → Open Notebook → AudioBookShelf → Cleanup (7 days)
```

---

## The Complete Bookmark Lifecycle

### Phase 1: Capture (Throughout Day)
- Save bookmarks via Karakeep iOS app share sheet
- Karakeep automatically tags using Ollama AI:
  - `#ai` - AI and machine learning content
  - `#finance` - Financial news and analysis
  - `#hometech` - Smart home and homelab content
  - (Additional tags as configured)

### Phase 2: Podcast Generation (Daily at 2:00 PM)
1. n8n queries Karakeep API for bookmarks added in last 24 hours
2. Groups bookmarks by primary tag
3. For each tag group with 2+ articles:
   - Fetches full article content and URLs
   - Creates markdown file for Open Notebook
   - Generates conversational podcast (10-15 min)
   - Creates show notes with article links
   - Saves to AudioBookShelf
   - Tags bookmarks as `#podcasted` and `#podcasted-YYYY-MM-DD`
4. Sends notification: "X podcasts ready: AI, Finance, Home Tech"

### Phase 3: Listen & Decide (2:00-3:00 PM)
- Open AudioBookShelf app/web interface
- Listen to topic-based podcasts
- Access article links via episode show notes
- Star interesting bookmarks in Karakeep for permanent keeping

### Phase 4: Automated Cleanup (Daily at 3:00 AM)
- Queries bookmarks tagged `#podcasted`, older than 7 days, NOT starred
- Deletes old bookmarks automatically
- Sends notification if >10 cleaned
- Keeps Karakeep database lean

---

## Option A Implementation (Recommended)

### Show Notes in AudioBookShelf

**Episode Description Format:**
```
Daily Digest - AI - December 4, 2024

Articles covered:
• OpenAI releases new model capabilities
  https://techcrunch.com/2024/12/04/openai-announces...
  
• EU AI regulation update and compliance deadlines
  https://reuters.com/technology/ai-regulation...
  
• Local AI tools comparison for homelab deployment
  https://selfhosted.show/episode/ai-tools...

---
Auto-generated from Karakeep bookmarks
Total articles: 3 | Duration: ~12 minutes
```

### User Experience
1. While listening, tap episode to view show notes
2. Click article link to open in browser
3. If article worth deeper reading → Open Karakeep app → Star the bookmark
4. Starred bookmarks saved from auto-deletion
5. Unstarred bookmarks auto-delete after 7 days

---

## Claude Code Prompt

Use this prompt in Claude Code to generate the complete n8n workflows:

```
I'm building an automated bookmark podcast generation system with lifecycle management. Here's the workflow I need:

CONTEXT:
- I use Karakeep (self-hosted bookmark manager) to save articles throughout the day
- Karakeep auto-tags bookmarks with topics like "AI", "finance", "hometech" using Ollama
- I have Open Notebook (self-hosted) for generating conversational podcasts
- I use AudioBookShelf to listen to generated podcasts
- Everything is orchestrated via n8n workflows
- Using Tailscale for secure remote access

WORKFLOW 1: DAILY PODCAST GENERATION (2PM)

Daily at 2:00 PM, I need n8n to:

1. Query Karakeep API for all bookmarks added in last 24 hours
2. Group bookmarks by their primary tag (AI, finance, hometech, etc.)
3. For each tag group with 2+ articles:
   a. Fetch full article content and URLs from Karakeep
   b. Create a markdown file formatted for Open Notebook:
      - Filename: YYYY-MM-DD-{tag}.md
      - Content: Combined article summaries with source URLs
   c. Spin up docker-compose.podcast.yml (Open Notebook)
   d. Process the markdown file → generate MP3
   e. Create show notes file with article links:
      - Filename: YYYY-MM-DD-{tag}.txt
      - Content: Formatted list of all article titles + URLs
   f. Move MP3 + show notes to AudioBookShelf directory: /mnt/user-data/audiobookshelf/Daily-Digests/
   g. Update AudioBookShelf metadata to include show notes
   h. Update Karakeep bookmarks: Add tag "#podcasted" and "#podcasted-YYYY-MM-DD"
   i. Spin down containers
4. Send notification: "X bookmark podcasts ready: [topics]"

WORKFLOW 2: CLEANUP (DAILY AT 3AM)

Daily at 3:00 AM, I need n8n to:

1. Query Karakeep API for bookmarks that are:
   - Tagged with "#podcasted"
   - Older than 7 days
   - NOT starred/favorited
2. Delete these bookmarks
3. Send notification if >10 bookmarks cleaned: "Cleaned up X old podcast bookmarks"

DELIVERABLES NEEDED:
1. Two n8n workflow JSONs (podcast generation + cleanup)
2. Show notes template for AudioBookShelf
3. Helper scripts for Karakeep API interactions
4. Updated docker-compose.podcast.yml if modifications needed

CURRENT DOCKER COMPOSE FILE:
[Paste your docker-compose.podcast.yml here]

KARAKEEP API DETAILS:
- Base URL: http://karakeep:3000/api
- Authentication: Bearer token (I'll provide via environment variable)
- Key endpoints:
  - GET /v1/bookmarks?limit=100&addedAfter={timestamp}
  - GET /v1/bookmarks/{id}
  - PATCH /v1/bookmarks/{id} (for adding tags)
  - DELETE /v1/bookmarks/{id}
  - GET /v1/bookmarks?tags=podcasted&createdBefore={timestamp}&starred=false

TECHNICAL CONSTRAINTS:
- All services run in Docker on same host (Mac Mini homelab)
- n8n has access to Docker socket for container management
- AudioBookShelf directory: /mnt/user-data/audiobookshelf/Daily-Digests
- Temporary files go to: /home/claude/temp/podcasts
- Use existing Open Notebook container config
- Show notes must be readable by AudioBookShelf (txt format)
- Podcast files: MP3 format, 128kbps minimum

FILE NAMING CONVENTIONS:
- Podcasts: "Daily Digest - {Tag} - {Date}.mp3"
  Example: "Daily Digest - AI - 2024-12-04.mp3"
- Show notes: "Daily Digest - {Tag} - {Date}.txt"
  Example: "Daily Digest - AI - 2024-12-04.txt"

SPECIFIC REQUESTS:
- Make the n8n workflows modular (separate nodes for each step)
- Include comprehensive error handling:
  - No bookmarks for the day
  - Karakeep API failures
  - Container start/stop issues
  - AudioBookShelf directory write errors
- Tag filtering: Only generate podcast if 2+ articles in a tag group
- Skip empty tag groups entirely
- Keep containers down when not in use (resource efficiency)
- Cleanup workflow should be safe (log before deletion)
- Include retry logic for API calls (3 attempts with backoff)

USER EXPERIENCE GOALS:
- While listening to podcast, user accesses show notes in AudioBookShelf
- Clicking a link in show notes opens the full article in browser
- If user stars a bookmark in Karakeep, it's permanently saved from auto-deletion
- Unchecked bookmarks auto-delete after 7 days
- Zero manual intervention required for daily operation
- Notifications only for success/errors, not every step

NOTIFICATION FORMAT:
Success: "📻 3 podcasts ready: AI (5 articles), Finance (3 articles), Home Tech (4 articles)"
Cleanup: "🧹 Cleaned up 47 old podcast bookmarks"
Error: "⚠️ Podcast generation failed: Karakeep API unreachable"

Please provide:
1. Complete n8n workflow JSONs (both workflows, ready to import)
2. Show notes template with proper formatting
3. Step-by-step setup instructions
4. Configuration files needed
5. Testing commands to verify each step works
6. Karakeep API interaction examples (curl commands)
7. Troubleshooting guide for common issues

COMPATIBILITY NOTE:
My existing study notes workflow uses the same Open Notebook setup for processing Obsidian files with #generate-podcast tags. Ensure this bookmark workflow maintains compatibility and doesn't interfere with the study notes workflow. Both should be able to run independently.
```

---

## Open Notebook Configuration (Local Models)

### Successfully Tested: Fully Local Podcast Generation ✅

**Achievement**: Complete podcast generation pipeline using only local models - no cloud APIs, complete privacy, zero API costs.

### Working Configuration Summary

**Models Required:**
- **LLM (Outline/Transcript)**: `qwen2.5:7b` via Ollama
- **TTS (Audio)**: `tts-1` via OpenEDAI Speech
- **Embedding**: `nomic-embed-text` via Ollama

**Why Qwen2.5 over Gemma3:**
- Gemma3 fails with JSON parsing errors on Open Notebook's Pydantic schemas
- Qwen2.5:7b successfully generates structured Outline and Transcript JSON
- Better at following complex JSON schema requirements

### Environment Configuration

File: [.env.open-notebook](../homelab/.env.open-notebook)

```bash
# API Server Configuration
API_URL=http://192.168.0.9:5055
INTERNAL_API_URL=http://localhost:5055
API_CLIENT_TIMEOUT=300

# Ollama Configuration
OLLAMA_API_BASE=http://host.docker.internal:11434

# Default LLM Provider Settings (for outline and transcript generation)
DEFAULT_LLM_PROVIDER=ollama
DEFAULT_LLM_MODEL=gemma3  # Note: UI uses this default, but profiles override

# OpenAI Configuration (redirected to local OpenEDAI Speech for TTS)
OPENAI_API_KEY=sk-111111111  # Dummy key for local service
OPENAI_BASE_URL=http://openedai-speech:8000/v1

# OpenAI-Compatible Provider Configuration
OPENAI_COMPATIBLE_BASE_URL=http://openedai-speech:8000/v1
OPENAI_COMPATIBLE_API_KEY=sk-111111111

# TTS Configuration (OpenAI-compatible local TTS)
OPENAI_COMPATIBLE_BASE_URL_TTS=http://openedai-speech:8000/v1
OPENAI_COMPATIBLE_API_KEY_TTS=sk-111111111
OPENAI_COMPATIBLE_MODELS_TTS=tts-1,tts-1-hd
TTS_BATCH_SIZE=2

# Default TTS Provider Settings
DEFAULT_TTS_PROVIDER=openai-compatible
DEFAULT_TTS_MODEL=tts-1

# Database connection (required for single-container)
SURREAL_URL=ws://localhost:8000/rpc
SURREAL_USER=root
SURREAL_PASSWORD=root
SURREAL_NAMESPACE=open_notebook
SURREAL_DATABASE=production
```

### UI Model Configuration

**Required Models in UI** (Settings → Models):

1. **Language Model**:
   - Provider: `ollama`
   - Model: `gemma3` (default, but profiles can override with qwen2.5)

2. **Text-to-Speech**:
   - Provider: `openai-compatible`
   - Model: `tts-1`

3. **Embedding Model**:
   - Provider: `ollama`
   - Model: `nomic-embed-text`

**Important**: These UI settings configure available models system-wide. Custom profiles (below) reference these models.

### Custom Profiles (API Configuration)

**Why Custom Profiles?**
- Default seeded profiles (`tech_experts`, `tech_discussion`) use OpenAI API
- Custom profiles use local models exclusively
- Profiles are stored in SurrealDB and persist across restarts

#### Speaker Profile: `tech_experts_local`

**Creation Endpoint**: `POST http://localhost:5055/api/speaker-profiles`

```json
{
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
}
```

**Profile ID**: `speaker_profile:s3wt2c9oaoa8o2x8a4yu`

**Available Voice IDs** (OpenEDAI Speech):
- `nova` - Clear, professional female voice
- `alloy` - Neutral, versatile voice
- `echo` - Male voice
- `fable` - Expressive voice
- `onyx` - Deep male voice
- `shimmer` - Warm female voice

#### Episode Profile: `tech_discussion_qwen`

**Creation Endpoint**: `POST http://localhost:5055/api/episode-profiles`

```json
{
  "name": "tech_discussion_qwen",
  "description": "Technical discussion using Qwen2.5 for better JSON output",
  "speaker_config": "tech_experts_local",
  "outline_provider": "ollama",
  "outline_model": "qwen2.5:7b",
  "transcript_provider": "ollama",
  "transcript_model": "qwen2.5:7b",
  "default_briefing": "Create an engaging technical discussion about the provided content. Focus on practical insights, real-world applications, and detailed explanations.",
  "num_segments": 5
}
```

**Profile ID**: `episode_profile:s1rw2rlbt9b5jkrhwoaf`

### Generating Podcasts with Custom Profiles

**API Endpoint**: `POST http://localhost:5055/api/podcasts/generate`

**Request Body**:
```json
{
  "episode_profile": "tech_discussion_qwen",
  "speaker_profile": "tech_experts_local",
  "episode_name": "Daily Digest - AI - 2024-12-08",
  "content": "# Daily Digest - AI - 2024-12-08\n\n## Article 1: Title\nSource: https://...\n\nContent here...\n\n## Article 2: Title\nSource: https://...\n\nMore content..."
}
```

**Response**:
```json
{
  "job_id": "command:xxx",
  "episode_id": "episode:xxx",
  "status": "processing"
}
```

**Check Status**: `GET http://localhost:5055/api/episodes/{episode_id}`

### Performance Metrics

**Test Episode**: "Local AI Podcast with Qwen"
- **Total Time**: 281.65 seconds (~4.7 minutes)
- **Segments**: 5 segments generated
- **Audio Clips**: 30+ clips generated and combined
- **Final Output**: `/app/data/podcasts/episodes/{episode_name}/audio/{episode_name}.mp3`

**Processing Breakdown**:
1. Outline generation (Qwen2.5): ~30 seconds
2. Transcript generation (Qwen2.5): ~60 seconds
3. Audio synthesis (OpenEDAI Speech): ~180 seconds (30+ clips)
4. Audio combining: ~10 seconds

### Troubleshooting

#### Issue: No Audio File Generated

**Symptoms**: Episode shows `"audio_file": null`, status is "completed"

**Causes**:
1. Using default seeded profiles with OpenAI provider
2. Invalid API key for OpenAI-compatible service
3. TTS provider configuration mismatch

**Solution**: Use custom profiles with local providers (`tech_discussion_qwen` + `tech_experts_local`)

#### Issue: JSON Parsing Error with Gemma3

**Error**:
```
Failed to parse Outline from completion. Got: 1 validation error for Outline
```

**Cause**: Gemma3 cannot generate properly structured JSON matching Open Notebook's Pydantic schemas

**Solution**: Use Qwen2.5:7b instead - create episode profile with `"outline_model": "qwen2.5:7b"`

#### Issue: Missing Embedding Model Warning

**Symptoms**: UI shows "Missing required models: Embedding Model"

**Solution**:
1. Pull model: `docker exec -it open-notebook ollama pull nomic-embed-text`
2. Configure in UI: Settings → Models → Add Embedding Model
   - Provider: `ollama`
   - Model: `nomic-embed-text`

#### Issue: OpenEDAI Speech Connection Failed

**Check Connectivity**:
```bash
# From inside Open Notebook container
docker exec open-notebook curl http://openedai-speech:8000/v1/models

# Should return:
{
  "data": [
    {"id": "tts-1"},
    {"id": "tts-1-hd"}
  ]
}
```

**Fix**: Ensure OpenEDAI Speech container is running and accessible via Docker network

### Database Reset (If Needed)

**Warning**: This deletes all episodes, profiles, and settings!

```bash
# Stop container
cd /Users/bud/home_space/homelab
docker compose down open-notebook

# Delete database
sudo rm -rf /Volumes/docker/container_configs/open-notebook/*

# Restart container
docker compose up -d open-notebook

# Reconfigure:
# 1. Set models in UI (LLM, TTS, Embedding)
# 2. Create custom profiles via API
```

### n8n Integration Notes

**For Automated Workflows**:

1. **Always use custom profiles**: `tech_discussion_qwen` + `tech_experts_local`
2. **Content format**: Markdown with article titles, sources, and content
3. **Episode naming**: `"Daily Digest - {Topic} - {Date}"`
4. **Status checking**: Poll `/api/episodes/{id}` until `status == "completed"`
5. **Audio retrieval**: Episode object contains `audio_file` path inside container

**Example n8n HTTP Request Node**:
```json
{
  "method": "POST",
  "url": "http://open-notebook:5055/api/podcasts/generate",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "episode_profile": "tech_discussion_qwen",
    "speaker_profile": "tech_experts_local",
    "episode_name": "{{$json.episodeName}}",
    "content": "{{$json.markdownContent}}"
  }
}
```

### Model Download Commands

```bash
# Pull required Ollama models
docker exec -it open-notebook ollama pull qwen2.5:7b
docker exec -it open-notebook ollama pull nomic-embed-text
docker exec -it open-notebook ollama pull gemma3  # Optional fallback

# Verify models
docker exec -it open-notebook ollama list
```

### Resource Requirements

**Per Podcast Generation**:
- **CPU**: 4-8 cores recommended (Qwen2.5:7b benefits from more cores)
- **RAM**: 8GB minimum (Qwen2.5 uses ~6GB during generation)
- **Disk**: ~50MB per 10-minute podcast episode
- **Time**: 4-6 minutes for 5-segment podcast

**Concurrent Generation**: Not recommended - run sequentially to avoid OOM errors

---

## n8n Workflow Structure

### Workflow 1: Podcast Generation (Daily 2PM)

```
[Schedule Trigger: Cron 0 14 * * *]
    ↓
[Set Variables: Date, Timestamps]
    ↓
[HTTP Request: GET Karakeep Bookmarks]
    (Last 24 hours, all tags)
    ↓
[Function: Filter & Group by Primary Tag]
    (Creates array of tag groups)
    ↓
[IF: Any groups with 2+ articles?]
    ├─ NO → [End: No podcasts needed]
    └─ YES ↓
[Split Into Batches]
    (One iteration per tag group)
    ↓
[Loop Start: For Each Tag Group]
    ↓
    [HTTP Request: Fetch Full Article Content]
        (Parallel requests for all articles in group)
        ↓
    [Function: Format Markdown for Open Notebook]
        (Combine articles, add metadata)
        ↓
    [Write File: Save .md to temp directory]
        (/home/claude/temp/podcasts/2024-12-04-AI.md)
        ↓
    [Execute Command: docker-compose up -d]
        (Start Open Notebook containers)
        ↓
    [Wait: 60 seconds]
        (Allow processing time)
        ↓
    [Execute Command: Check if MP3 exists]
        ↓
    [IF: MP3 Generated Successfully?]
        ├─ NO → [Log Error & Skip]
        └─ YES ↓
        [Function: Create Show Notes Content]
            (Format article links)
            ↓
        [Write File: Save show notes .txt]
            ↓
        [Move Files: MP3 + TXT to AudioBookShelf]
            (/mnt/user-data/audiobookshelf/Daily-Digests/)
            ↓
        [HTTP Request: PATCH Karakeep Bookmarks]
            (Add #podcasted and #podcasted-YYYY-MM-DD tags)
            ↓
        [Execute Command: docker-compose down]
            (Clean up containers)
            ↓
        [Loop Continue]
    ↓
[Merge: Collect Results from All Groups]
    ↓
[Function: Build Summary Message]
    ↓
[HTTP Request: Send Notification]
    (Webhook or Pushover)
    ↓
[End]
```

### Workflow 2: Cleanup (Daily 3AM)

```
[Schedule Trigger: Cron 0 3 * * *]
    ↓
[Set Variables: Calculate 7-day cutoff date]
    ↓
[HTTP Request: GET Karakeep Bookmarks]
    (tags=podcasted, createdBefore=7daysago, starred=false)
    ↓
[Function: Count bookmarks to delete]
    ↓
[IF: Any bookmarks to delete?]
    ├─ NO → [End: Nothing to clean]
    └─ YES ↓
    [Function: Log bookmarks for deletion]
        (For audit trail)
        ↓
    [HTTP Request: Batch DELETE Karakeep]
        (Delete all matched bookmarks)
        ↓
    [IF: Deleted count > 10?]
        ├─ NO → [Silent: No notification]
        └─ YES ↓
        [HTTP Request: Send Notification]
            ("Cleaned up X bookmarks")
            ↓
[End]
```

---

## Setup Instructions

### 1. Karakeep Installation

```bash
# Create directory
mkdir -p ~/docker/karakeep

# Create docker-compose.yml
cat > ~/docker/karakeep/docker-compose.yml << 'EOF'
version: "3.8"
services:
  web:
    image: ghcr.io/karakeep-app/karakeep:latest
    container_name: karakeep
    restart: unless-stopped
    volumes:
      - karakeep-data:/data
    environment:
      - DATA_DIR=/data
      - NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
      - NEXTAUTH_URL=http://localhost:3000
      - MEILI_ADDR=http://meilisearch:7700
      - MEILI_MASTER_KEY=${MEILI_MASTER_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY} # Optional: For AI features
      - OLLAMA_BASE_URL=http://host.docker.internal:11434 # For local AI
    ports:
      - "3000:3000"
    depends_on:
      - meilisearch
      - chrome

  chrome:
    image: ghcr.io/karakeep-app/karakeep-chrome:latest
    container_name: karakeep-chrome
    restart: unless-stopped

  meilisearch:
    image: getmeili/meilisearch:v1.5
    container_name: karakeep-meilisearch
    restart: unless-stopped
    volumes:
      - meilisearch-data:/meili_data
    environment:
      - MEILI_MASTER_KEY=${MEILI_MASTER_KEY}

volumes:
  karakeep-data:
  meilisearch-data:
EOF

# Create .env file
cat > ~/docker/karakeep/.env << 'EOF'
NEXTAUTH_SECRET=your_random_secret_here_minimum_32_chars
MEILI_MASTER_KEY=your_random_master_key_here
OPENAI_API_KEY=optional_if_using_openai
EOF

# Start Karakeep
cd ~/docker/karakeep
docker-compose up -d
```

### 2. Configure Karakeep AI Tagging

1. Access Karakeep: `http://localhost:3000` or via Tailscale
2. Go to Settings → AI
3. Configure Ollama:
   - Enable AI tagging
   - Set Ollama URL: `http://host.docker.internal:11434`
   - Select model (e.g., `llama2` or `mistral`)
4. Create tag rules:
   - Keywords for `#ai`: artificial intelligence, machine learning, LLM, neural network
   - Keywords for `#finance`: investing, stocks, portfolio, market, dividend
   - Keywords for `#hometech`: smart home, homelab, docker, self-hosted

### 3. Generate API Token

1. In Karakeep, go to Settings → API
2. Create new token: "n8n Podcast Automation"
3. Set permissions: Read bookmarks, Write bookmarks, Delete bookmarks
4. Copy token and save to n8n credentials

### 4. Import n8n Workflows

1. Open n8n interface
2. Click "Import from File"
3. Import `podcast-generation.json`
4. Import `bookmark-cleanup.json`
5. Configure credentials:
   - Karakeep API token
   - Notification webhook URL
6. Test each workflow manually first

### 5. AudioBookShelf Setup

```bash
# Create directory structure
mkdir -p /mnt/user-data/audiobookshelf/Daily-Digests

# Set permissions
chmod 755 /mnt/user-data/audiobookshelf/Daily-Digests

# Add library in AudioBookShelf UI
# Library name: "Daily Digests"
# Path: /mnt/user-data/audiobookshelf/Daily-Digests
# Type: Podcast
```

---

## Testing

### Test Karakeep API

```bash
# Set your API token
TOKEN="your_karakeep_api_token"

# Test: Get recent bookmarks
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/bookmarks?limit=10

# Test: Get bookmarks by tag
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/bookmarks?tags=ai

# Test: Add tag to bookmark
curl -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tags":["podcasted","podcasted-2024-12-04"]}' \
  http://localhost:3000/api/v1/bookmarks/{bookmark_id}
```

### Manual Workflow Test

1. Save 3-5 bookmarks in Karakeep (on a test topic like "test")
2. Tag them manually with `#test`
3. Run podcast generation workflow manually in n8n
4. Check for:
   - MP3 file in AudioBookShelf directory
   - Show notes .txt file created
   - Bookmarks tagged with `#podcasted`
   - AudioBookShelf shows new episode

### Cleanup Test

1. Create test bookmarks
2. Tag them with `#podcasted` and old date
3. Run cleanup workflow
4. Verify bookmarks deleted
5. Check starred bookmarks are NOT deleted

---

## Troubleshooting

### Karakeep Issues

**Problem:** AI tagging not working
- Check Ollama is running: `curl http://localhost:11434/api/tags`
- Verify Karakeep can reach Ollama: Check container logs
- Ensure model is downloaded: `ollama pull llama2`

**Problem:** API returns 401 Unauthorized
- Verify token is valid in Karakeep settings
- Check token has correct permissions
- Ensure Bearer prefix in Authorization header

### n8n Workflow Issues

**Problem:** No bookmarks returned
- Check date range in query
- Verify tags exist in Karakeep
- Test API endpoint manually with curl

**Problem:** Podcast generation fails
- Check Open Notebook containers are running
- Verify markdown file was created correctly
- Check temp directory permissions
- Review Open Notebook logs

**Problem:** Files not appearing in AudioBookShelf
- Verify directory path is correct
- Check file permissions (should be 644)
- Trigger AudioBookShelf library scan
- Check AudioBookShelf logs

### Docker Issues

**Problem:** Containers won't start
- Check port conflicts: `docker ps`
- Verify docker-compose.yml syntax
- Check available disk space
- Review container logs: `docker logs karakeep`

---

## Maintenance

### Weekly Tasks
- Review generated podcasts for quality
- Check disk usage in AudioBookShelf directory
- Verify cleanup workflow is running

### Monthly Tasks
- Review Karakeep database size
- Update container images: `docker-compose pull && docker-compose up -d`
- Backup Karakeep data volume
- Archive old podcasts (optional)

### Backup Strategy

```bash
# Backup Karakeep data
docker run --rm \
  -v karakeep-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/karakeep-backup-$(date +%Y%m%d).tar.gz /data

# Backup n8n workflows
# Export from n8n UI to JSON files
# Store in version control (Git)
```

---

## Future Enhancements

### Potential Additions
- RSS feed generation for podcasts
- Custom voices/personas for different topics
- Integration with Obsidian for permanent notes
- Podcast transcripts for searchability
- Weekly digest (combine daily podcasts)
- Custom podcast length preferences per topic
- Multi-language support
- Reading progress tracking
- Social sharing of favorite articles

---

## Resources

- [Karakeep Documentation](https://docs.karakeep.app/)
- [Karakeep API Reference](https://docs.karakeep.app/api/)
- [n8n Community Forum](https://community.n8n.io/)
- [AudioBookShelf Documentation](https://www.audiobookshelf.org/docs)
- [Open Notebook GitHub](https://github.com/your-open-notebook-repo)

---

## Notes

- This workflow is designed for personal use (single user)
- Estimated resource usage: 2GB RAM, 10GB disk for 1000 bookmarks
- Processing time: ~2-3 minutes per topic podcast
- Recommended minimum: 2 CPU cores, 4GB RAM
- Tested on: Mac Mini M1, Docker Desktop, macOS Sonoma

---

**Last Updated:** December 8, 2024
**Version:** 1.0
**Author:** Bud
**Status:** Ready for Implementation
