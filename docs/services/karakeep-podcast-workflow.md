# Karakeep Podcast Workflow

Automatically converts daily bookmarks into topic-based podcasts, then cleans them up after 7 days.

## Data Flow

```
iPhone → Karakeep (auto-tag) → n8n (2pm) → Open Notebook → AudioBookShelf → Cleanup (3am, 7 days)
```

---

## Bookmark Lifecycle

### 1. Capture (Throughout the day)
- Save via iOS share sheet → Karakeep auto-tags with `#ai`, `#finance`, `#hometech`, etc.
- **You decide**: Add `#consume` if you want it podcasted and then deleted
  - News, announcements, time-sensitive analysis → add `#consume`
  - How-tos, docs, reference material → leave it, stays in library permanently

### 2. Podcast Generation (Daily 2:00 PM)
- n8n queries Karakeep for `#consume`-tagged bookmarks
- Groups by topic tag (`#ai`, `#finance`, `#hometech`, etc.)
- For each group with 2+ articles:
  1. Builds markdown content from article summaries + URLs
  2. Sends to Open Notebook API → generates MP3 (~4.7 min for 5 segments)
  3. Copies MP3 + show notes to AudioBookShelf via alpine-utility
  4. Triggers AudioBookShelf library scan
  5. Removes `#consume`, adds `#podcasted` + `#podcasted-YYYY-MM-DD`, archives bookmark

### 3. Cleanup (Daily 3:00 AM)
- Deletes archived `#podcasted` bookmarks older than 7 days
- **Starred bookmarks are never deleted** — star it in Karakeep to keep it permanently
- Sends notification if >10 cleaned

---

## Tagging Reference

| Article type | Auto tags | You add | Result |
|---|---|---|---|
| "New GPT-5 announcement" | `#ai` | `#consume` | Podcasted → deleted after 7 days |
| "How to configure SSH" | `#hometech` | (nothing) | Stays in library forever |
| "Stock market analysis" | `#finance` | `#consume` | Podcasted → deleted after 7 days |
| "Docker Compose best practices" | `#hometech` | (nothing) | Stays in library forever |

**To save a podcasted article permanently**: Star it in Karakeep → cleanup will skip it.

---

## Open Notebook Configuration

### Models in Use
- **LLM**: `qwen2.5:7b` via Ollama (outline + transcript generation)
- **TTS**: `tts-1` via OpenEDAI Speech
- **Embedding**: `nomic-embed-text` via Ollama

> **Why Qwen2.5 over Gemma3**: Gemma3 fails with JSON parsing errors on Open Notebook's Pydantic schemas. Qwen2.5:7b reliably generates structured JSON.

### Custom Profiles (required — default profiles use OpenAI)

**Speaker Profile** (`tech_experts_local`):
```json
{
  "name": "tech_experts_local",
  "tts_provider": "openai-compatible",
  "tts_model": "tts-1",
  "speakers": [
    {"name": "Dr. Alex Chen", "voice_id": "nova", "personality": "Analytical, clear communicator"},
    {"name": "Jamie Rodriguez", "voice_id": "alloy", "personality": "Enthusiastic, practical-minded"}
  ]
}
```
Profile ID: `speaker_profile:s3wt2c9oaoa8o2x8a4yu`

**Episode Profile** (`tech_discussion_qwen`):
```json
{
  "name": "tech_discussion_qwen",
  "speaker_config": "tech_experts_local",
  "outline_provider": "ollama",
  "outline_model": "qwen2.5:7b",
  "transcript_provider": "ollama",
  "transcript_model": "qwen2.5:7b",
  "num_segments": 5
}
```
Profile ID: `episode_profile:s1rw2rlbt9b5jkrhwoaf`

### Generate Podcast via API

```bash
POST http://localhost:5055/api/podcasts/generate
{
  "episode_profile": "tech_discussion_qwen",
  "speaker_profile": "tech_experts_local",
  "episode_name": "Daily Digest - AI - 2024-12-08",
  "content": "# Article content in markdown..."
}
# Returns: { "job_id": "...", "episode_id": "episode:xxx", "status": "processing" }

# Poll status:
GET http://localhost:5055/api/episodes/{episode_id}
```

