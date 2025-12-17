# GitHub Repository Structure Plan

**Created:** 2024-12-04 (Las Vegas - AWS re:Invent)
**Status:** In Progress - Creating obsidian-vault first
**Related:** See `buds-productivity-system-plan.md` for full system details

---

## Current State

### GitHub Repos
1. **home** (private) - Catch-all repository
   - `car_logs/` - Vehicle maintenance tracking
   - `homelab/` - Docker configs and scripts
   - `mac_mini/` - Homebrew files, network diagram
   - `range_info/` - Firearms information
   - `shops/` - Business ideas
   - Misc files (smart home config, homelab architecture PNG)

2. **coding** (private) - Code examples and projects
   - `ai_prompts/` - AI prompts (needs cleanup)
   - `habit-tracker/` - Python project
   - `python-budget-tracker/` - Expense tracking
   - `python-learning-dashboard/` - Learning Python
   - `terraform/` - Terraform examples
   - `youtube-transcript-api/` - REST API project

### Gitea Repos (Private Data)
1. **financial-data** - Used by budget tracker
2. **health-tracking** - Weight, supplements
3. **investment-strategy** - Personal finance

---

## Target State

### GitHub Repos
1. **obsidian-vault** (NEW) - Productivity system
   - Primary remote: GitHub (cloud backup, mobile access)
   - Secondary remote: Gitea (fast local access)
   - Daily notes, projects, meetings, learning, dashboard

2. **homelab** (NEW) - Infrastructure configs
   - Docker compose files
   - Bash utility scripts
   - `.env.template` files (safe to commit)
   - Architecture diagrams
   - **NO actual secrets** (templates only)

3. **personal-life** (NEW) - Life admin
   - `car_logs/` (from old home repo)
   - `range_info/` (from old home repo)
   - `shops/` (from old home repo)
   - `mac_mini/` (from old home repo)
   - Non-work personal tracking

4. **coding** (KEEP) - Development projects
   - Clean up `ai_prompts/`
   - Keep all existing projects

### Gitea Repos
1. **obsidian-vault** (MIRROR) - Secondary remote
2. **homelab-secrets** (NEW) - Actual .env files
3. **financial-data** (KEEP)
4. **health-tracking** (KEEP)
5. **investment-strategy** (KEEP)

---

## Implementation Plan

### Phase 1: Create Obsidian Vault ✓ IN PROGRESS

**Status:** Creating now (Vegas)

```bash
# 1. Create directory
mkdir -p ~/ObsidianVault

# 2. Initialize git
cd ~/ObsidianVault
git init

# 3. Create .gitignore
cat > .gitignore << 'EOF'
# Obsidian workspace
.obsidian/workspace*
.obsidian/cache
.obsidian/plugins/*/data.json
.trash/

# Private sections
Private/
Sensitive/

# Environment
.env
.env.*

# OS files
.DS_Store
Thumbs.db
*.swp
*~

# IDE
.vscode/
.idea/

# Temporary
*.tmp
temp/
EOF

# 4. Create basic structure
mkdir -p "Daily Notes" Projects Meetings Learning

# 5. Create README
cat > README.md << 'EOF'
# Obsidian Vault

Personal knowledge base and productivity system.

## Structure
- `Dashboard.md` - Main homepage with weekly view
- `Daily Notes/` - Daily journals
- `Projects/` - Work and personal projects
- `Meetings/` - Meeting transcripts and notes
- `Learning/` - Study materials and resources

## Setup
1. Clone this repo
2. Install Obsidian
3. Open vault in Obsidian
4. Install required plugins: Dataview, Tasks, Calendar, Templater

## Sync Strategy
- **Primary:** GitHub (cloud backup, accessible anywhere)
- **Secondary:** Gitea (fast local access at home)
- **Auto-sync:** via n8n (9am & 9pm daily)

## Access
- **Mac Mini:** Primary workspace (Texas)
- **MacBook Air:** Travel access (~3x/year)
- **iPhone:** Read-only via MkDocs (Tailscale)
- **Anywhere:** GitHub web interface (fallback)

## Related
- See `buds-productivity-system-plan.md` for full system architecture
- Homelab configs in separate `homelab` repository
EOF

# 6. Create GitHub repository
gh repo create obsidian-vault --private --source=. --remote=origin

# 7. Initial commit
git add .
git commit -m "Initial Obsidian vault structure

- Basic folder structure (Daily Notes, Projects, Meetings, Learning)
- .gitignore for Obsidian workspace files
- README with setup instructions
- Ready for full implementation when back from Vegas"

# 8. Push to GitHub
git push -u origin main

# 9. Add Gitea remote (when back home)
# git remote add gitea ssh://git@MAC_MINI_IP:2222/bud/obsidian-vault.git
# git config alias.pushall '!git push origin main && git push gitea main'
```

