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
- **Manual decision:** Add `#consume` tag if you want this article podcasted
  - Articles to consume once (news, announcements, analysis) → Add `#consume`
  - Reference articles to keep (how-tos, documentation, guides) → No extra tag needed

### Phase 2: Podcast Generation (Daily at 2:00 PM)
1. n8n queries Karakeep API for bookmarks tagged with `#consume`
2. Groups bookmarks by topic tag (`#ai`, `#finance`, `#hometech`, etc.)
3. For each topic group with 2+ articles:
   - Fetches full article content and URLs
   - Creates markdown file for Open Notebook
   - Submits podcast generation request to Open Notebook API
   - Polls for completion status
   - Extracts audio file path from completed episode
   - Creates show notes with article titles and URLs
   - Copies MP3 and show notes to AudioBookShelf via alpine-utility bastion host
   - Triggers AudioBookShelf library scan
   - Removes `#consume` tag, adds `#podcasted` and `#podcasted-YYYY-MM-DD`
   - Archives bookmark in Karakeep
4. Sends notification: "X podcasts ready: AI, Finance, Home Tech"

### Phase 3: Listen (2:00-3:00 PM)
- Open AudioBookShelf app/web interface
- Listen to topic-based podcasts
- Access article links via episode show notes if you want to read the full article
- Your permanent bookmark library (items without `#consume` tag) remains untouched in Karakeep

### Phase 4: Automated Cleanup (Daily at 3:00 AM)
- Queries archived bookmarks with `#podcasted` tag older than 7 days
- **Protects starred bookmarks** - if you starred a podcasted bookmark, it won't be deleted
- Deletes old un-starred podcasted bookmarks automatically
- Sends notification if >10 cleaned
- Keeps Karakeep database lean
- **Important:** Only deletes consumed/podcasted bookmarks - your reference library is safe

---

## Tagging Strategy

### How Tags Work Together

**Auto-tags (from Karakeep AI):**
- `#ai` - AI and machine learning articles
- `#finance` - Financial news and analysis
- `#hometech` - Smart home, homelab, Docker, self-hosting
- etc. (configured in Karakeep settings)

**Manual tag (you decide):**
- `#consume` - "I want this podcasted and then deleted"

### Examples

| Article | Auto Tags | You Add | What Happens |
|---------|-----------|---------|--------------|
| "New GPT-5 announcement" | `#ai` | `#consume` | → Podcasted in "Daily Digest - AI", then deleted after 7 days |
| "How to configure SSH on Mac" | `#hometech` | (nothing) | → Stays in your Karakeep library forever |
| "Stock market analysis today" | `#finance` | `#consume` | → Podcasted in "Daily Digest - Finance", then deleted after 7 days |
| "Docker Compose best practices" | `#hometech` | (nothing) | → Stays in your Karakeep library forever |
| "Understanding RAG systems" | `#ai` | `#consume` | → Podcasted in "Daily Digest - AI", then deleted after 7 days |
| "n8n workflow examples" | `#hometech` | (nothing) | → Stays in your Karakeep library forever |

### Decision Guide

