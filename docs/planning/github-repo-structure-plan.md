# Repository Structure

Overview of the Git repository organization across GitHub and Gitea.

## GitHub Repos (Public/Private)

| Repo | Purpose | Notes |
|------|---------|-------|
| `homelab` | Docker Compose, scripts, templates | Templates only — no secrets |
| `obsidian-vault` | Daily notes, projects, meetings, learning | Primary remote: GitHub. Secondary: Gitea |
| `coding` | Development projects | Budget tracker, learning dashboard, etc. |
| `personal-life` | Car logs, misc life admin | Extracted from old `home` repo |

## Gitea Repos (Local Network Only)

| Repo | Purpose |
|------|---------|
| `homelab-secrets` | Actual `.env` files — **NEVER on GitHub** |
| `obsidian-vault` | Mirror of GitHub repo (secondary remote) |
| `financial-data` | Budget tracker data |
| `health-tracking` | Personal health data |
| `investment-strategy` | Personal finance |

---

## Key Rules

- **homelab** repo: templates + infrastructure only. Secrets go to `homelab-secrets` in Gitea.
- **obsidian-vault**: auto-syncs to both GitHub (primary) and Gitea (secondary) via `pushall` alias
- **homelab-secrets**: Gitea only. Never add a GitHub remote to this repo.

---

## Git Workflow

### Obsidian Vault (automated via n8n, daily)
```bash
git pull origin main && git add . && git commit -m "Daily update: $(date +%Y-%m-%d)" && git pushall
```

### Homelab (manual, when changing configs)
```bash
git add compose.yml   # specific files only, never git add -A
git commit -m "Add new service"
git push origin main  # GitHub only
```

### Secrets (manual, rarely)
```bash
# cd homelab-secrets — Gitea only
git add .env && git commit -m "Update API key" && git push origin main
```

---

## Disaster Recovery

### If Mac Mini dies
1. Set up new Mac Mini
2. Clone GitHub repos (`homelab`, `obsidian-vault`, `coding`)
3. Clone `homelab-secrets` from Gitea backup (or restore from 1Password)
4. Rebuild Docker stack: copy `.env` files, run `docker compose up -d`

### Backups
- Obsidian vault: GitHub (cloud) + Gitea (local)
- Homelab templates: GitHub
- Secrets: Gitea + 1Password (emergency)
- Gitea itself: automated backup via alpine-utility

---

## Branch Strategy

Main branch only. Solo user — feature branches add complexity without benefit.

Exception: major homelab changes can use a test branch before merging to main.