**Next Steps (when home):**
- Set up Gitea remote
- Configure `pushall` alias
- Implement full Obsidian setup (see main plan)

---

### Phase 2: Create Personal-Life Repo (When Home)

**Status:** Pending - Will do when back in Texas

**Approach:** Create NEW repo, copy files (safer than renaming)

```bash
# 1. Create new directory
mkdir -p ~/personal-life-repo

# 2. Copy folders from home repo
cd ~/home_space/home
cp -r car_logs ~/personal-life-repo/
cp -r range_info ~/personal-life-repo/
cp -r shops ~/personal-life-repo/
cp -r mac_mini ~/personal-life-repo/
# Copy any other misc files you want to keep

# 3. Initialize new repo
cd ~/personal-life-repo
git init

# 4. Create .gitignore
cat > .gitignore << 'EOF'
# Environment
.env
.env.*

# OS files
.DS_Store
Thumbs.db
*.swp

# IDE
.vscode/
.idea/

# Backups
*.bak
*.backup
EOF

# 5. Create README
cat > README.md << 'EOF'
# Personal Life Management

Personal tracking and planning for non-work life.

## Contents
- `car_logs/` - Vehicle maintenance, plans, history
- `range_info/` - Firearms information and planned purchases
- `shops/` - Business ideas and potential ventures
- `mac_mini/` - System configuration (homebrew, network diagram)

## Separate From
- **Work/Productivity:** See `obsidian-vault` repo
- **Homelab Infrastructure:** See `homelab` repo
- **Coding Projects:** See `coding` repo
- **Private Financial:** See Gitea repos
EOF

# 6. Create GitHub repo
gh repo create personal-life --private --source=. --remote=origin

# 7. Initial commit
git add .
git commit -m "Initial personal life repo - extracted from old home repo"
git push -u origin main
```

**Note:** Keep old `home` repo for now as backup. Can archive later.

---

### Phase 3: Create Homelab Repo (When Home)

**Status:** Pending - Will create when ready to reorganize

**Important:** Current homelab is ACTIVE. Don't break running services!

```bash
# 1. Create new directory (don't touch existing configs yet)
mkdir -p ~/homelab-repo

# 2. Copy docker files from current home repo
cd ~/home_space/home/homelab
cp docker-compose.yml ~/homelab-repo/
# Copy any other docker-compose files
cp *.sh ~/homelab-repo/  # Bash scripts

# 3. Navigate to new repo
cd ~/homelab-repo

# 4. Create .env.template files
cat > .env.template << 'EOF'
# Docker Homelab Environment Variables Template
# Copy to .env and fill in actual values

# Tailscale
TS_AUTHKEY=your_tailscale_auth_key_here
TS_HOSTNAME=homelab-docker

# n8n
N8N_ENCRYPTION_KEY=generate_32_char_random_key_here
WEBHOOK_URL=http://host.docker.internal:5678/

# AnythingLLM
ANTHROPIC_API_KEY=your_anthropic_key_here
OLLAMA_BASE_URL=http://host.docker.internal:11434

# Database
POSTGRES_PASSWORD=your_secure_password_here
EOF

cat > .env.open-notebook.template << 'EOF'
# Open Notebook Configuration Template

# LLM Configuration
GEMINI_API_KEY=your_gemini_api_key_here
OPENAI_API_KEY=your_openai_key_if_using

# Model Selection
LLM_MODEL=gemini-flash-1.5
EMBEDDING_MODEL=gemma3

# TTS Configuration
TTS_PROVIDER=openedai-speech
TTS_API_URL=http://host.docker.internal:8000
TTS_VOICE=en_US-amy-medium

# Ollama
OLLAMA_BASE_URL=http://host.docker.internal:11434
EOF

# 5. Create comprehensive .gitignore
cat > .gitignore << 'EOF'
# CRITICAL: SECRETS - NEVER COMMIT
.env
.env.*
!.env.*.template
*.key
*.pem
secrets/
credentials/

# Docker volumes and data
*/data/
*/config/
container_configs/*/data/
container_configs/*/config/

# Logs
*.log
logs/

# Backups (may contain secrets)
backups/
*.backup
*.bak

# OS
.DS_Store
Thumbs.db
*.swp

# IDE
.vscode/
.idea/

# Temporary
tmp/
temp/
*.tmp
EOF

# 6. Create README
cat > README.md << 'EOF'
# Homelab Infrastructure

Docker-based homelab running on Mac Mini (Texas).

## Services
- **n8n** - Automation orchestration
- **Gitea** - Self-hosted Git server
- **Open WebUI** - LLM chat interface
- **AnythingLLM** - Knowledge base AI
- **MkDocs** - Documentation server
- **AudioBookShelf** - Media library
- **Tailscale** - VPN access
- **SearXNG** - Search aggregator
- **Linkwarden** - Bookmark manager
- And more...

## Setup Instructions

1. Clone this repository
2. Copy environment templates:
   ```bash
   cp .env.template .env
   cp .env.open-notebook.template .env.open-notebook
   ```
3. Edit `.env` files with actual secrets (get from `homelab-secrets` Gitea repo)
4. Deploy stack:
   ```bash
   docker-compose up -d
   ```

## Volume Locations
- **Configs:** `/Volumes/docker/container_configs/`
- **Data:** Managed by Docker volumes

## Security
- **NEVER** commit actual `.env` files to GitHub
- Actual secrets stored in Gitea `homelab-secrets` repo (local only)
- This repo contains templates and infrastructure-as-code only

## Related
- **Productivity System:** See `obsidian-vault` repo
- **Personal Projects:** See `coding` repo
- **System Plan:** See `buds-productivity-system-plan.md`
EOF

# 7. Initialize git
git init

# 8. Create GitHub repo
gh repo create homelab --private --source=. --remote=origin

# 9. IMPORTANT: Review before committing!
git status
git diff

# Search for any secrets that might have slipped in
grep -r "password\|api_key\|secret\|token" . --exclude-dir=.git

# 10. If clean, commit
git add .
git commit -m "Initial homelab infrastructure repository

- Docker compose files
- Environment templates (.env.template)
- Utility scripts
- Comprehensive .gitignore
- No secrets committed (templates only)"

git push -u origin main
```

