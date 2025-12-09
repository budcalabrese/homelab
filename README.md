# Homelab Infrastructure

Docker-based homelab running on Mac Mini (Texas).

## Services

### Core Services
- **n8n** - Automation orchestration
- **Gitea** - Self-hosted Git server
- **Tailscale** - VPN access

### AI & LLM
- **Open WebUI** - LLM chat interface
- **Ollama** - Local LLM server (runs on Mac Mini, not in Docker)
- **Open Notebook** - Podcast generation
- **OpenEDAI Speech** - Text-to-speech engine

### Productivity
- **Karakeep** - Bookmark manager with AI auto-tagging (replaces Linkwarden)
- **AudioBookShelf** - Media library and podcast player

### Voice Services
- **Wyoming Whisper** - Speech-to-text
- **Wyoming Piper** - Text-to-speech
- **Wyoming OpenWakeWord** - Wake word detection

### Utilities
- **SearXNG** - Privacy-focused search aggregator
- **MeTube** - YouTube downloader
- **Budget Dashboard** - Personal finance tracking (2 instances)
- **Learning Dashboard** - Learning progress tracking
- **YouTube Transcripts API** - REST API for video transcripts
- **Alpine Utility** - Monitoring and health checks

## Setup Instructions

### Initial Setup

1. **Clone this repository**
   ```bash
   git clone https://github.com/yourusername/homelab.git
   cd homelab
   ```

2. **Copy environment templates**
   ```bash
   cp .env.template .env
   cp .env.karakeep.template .env.karakeep
   cp .env.open-notebook.template .env.open-notebook
   cp .env.openedai-speech.template .env.openedai-speech
   cp .env.tailscale.template .env.tailscale
   ```

3. **Edit `.env` files with actual secrets**
   - Get actual values from `homelab-secrets` Gitea repo (local only)
   - Or generate new secrets using secure random generators
   - **NEVER commit actual `.env` files!**

4. **Create required directories**
   ```bash
   sudo mkdir -p /Volumes/docker/container_configs/{open-webui,wyoming-whisper,wyoming-piper,wyoming-openwakeword,n8n,searxng,metube,karakeep,budget-dashboard,budget-dashboard-gf,gitea,learning-dashboard,audiobookshelf,open-notebook,openedai-speech,tailscale,alpine-utility}
   sudo mkdir -p /Volumes/docker/youtube_dls
   ```

5. **Deploy stack**
   ```bash
   docker compose up -d
   ```

## Karakeep Setup (Replacing Linkwarden)

Karakeep (formerly Hoarder) is a self-hostable bookmark manager with AI-powered auto-tagging using your local Ollama instance.

### First-Time Setup

1. **Access Karakeep**: http://localhost:3000
2. **Create account** (first user becomes admin)
3. **Start bookmarking**:
   - Use the Chrome/Firefox extension
   - Use the iOS/Android mobile app
   - Manually add links via the web interface

### AI Configuration (Optional)

Configure AI-powered auto-tagging:
1. Go to Settings → AI
2. Enable AI inference
3. Choose provider:
   - **Ollama** (recommended for self-hosting):
     - URL: `http://host.docker.internal:11434`
     - Select model: `llama3.2`, `mistral`, etc.
   - **OpenAI**: Add API key to `.env.karakeep`
4. Karakeep will automatically tag and summarize bookmarks

### Mobile Access

