# Homelab Infrastructure

Docker-based homelab running on Mac Mini (Texas).

## Services

### Core
- **n8n** - Automation orchestration
- **Gitea** - Self-hosted Git server
- **Tailscale** - VPN access

### AI & LLM
- **Open WebUI** - LLM chat interface
- **Ollama** - Local LLM server (runs on Mac Mini, not in Docker)
- **Open Notebook** - Podcast generation
- **OpenEDAI Speech** - Text-to-speech engine

### Productivity
- **Karakeep** - Bookmark manager with AI auto-tagging
- **AudioBookShelf** - Media library and podcast player

### Voice Services
- **Wyoming Whisper** - Speech-to-text
- **Wyoming Piper** - Text-to-speech
- **Wyoming OpenWakeWord** - Wake word detection

### Utilities
- **SearXNG** - Privacy-focused search aggregator
- **MeTube** - YouTube downloader
- **Budget Dashboard** - Personal finance tracking
- **Learning Dashboard** - Learning progress tracking
- **YouTube Transcripts API** - REST API for video transcripts
- **Alpine Utility** - Monitoring, backups, and health checks

---

## Automation Stacks

### Podcast Automation
**Location**: [`podcast-automation/`](podcast-automation/)

Daily bookmark-to-podcast pipeline using Karakeep → Open Notebook → n8n.
- 2PM daily: Converts bookmarks to topic-based podcasts
- 3AM daily: Cleans up old podcasted bookmarks
- 100% local AI (Qwen2.5 + OpenEDAI Speech)

See [podcast-automation/README.md](podcast-automation/README.md) for setup.

---

## Setup

1. **Clone and configure environment**
   ```bash
   git clone https://github.com/yourusername/homelab.git
   cd homelab
   cp env/.env.template env/.env
   cp env/.env.karakeep.template env/.env.karakeep
   cp env/.env.open-notebook.template env/.env.open-notebook
   cp env/.env.openedai-speech.template env/.env.openedai-speech
   cp env/.env.tailscale.template env/.env.tailscale
   ```
   Get actual secret values from `homelab-secrets` Gitea repo.

2. **Confirm path variables in `env/.env`**
   ```
   HOMELAB_ROOT=/Users/bud/home_space/homelab
   HOME_SPACE_ROOT=/Users/bud/home_space
   CODING_ROOT=/Users/bud/home_space/coding
   DOCKER_CONFIG_ROOT=/Volumes/docker/container_configs
   DOCKER_DOWNLOADS_ROOT=/Volumes/docker/youtube_dls
   BACKUPS_ROOT=/Volumes/backups
   OBSIDIAN_VAULT=/Users/bud/home_space/obsidian-vault
   ```

3. **Create required directories**
   ```bash
   export DOCKER_CONFIG_ROOT=/Volumes/docker/container_configs
   export DOCKER_DOWNLOADS_ROOT=/Volumes/docker/youtube_dls
   sudo mkdir -p "${DOCKER_CONFIG_ROOT}"/{open-webui,wyoming-whisper,wyoming-piper,wyoming-openwakeword,n8n,searxng,metube,karakeep,budget-dashboard,gitea,learning-dashboard,audiobookshelf,open-notebook,openedai-speech,tailscale,alpine-utility}
   sudo mkdir -p "${DOCKER_DOWNLOADS_ROOT}"
   ```

4. **Deploy**
   ```bash
   docker compose up -d
   ```

---

## Port Mappings

| Service | Port | URL |
|---------|------|-----|
| Open WebUI | 8080 | http://localhost:8080 |
| Karakeep | 3000 | http://localhost:3000 |
| Gitea (Web) | 3002 | http://localhost:3002 |
| Gitea (SSH) | 2222 | ssh://localhost:2222 |
| n8n | 5678 | http://localhost:5678 |
| SearXNG | 8081 | http://localhost:8081 |
| MeTube | 8082 | http://localhost:8082 |
| Open Notebook | 8503 | http://localhost:8503 (disabled) |
| OpenEDAI Speech | 8000 | http://localhost:8000 |
| Budget Dashboard | 8501 | http://localhost:8501 |
| Learning Dashboard | 8502 | http://localhost:8502 |
| Garage Tracker | 8504 | http://localhost:8504 |
| AudioBookShelf | 13378 | http://localhost:13378 |
| YouTube Transcripts | 5001 | http://localhost:5001 |
| Wyoming Whisper | 10300 | - |
| Wyoming Piper | 10200 | - |
| Wyoming OpenWakeWord | 10400 | - |
| Victoria Logs | 9428 | http://localhost:9428 |
| Alpine Utility (SSH) | 2223 | ssh://localhost:2223 |

**Volume location**: `/Volumes/docker/container_configs/` (network drive — all container data persists here, safe across Docker resets)

---

## Management Commands

```bash
# Status
docker compose ps

# Logs
docker compose logs -f [service-name]

# Restart a service
docker compose restart [service-name]
# Use 'up -d' instead if you changed env vars
docker compose up -d [service-name]

# Stop all
docker compose down

# Update all (pull + rebuild + restart)
bash scripts/homelab_update.sh
```

---

## Troubleshooting

### Docker Desktop won't start after an update

This happens when Docker's update ships a new `desktop.img` incompatible with the existing virtual disk. **Your data on the network drive is always safe** — all volumes are bind-mounted to `/Volumes/docker/`.

```bash
# 1. Check the virtualization log to confirm the cause
tail -30 ~/Library/Containers/com.docker.docker/Data/log/host/com.docker.virtualization.log
# Look for: "VM has stopped: Invalid virtual machine configuration. The storage device attachment is invalid."

# 2. Kill Docker fully
killall -9 com.docker.vmnetd com.docker.backend Docker 2>/dev/null

# 3. Delete the virtual disk (recreated fresh on next launch)
rm ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw

# 4. Relaunch Docker Desktop
```

### Service won't start
```bash
docker compose logs [service-name]
lsof -i :[port-number]    # check if port is in use
docker compose config     # validate compose syntax
```

### Karakeep AI tagging not working
```bash
curl http://localhost:11434/api/tags                              # Ollama running?
ollama list                                                       # model downloaded?
docker exec karakeep curl http://host.docker.internal:11434/api/tags  # container can reach Ollama?
```

### Out of disk space
```bash
docker system df
docker system prune -a --volumes
```

---

## Security

**NEVER commit actual `.env` files.** Secrets live in the `homelab-secrets` Gitea repo (local network only). This repo contains templates and infrastructure-as-code only.

```bash
# Verify before any commit to GitHub
git ls-files | grep "env/"        # should ONLY show *.template files
git check-ignore env/.env         # should output: env/.env
```

---

## Backup Strategy

- **Container data**: `/Volumes/docker/container_configs/` — back up this directory
- **Secrets**: `env/.env*` files stored in Gitea `homelab-secrets` repo
- **Gitea backup**: `docker exec alpine-utility /scripts/export_gitea_backup.sh`
- See `alpine-utility/docker-monitor.sh` for automated health checks

---

## Documentation

- [Open Notebook Setup](docs/services/open-notebook-setup.md)
- [Karakeep API Reference](docs/api/karakeep-api-reference.md)
- [Karakeep Podcast Workflow](docs/services/karakeep-podcast-workflow.md)
- [Restore Runbook](docs/restore.md)
- [Service Inventory](docs/services/inventory.md)
- [Full Docs Index](docs/README.md)

## Related Repositories

- **Secrets**: `homelab-secrets` (Gitea only — never on GitHub)
- **Productivity**: `obsidian-vault`
- **Projects**: `coding`