**Performance**: ~4.7 min per 5-segment podcast (outline 30s, transcript 60s, audio 180s, combine 10s)

### AudioBookShelf Library Scan
```
POST http://192.168.0.9:13378/api/libraries/5194d2f8-5178-41f2-a0fd-43fea1c36604/scan
Auth: Bearer token (credential: "AudioBookshelf API")
```

---

## AudioBookShelf Integration

Files are copied from Open Notebook → AudioBookShelf via the alpine-utility bastion host (n8n doesn't have Docker socket access directly).

```
n8n → SSH to alpine-utility → docker cp from open-notebook → /mnt/audiobookshelf/Daily-Digests/
```

**File naming**:
- `Daily Digest - AI - 12-08-2024.mp3`
- `Daily Digest - AI - 12-08-2024.txt` (show notes)

**Show notes format**:
```
Daily Digest - AI - December 8, 2024

Articles covered:
• Article Title
  https://example.com/article

• Another Article
  https://example.com/another

---
Auto-generated from Karakeep bookmarks
Total articles: 2 | Generated: 12-08-2024
```

**Copy command** (run from n8n via Execute Command node):
```bash
echo '{{ $json.showNotesB64 }}' | ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility \
  'TMPF=/tmp/shownotes-$$.b64 && cat > $TMPF && /tmp/copy-podcast.sh "{{ $json.episodeName }}" "{{ $json.audioFile }}" $TMPF'
```
Show notes are base64-encoded to safely pass special characters (bullets, newlines, URLs) through SSH.

---

## n8n Workflow Structure

### Workflow 1: Podcast Generation (Daily 2 PM)

```
Schedule Trigger (cron: 0 14 * * *)
  → GET Karakeep bookmarks (tagged #consume, not archived)
  → Group by topic tag
  → IF any groups with 2+ articles
    → For each group:
        → Build markdown content
        → POST /api/podcasts/generate (Open Notebook)
        → Poll status every 30s until completed (max 10 min)
        → Get Episode Details (extract audio_file path)
        → Create Show Notes
        → Prepare Copy Data (base64-encode show notes)
        → Copy Files via Alpine Utility (SSH → docker cp)
        → Scan AudioBookShelf Library
        → Update bookmark tags (remove #consume, add #podcasted)
        → Archive bookmark in Karakeep
  → Send success notification
```

Workflow file: `n8n-workflows/Karakeep Daily Podcast Generation.json`

### Workflow 2: Cleanup (Daily 3 AM)

```
Schedule Trigger (cron: 0 3 * * *)
  → GET archived bookmarks (tagged #podcasted, not starred)
  → Filter: older than 7 days
  → IF any found:
      → DELETE each bookmark
      → IF deleted > 10: send notification
```

Workflow file: `n8n-workflows/Karakeep Bookmark Cleanup.json`

---

## Troubleshooting

**No audio file generated (status shows "completed" but audio_file is null)**
→ You're using default seeded profiles which need OpenAI. Use `tech_discussion_qwen` + `tech_experts_local`.

**JSON parsing error with Gemma3**
→ Switch to `qwen2.5:7b`. Create/update the episode profile to use Qwen2.5.

**Missing embedding model warning in UI**
```bash
docker exec -it open-notebook ollama pull nomic-embed-text
# Then add in UI: Settings → Models → Embedding → ollama / nomic-embed-text
```

**OpenEDAI Speech connection failed**
```bash
docker exec open-notebook curl http://openedai-speech:8000/v1/models
# Should return list with tts-1, tts-1-hd
```

**Files not appearing in AudioBookShelf**
```bash
docker exec alpine-utility ls /mnt/audiobookshelf/Daily-Digests/   # files there?
docker logs audiobookshelf                                          # scan errors?
```

**SSH connection from n8n fails**
```bash
docker exec alpine-utility cat /root/.ssh/authorized_keys  # should have n8n's key
# If empty: cd homelab && ./alpine-utility/setup-persistent-config.sh
```

**Database reset** (warning: deletes all episodes, profiles, settings):
```bash
docker compose down open-notebook
sudo rm -rf /Volumes/docker/container_configs/open-notebook/*
docker compose up -d open-notebook
# Reconfigure: add models in UI, recreate profiles via API
```
