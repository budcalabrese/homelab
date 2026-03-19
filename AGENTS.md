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
- **n8n**: All automation workflows, SSH keys persisted to survive restarts
- **alpine-utility**: Bastion host for script execution, password set via `ALPINE_UTILITY_PASSWORD`

## Alpine-Utility Container

The `alpine-utility` container is the bastion host for all automation.

### Key Facts
- **SSH from host**: Port 2223, password auth (`ALPINE_UTILITY_PASSWORD` from env/.env)
- **SSH from n8n**: Port 2223 via `host.docker.internal`, password auth (same password)
- **n8n credential**: "SSH Password account" (ID: JFyXom4nOrhtezt1)
  - Host: `host.docker.internal`
  - Port: `2223`
  - Username: `root`
  - Password: Value of `ALPINE_UTILITY_PASSWORD` from env/.env
- **n8n SSH keys**: Persisted at `${DOCKER_CONFIG_ROOT}/n8n/.ssh/` (survives restarts)

### Volume Mounts
- `/scripts` → `homelab/alpine-utility/scripts/` (git-tracked, live)
- `/config` → `/Volumes/docker/container_configs/alpine-utility/` (persistent)
- `/mnt/budget-dashboard` → Budget data (read-only)
- `/mnt/backups/budget-dashboard` → Budget export destination (read-write)
- `/mnt/obsidian-vault` → Obsidian vault
- `/mnt/audiobookshelf` → AudioBookShelf podcasts
- `/mnt/karakeep` → Karakeep data (for backups)
- `/mnt/backups/karakeep` → Karakeep backup destination
- `/mnt/garage-tracker` → Garage tracker data (for backups)
- `/mnt/backups/garage-tracker` → Garage tracker backup destination
- `/mnt/gitea` → Gitea data (for backups)
- `/mnt/backups/gitea` → Gitea backup destination
- `/mnt/n8n` → n8n database (for maintenance/troubleshooting)

### Script Development
- Edit scripts in `alpine-utility/scripts/` — changes are live immediately (no rebuild needed)
- All scripts version-controlled in git

### Canonical Paths
- Runtime script directory: `alpine-utility/scripts/`
- Container path for those scripts: `/scripts/`
- Docker Health Monitor script: `alpine-utility/scripts/docker-monitor.sh`
- n8n workflow directory: `n8n-workflows/`
- Service secrets: `env/.env.{service}` (gitignored)
- Service templates: `env/.env.{service}.template` (committed)

### Negative Rules
- Do not create duplicate copies of scripts in `alpine-utility/`
- Do not reintroduce `alpine-utility/docker-monitor.sh`
- Do not edit files under `env/` unless they are `*.template`
- Do not create new files unless the task explicitly requires a new file
- Do not keep retired services documented in active READMEs, indexes, or workflow folders

### Required Verification Before Editing
1. Read this file plus the nearest relevant README before making changes
2. Check `compose.yml` for the active bind mount or runtime path
3. Search for same-named files with `rg --files | rg '<filename>'` before editing
4. If a task touches alpine-utility monitoring, verify the workflow still calls `/scripts/docker-monitor.sh`

### Known Failure Modes
- Editing a same-named file outside `alpine-utility/scripts/`
- Assuming a file copied in a Dockerfile is the live runtime source when Compose bind-mounts over it
- Creating extra “backup”, “example”, or “fixed” files instead of updating the canonical file

### Repo Invariants
- Every operational script has exactly one canonical source file
- Active documentation should describe active services only
- Retired services should be removed, not left in active indexes or workflow directories
- `compose.yml`, root `README.md`, subtree READMEs, and workflow docs should agree on runtime paths
- Only `env/*.template` files are tracked in git

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
- Use credential: "SSH Password account" (connects to `host.docker.internal:2223`)
- SSH node returns `code` field for exit code (not `exitCode`)
- Store all workflow JSON files in `n8n-workflows/`
- Update `n8n-workflows/README.md` when adding/modifying workflows
- If SSH workflows fail with auth errors: check password in credential matches `ALPINE_UTILITY_PASSWORD` in env/.env

---

## Common Tasks

### Adding a New Service
1. Add service to `compose.yml`
2. Create `env/.env.{service}.template`
3. Update `README.md` port mappings and service list
4. Test locally, then commit

### Structural Change Checklist
1. Update the runtime source file first
2. Update the nearest README for that subsystem
3. Update root `README.md` if the change affects user-visible setup or maintenance
4. Update any relevant index files such as `docs/services/inventory.md` or `n8n-workflows/README.md`
5. Remove stale references to retired paths, files, or services
6. Run `bash scripts/audit_repo_docs.sh`

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

**n8n crash loop after upgrade:**
- **Pinned to version 2.10.4** due to incompatibility with 2.11.x task runner architecture
- Symptom: "Last session crashed" + restarts after "Start Active Workflows"
- Root cause: n8n 2.11+ requires task runners (internal or external mode)
- Solution: Stay on 2.10.4 until task runner migration path is clearer
- Database backup location: `/Volumes/docker/container_configs/n8n/database.sqlite.backup-*`

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
9. **Prefer canonical paths** — if duplicate names exist, use the path documented in `Canonical Paths`
10. **Use negative rules literally** — if this file says “do not edit” or “do not create,” treat that as a hard stop

## Promotion Policy

Assistant trust levels for this repository:

### L1 - Read Only
- Allowed: inspect files, search the repo, compare runtime paths, and propose changes
- Not allowed: modify files, create files, delete files, or rename files without explicit approval
- Use when the assistant has recently violated canonical path or repo hygiene rules

### L2 - Implementation Engineer
- Allowed: implement well-scoped changes in canonical files after reading the relevant docs
- Required: update related docs when changing behavior, verify runtime paths before editing, avoid duplicate file creation
- Not allowed: make structural cleanup decisions without clear repo evidence or user approval

### L3 - Trusted Engineer
- Allowed: make small structural cleanup decisions, remove stale references, and reconcile docs with runtime behavior without step-by-step guidance
- Required: consistently choose canonical files, catch stale docs proactively, and avoid unnecessary artifacts
- Expected: treat repo hygiene as part of the task, not optional follow-up work

### Promotion Gates
- L1 to L2: 3 consecutive clean implementation tasks with no duplicate files, no wrong-file edits, and docs updated when needed
- L2 to L3: 5 additional clean tasks that require path verification or small structural reasoning, with no supervision corrections
- Any trust reduction trigger resets the streak for the current level

### Trust Reduction Triggers
- Editing a non-canonical duplicate when a canonical path is documented
- Creating “backup”, “fixed”, “copy”, or “final” files without explicit approval
- Leaving active docs inconsistent with the implemented runtime behavior
- Treating retired services or files as active without verification

---

**Last Updated**: March 10, 2026
**Repository**: https://github.com/budcalabrese/homelab
