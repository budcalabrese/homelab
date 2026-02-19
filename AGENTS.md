# AI Agent Instructions - Homelab Repository

Context and rules for AI assistants working with this homelab infrastructure repository.

## Repository Purpose

**Templates-only** repository. Docker Compose + scripts for a self-hosted homelab on a Mac Mini named "Texas". **No secrets stored here** — only infrastructure-as-code and templates.

---

## Key Architecture

### Secrets Management
- **Actual secrets**: Local Gitea `homelab-secrets` repo (never on GitHub)
- **This repo**: Only `env/.env.*.template` files
- `.gitignore` blocks all `env/.env*` except `.template` variants

### Data Persistence
- All service data: `/Volumes/docker/container_configs/{service-name}/`
- Downloads: `/Volumes/docker/youtube_dls/`
- Backups: `/Volumes/backups/`
- All volumes are bind-mounted to network drive — safe across Docker resets

### Notable Configurations
- **Ollama**: Runs natively on Mac Mini (not in Docker) for performance
- **Tailscale**: VPN access, uses `network_mode: host`
- **n8n**: All automation workflows
- **alpine-utility**: Bastion host for script execution

---

## Alpine-Utility Container

The `alpine-utility` container is the bastion host for all automation.

### Key Facts
- **SSH from host**: Port 2223, password auth (`ALPINE_UTILITY_PASSWORD`)
- **SSH from n8n**: Port 22, key-based auth, hostname `alpine-utility`
- **n8n credential**: "SSH Password account" (ID: JFyXom4nOrhtezt1)

### Volume Mounts
- `/scripts` → `homelab/alpine-utility/scripts/` (git-tracked, live)
- `/config` → `/Volumes/docker/container_configs/alpine-utility/` (persistent)
- `/mnt/budget-dashboard` → Budget data (read-only)
- `/mnt/backups/budget-dashboard` → Budget export destination (read-write)
- `/mnt/obsidian-vault` → Obsidian vault
- `/mnt/audiobookshelf` → AudioBookShelf podcasts
- `/mnt/karakeep` → Karakeep data (for backups)
- `/mnt/backups/karakeep` → Karakeep backup destination

### Script Development
- Edit scripts in `alpine-utility/scripts/` — changes are live immediately (no rebuild needed)
- All scripts version-controlled in git

---

## n8n Workflow Development

### Available Node Types
- ✅ SSH node (`n8n-nodes-base.ssh`) — primary way to run commands
- ✅ Code node (`n8n-nodes-base.code`) — JavaScript only
- ✅ Schedule Trigger (`n8n-nodes-base.scheduleTrigger`)
- ❌ `executeCommand` node — not available in this n8n version
- ❌ Python Code node — use JavaScript instead

### Rules
- Always use SSH node to run commands via alpine-utility
- Connect to hostname: `alpine-utility`, credential: "SSH Password account"
- SSH node returns `code` field for exit code (not `exitCode`)
- Store all workflow JSON files in `n8n-workflows/`
- Update `n8n-workflows/README.md` when adding/modifying workflows

---

## Common Tasks

### Adding a New Service
1. Add service to `compose.yml`
2. Create `env/.env.{service}.template`
3. Update `README.md` port mappings and service list
4. Test locally, then commit

### Security Check Before Any Commit
```bash
git ls-files | grep "env/"                                  # should ONLY show .template files
git check-ignore env/.env                                   # should output: env/.env
git diff --cached | grep -iE "password|api_key|secret|token"
```

### Environment File Pattern
- `env/.env` — shared variables (gitignored)
- `env/.env.{service}` — service-specific secrets (gitignored)
- `env/.env.template` — documents required variables (committed)
- `env/.env.{service}.template` — service template (committed)

### Docker Commands
- Use `docker compose up -d` to apply env changes (recreates containers)
- Don't use `docker compose restart` — it won't apply env changes

---

## Port Allocations

| Port | Service |
|------|---------|
| 2223 | alpine-utility SSH |
| 3000 | Karakeep |
| 3002 | Gitea |
| 5001 | YouTube Transcripts API |
| 5678 | n8n |
| 8000 | OpenEDAI Speech |
| 8080 | Open WebUI |
| 8503 | Open Notebook |
| 9428 | VictoriaLogs |
| 13378 | AudioBookShelf |

---

## Build Services (Local Source)

- `budget-dashboard`: `coding/python-budget-tracker`
- `learning-dashboard`: `coding/python-learning-dashboard`
- `youtube-transcripts-api`: `coding/youtube-transcripts-api`
- `alpine-utility`: `./alpine-utility` (local Dockerfile)

---

## Troubleshooting Patterns

**Container won't start:**
```bash
docker compose logs {service}
docker compose config          # verify env vars
lsof -i :{port}                # check port conflicts
```

**Meilisearch version conflict after upgrade:**
- Delete `/Volumes/docker/container_configs/{service}/meili_data` (backup first)

**n8n workflow errors:**
- Python code → convert to JavaScript
- SSH exit code → use `code` field, not `exitCode`
- Empty results → workflow stops if node returns no data (expected)

**Docker Desktop won't start after update:**
```bash
tail -30 ~/Library/Containers/com.docker.docker/Data/log/host/com.docker.virtualization.log
# Look for: "Invalid virtual machine configuration. The storage device attachment is invalid."
killall -9 com.docker.vmnetd com.docker.backend Docker 2>/dev/null
rm ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw
# Relaunch Docker Desktop — data on /Volumes/docker/ is unaffected
```

---

## AI Assistant Rules

1. **Read before modifying** — always read existing files first
2. **Never commit secrets** — only `.template` files go to GitHub
3. **Don't push until user confirms** testing is complete
4. **Keep READMEs current** — update when making changes
5. **Match existing patterns** — code style, conventions, node types
6. **JavaScript over Python** in n8n
7. **Stage specific files** — never `git add -A`
8. **Commit co-authorship**: `Co-Authored-By: Claude <noreply@anthropic.com>`

---

**Last Updated**: February 19, 2026
**Repository**: https://github.com/budcalabrese/homelab