**Migration Strategy:**
1. Create new repo with copies (don't touch running configs)
2. Test that templates are complete
3. Later: Update docker-compose to pull from new repo location
4. Keep old `home/homelab/` as backup until verified

---

### Phase 4: Create Homelab Secrets Repo in Gitea (When Home)

**Status:** Pending - Local network only!

```bash
# 1. In Gitea web interface (http://MAC_MINI_IP:3000)
#    - Create new repository: homelab-secrets
#    - Set to PRIVATE
#    - No GitHub mirror!

# 2. Create local directory
mkdir -p ~/homelab-secrets
cd ~/homelab-secrets

# 3. Initialize git
git init

# 4. Create .gitignore (defensive)
cat > .gitignore << 'EOF'
# OS files
.DS_Store
Thumbs.db
*.swp
EOF

# 5. Copy actual .env files
cp /Volumes/docker/container_configs/.env .
cp /Volumes/docker/container_configs/.env.open-notebook .
# Copy any other actual secret files

# 6. Create README
cat > README.md << 'EOF'
# Homelab Secrets

**WARNING: This repository contains actual secrets and API keys!**

## Security
- ⚠️ ONLY stored in Gitea (NEVER push to GitHub)
- ⚠️ NEVER make this repository public
- ⚠️ Keep encrypted backups separately (1Password/USB)

## Contents
- `.env` - Main docker-compose environment variables
- `.env.open-notebook` - Podcast generation API keys
- Other sensitive configuration files

## Usage
When setting up homelab on fresh machine or after disaster:
1. Clone `homelab` repo from GitHub (templates)
2. Clone THIS repo from Gitea (actual secrets - local network only)
3. Copy `.env` files from here to homelab config directory
4. Run `docker-compose up -d`

## Backup Strategy
- Gitea is backed up regularly (see backup scripts)
- Keep encrypted copy in 1Password (emergency access)
- Document which keys are used where
EOF

# 7. Add Gitea remote
git remote add origin ssh://git@MAC_MINI_IP:2222/bud/homelab-secrets.git

# 8. Initial commit
git add .
git commit -m "Initial secrets repository - GITEA ONLY"
git push -u origin main

# 9. Verify it's NOT on GitHub
# Double check that this directory has no GitHub remote
git remote -v  # Should only show Gitea
```

---

## Security Checklist

Before ANY commit to GitHub, verify:

```bash
# 1. Check what will be committed
git status
git diff --cached

# 2. Search for potential secrets
git diff --cached | grep -iE "password|api_key|secret|token|authkey"

# 3. Verify .gitignore is working
git check-ignore .env          # Should output: .env
git check-ignore .env.something # Should output: .env.something

# 4. List all files that will be committed
git ls-files

# 5. Ensure no .env files (except .template)
git ls-files | grep "\.env"    # Should ONLY show .env.template files
```

**If you find secrets:**
```bash
# Don't commit! Remove from staging
git reset HEAD <file-with-secrets>

# Add to .gitignore
echo "<file-with-secrets>" >> .gitignore
```

---

## Git Workflow Summary

### Obsidian Vault
```bash
# Daily (automated via n8n)
cd ~/ObsidianVault
git pull origin main
git add .
git commit -m "Daily update: $(date +%Y-%m-%d)"
git pushall  # To both GitHub + Gitea

# Manual (when needed)
git pull origin main  # Before starting work
# ... make changes ...
git add .
git commit -m "Descriptive message"
git pushall
```

### Homelab
```bash
# When updating infrastructure
cd ~/homelab-repo
git add docker-compose.yml
git commit -m "Add AnythingLLM service"
git push origin main  # GitHub only (no secrets)

# When updating secrets (SEPARATE repo, Gitea only)
cd ~/homelab-secrets
git add .env
git commit -m "Update Anthropic API key"
git push origin main  # Gitea only - NEVER GitHub
```

### Personal Life / Coding
```bash
# Standard git workflow
cd ~/personal-life-repo  # or ~/coding
git add <files>
git commit -m "Update car maintenance log"
git push origin main
```

---

## Branch Strategy

**Recommendation:** Main branch only (simple workflow)

**Rationale:**
- Solo user (no collaboration)
- Quick daily commits
- Git history provides version control
- Feature branches add complexity without benefit

**Exception:** Major homelab changes
```bash
# Optional: Use branch for testing major changes
git checkout -b test-new-docker-stack
# ... make changes ...
# ... test thoroughly ...
git checkout main
git merge test-new-docker-stack
git branch -d test-new-docker-stack
```

---

## Migration Timeline

### Week 1 (In Vegas - NOW)
- [x] Create `obsidian-vault` GitHub repo ← **DOING NOW**
- [ ] Initial structure and README
- [ ] Push to GitHub

### Week 2 (Back in Texas)
- [ ] Set up Obsidian on Mac Mini
- [ ] Add Gitea as secondary remote for obsidian-vault
- [ ] Create `personal-life` repo
- [ ] Copy files from old `home` repo

### Week 3 (When Ready)
- [ ] Create `homelab` repo on GitHub (templates only)
- [ ] Create `homelab-secrets` repo on Gitea
- [ ] Test that templates are complete
- [ ] Verify no secrets leaked to GitHub

### Week 4+ (Gradual)
- [ ] Archive old `home` repo (keep as backup)
- [ ] Clean up `coding` repo
- [ ] Implement full Obsidian system (see main plan)

**No rush:** Old repos aren't going anywhere. Migrate safely.

---

## Repository Access Patterns

| Repository | Primary Use | Access From | Update Frequency |
|------------|-------------|-------------|------------------|
| obsidian-vault | Daily productivity | Mac Mini, MacBook | Daily (multiple times) |
| homelab | Infrastructure reference | Mac Mini, anywhere | Weekly or less |
| personal-life | Life admin | Mac Mini | Monthly or less |
| coding | Active development | Mac Mini | Project-based |
| homelab-secrets | Secret management | Mac Mini only | Rarely (API key changes) |
| financial-data | Budget tracking | Mac Mini only | Weekly |

---

## Disaster Recovery

### Obsidian Vault
- **Primary backup:** GitHub (cloud)
- **Secondary backup:** Gitea (local)
- **Recovery:** Clone from either remote

### Homelab Configs
- **Primary backup:** GitHub (templates)
- **Secrets backup:** Gitea + encrypted export
- **Recovery:** Clone templates, restore secrets from Gitea or 1Password

### If Mac Mini Dies
1. Set up new Mac Mini
2. Clone all GitHub repos
3. Access Gitea backup (if available) or use 1Password secrets
4. Rebuild Docker stack from templates + secrets
5. Restore vault from GitHub

---

## Questions & Decisions

### Should I consolidate repos?
**Decision:** No - Keep separate by concern
- Better security (different secret levels)
- Clearer organization
- Different access patterns

### Monorepo vs separate?
**Decision:** Separate repositories
- Obsidian needs different sync strategy (GitHub primary + Gitea secondary)
- Homelab has secrets that shouldn't touch GitHub
- Personal life is low-churn
- Easier to manage independently

### Keep old `home` repo?
**Decision:** Yes, as archive/backup
- Don't delete until new structure proven
- Can make it private/archived on GitHub
- Good to have git history preserved

### What about `coding` repo?
**Decision:** Keep as-is, minor cleanup
- Working fine as catch-all for projects
- Clean up `ai_prompts/` when you have time
- No urgent changes needed

---

## Notes

- Created 2024-12-04 while in Vegas
- Starting with obsidian-vault repo first (lowest risk)
- Will migrate homelab carefully (currently running production services)
- No rush - old structure works, new structure is better
- Document everything as you go

---

## Related Documents

- `buds-productivity-system-plan.md` - Full system architecture
- Obsidian vault README (once created)
- Homelab repo README (once created)

---

**Last Updated:** 2024-12-04
**Status:** Phase 1 (Obsidian Vault) - In Progress
**Location:** Las Vegas → Texas (soon)
