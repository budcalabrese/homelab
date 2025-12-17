# Open Notebook Configuration (Local Models)

## Successfully Tested: Fully Local Podcast Generation ✅

**Achievement**: Complete podcast generation pipeline using only local models - no cloud APIs, complete privacy, zero API costs.

## Working Configuration Summary

**Models Required:**
- **LLM (Outline/Transcript)**: `qwen2.5:7b` via Ollama
- **TTS (Audio)**: `tts-1` via OpenEDAI Speech
- **Embedding**: `nomic-embed-text` via Ollama

**Why Qwen2.5 over Gemma3:**
- Gemma3 fails with JSON parsing errors on Open Notebook's Pydantic schemas
- Qwen2.5:7b successfully generates structured Outline and Transcript JSON
- Better at following complex JSON schema requirements

## Environment Configuration

File: [.env.open-notebook](.env.open-notebook)

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

## UI Model Configuration

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

## Custom Profiles (API Configuration)

**Why Custom Profiles?**
- Default seeded profiles (`tech_experts`, `tech_discussion`) use OpenAI API
- Custom profiles use local models exclusively
- Profiles are stored in SurrealDB and persist across restarts

### Speaker Profile: `tech_experts_local`

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

### Episode Profile: `tech_discussion_qwen`

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

## Generating Podcasts with Custom Profiles

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

## Performance Metrics

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

## Troubleshooting

### Issue: No Audio File Generated

**Symptoms**: Episode shows `"audio_file": null`, status is "completed"

**Causes**:
1. Using default seeded profiles with OpenAI provider
2. Invalid API key for OpenAI-compatible service
3. TTS provider configuration mismatch

**Solution**: Use custom profiles with local providers (`tech_discussion_qwen` + `tech_experts_local`)

### Issue: JSON Parsing Error with Gemma3

**Error**:
```
Failed to parse Outline from completion. Got: 1 validation error for Outline
```

**Cause**: Gemma3 cannot generate properly structured JSON matching Open Notebook's Pydantic schemas

**Solution**: Use Qwen2.5:7b instead - create episode profile with `"outline_model": "qwen2.5:7b"`

### Issue: Missing Embedding Model Warning

**Symptoms**: UI shows "Missing required models: Embedding Model"

**Solution**:
1. Pull model: `docker exec -it open-notebook ollama pull nomic-embed-text`
2. Configure in UI: Settings → Models → Add Embedding Model
   - Provider: `ollama`
   - Model: `nomic-embed-text`

### Issue: OpenEDAI Speech Connection Failed

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

## Database Reset (If Needed)

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

## n8n Integration Notes

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

## Model Download Commands

```bash
# Pull required Ollama models
docker exec -it open-notebook ollama pull qwen2.5:7b
docker exec -it open-notebook ollama pull nomic-embed-text
docker exec -it open-notebook ollama pull gemma3  # Optional fallback

# Verify models
docker exec -it open-notebook ollama list
```

## Resource Requirements

**Per Podcast Generation**:
- **CPU**: 4-8 cores recommended (Qwen2.5:7b benefits from more cores)
- **RAM**: 8GB minimum (Qwen2.5 uses ~6GB during generation)
- **Disk**: ~50MB per 10-minute podcast episode
- **Time**: 4-6 minutes for 5-segment podcast

**Concurrent Generation**: Not recommended - run sequentially to avoid OOM errors

---

**Last Updated:** December 8, 2024
**Status:** Production Ready