**Add `#consume` tag when:**
- News articles (want to stay informed, but don't need to keep)
- Product announcements (interesting now, not needed later)
- Opinion pieces or analysis (consume once)
- Time-sensitive content
- Long-form articles you won't have time to read

**Don't add `#consume` tag when:**
- How-to guides or tutorials
- Documentation or reference material
- Troubleshooting guides
- Code examples or snippets
- Anything you might need to reference later

### Quick Tagging on Mobile

When saving from iOS Safari:
1. Tap Share button
2. Select Karakeep
3. Karakeep AI auto-tags the article (`#ai`, `#hometech`, etc.)
4. If you want it podcasted → tap to add `#consume` tag
5. Save

That's it! The n8n workflow handles everything else automatically.

### Saving Podcasted Bookmarks

If you listen to a podcast and decide you want to keep the article:
1. Open Karakeep
2. Go to **Archives** tab
3. Find the bookmark (it will be tagged `#podcasted`)
4. **Star/favorite it** ⭐
5. The cleanup workflow will skip it - starred bookmarks are never deleted

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
2. Click article link to open in browser if you want to read the full version
3. Podcasted bookmarks are archived and auto-deleted after 7 days
4. Your permanent bookmark library (reference articles, how-tos, etc.) stays untouched in Karakeep

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

## AudioBookshelf Integration Implementation

### Overview

The workflow integrates with AudioBookshelf by copying generated podcast files from the Open Notebook container to the AudioBookshelf directory and triggering a library scan. This is accomplished using the alpine-utility container as a bastion host.

### Architecture

```
n8n → SSH to alpine-utility → docker cp from open-notebook → AudioBookshelf directory
```

**Why alpine-utility?**
- n8n container doesn't have Docker CLI or socket access
- alpine-utility has Docker socket access for health monitoring
- Reuses existing infrastructure instead of adding Docker socket to n8n
- Provides secure separation of concerns

### Implementation Details

#### 1. Volume Configuration

The alpine-utility container has access to the AudioBookshelf directory:

```yaml
# compose.yml - alpine-utility service
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
  - /Volumes/docker/container_configs/alpine-utility:/config
  - /Volumes/docker/container_configs/audiobookshelf/podcasts:/mnt/audiobookshelf
```

This mounts the AudioBookshelf podcasts directory at `/mnt/audiobookshelf` inside alpine-utility.

#### 2. File Copy Script

A script at `/tmp/copy-podcast.sh` inside alpine-utility handles the file operations:

```bash
#!/bin/sh
# Copy podcast files from Open Notebook to AudioBookshelf

EPISODE_NAME="$1"
AUDIO_FILE="$2"
SHOW_NOTES="$3"

TARGET_DIR="/mnt/audiobookshelf/Daily-Digests"

echo "=== Podcast File Copy Script ==="
echo "Episode name: $EPISODE_NAME"
echo "Audio file: $AUDIO_FILE"
echo "Target dir: $TARGET_DIR"

# Copy MP3 from Open Notebook container
echo "Copying MP3 from container..."
docker cp "open-notebook:$AUDIO_FILE" "$TARGET_DIR/$EPISODE_NAME.mp3" 2>&1
if [ $? -eq 0 ]; then
  echo "✓ Audio file copied successfully"
else
  echo "✗ Failed to copy audio file"
  exit 1
fi

# Create show notes file
echo "Creating show notes..."
printf "%s" "$SHOW_NOTES" > "$TARGET_DIR/$EPISODE_NAME.txt"
if [ $? -eq 0 ]; then
  echo "✓ Show notes created"
else
  echo "✗ Failed to create show notes"
  exit 1
fi

echo "=== SUCCESS: All files copied ==="
```

**Script location**: Created via `docker exec` and persists in `/tmp/` (recreated on container restart if needed)

#### 3. n8n Workflow Nodes

After the "Is Completed?" node that checks podcast generation status, the workflow includes:

**A. Get Episode Details** (Code node)
- Extracts `episode_id` and `audio_file` path from the completion status response
- No additional API call needed - data already in previous node's response

**B. Create Show Notes** (Code node)
- References the "Build Markdown Content" node to get bookmark data
- Formats show notes with episode name, article titles, and URLs
- Format:
  ```
  Daily Digest - AI - 12-08-2024

  Articles covered:

  • Article Title
    https://example.com/article

  • Another Article
    https://example.com/another

  ---
  Auto-generated from Karakeep bookmarks
  Total articles: 2 | Generated: 12-08-2024
  ```

**C. Prepare Copy Data** (Code node)
- Packages episode name, audio file path, and show notes for SSH command
- **Base64-encodes show notes** to handle special characters (bullets •, newlines, URLs)
- Validates data is present
- Returns: `episodeName`, `audioFile`, `showNotesB64`

**D. Copy Files via Alpine Utility** (Execute Command node)
- Uses SSH key authentication to execute the copy script on alpine-utility
- **Uses stdin piping** to safely pass base64-encoded show notes
- Command:
  ```bash
  echo '{{ $json.showNotesB64 }}' | ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility \
    'TMPF=/tmp/shownotes-$$.b64 && cat > $TMPF && /tmp/copy-podcast.sh "{{ $json.episodeName }}" "{{ $json.audioFile }}" $TMPF'
  ```
- **How it works:**
  1. Base64-encoded show notes are echoed
  2. Piped via SSH stdin to alpine-utility
  3. Written to temp file with unique PID-based name (`$$` = process ID)
  4. Temp file path passed to copy script
  5. Script decodes base64, writes show notes, cleans up temp file
- Port 22: Internal container port (not the host-exposed 2223)
- Username: `root` (SSH key authentication)
- Container name: `alpine-utility` (Docker network DNS)
- StrictHostKeyChecking=no: Avoids SSH key prompts in automation
- SSH keys: Generated in n8n container at `/home/node/.ssh/id_ed25519`, public key added to alpine-utility's `/root/.ssh/authorized_keys`

**E. Scan AudioBookshelf Library** (HTTP Request node)
- Triggers library scan so new podcasts appear immediately
- Endpoint: `POST http://192.168.0.9:13378/api/libraries/5194d2f8-5178-41f2-a0fd-43fea1c36604/scan`
- Library ID: `5194d2f8-5178-41f2-a0fd-43fea1c36604` (Podcats library)
- Authentication: HTTP Header Auth with Bearer token
- Credential name: "AudioBookshelf API"

### File Naming Convention

- **MP3 files**: `Daily Digest - {Tag} - {MM-DD-YYYY}.mp3`
  - Example: `Daily Digest - AI - 12-08-2024.mp3`
- **Show notes**: `Daily Digest - {Tag} - {MM-DD-YYYY}.txt`
  - Example: `Daily Digest - AI - 12-08-2024.txt`

### Directory Structure

```
/Volumes/docker/container_configs/audiobookshelf/podcasts/
└── Daily-Digests/
    ├── Daily Digest - AI - 12-08-2024.mp3
    ├── Daily Digest - AI - 12-08-2024.txt
    ├── Daily Digest - Finance - 12-08-2024.mp3
    ├── Daily Digest - Finance - 12-08-2024.txt
    └── ...
```

### Error Handling

**Script-level errors**:
- Docker cp failures (container not found, file not found)
- File write failures (permissions, disk space)
- Script exits with non-zero status, n8n workflow catches error

**Workflow-level handling**:
- If copy fails, workflow logs error but continues with other episodes
- Failed episodes retain `#podcasted` tag but won't appear in AudioBookShelf
- Manual intervention required for failed copies

### Testing the Integration

**Test the copy script manually**:
```bash
# Verify script exists
docker exec alpine-utility ls -l /tmp/copy-podcast.sh

# Test with dummy data
docker exec alpine-utility /tmp/copy-podcast.sh \
  "Test Episode" \
  "/app/data/podcasts/test.mp3" \
  "Test show notes content"

# Verify AudioBookshelf mount
docker exec alpine-utility ls -l /mnt/audiobookshelf/Daily-Digests/
```

**Test from n8n**:
```bash
# Test SSH key authentication from n8n container
docker exec n8n ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility echo "SSH key auth works!"

# Test the full copy command with base64-encoded show notes
docker exec n8n sh -c "echo 'VGVzdCBzaG93IG5vdGVz' | ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility 'TMPF=/tmp/shownotes-\$\$.b64 && cat > \$TMPF && /tmp/copy-podcast.sh \"Test-Episode\" \"/app/data/podcasts/test.mp3\" \$TMPF'"
```

### Security Considerations

- **SSH access**: alpine-utility is only accessible via localhost:2223 from host, internal port 22 on Docker network
- **Docker socket**: Mounted read-only (`:ro`) but `docker cp` still works for reading files from containers
- **File permissions**: alpine-utility SSH runs as root user for docker access
- **Network isolation**: All services on same Docker network, no external exposure
- **Authentication**:
  - n8n uses SSH key authentication (ed25519 key pair)
  - Public key stored in alpine-utility's `/root/.ssh/authorized_keys`
  - Private key persists in n8n's `/home/node/.ssh/` directory (survives container rebuilds)
  - Password authentication still available from host for manual access via port 2223

### Troubleshooting

**Issue**: SSH connection refused
- **Check**: `docker ps | grep alpine-utility` - is container running?
- **Check**: `docker logs alpine-utility` - any SSH errors?
- **Test**: `ssh -p 2223 alpine@localhost` from host machine

**Issue**: Docker cp fails with "no such container"
- **Check**: `docker exec alpine-utility docker ps` - can alpine-utility see open-notebook?
- **Verify**: open-notebook container name is exactly `open-notebook`

**Issue**: Files not appearing in AudioBookShelf
- **Check**: `docker exec alpine-utility ls /mnt/audiobookshelf/Daily-Digests/`
- **Verify**: AudioBookShelf library scan completed
- **Check**: AudioBookShelf logs: `docker logs audiobookshelf`

**Issue**: Show notes are empty or malformed
- **Check**: "Create Show Notes" node output in n8n
- **Verify**: Bookmark data from "Build Markdown Content" is available
- **Check**: "Prepare Copy Data" node - verify base64 encoding is working
- **Test**: Run workflow with debug mode to inspect node outputs
- **Common cause**: Special characters in show notes breaking shell escaping (fixed by base64 encoding)

### Maintenance

**After container restarts**:

1. **alpine-utility restart**:
   - Recreate `/tmp/copy-podcast.sh` (stored in /tmp, doesn't persist)
   - Re-add n8n's public SSH key to `/root/.ssh/authorized_keys`

2. **n8n restart**:
   - SSH keys persist in volume (`/home/node/.ssh/` is part of n8n's data volume)
   - No action needed - keys survive rebuilds

**One-time SSH key setup** (if keys are lost):
```bash
# Generate SSH key in n8n container
docker exec n8n sh -c 'mkdir -p ~/.ssh && ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "n8n-to-alpine-utility"'

# Get the public key
docker exec n8n cat /home/node/.ssh/id_ed25519.pub

# Add to alpine-utility
docker exec alpine-utility sh -c 'mkdir -p /root/.ssh && echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBoU6n6VqsTqysPQjXp1jKHyEEM9IOfcQIaLIqos0BbV n8n-to-alpine-utility" > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && chmod 700 /root/.ssh'

# Test connection
docker exec n8n ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility echo "SSH key auth works!"
```

**Script updates**:
```bash
# Update the copy script
docker exec alpine-utility sh -c 'cat > /tmp/copy-podcast.sh << "EOF"
# [new script content]
EOF'

# Make executable
docker exec alpine-utility chmod +x /tmp/copy-podcast.sh
```

---

## n8n Workflow Structure

### Workflow 1: Podcast Generation (Daily 2PM)

**Current Implementation Status**: AudioBookshelf integration completed and tested

```
[Schedule Trigger: Cron 0 14 * * *]
    ↓
[Set Variables: Date, Timestamps]
    ↓
[HTTP Request: GET Karakeep Bookmarks]
    (Query bookmarks with #consume tag, not archived)
    ↓
[Filter Bookmarks]
    (Group by topic tag: #ai, #finance, #hometech, etc.)
    ↓
[IF: Any bookmarks to process?]
    ├─ NO → [End: No podcasts needed]
    └─ YES ↓
[Loop: For Each Tag Group]
    ↓
    [Build Markdown Content]
        (Combine articles with titles and URLs)
        ↓
    [HTTP Request: POST /api/podcasts/generate]
        (Open Notebook API with custom profiles)
        Body: {
          episode_profile: "tech_discussion_qwen",
          speaker_profile: "tech_experts_local",
          episode_name: "Daily Digest - {Tag} - {Date}",
          content: "{markdown}"
        }
        ↓
    [Wait 10 seconds]
        (Initial processing delay)
        ↓
    [Loop: Check Episode Status]
        (Poll every 30s, max 10 minutes)
        ↓
        [HTTP Request: GET /api/episodes/{episode_id}]
        ↓
        [Is Completed?]
        ├─ NO → [Wait 30s and retry]
        └─ YES ↓
            [Get Episode Details] (Code node)
                Extract: episode_id, audio_file path
                ↓
            [Create Show Notes] (Code node)
                Format: episode name + article list + URLs
                ↓
            [Prepare Copy Data] (Code node)
                Package: episodeName, audioFile, showNotes
                ↓
            [Copy Files via Alpine Utility] (Execute Command)
                SSH: alpine@localhost:2223
                Command: /tmp/copy-podcast.sh
                Args: episodeName, audioFile, showNotes
                ↓
            [Scan AudioBookShelf Library] (HTTP Request)
                POST /api/libraries/scan
                (Triggers immediate library refresh)
                ↓
            [Update Bookmark Tags]
                (Remove #consume, add #podcasted and #podcasted-YYYY-MM-DD)
                ↓
            [Archive Bookmark]
                (Archive bookmark in Karakeep - will be auto-deleted in 7 days)
                ↓
[End Loop]
    ↓
[Send Success Notification]
    (Optional: notify user of completed podcasts)
    ↓
[End]
```

**Key Differences from Original Plan**:
- Uses Open Notebook API instead of file-based processing
- Polls for completion status instead of fixed wait time
- Uses alpine-utility bastion host for docker cp operations
- Triggers AudioBookShelf scan via API instead of file monitoring

### Workflow 2: Cleanup (Daily 3AM)

This workflow cleans up old archived bookmarks to prevent database clutter.

```
[Schedule Trigger: Cron 0 3 * * *]
    ↓
[Set Variables: Calculate 7-day cutoff date]
    ↓
[HTTP Request: GET Archived Bookmarks]
    (archived=true, tags=podcasted, limit=100)
    ↓
[Function: Filter old podcasted bookmarks]
    (createdBefore=7daysago)
    ↓
[IF: Any bookmarks to delete?]
    ├─ NO → [End: Nothing to clean]
    └─ YES ↓
    [Function: Log bookmarks for deletion]
        (For audit trail)
        ↓
    [HTTP Request: DELETE each bookmark]
        (Loop through filtered bookmarks)
        ↓
    [Function: Build summary]
        ↓
    [IF: Deleted count > 10?]
        ├─ NO → [Silent: No notification]
        └─ YES ↓
        [Log Notification]
            ("🧹 Cleaned up X old podcast bookmarks")
            ↓
[End]
```

**Key Changes from Original Design:**
- Only processes bookmarks tagged with `#consume` (opt-in model)
- Targets archived bookmarks with `#podcasted` tag for cleanup
- Works in conjunction with podcast workflow that archives bookmarks after processing
- Only deletes podcasted bookmarks older than 7 days
- **Your reference library (bookmarks without `#consume` tag) is never touched**

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

# Test: Get bookmarks tagged for podcasting
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/bookmarks?tags=consume&archived=false&limit=100

# Test: Get bookmarks by topic tag
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/bookmarks?tags=ai

# Test: Update bookmark tags after podcasting (remove #consume, add #podcasted)
curl -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tags":["ai","podcasted","podcasted-2024-12-04"]}' \
  http://localhost:3000/api/v1/bookmarks/{bookmark_id}

# Test: Archive bookmark after podcasting
curl -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"archived":true}' \
  http://localhost:3000/api/v1/bookmarks/{bookmark_id}
```

### Manual Workflow Test

1. Save 3-5 bookmarks in Karakeep with different topics
2. Tag 2-3 of them with `#consume` (leave others without it)
3. Run podcast generation workflow manually in n8n
4. Check for:
   - MP3 files in AudioBookShelf directory (only for `#consume` tagged items)
   - Show notes .txt files created
   - Bookmarks that had `#consume` are now tagged with `#podcasted` and archived
   - Bookmarks without `#consume` are still untouched in your library
   - AudioBookShelf shows new episodes

### Cleanup Test

1. Create test bookmarks with `#consume` and podcast them (will be archived)
2. Manually edit their created date to be 8+ days ago
3. Run cleanup workflow
4. Verify archived `#podcasted` bookmarks are deleted
5. Check that your regular bookmarks (without `#consume` tag) are still in your library

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

**Last Updated:** December 11, 2024
**Version:** 1.1
**Author:** Bud
**Status:** Production - Fully Implemented and Tested