Install the mobile app:
- **iOS**: [Karakeep on App Store](https://apps.apple.com/us/app/karakeep-app/id6479258022)
- **Android**: [Karakeep on Play Store](https://play.google.com/store/apps/details?id=app.hoarder.hoardermobile)

Configure:
- Server URL: Your Tailscale hostname (e.g., `http://homelab-docker.tail-scale.ts.net:3000`)
- Login with your account credentials

### Browser Extensions

- **Chrome**: [Karakeep Extension](https://chromewebstore.google.com/detail/karakeep/kgcjekpmcjjogibpjebkhaanilehneje)
- **Firefox**: [Karakeep Add-on](https://addons.mozilla.org/en-US/firefox/addon/karakeep/)

### Migrating from Linkwarden

If you have existing Linkwarden bookmarks:
1. Export bookmarks from Linkwarden (Settings → Export)
2. Import into Karakeep (Settings → Import → Linkwarden)
3. Verify bookmarks imported successfully
4. Remove old Linkwarden containers if no longer needed

## Volume Locations

- **Configs**: `/Volumes/docker/container_configs/`
- **Data**: Managed by Docker volumes within config directories

## Port Mappings

| Service | Port | Access |
|---------|------|--------|
| Open WebUI | 8080 | http://localhost:8080 |
| Karakeep | 3000 | http://localhost:3000 |
| Gitea (Web) | 3002 | http://localhost:3002 |
| Gitea (SSH) | 2222 | ssh://localhost:2222 |
| n8n | 5678 | http://localhost:5678 |
| SearXNG | 8081 | http://localhost:8081 |
| MeTube | 8082 | http://localhost:8082 |
| Open Notebook | 8503 | http://localhost:8503 |
| OpenEDAI Speech | 8000 | http://localhost:8000 |
| Budget Dashboard | 8501 | http://localhost:8501 |
| Budget Dashboard GF | 8504 | http://localhost:8504 |
| Learning Dashboard | 8502 | http://localhost:8502 |
| AudioBookShelf | 13378 | http://localhost:13378 |
| YouTube Transcripts | 5001 | http://localhost:5001 |
| Wyoming Whisper | 10300 | - |
| Wyoming Piper | 10200 | - |
| Wyoming OpenWakeWord | 10400 | - |
| Alpine Utility (SSH) | 2223 | ssh://localhost:2223 |

## Management Commands

### View running services
```bash
docker compose ps
```

### View logs
```bash
docker compose logs -f [service-name]
```

### Restart a service
```bash
docker compose restart [service-name]
```

### Stop all services
```bash
docker compose down
```

### Update all services
```bash
docker compose pull
docker compose up -d
```

## Security

⚠️ **CRITICAL SECURITY NOTES**:

- **NEVER** commit actual `.env` files to GitHub
- Actual secrets are stored in Gitea `homelab-secrets` repo (local network only)
- This repo contains **templates and infrastructure-as-code only**
- Always verify `.gitignore` is working before commits:
  ```bash
  git status
  git check-ignore .env  # Should output: .env
  ```

### Pre-commit Security Check

Before ANY commit to GitHub:
```bash
# Check what will be committed
git status
git diff --cached

# Search for potential secrets
git diff --cached | grep -iE "password|api_key|secret|token|authkey"

# List all files to be committed
git ls-files | grep "\.env"  # Should ONLY show .env.template files
```

## Backup Strategy

### What to Backup
- `/Volumes/docker/container_configs/` - All service data
- `.env` files (store in Gitea `homelab-secrets` repo)
- This Git repository structure

### Automated Backups
See `alpine-utility/docker-monitor.sh` for automated health checks and monitoring.

## Related Repositories

- **Productivity System**: `obsidian-vault` repo
- **Personal Projects**: `coding` repo
- **Secrets**: `homelab-secrets` repo (Gitea only - never on GitHub)
- **System Plans**: See `buds-productivity-system-plan.md` in planning docs

## Troubleshooting

### Service won't start
```bash
# Check logs
docker compose logs [service-name]

# Check if port is already in use
lsof -i :[port-number]

# Verify environment variables
docker compose config
```

### Karakeep AI tagging not working
```bash
# Check Ollama is running on host
curl http://localhost:11434/api/tags

# Verify model is downloaded
ollama list

# Check Karakeep can reach Ollama
docker exec karakeep curl http://host.docker.internal:11434/api/tags
```

### Out of disk space
```bash
# Check Docker disk usage
docker system df

# Clean up unused images/volumes
docker system prune -a --volumes
```

## Development

### Testing Changes

1. Make changes to `compose.yml`
2. Test with docker compose:
   ```bash
   docker compose config  # Validate syntax
   docker compose up -d [service-name]  # Test specific service
   ```
3. Commit to Git after verification

### Adding New Services

1. Add service definition to `compose.yml`
2. Create `.env.[service].template` if needed
3. Update this README with port mapping and description
4. Test deployment
5. Commit changes

## System Requirements

- **Minimum**: 8GB RAM, 4 CPU cores, 100GB storage
- **Recommended**: 16GB+ RAM, 8+ CPU cores, 500GB+ storage
- **Tested on**: Mac Mini M1/M2/M4, Docker Desktop, macOS Sonoma+

## Notes

- Ollama runs natively on Mac Mini (not containerized) for better performance
- Tailscale provides secure remote access to all services
- All services use health checks and automatic restart policies
- Resource limits prevent any single service from consuming all resources

---

**Created**: December 8, 2024
**Status**: Active Development
**Owner**: Bud