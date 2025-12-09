# Claude Context - Homelab Repository

This document provides context for Claude AI when working with this homelab infrastructure repository.

## Repository Purpose

This is a **templates-only** repository containing Docker Compose configurations for a self-hosted homelab running on a Mac Mini. **No secrets are stored here** - only infrastructure-as-code templates.

## Key Architecture Decisions

### Secrets Management
- **Actual secrets**: Stored in local Gitea `homelab-secrets` repo (NEVER on GitHub)
- **This repo**: Contains only `env/.env.*.template` files for documentation
- `.gitignore` is configured to block all `env/.env*` files except `.template` variants
- **Env folder**: All environment files organized in `env/` directory (cleaner root)

### Service Organization
- **Karakeep** (formerly Hoarder): Bookmark manager - replaced Linkwarden in December 2024
  - Uses 3 containers: karakeep, karakeep-meilisearch, karakeep-chrome
  - Requires `NEXTAUTH_SECRET` and `MEILI_MASTER_KEY` in `env/.env.karakeep`
  - No PostgreSQL database (simpler than Linkwarden)

### Stack Organization (New - December 2024)
- **Automation stacks**: Pre-built workflows organized by use case
  - `podcast-automation/` - Bookmark-to-podcast pipeline with n8n
  - Future stacks: monitoring, backups, media automation
- Each stack has own README and workflows (self-contained)

### Data Persistence
- All service data: `/Volumes/docker/container_configs/{service-name}/`
- Downloads: `/Volumes/docker/youtube_dls/`
- Data persists across compose file changes since it's stored on host volumes

### Special Configurations
- **Ollama**: Runs natively on Mac Mini (NOT in Docker) for performance
- **Tailscale**: Provides VPN access to all services
- **n8n**: Used for automation (future: Karakeep → podcast workflow)
- **Open Notebook**: Podcast generation from markdown files
- **AudioBookShelf**: Podcast playback

## Common Tasks

### Adding a New Service
1. Add service definition to `compose.yml`
2. Create `env/.env.{service}.template` if service needs secrets
3. Update README.md port mappings and service list
4. Test deployment locally
5. Commit changes to GitHub

### Security Checks Before Commit
```bash
git status
git check-ignore env/.env  # Should output: env/.env
git diff --cached | grep -iE "password|api_key|secret|token"
git ls-files | grep "env/"  # Should ONLY show .template files
```

### Environment File Pattern
- `env/.env` - Main shared variables (gitignored)
- `env/.env.{service}` - Service-specific secrets (gitignored)
- `env/.env.template` - Documentation of required variables (committed)
- `env/.env.{service}.template` - Service-specific template (committed)

## Migration History

### December 8, 2024 - Linkwarden → Karakeep
- **Removed**: Linkwarden (3 containers: app, postgres, meilisearch)
- **Added**: Karakeep (3 containers: app, meilisearch, chrome)
- **Reason**: Simpler setup, better AI integration with Ollama
- **Data**: Fresh start (no Linkwarden bookmarks existed)

## Port Allocations

Critical ports to avoid conflicts:
- 3000: Karakeep
- 3002: Gitea
- 5678: n8n
- 8080: Open WebUI
- 8000: OpenEDAI Speech
- 8503: Open Notebook
- 13378: AudioBookShelf

## Build Services

Some services build from local source code:
- `budget-dashboard`: `/Users/bud/home_space/coding/python-budget-tracker`
- `budget-dashboard-gf`: Same source, different instance
- `learning-dashboard`: `/Users/bud/home_space/coding/python-learning-dashboard`
- `youtube-transcripts-api`: `/Users/bud/home_space/coding/youtube-transcripts-api`
- `alpine-utility`: `./alpine-utility` (local Dockerfile)

## Documentation Structure

Located in `docs/`:
- `open-notebook-setup.md` - Local AI podcast generation with Qwen2.5
- `karakeep-api-reference.md` - Complete Karakeep REST API documentation
- `karakeep-podcast-workflow.md` - Full automation workflow design
- `buds-productivity-system-plan.md` - Overall productivity system
- `github-repo-structure-plan.md` - Repository organization

Located in `podcast-automation/`:
- `README.md` - 15-minute quick start guide
- `n8n-workflows/` - Daily podcast generation & cleanup workflows

## Completed: Podcast Automation Stack ✅

**Achievement** (December 2024):
- Fully local AI podcast generation (Qwen2.5 + OpenEDAI Speech)
- Automated bookmark-to-podcast pipeline via n8n
- Daily workflows: 2PM generation, 3AM cleanup
- 100% local processing, no cloud APIs
- ~4.7 minutes per 5-segment podcast

See `podcast-automation/README.md` for setup guide.

## Important Reminders

- This Mac Mini is named "Texas" (homelab location)
- Always verify `.gitignore` before commits
- Use `docker compose` (not `docker-compose`) - newer syntax
- Services auto-restart unless stopped explicitly
- Resource limits set on all containers to prevent resource exhaustion

## Troubleshooting Patterns

### Container Won't Start
1. Check logs: `docker compose logs {service}`
2. Verify env variables: `docker compose config`
3. Check port conflicts: `lsof -i :{port}`

### Meilisearch Version Conflicts
- If upgrading Meilisearch, may need to delete old data directory
- Path: `/Volumes/docker/container_configs/{service}/meili_data`
- Backup first if data is important

### Environment Variables Not Applied
- Use `docker compose up -d` (recreates containers)
- Don't use `docker compose restart` (only restarts existing container)

---

**Last Updated**: December 8, 2024
**Repository**: https://github.com/budcalabrese/homelab
