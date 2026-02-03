# AI Agent Instructions - Homelab Repository

This document provides context and rules for AI assistants (Claude, ChatGPT, etc.) when working with this homelab infrastructure repository.

## Repository Purpose

This is a **templates-only** repository containing Docker Compose configurations for a self-hosted homelab running on a Mac Mini named "Texas". **No secrets are stored here** - only infrastructure-as-code templates.

---

## Key Architecture Decisions

### Secrets Management
- **Actual secrets**: Stored in local Gitea `homelab-secrets` repo (NEVER on GitHub)
- **This repo**: Contains only `env/.env.*.template` files for documentation
- `.gitignore` is configured to block all `env/.env*` files except `.template` variants
- **Env folder**: All environment files organized in `env/` directory (cleaner root)

### Data Persistence
- All service data: `/Volumes/docker/container_configs/{service-name}/`
- Downloads: `/Volumes/docker/youtube_dls/`
- Backups: `/Volumes/backups/`
- Data persists across compose file changes since it's stored on host volumes

### Special Configurations
- **Ollama**: Runs natively on Mac Mini (NOT in Docker) for performance
- **Tailscale**: Provides VPN access to all services
- **n8n**: Used for automation workflows
- **Open Notebook**: Podcast generation from markdown files
- **AudioBookShelf**: Podcast playback

---

## Alpine-Utility Container (Bastion Host)

The `alpine-utility` container is our **bastion host** for homelab operations.

### Key Facts:
- **Container name**: `alpine-utility`
- **SSH Access**: Configured with SSH keys (port 2223 on host, port 22 in container)
- **SSH Credentials in n8n**: "SSH Password account" (ID: JFyXom4nOrhtezt1)
- **Hostname**: `alpine-utility` (accessible by name from other containers)

### Volume Mounts:
- `/scripts` → `/Users/bud/home_space/homelab/alpine-utility/scripts` (Git-tracked scripts)
- `/config` → `/Volumes/docker/container_configs/alpine-utility` (Persistent config)
- `/mnt/budget-dashboard` → Budget dashboard data (read-only)
- `/mnt/budget-dashboard-gf` → Budget dashboard GF data (read-only)
- `/mnt/backups/budget-dashboard` → Budget export destination (read-write)
- `/mnt/obsidian-vault` → Obsidian vault
- `/mnt/audiobookshelf` → Audiobookshelf podcasts
- `/mnt/karakeep` → Karakeep data (for backups)
- `/mnt/backups/karakeep` → Karakeep backup destination

### Usage Patterns:
1. **From n8n workflows**: Use SSH node to execute commands
   - Example: SSH to `alpine-utility`, run `/scripts/export_monthly_snapshot.sh`
2. **From local CLI**: `docker exec alpine-utility <command>`
3. **Scripts location**: Always use `/scripts/` (git-tracked, auto-synced)

### Script Development:
- Edit scripts in: `/Users/bud/home_space/homelab/alpine-utility/scripts/`
- Changes are immediately available in container (live mount)
- All scripts are version-controlled in git

---

## n8n Workflow Development

### Node Types Available:
- ✅ SSH node (`n8n-nodes-base.ssh`) - for command execution
- ✅ Code node (`n8n-nodes-base.code`) - for JavaScript (Python requires external runner)
- ✅ Schedule Trigger (`n8n-nodes-base.scheduleTrigger`)
- ❌ NOT AVAILABLE: `executeCommand` node (unrecognized in this n8n version)
- ❌ Python Code node: Requires external Python runner setup (prefer JavaScript)

### Best Practices:
- Store workflow JSON files in `/Users/bud/home_space/homelab/n8n-workflows/`
- Use SSH node for all command execution via alpine-utility
- Check exit codes: SSH node returns `code`, not `exitCode`
- Version all workflows in git before importing to n8n
- **Prefer JavaScript over Python**: Convert Python code to JavaScript when possible
- Update `n8n-workflows/README.md` when adding/modifying workflows

### When writing n8n workflows:
- ALWAYS use the SSH node type (`n8n-nodes-base.ssh`)
- Connect to hostname: `alpine-utility`
- Use credential: "SSH Password account"
- Execute scripts from `/scripts/` directory

---

## Service Organization

### Core Services
- **Karakeep** (formerly Hoarder): Bookmark manager - replaced Linkwarden in December 2024
  - Uses 3 containers: karakeep, karakeep-meilisearch, karakeep-chrome
  - Requires `NEXTAUTH_SECRET` and `MEILI_MASTER_KEY` in `env/.env.karakeep`
  - No PostgreSQL database (simpler than Linkwarden)

