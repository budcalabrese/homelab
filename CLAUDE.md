# Claude Context - Homelab Repository

This document provides context for Claude AI when working with this homelab infrastructure repository.

## Repository Purpose

This is a **templates-only** repository containing Docker Compose configurations for a self-hosted homelab running on a Mac Mini. **No secrets are stored here** - only infrastructure-as-code templates.

## Key Architecture Decisions

### Secrets Management
- **Actual secrets**: Stored in local Gitea `homelab-secrets` repo (NEVER on GitHub)
- **This repo**: Contains only `.env.template` files for documentation
- `.gitignore` is configured to block all `.env` files except `.template` variants

### Service Organization
- **Karakeep** (formerly Hoarder): Bookmark manager - replaced Linkwarden in December 2024
  - Uses 3 containers: karakeep, karakeep-meilisearch, karakeep-chrome
  - Requires `NEXTAUTH_SECRET` and `MEILI_MASTER_KEY` in `.env.karakeep`
  - No PostgreSQL database (simpler than Linkwarden)

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
2. Create `.env.{service}.template` if service needs secrets
3. Update README.md port mappings and service list
4. Test deployment locally
5. Commit changes to GitHub

### Security Checks Before Commit
```bash
git status
git check-ignore .env  # Should output: .env
git diff --cached | grep -iE "password|api_key|secret|token"
```

### Environment File Pattern
- `.env` - Main shared variables (gitignored)
- `.env.{service}` - Service-specific secrets (gitignored)
- `.env.template` - Documentation of required variables (committed)
- `.env.{service}.template` - Service-specific template (committed)

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

## Related Planning Documents

Located in `/Users/bud/home_space/home/homelab/`:
- `buds-productivity-system-plan.md` - Overall productivity system design
- `github-repo-structure-plan.md` - Repo organization strategy
- `karakeep-podcast-workflow.md` - Planned n8n automation for bookmark → podcast

## Future Enhancements

1. **Karakeep Podcast Workflow** (see karakeep-podcast-workflow.md):
   - Daily n8n workflow to convert bookmarks → podcasts via Open Notebook
   - Automated cleanup of old bookmarks
   - Integration with AudioBookShelf for playback

2. **Gitea homelab-secrets Repo**:
   - Phase 4 of repo structure plan
   - Store actual `.env` files
   - Local-only, never pushed to GitHub

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