### Stack Organization (December 2024)
- **Automation stacks**: Pre-built workflows organized by use case
  - `podcast-automation/` - Bookmark-to-podcast pipeline with n8n
  - Future stacks: monitoring, backups, media automation
- Each stack has own README and workflows (self-contained)

---

## Repository Structure

This homelab repo contains:
- Docker Compose configurations (`compose.yml`)
- n8n workflow JSON files (`n8n-workflows/`)
- Alpine-utility scripts (`alpine-utility/scripts/`)
- Container configurations and environment file templates (`env/`)
- Documentation (`docs/` and stack-specific READMEs)

---

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

### Docker Commands
- Use `docker compose` (not `docker-compose`) - newer syntax
- Recreate containers: `docker compose up -d` (applies env changes)
- Don't use `docker compose restart` (doesn't apply env changes)
- Services auto-restart unless stopped explicitly

---

## Port Allocations

Critical ports to avoid conflicts:
- 2223: alpine-utility SSH
- 3000: Karakeep
- 3002: Gitea
- 5001: YouTube Transcripts API
- 5678: n8n
- 8000: OpenEDAI Speech
- 8080: Open WebUI
- 8503: Open Notebook
- 9428: VictoriaLogs
- 13378: AudioBookShelf

---

## Build Services

Some services build from local source code:
- `budget-dashboard`: `/Users/bud/home_space/coding/python-budget-tracker`
- `budget-dashboard-gf`: Same source, different instance
- `learning-dashboard`: `/Users/bud/home_space/coding/python-learning-dashboard`
- `youtube-transcripts-api`: `/Users/bud/home_space/coding/youtube-transcripts-api`
- `alpine-utility`: `./alpine-utility` (local Dockerfile)

---

## Documentation Structure

### Main Documentation (`docs/`)
- `open-notebook-setup.md` - Local AI podcast generation with Qwen2.5
- `karakeep-api-reference.md` - Complete Karakeep REST API documentation
- `karakeep-podcast-workflow.md` - Full automation workflow design
- `buds-productivity-system-plan.md` - Overall productivity system
- `github-repo-structure-plan.md` - Repository organization

### Stack-Specific Documentation
- `podcast-automation/README.md` - 15-minute quick start guide
- `n8n-workflows/README.md` - Complete workflow documentation

---

## Migration History

### December 8, 2024 - Linkwarden → Karakeep
- **Removed**: Linkwarden (3 containers: app, postgres, meilisearch)
- **Added**: Karakeep (3 containers: app, meilisearch, chrome)
- **Reason**: Simpler setup, better AI integration with Ollama
- **Data**: Fresh start (no Linkwarden bookmarks existed)

---

## Completed: Podcast Automation Stack ✅

**Achievement** (December 2024):
- Fully local AI podcast generation (Qwen2.5 + OpenEDAI Speech)
- Automated bookmark-to-podcast pipeline via n8n
- Daily workflows: 2PM generation, 3AM cleanup
- 100% local processing, no cloud APIs
- ~4.7 minutes per 5-segment podcast

See `podcast-automation/README.md` for setup guide.

---

## Important Reminders for AI Assistants

### Security
- This Mac Mini is named "Texas" (homelab location)
- Always verify `.gitignore` before commits
- Never commit actual secrets (only `.template` files)
- Check for secrets with `git diff --cached | grep -iE "password|api_key|secret|token"`

### Development Patterns
- Resource limits set on all containers to prevent resource exhaustion
- Always test locally before committing
- Update relevant README files when making changes
- Version control all scripts and workflows

### Git Workflow
- Don't push commits until user confirms testing is complete
- Use descriptive commit messages
- Add `Co-Authored-By: {AI Name} <noreply@{provider}.com>` to commits
- Stage specific files rather than using `git add -A`

---

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

### n8n Workflow Errors
- Python code node errors: Convert to JavaScript instead
- SSH node exit code: Use `code` field, not `exitCode`
- Empty results: Workflow stops if node returns no data (expected behavior)

---

## AI Assistant Guidelines

When working with this repository:

1. **Read before modifying**: Always read existing files before suggesting changes
2. **Security first**: Never commit secrets, always use templates
3. **Test before push**: Don't push until user confirms testing
4. **Update documentation**: Keep README files current with changes
5. **Follow patterns**: Match existing code style and conventions
6. **Ask when unsure**: Better to clarify than make incorrect assumptions
7. **Use correct tools**: Prefer SSH nodes over executeCommand, JavaScript over Python
8. **Version everything**: All workflows, scripts, and configs should be in git

---

**Last Updated**: February 3, 2026
**Repository**: https://github.com/budcalabrese/homelab
**Compatible AI Assistants**: Claude (Anthropic), ChatGPT (OpenAI), and other code-capable LLMs
