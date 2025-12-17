# Bud's Personal Productivity System - Complete Plan

## System Overview

**Goal:** Self-hosted productivity system for task management, knowledge management, learning, and work tracking - replacing Notion and NotebookLM.

**Current Location:** Las Vegas for AWS re:Invent (implementing when back home in Texas)

---

## The Stack

### Always Running (Core Services)
- **Obsidian** - Everything (notes, journals, projects, meetings, AND task dashboard)
- **MkDocs** - Read-only web interface for mobile reference via Tailscale
- **AnythingLLM** - Interactive AI research assistant (chat with your notes)
- **n8n** - Automation orchestration (already running)
- **Gitea** - Local Git server for Docker configs (already running)
- **GitHub** - Cloud Git for Obsidian vault (primary remote)
- **AudioBookShelf** - Podcast library (already running)
- **Open WebUI** - Chat interface for Ollama (already running)
- **Ollama** - Local LLM server (already running on Mac Mini)

### Ephemeral (On-Demand Only)
- **Open Notebook** - Podcast generator (spins up when needed)
- **OpenEDAI Speech** - TTS engine for podcasts (already configured)

### Already Running Services
- Tailscale (VPN access)
- SearXNG (search)
- Linkwarden (bookmarks)
- Wyoming Whisper, Piper, OpenWakeWord (voice services)
- Budget Dashboard, Learning Dashboard (custom Streamlit apps)
- MeTube (YouTube downloader)
- Alpine Utility (monitoring container)

---

## Data Architecture

### Obsidian Vault Structure
```
ObsidianVault/
├── .git/
├── .gitignore
├── mkdocs.yml
├── Dashboard.md  ← YOUR HOMEPAGE (Notion-style weekly view)
├── Daily Notes/
│   └── YYYY-MM-DD.md (unified - work + personal + homelab)
├── Projects/
│   ├── Work/
│   │   ├── AWS-Central-Logging-Q1.md
│   │   └── [Other Work Projects]/
│   └── Personal/
│       ├── Home-Office-Upgrade.md
│       └── [Other Personal Projects]/
├── Meetings/
│   ├── Work/
│   │   └── YYYY-MM-DD-client-sync.md
│   └── Personal/
│       └── YYYY-MM-DD-family-planning.md
├── Learning/
│   ├── AI-Certification-2025/
│   │   ├── study-notes.md
│   │   ├── resources.md  #generate-podcast
│   │   └── key-concepts.md
│   └── [Other Topics]/
└── Templates/
    ├── Daily Note.md
    ├── Project.md
    └── Meeting.md
```

**Tag Strategy:**
- `#work` - Professional work tasks and projects
- `#personal` - General life tasks (fitness, errands, appointments)
- `#home` - Homelab infrastructure and house-related projects

### Docker Homelab Structure
```
docker-homelab/  (Gitea repo)
├── docker-compose.yml  (main stack - already exists)
├── docker-compose.podcast.yml  (NEW - ephemeral podcast stack)
├── .env.template  (NEW - safe to commit)
├── .env.open-notebook.template  (NEW)
├── .env.tailscale.template  (NEW)
├── .gitignore  (UPDATE - ignore actual .env files)
└── README.md  (UPDATE - document setup)

/Volumes/docker/container_configs/  (Mac Mini local)
├── .env  (NOT in Git - secrets)
├── .env.open-notebook  (NOT in Git - secrets)
├── open-webui/  (already exists)
├── n8n/  (already exists)
├── mkdocs/
│   └── obsidian-vault/  (NEW - Git clone for MkDocs serving)
├── anythingllm/  (NEW)
└── [other existing services]/
```

---

## Obsidian Dashboard Setup

### Dashboard.md (Homepage)
**Replicates Notion screenshot layout with these sections:**

```markdown
# THIS WEEK

## MONDAY
- [ ] Workout #personal #this-week monday
- [ ] 9am - Client zoom call #work #this-week monday
- [ ] Check and update budget #home #this-week monday

## TUESDAY
- [ ] Configure AWS IAM roles #work #this-week tuesday

## WEDNESDAY
- [ ] [Tasks auto-populated from project files] #this-week wednesday

## THURSDAY
- [ ] [Tasks auto-populated] #this-week thursday

## FRIDAY
- [ ] [Tasks auto-populated] #this-week friday

## WEEKEND
- [ ] Register car #personal #this-week saturday
- [ ] Update Docker containers #home #this-week sunday

---

## DEADLINES
```dataview
TASK
WHERE contains(text, "#deadline")
SORT due ASC
```

## WORK TASKS
```dataview
TASK
WHERE contains(text, "#work") AND !completed
```

## PERSONAL TASKS
```dataview
TASK
WHERE contains(text, "#personal") AND !completed
```

## HOMELAB TASKS
```dataview
TASK
WHERE contains(text, "#home") AND !completed
```

---

## WEEKLY FOCUS
- [ ] Complete AWS logging architecture #work #weekly-focus
- [ ] Gym 3x this week #personal #weekly-focus

## SIDE QUESTS
- [ ] Research new monitoring tools #home #side-quest

## ACTIVE WORK PROJECTS
```dataview
TABLE status as Status, file.mtime as "Last Modified"
FROM "Projects/Work"
WHERE contains(file.frontmatter.status, "In Progress") OR contains(file.frontmatter.status, "Planning")
SORT file.mtime DESC
```

## ACTIVE PERSONAL PROJECTS
```dataview
TABLE status as Status, file.mtime as "Last Modified"
FROM "Projects/Personal"
WHERE contains(file.frontmatter.status, "In Progress") OR contains(file.frontmatter.status, "Planning")
SORT file.mtime DESC
```
```

### Required Obsidian Plugins
1. **Dataview** - Query tasks from across vault dynamically
2. **Tasks** - Enhanced task management with due dates, recurrence
3. **Calendar** - Visual calendar widget
4. **Templater** - Templates for daily notes, projects, meetings
5. **Git** (optional) - Git integration within Obsidian

### Project File Template
```markdown
# [Project Name] - [Quarter/Year]

**Type**: Work | Personal | Homelab
**Status**: Planning | In Progress | On Hold | Completed
**Tags**: #work | #personal | #home

## Overview
[Brief description]

## Related Meetings
- [[Meetings/Work/]] or [[Meetings/Personal/]]

## Tasks
- [ ] Research phase #project-name #weekly-focus
- [ ] Design architecture #project-name #deadline
  Due: YYYY-MM-DD
- [ ] Implementation #project-name #this-week monday
- [ ] Testing #project-name

## Research Notes
[Findings from AnythingLLM, URLs, key insights]

## Architecture/Design
[Technical details, diagrams, decisions]

## Timeline
- Research: [Month]
- Design: [Month]
- Implementation: [Month]

---
**Location**: [[Projects/Work/]] or [[Projects/Personal/]]
```

### Daily Note Template
```markdown
# {{date:YYYY-MM-DD}}

## Work
-

## Personal
-

## Homelab
-

## Tomorrow
-

## Links
- Related projects:
- Related meetings:

---
**Tags**: #work #personal #home
```

### Meeting Note Template
```markdown
# [Meeting Topic] - {{date:YYYY-MM-DD}}

**Type**: Work | Personal
**Tags**: #work | #personal

## Attendees
-

## Key Takeaways
-

## Action Items
- [ ] [Task] #this-week monday

## Transcript
[Plaud Note transcript goes here via n8n]

## Related
- Project: [[Projects/Work/]] or [[Projects/Personal/]]

---
**Location**: [[Meetings/Work/]] or [[Meetings/Personal/]]
```

---

## Tag System Explained

The system uses **three primary tags** to categorize all tasks and content:

1. **#work** - Professional work tasks and projects
   - Examples: AWS projects, client meetings, certifications, work deadlines
   - Location: `Projects/Work/`, `Meetings/Work/`

2. **#personal** - General life tasks (fitness, errands, appointments)
   - Examples: Gym workouts, doctor appointments, car maintenance, errands
   - Location: `Projects/Personal/`, `Meetings/Personal/`

3. **#home** - Homelab infrastructure and house-related projects
   - Examples: Docker container updates, network configuration, home improvements, monitoring setup
   - Location: Can be in `Projects/Personal/` or mixed throughout
   - **Why separate from #personal?** Your homelab is substantial technical work - it's at home but different from personal errands

**Key Principle:** Daily Notes stay unified (work + personal + homelab mixed), but Projects and Meetings are organized into Work/Personal subfolders. Tags allow Dashboard queries to pull tasks by category regardless of location.

---

## The Three Core Workflows

### 1. Daily Work Workflow

**Morning Routine:**
1. Open Obsidian → `Dashboard.md` (homepage)
2. See today's tasks organized by category
3. Review yesterday's `Daily Notes/YYYY-MM-DD.md`
4. Create today's daily note from template
5. Check calendar (manually added work appointments)

**During the Day:**
- Meeting happens → Plaud Note records on phone
- n8n: Plaud transcript → Obsidian meeting note (automated)
- Work in Obsidian, update daily journal
- Check off tasks in project files as completed
- Dashboard auto-updates (Dataview queries pull from project files)
- Need to research? Ask AnythingLLM: "What did we discuss about AWS logging?"

**Evening Routine:**
- Update daily journal with accomplishments
- Check off completed tasks in project files
- Review tomorrow's tasks on Dashboard
- Git commit + push to GitHub (can be automated via n8n)
- Obsidian → GitHub → Gitea mirror

**Key Principle:** Tasks live in project context, Dashboard aggregates them via queries. No duplication.

**Example Daily Journal Entry:**
```markdown
# 2024-12-03

## Work
- Updated [[Projects/Work/AWS-Central-Logging-Q1]] architecture design
- Call with [[Meetings/Work/2024-12-03-John-Discussion]] regarding timeline concerns
- Completed: ~~Configure IAM roles for dev accounts~~ ✓
- Researched best practices for CloudWatch integration

## Personal
- Gym (push day) ✓
- Checked budget in [[Budget Dashboard]] - on track for month

## Homelab
- Updated Docker containers on Mac Mini
- Fixed n8n workflow for podcast generation
- Researched new monitoring tools

## Blockers
- Need Security team approval for prod access

## Tomorrow
- Finish remaining 4 IAM role configurations #work
- Follow up with Security team #work
- Review Q1 timeline with manager #work

---
**Tags**: #work #personal #home
```

---

### 2. Project Research Workflow

**Scenario:** New work project assigned (e.g., AWS Central Logging)

**Step 1: Meeting & Transcript Capture**
- Attend project kickoff meeting
- Record with Plaud Note on phone
- Plaud syncs transcript automatically
- n8n workflow detects new transcript
- Creates `Meetings/2024-12-02-AWS-Logging-Kickoff.md` in Obsidian
- Git auto-commits to GitHub

**Step 2: Create Project Structure**
Create new project: `Projects/Work/AWS-Central-Logging-Q1.md`

```markdown
# AWS Central Logging - Q1 2025 Project

**Type**: Work
**Status**: In Progress
**Tags**: #work

## Overview
Implement centralized logging using AWS unified management across 12 accounts

## Related Meetings
- [[Meetings/Work/2024-12-02-AWS-Logging-Kickoff]]

## Tasks
- [ ] Research AWS unified management capabilities #work #aws-logging #weekly-focus
- [ ] Set up central logging account #work #aws-logging #deadline
  Due: 2024-12-15
- [ ] Configure IAM roles (12 accounts) #work #aws-logging #this-week monday
- [ ] Set up S3 buckets with lifecycle policies #work #aws-logging
- [ ] Test in dev environment #work #aws-logging
- [ ] Deploy to production accounts #work #aws-logging #deadline
  Due: 2025-02-15

## Research Notes
(Findings added here as you learn)

## Architecture Design
(Technical diagrams and decisions)

## Implementation Log
(Link to daily journal entries where you worked on this)

## Timeline
- Research: Dec 2024
- Design: Jan 2025
- Implementation: Feb 2025

---
**Location**: [[Projects/Work/]]
```

**Step 3: Research with AnythingLLM**
- AnythingLLM has read-only access to Obsidian vault
- Open AnythingLLM web interface
- Ask: "Based on my AWS logging kickoff meeting, what are the key requirements?"
- Ask: "What are best practices for AWS unified management IAM configuration?"
- Ask: "Search my notes for any previous AWS logging work"
- AnythingLLM uses Ollama + Claude API to analyze your vault
- Copy useful findings back to project.md Research Notes section

**Step 4: Tasks Auto-Appear on Dashboard**
- Tasks in project.md have tags (#this-week, #deadline, #weekly-focus)
- Dashboard Dataview queries automatically pull them in
- Organized by day, category, priority
- Single source of truth - tasks live in project context

**Step 5: Track Daily Progress**
- Work on task (e.g., configure IAM roles)
- Update daily journal: "Configured IAM roles for 8/12 accounts today"
- Check off task when complete in project file
- Link daily journal to project: `[[Projects/Work/AWS-Central-Logging-Q1]]`
- Dashboard updates automatically

**Step 6: Performance Review Time**
- Need Q1 accomplishments for review
- Option A: Search Obsidian for "AWS-Central-Logging"
  - Finds: Meeting transcripts, project notes, daily journal entries, research
- Option B: Ask AnythingLLM: "Summarize my work on AWS Central Logging project"
  - Gets: "You researched and implemented centralized logging across 12 AWS accounts, designed architecture, configured IAM roles, deployed to production in Q1 2025"
- Copy summary to review document

**Key Insight:** All context stays together. Meeting transcript → Project notes → Daily work logs → Research findings. AnythingLLM can query across all of it.

---

### 3. Learning/Study Workflow (with Podcast Generation)

**Scenario:** Studying for AI certification or learning new technology

**Step 1: Create Learning Material in Obsidian**
`Learning/AI-Certification-2025/resources.md`:

```markdown
# AI Agent Study Resources

## Study URLs
- https://claude.ai/docs/prompt-engineering
- https://openai.com/research/agents
- https://www.anthropic.com/research/agent-architectures
- https://example.com/rag-systems-explained

## Key Concepts to Master
- Prompt engineering techniques (temperature, top_p, system prompts)
- Agent state management and memory
- Tool use and function calling
- RAG (Retrieval Augmented Generation) systems
- Error handling and fallback strategies

## My Questions
- How do agents maintain context across sessions?
- What's the difference between ReAct and Chain-of-Thought?
- Best practices for agent error handling?
- When to use RAG vs fine-tuning?

## Study Tasks
- [ ] Read agent architectures paper #learning #this-week
- [ ] Practice prompt engineering exercises #learning #this-week
- [ ] Build sample agent with Ollama #learning #side-quest

## Notes
(Add notes as you study)

#generate-podcast
```

**Step 2: Automated Podcast Generation**

**Trigger:** 2pm daily OR manual webhook OR tag detection

**n8n Workflow Process:**
1. Scan `Learning/` folder for `#generate-podcast` tag
2. If found: Execute `docker-compose -f docker-compose.podcast.yml up -d`
3. Wait for healthcheck (Open Notebook + OpenEDAI Speech containers)
4. API call to Open Notebook: "Generate podcast from Learning/AI-Certification-2025/resources.md"
5. Open Notebook:
   - Fetches all URLs
   - Reads your notes and questions
   - Uses Gemini Flash 1.5 to analyze content
   - Generates conversational podcast script
   - OpenEDAI Speech (TTS) converts to audio
   - Outputs: `ai-study-podcast-2024-12-04.mp3`
6. MP3 dropped directly into `/audiobookshelf/podcasts/` folder
7. Trigger AudioBookShelf library scan
8. Send notification: "Your AI certification study podcast is ready"
9. Cleanup: `docker-compose -f docker-compose.podcast.yml down`
10. Log completion

**Step 3: Listen and Learn**
- Open AudioBookShelf app on phone
- Find new podcast in library
- Listen during gym workout or commute
- Passive learning while doing other activities

**Resource Efficiency:**
- Open Notebook + TTS only run for ~30 minutes during generation
- Saves 10GB RAM and 4-6 CPU cores for rest of day
- On-demand workload, not always-on service

**Use Cases for Podcast Learning:**
- Certification study materials
- Work research topics (SMR technology, nuclear regulations)
- Conference talk summaries
- Industry trend analysis
- Technical documentation (when you want audio version)

**What NOT to podcast:**
- Daily work notes (stay text-based)
- Meeting transcripts (already have Plaud audio)
- Project implementation details (reference in Obsidian)

---

## Git & Sync Strategy

### Obsidian Vault - GitHub Primary, Gitea Secondary

**Why GitHub Primary:**
- Already paying for GitHub premium
- Better mobile web interface than Gitea
- Cloud backup (accessible even if Mac Mini is down)
- Can access anywhere (not just via Tailscale)

**Why Gitea Secondary:**
- Local "source of truth" when at home
- Faster push/pull operations (LAN)
- Part of existing homelab infrastructure
- Privacy for sensitive work notes

**Git Remote Setup:**
```bash
cd ~/ObsidianVault
git remote add origin git@github.com:yourusername/obsidian-vault.git  # Primary
git remote add gitea ssh://git@your-mac-mini:2222/bud/obsidian-vault.git  # Secondary

# Create alias for pushing to both
git config alias.pushall '!git push origin main && git push gitea main'
```

### Mac Mini (Primary Work Machine)

**Morning Routine:**
```bash
cd ~/ObsidianVault
git pull origin main  # Get any changes from MacBook
```

**Evening Routine (can be automated via n8n):**
```bash
cd ~/ObsidianVault
git add .
git commit -m "Daily update: $(date +%Y-%m-%d)"
git pushall  # Pushes to both GitHub and Gitea
```

**Or create script:** `~/sync-obsidian.sh`
```bash
#!/bin/bash
cd ~/ObsidianVault
git pull origin main && \
git add . && \
git commit -m "Auto-sync: $(date +%Y-%m-%d %H:%M)" && \
git pushall
echo "Obsidian vault synced successfully"
```

**Automated via n8n (optional):**
- Schedule: 9am and 9pm daily
- Execute: `~/sync-obsidian.sh`
- Send notification if errors

### MacBook Air (Travel - ~3 times/year)

**Before Leaving for Trip:**
```bash
cd ~/ObsidianVault
git pull origin main  # Get latest from Mac Mini
```

**During Travel:**
- Work offline (Git doesn't require connection)
- Make notes, update projects
- All changes tracked locally

**At Hotel (via Tailscale or public WiFi):**
```bash
cd ~/ObsidianVault
git add .
git commit -m "Re:Invent Day 2 notes"
git push origin main  # Push to GitHub
```

**Back Home:**
```bash
# On Mac Mini
cd ~/ObsidianVault
git pull origin main  # Get all travel notes
```

**Important:** If you forget to push from MacBook and edit same file on Mac Mini → merge conflict. Resolve manually or use "theirs" strategy for one-way sync.

### iPhone (Mobile Quick Capture)

**Primary Method: Apple Notes**
- Quick thought or task → Open Apple Notes
- Create note with tag: `#obsidian-inbox`
- Apple Notes syncs via iCloud automatically
- Next day on Mac Mini: Review Apple Notes inbox
- Copy important items to Obsidian
- Delete from Apple Notes after processing

**Why this works:**
- Fast (no friction, native iOS app)
- Reliable (iCloud sync always works)
- Temporary (Apple cloud is just a buffer)
- Permanent storage still in self-hosted Obsidian + GitHub

**Read-Only Access via MkDocs:**
- Access via Tailscale: `http://192.168.0.9:8085`
- Beautiful searchable web interface
- Can reference notes, meeting transcripts, project details
- Cannot edit (read-only, which is fine for mobile reference)

**Fallback: GitHub Web Interface**
- If Tailscale unavailable or Mac Mini is down
- Browse to github.com/yourusername/obsidian-vault
- View any markdown file
- Basic rendering (no Obsidian wiki links)

### Docker Configs - Gitea Only (Local)

**In Gitea Repository:**
- ✅ `docker-compose.yml` (safe to commit)
- ✅ `docker-compose.podcast.yml` (safe to commit)
- ✅ `.env.template` files (no secrets, safe to commit)
- ✅ `.gitignore` (ignore actual .env files)
- ✅ `README.md` (setup documentation)
- ✅ Scripts (backup, health check, etc.)

**Local Only (NOT in Git):**
- ❌ `.env` (has API keys, secrets)
- ❌ `.env.open-notebook` (has Gemini API key)
- ❌ `.env.tailscale` (has Tailscale auth key)
- ❌ Any file with passwords, tokens, keys

**.gitignore for Docker Repo:**
```gitignore
# Secrets - NEVER COMMIT
.env
.env.*
!.env.*.template  # Allow templates

# Docker volumes (data lives elsewhere)
*/data/
*/config/

# OS files
.DS_Store
Thumbs.db
*.swp

# IDE
.vscode/
.idea/

# Logs
*.log
```

**.env.template Example:**
```bash
# Open Notebook Configuration
OPENAI_API_KEY=your_key_here
GEMINI_API_KEY=your_gemini_key_here
TTS_API_URL=http://host.docker.internal:8000

# Tailscale
TS_AUTHKEY=your_tailscale_auth_key_here
TS_HOSTNAME=homelab-docker

# n8n
N8N_ENCRYPTION_KEY=generate_32_char_random_key_here
WEBHOOK_URL=http://host.docker.internal:5678/

# Database passwords
POSTGRES_PASSWORD=your_secure_password_here
```

**Setup on Fresh Machine:**
```bash
git clone ssh://git@gitea:2222/bud/docker-homelab.git
cd docker-homelab
cp .env.template .env
cp .env.open-notebook.template .env.open-notebook
nano .env  # Fill in real secrets
nano .env.open-notebook  # Fill in real API keys
docker-compose up -d
```

---

## Mobile Access Strategy

### Read-Only Reference (MkDocs)
**Primary method for referencing notes on phone**

**Access:** Via Tailscale at `http://192.168.0.9:8085`

**Features:**
- Beautiful Material Design interface
- Full-text search across all notes
- Proper markdown rendering
- Navigation by folder
- Dark mode
- Code syntax highlighting
- Auto-updates when vault changes

**Use Cases:**
- "What was that AWS architecture decision?"
- "Show me my workout routine notes"
- "Find the meeting notes from last week"
- "Look up nuclear SMR cost projections"

**Limitations:**
- Read-only (cannot edit)
- No Obsidian wiki links (shows as plain text)
- No graph view
- Requires Tailscale connection

### Quick Capture (Apple Notes)
**For capturing thoughts on the go**

**Workflow:**
1. Thought occurs → Open Apple Notes (native iOS)
2. Create note, add tag `#obsidian-inbox`
3. Apple Notes syncs via iCloud
4. Next morning on Mac Mini: Open Apple Notes
5. Review inbox items
6. Copy to appropriate Obsidian location
7. Delete from Apple Notes

**Example Apple Note:**
```
#obsidian-inbox

AWS Logging Project:
- Need to check if CloudWatch supports cross-region aggregation
- Follow up with John about timeline

Home:
- Register car by Dec 15
- Schedule dentist appointment
```

**Then in Obsidian:**
- Add CloudWatch question to project research notes
- Add tasks to Dashboard with #deadline tags
- Delete Apple Note

### Fallback Access (GitHub Web)
**When Tailscale is unavailable**

- Browse to github.com
- Navigate to private obsidian-vault repo
- Click through folders to find note
- Read markdown (basic rendering)
- No search, no special features
- But data is accessible anywhere

---

## n8n Automation Workflows

### Workflow 1: Plaud Transcript → Obsidian
**Purpose:** Automatically process meeting transcripts

**Trigger:** 
- File watcher on Plaud sync folder
- OR Webhook from Plaud API (if available)
- OR Scheduled check every 30 minutes

**Actions:**
1. **Detect New Transcript**
   - Check for new files in `/path/to/plaud/transcripts/`
   - Filter for .txt or .json files

2. **Parse Transcript**
   - Extract: date, title, transcript text
   - Identify: meeting participants (if in transcript)

3. **Create Obsidian Meeting Note**
   - Use meeting template
   - Filename: `YYYY-MM-DD-{meeting-topic}.md`
   - Location: `Meetings/Work/` or `Meetings/Personal/` (based on meeting type)
   - Content: Formatted transcript + metadata
   - Add appropriate tag: #work or #personal

4. **Git Commit**
   - `cd ~/ObsidianVault`
   - `git add Meetings/Work/YYYY-MM-DD-*.md` or `Meetings/Personal/YYYY-MM-DD-*.md`
   - `git commit -m "Add meeting transcript: {topic}"`
   - `git pushall`

5. **Notification**
   - Send to phone: "New meeting transcript added to Obsidian"
   - Include link to file (for MkDocs viewing)

**Expected Runtime:** ~30 seconds per transcript

---

### Workflow 2: Daily Git Sync
**Purpose:** Ensure Obsidian vault is always synced

**Trigger:** 
- Schedule: 9:00 AM and 9:00 PM daily
- OR Manual webhook trigger

**Actions:**
1. **Pull Changes**
   ```bash
   cd ~/ObsidianVault
   git pull origin main
   ```
   - Gets any changes from MacBook
   - Handles merge if needed

2. **Add & Commit Local Changes**
   ```bash
   git add .
   git commit -m "Auto-sync: $(date +%Y-%m-%d %H:%M)"
   ```
   - Commits any uncommitted work from day

3. **Push to Remotes**
   ```bash
   git pushall  # GitHub + Gitea
   ```

4. **Verify Success**
   - Check git status
   - Verify no conflicts

5. **Notification on Error**
   - If git pull/push fails
   - Send alert: "Obsidian sync failed - check for conflicts"

6. **Update MkDocs**
   ```bash
   cd /Volumes/docker/container_configs/mkdocs/obsidian-vault
   git pull origin main
   ```
   - Keeps MkDocs copy in sync for mobile viewing

**Expected Runtime:** ~10 seconds

---

### Workflow 3: Podcast Generation (Ephemeral Stack)
**Purpose:** Generate learning podcasts on-demand

**Trigger:**
- Schedule: 2:00 PM daily
- OR Manual webhook: `http://localhost:5678/webhook/generate-podcast`
- OR File watcher for `#generate-podcast` tag

**Actions:**

1. **Scan for Podcast Requests**
   ```bash
   grep -r "#generate-podcast" ~/ObsidianVault/Learning/
   ```
   - If no matches: Exit gracefully
   - If matches found: Continue

2. **Spin Up Podcast Stack**
   ```bash
   cd /Volumes/docker/container_configs/
   docker-compose -f docker-compose.podcast.yml up -d
   ```

3. **Wait for Health Checks**
   ```bash
   # Loop until both services healthy
   while true; do
     NOTEBOOK_HEALTH=$(docker inspect open-notebook-ephemeral --format='{{.State.Health.Status}}')
     TTS_HEALTH=$(docker inspect openedai-speech-ephemeral --format='{{.State.Health.Status}}')
     
     if [ "$NOTEBOOK_HEALTH" = "healthy" ] && [ "$TTS_HEALTH" = "healthy" ]; then
       break
     fi
     sleep 5
   done
   ```

4. **API Call to Open Notebook**
   ```javascript
   // HTTP Request Node
   POST http://localhost:5055/api/generate-podcast
   {
     "source": "/learning/AI-Certification-2025/",
     "output_filename": "ai-study-podcast-{date}.mp3",
     "voice": "en_US-amy-medium"
   }
   ```

5. **Poll for Completion**
   ```bash
   # Check every 30 seconds for MP3
   while [ ! -f /Volumes/docker/container_configs/audiobookshelf/podcasts/ai-study-podcast-*.mp3 ]; do
     sleep 30
     # Timeout after 10 minutes
   done
   ```

6. **Refresh AudioBookShelf**
   ```bash
   curl -X POST http://localhost:13378/api/libraries/scan
   ```

7. **Send Notification**
   - Message: "Your AI study podcast is ready in AudioBookShelf"
   - Include: podcast title, duration

8. **Cleanup - Spin Down Stack**
   ```bash
   docker-compose -f docker-compose.podcast.yml down
   ```

9. **Remove Tag from Obsidian File**
   ```bash
   # Remove #generate-podcast tag so it doesn't re-trigger
   sed -i '' 's/#generate-podcast//g' ~/ObsidianVault/Learning/AI-Certification-2025/resources.md
   git add .
   git commit -m "Podcast generated - remove tag"
   git pushall
   ```

**Expected Runtime:** ~5-15 minutes (depending on content length)

**Error Handling:**
- If stack fails to start: Notification + cleanup
- If generation takes >10 minutes: Timeout + cleanup
- If orphaned stack running >2 hours: Alpine utility auto-cleans

---

### Workflow 4: Weekly Summary
**Purpose:** Generate summary of week's work for review

**Trigger:**
- Schedule: Sunday 8:00 PM weekly

**Actions:**

1. **Collect Week's Daily Journals**
   ```bash
   # Get last 7 days of daily notes
   find ~/ObsidianVault/Daily\ Notes/ -name "$(date -v-7d +%Y-%m-%d)*.md" -type f
   ```

2. **Concatenate Content**
   - Combine all daily journal entries
   - Extract work sections

3. **Send to AnythingLLM API**
   ```javascript
   POST http://localhost:3003/api/chat
   {
     "message": "Based on these daily journal entries from the past week, create a summary of:\n1. Key accomplishments\n2. Projects worked on\n3. Meetings attended\n4. Challenges faced\n\n[DAILY JOURNAL CONTENT]",
     "mode": "chat"
   }
   ```

4. **Create Summary Note**
   - Create: `Weekly-Summary-YYYY-MM-DD.md` in Obsidian
   - Content: AI-generated summary
   - Format with headers, bullet points

5. **Git Commit**
   ```bash
   git add Weekly-Summary-*.md
   git commit -m "Weekly summary: $(date +%Y-%m-%d)"
   git pushall
   ```

6. **Send Notification**
   - Email or push notification
   - Subject: "Your weekly summary is ready"
   - Body: Brief preview of accomplishments

**Expected Runtime:** ~30 seconds

**Use Case:** Helps with performance reviews, manager check-ins, reflection

---

### Workflow 5: Apple Notes Inbox Processing (Optional)
**Purpose:** Remind to process quick captures

**Trigger:**
- Schedule: 9:00 AM daily

**Actions:**

1. **Check Apple Notes via AppleScript** (Mac only)
   ```applescript
   tell application "Notes"
     set inboxNotes to every note whose body contains "#obsidian-inbox"
     return count of inboxNotes
   end tell
   ```

2. **If Count > 0**
   - Send notification: "You have X notes in Obsidian inbox to process"
   - Include: Note titles

3. **User Reviews Apple Notes**
   - Manually move content to Obsidian
   - Delete from Apple Notes

**Note:** This is just a reminder workflow, not full automation (to preserve context and judgment)

---

## Docker Configuration Files

### docker-compose.podcast.yml (NEW - Ephemeral Stack)

```yaml
version: '3.8'

services:
  open-notebook-ephemeral:
    image: lfnovo/open_notebook:v1-latest-single
    container_name: open-notebook-ephemeral
    env_file:
      - .env
      - .env.open-notebook
    ports:
      - "8503:8502"  # Web UI
      - "5055:5055"  # API (required!)
    volumes:
      - /Volumes/docker/container_configs/open-notebook/notebook_data:/app/data
      - /Volumes/docker/container_configs/open-notebook/surreal_single_data:/mydata
      - /Users/bud/ObsidianVault/Learning:/learning:ro  # Learning folder only
      - /Volumes/docker/container_configs/audiobookshelf/podcasts:/output  # Output to AudioBookShelf
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: "no"  # Don't auto-restart (ephemeral)
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8502/ || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2.0'

  openedai-speech-ephemeral:
    image: ghcr.io/matatonic/openedai-speech:latest
    container_name: openedai-speech-ephemeral
    env_file:
      - .env
      - .env.openedai-speech
    ports:
      - "8000:8000"  # TTS API
    volumes:
      - /Volumes/docker/container_configs/openedai-speech/voices:/app/voices
      - /Volumes/docker/container_configs/openedai-speech/config:/app/config
    restart: "no"  # Don't auto-restart (ephemeral)
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/v1/models || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 180s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 8G
          cpus: '4.0'
```

**Usage:**
```bash
# Spin up (via n8n or manually)
docker-compose -f docker-compose.podcast.yml up -d

# Check status
docker-compose -f docker-compose.podcast.yml ps

# Spin down
docker-compose -f docker-compose.podcast.yml down
```

---

### Add to docker-compose.yml (Main Stack)

**MkDocs Service:**
```yaml
  mkdocs-vault:
    image: squidfunk/mkdocs-material:latest
    container_name: mkdocs-vault
    env_file: .env
    ports:
      - "8085:8000"
    volumes:
      - /Volumes/docker/container_configs/mkdocs/obsidian-vault:/docs:ro
    command: serve --dev-addr=0.0.0.0:8000
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8000/ || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
```

**AnythingLLM Service:**
```yaml
  anythingllm:
    image: mintplexlabs/anythingllm:latest
    container_name: anythingllm
    env_file: .env
    ports:
      - "3003:3001"
    volumes:
      - /Volumes/docker/container_configs/anythingllm:/app/server/storage
      - /Users/bud/ObsidianVault:/obsidian:ro  # Mount entire vault read-only
    environment:
      - STORAGE_DIR=/app/server/storage
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}  # For Claude API access
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:3001/ || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2.0'
```

---

### mkdocs.yml (Obsidian Vault Root)

```yaml
site_name: Bud's Knowledge Base
site_description: Personal notes, projects, meetings, and learning
site_author: Bud

theme:
  name: material
  palette:
    # Dark mode (easier on eyes)
    - scheme: slate
      primary: indigo
      accent: indigo
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
    # Light mode
    - scheme: default
      primary: indigo
      accent: indigo
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
  
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.top
    - navigation.tracking
    - search.suggest
    - search.highlight
    - search.share
    - content.code.copy
    - content.code.annotate

plugins:
  - search:
      lang: en
  - tags

markdown_extensions:
  - pymdownx.highlight:
      anchor_linenums: true
  - pymdownx.superfences
  - pymdownx.tasklist:
      custom_checkbox: true
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - admonition
  - pymdownx.details
  - footnotes
  - attr_list
  - md_in_html
  - tables
  - def_list

nav:
  - Home: index.md
  - Dashboard: Dashboard.md
  - Daily Notes: Daily Notes/
  - Projects: Projects/
  - Meetings: Meetings/
  - Learning: Learning/

extra:
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/yourusername
```

---

### .env.open-notebook.template

```bash
# Open Notebook Configuration Template
# Copy to .env.open-notebook and fill in actual values

# LLM Configuration
OPENAI_API_KEY=your_openai_key_if_using
GEMINI_API_KEY=your_gemini_api_key_here
ANTHROPIC_API_KEY=your_anthropic_key_if_using

# Model Selection
LLM_MODEL=gemini-flash-1.5
EMBEDDING_MODEL=gemma3

# TTS Configuration
TTS_PROVIDER=openedai-speech
TTS_API_URL=http://host.docker.internal:8000
TTS_VOICE=en_US-amy-medium

# STT Configuration (if using)
STT_PROVIDER=openedai-speech
STT_API_URL=http://host.docker.internal:8000

# Ollama Configuration
OLLAMA_BASE_URL=http://host.docker.internal:11434

# Database (SurrealDB is included in single image)
# No additional config needed for single image version
```

---

## Alpine Utility Health Script Update

**Add to existing health script:**

```bash
#!/bin/bash
# /config/health-check.sh

# ... existing error checking code ...

# NEW: Check if podcast generation needed
echo "Checking for podcast generation requests..."
if grep -rq "#generate-podcast" /path/to/obsidian/vault/Learning/**/*.md; then
  echo "Podcast generation requested - triggering n8n workflow"
  curl -X POST http://host.docker.internal:5678/webhook/generate-podcast
fi

# NEW: Check if podcast stack is orphaned (running too long)
if docker ps --format '{{.Names}}' | grep -q "open-notebook-ephemeral"; then
  echo "Podcast stack is running - checking uptime..."
  
  START_TIME=$(docker inspect open-notebook-ephemeral --format='{{.State.StartedAt}}')
  START_EPOCH=$(date -d "$START_TIME" +%s)
  NOW_EPOCH=$(date +%s)
  UPTIME_HOURS=$(( ($NOW_EPOCH - $START_EPOCH) / 3600 ))
  
  if [ $UPTIME_HOURS -gt 2 ]; then
    echo "WARNING: Podcast stack has been running for $UPTIME_HOURS hours - cleaning up orphaned containers"
    cd /Volumes/docker/container_configs/
    docker-compose -f docker-compose.podcast.yml down
    
    # Send alert
    echo "Orphaned podcast stack cleaned up" | mail -s "Docker Health Alert" your@email.com
  fi
fi

# ... rest of existing health check ...
```

---

## Resource Usage Summary

### Current State (Main Stack - Always Running)
```
Service                 Memory    CPU
--------------------------------
open-webui             500MB     0.5
n8n                    1GB       1.0
gitea                  500MB     1.0
linkwarden            1.5GB      1.5
searxng               512MB      0.5
tailscale             256MB      0.25
audiobookshelf         500MB     0.5
budget-dashboards      1GB       1.0
mkdocs (NEW)           100MB     0.25
anythingllm (NEW)      2GB       1.0
Other services         2GB       2.0
--------------------------------
TOTAL                 ~10GB      ~10 cores
```

### Ephemeral Stack (Podcast Generation - On-Demand)
```
Service                 Memory    CPU      Duration
------------------------------------------------
open-notebook          2GB       2.0      ~30 min/day
openedai-speech        8GB       4.0      ~30 min/day
------------------------------------------------
TOTAL                  10GB      6.0      ~30 min/day

Savings: 23.5 hours/day of freed resources
```

### Mac Mini Specs (Assumed)
- M2 or M4 Mac Mini
- 16-24GB RAM
- 8-10 CPU cores
- Running this stack should be comfortable

---

## Setup Checklist (When Home from Vegas)

### Phase 1: Test Existing Infrastructure (1-2 hours)
- [ ] Verify Open Notebook is accessible at `http://localhost:8503`
- [ ] Test OpenEDAI Speech TTS at `http://localhost:8000`
- [ ] Upload test markdown file to Open Notebook
- [ ] Generate test podcast
- [ ] Verify MP3 output quality
- [ ] Check AudioBookShelf can see generated files
- [ ] Confirm Ollama + Open WebUI working
- [ ] Test n8n is accessible and functioning

### Phase 2: Obsidian Setup (2-3 hours)
- [ ] Install Obsidian on Mac Mini (if not already)
- [ ] Create vault directory: `~/ObsidianVault`
- [ ] Install required plugins:
  - [ ] Dataview
  - [ ] Tasks
  - [ ] Calendar
  - [ ] Templater
- [ ] Create folder structure:
  - [ ] `Daily Notes/`
  - [ ] `Projects/Work/`
  - [ ] `Projects/Personal/`
  - [ ] `Meetings/Work/`
  - [ ] `Meetings/Personal/`
  - [ ] `Learning/`
  - [ ] `Templates/`
- [ ] Create `Dashboard.md` homepage
- [ ] Test Dataview queries on Dashboard
- [ ] Create daily note template
- [ ] Create project template
- [ ] Create meeting template
- [ ] Add test content to verify queries work

### Phase 3: Git Configuration (30 minutes)
- [ ] Initialize Git in Obsidian vault
- [ ] Create `.gitignore` file
- [ ] Create GitHub private repository
- [ ] Add GitHub as remote: `git remote add origin ...`
- [ ] Push initial vault to GitHub
- [ ] Create Gitea repository (if desired)
- [ ] Add Gitea as secondary remote
- [ ] Create `pushall` alias
- [ ] Test push to both remotes
- [ ] Verify vault is accessible on GitHub web

### Phase 4: MkDocs Setup (30 minutes)
- [ ] Create `mkdocs.yml` in vault root
- [ ] Add MkDocs service to `docker-compose.yml`
- [ ] Create folder: `/Volumes/docker/container_configs/mkdocs/`
- [ ] Clone vault to MkDocs folder:
  ```bash
  cd /Volumes/docker/container_configs/mkdocs/
  git clone ~/ObsidianVault obsidian-vault
  ```
- [ ] Start MkDocs container: `docker-compose up -d mkdocs-vault`
- [ ] Access web interface: `http://localhost:8085`
- [ ] Test on iPhone via Tailscale
- [ ] Test search functionality
- [ ] Verify dark mode works
- [ ] Test navigation between sections

### Phase 5: AnythingLLM Setup (1 hour)
- [ ] Add AnythingLLM service to `docker-compose.yml`
- [ ] Create folder: `/Volumes/docker/container_configs/anythingllm/`
- [ ] Start AnythingLLM: `docker-compose up -d anythingllm`
- [ ] Access web interface: `http://localhost:3003`
- [ ] Complete initial setup wizard
- [ ] Add Ollama connection: `http://host.docker.internal:11434`
- [ ] Add Anthropic API key (optional, for Claude)
- [ ] Create workspace: "Work Notes"
- [ ] Sync Obsidian vault to workspace
- [ ] Test queries:
  - [ ] "What projects am I working on?"
  - [ ] "Summarize my meeting notes from last week"
- [ ] Verify response quality
- [ ] Test different embedding models

### Phase 6: Podcast Stack Separation (1 hour)
- [ ] Create `docker-compose.podcast.yml`
- [ ] Move Open Notebook and OpenEDAI Speech to ephemeral file
- [ ] Update volume paths to point to Learning folder
- [ ] Update restart policy to `"no"` (ephemeral)
- [ ] Remove from main `docker-compose.yml`
- [ ] Test manual spin-up:
  ```bash
  docker-compose -f docker-compose.podcast.yml up -d
  ```
- [ ] Verify both containers start
- [ ] Wait for healthchecks
- [ ] Generate test podcast
- [ ] Verify MP3 in AudioBookShelf
- [ ] Test manual spin-down:
  ```bash
  docker-compose -f docker-compose.podcast.yml down
  ```
- [ ] Confirm containers removed
- [ ] Verify resources freed

### Phase 7: n8n Workflow Development (3-4 hours)

**Workflow 1: Git Sync (30 min)**
- [ ] Create scheduled workflow: 9am & 9pm
- [ ] Add Execute Command node: git pull
- [ ] Add Execute Command node: git add & commit
- [ ] Add Execute Command node: git pushall
- [ ] Add Notification node on error
- [ ] Test workflow execution
- [ ] Verify vault synced to GitHub

**Workflow 2: Plaud Transcript (1 hour)**
- [ ] Determine Plaud sync location
- [ ] Create file watcher trigger
- [ ] Add file read node
- [ ] Add text parsing node (extract date, title)
- [ ] Add Obsidian file creation node
- [ ] Test with sample transcript
- [ ] Verify meeting note created correctly
- [ ] Add git commit step
- [ ] Add notification step

**Workflow 3: Podcast Generation (2 hours)**
- [ ] Create scheduled trigger: 2pm daily
- [ ] Add grep command: check for #generate-podcast
- [ ] Add conditional: if tag found
- [ ] Add docker-compose up command
- [ ] Add healthcheck wait loop
- [ ] Add HTTP Request to Open Notebook API
- [ ] Add file polling for MP3
- [ ] Add AudioBookShelf scan trigger
- [ ] Add docker-compose down command
- [ ] Add tag removal from Obsidian file
- [ ] Add notification on completion
- [ ] Test full workflow end-to-end
- [ ] Verify orphan cleanup in Alpine script

**Workflow 4: Weekly Summary (30 min)**
- [ ] Create Sunday 8pm trigger
- [ ] Add node to collect daily journals
- [ ] Add AnythingLLM API call
- [ ] Add summary file creation
- [ ] Add git commit
- [ ] Add email notification
- [ ] Test with sample week

### Phase 8: Environment File Management (1 hour)
- [ ] Create `.env.template` files for all services
- [ ] Move actual `.env` files out of any Git repo
- [ ] Update `.gitignore` in docker-homelab repo
- [ ] Test that secrets are not in Git:
  ```bash
  git log --all -- .env  # Should show nothing
  ```
- [ ] Document setup process in README.md
- [ ] Create backup of .env files (encrypted USB or 1Password)
- [ ] Verify docker-compose still works with new .env locations

### Phase 9: Testing & Validation (2 hours)

**End-to-End Workflow Tests:**
- [ ] Create test project in Obsidian
- [ ] Add tasks with #this-week tags
- [ ] Verify tasks appear on Dashboard
- [ ] Check off task in project
- [ ] Verify Dashboard updates
- [ ] Create test meeting note
- [ ] Query AnythingLLM about meeting
- [ ] Create learning resource with #generate-podcast
- [ ] Trigger podcast workflow manually
- [ ] Verify MP3 in AudioBookShelf
- [ ] Listen to podcast quality
- [ ] Test git sync workflow
- [ ] Test from MacBook (if available)
- [ ] Test MkDocs on iPhone via Tailscale
- [ ] Test Apple Notes → Obsidian workflow

**Resource Monitoring:**
- [ ] Check memory usage before/after podcast generation
- [ ] Verify ephemeral stack actually stops
- [ ] Monitor Alpine utility health checks
- [ ] Check Docker logs for any errors
- [ ] Verify no orphaned containers after 24 hours

### Phase 10: Documentation & Backup (1 hour)
- [ ] Update README.md with full setup instructions
- [ ] Document all n8n workflows (export JSON)
- [ ] Create disaster recovery plan
- [ ] Backup Gitea repositories
- [ ] Backup .env files (encrypted)
- [ ] Document daily workflow process
- [ ] Create quick reference guide for mobile access
- [ ] Share this plan with future self (save in Obsidian!)

---

## Estimated Total Setup Time: 15-20 hours
(Spread over several days, can pause between phases)

---

## Daily Usage After Setup

### Morning Routine (5 minutes)
1. Open Obsidian on Mac Mini
2. Dashboard.md loads → See today's tasks
3. Review yesterday's daily journal
4. Create today's journal from template
5. Coffee ☕

### During Work Day (Ongoing)
- Work on tasks, check off in project files
- Meetings → Plaud records → n8n auto-processes
- Need info? Ask AnythingLLM
- Update daily journal as you work

### Evening Routine (5 minutes)
1. Update daily journal with accomplishments
2. Check tomorrow's Dashboard preview
3. (Optional) Manual git push or let n8n handle it
4. Done ✓

### Weekly Routine (Sunday, 15 minutes)
1. Review week via weekly summary (auto-generated)
2. Plan next week's Weekly Focus goals
3. Update any project statuses
4. Generate study podcasts for upcoming week if needed

---

## Key Principles (Remember These!)

1. **Obsidian is the single source of truth**
   - All notes, tasks, projects live here
   - Dashboard aggregates via queries
   - No duplication

2. **Tasks live in context**
   - Task in project file, not separate task manager
   - Dashboard pulls them in dynamically
   - Check off in project, Dashboard updates

3. **Git is your safety net**
   - Regular commits to GitHub (cloud backup)
   - Gitea for local/fast access
   - Never lose data

4. **Mobile is read-only (mostly)**
   - MkDocs for reference via Tailscale
   - Apple Notes for quick capture
   - Process captures back to Obsidian

5. **AI is your assistant, not your memory**
   - AnythingLLM for querying vault
   - Open Notebook for learning podcasts
   - Obsidian stores the actual data

6. **Ephemeral workloads save resources**
   - Podcast generation only when needed
   - 10GB freed 23.5 hours/day
   - More room for other services

7. **Automation reduces friction**
   - n8n handles repetitive tasks
   - Git sync automated
   - Podcast generation automated
   - You focus on actual work

8. **Everything is self-hosted**
   - Your data stays local
   - GitHub is backup, not primary
   - Control your infrastructure

---

## Troubleshooting Guide

### Obsidian Dashboard Not Showing Tasks
**Problem:** Dataview queries show no results

**Solutions:**
- Verify Dataview plugin is installed and enabled
- Check task format: `- [ ]` with space after brackets
- Verify tags are present: `#this-week`, `#deadline`, etc.
- Test query in separate note to isolate issue
- Check Dataview syntax: ``` after TASK, not inside

### Git Conflicts on Sync
**Problem:** `git pull` shows conflicts

**Solutions:**
```bash
# Option 1: Accept remote version (GitHub/MacBook)
git pull --strategy=recursive --strategy-option=theirs origin main

# Option 2: Accept local version (Mac Mini)
git pull --strategy=recursive --strategy-option=ours origin main

# Option 3: Manual merge
git mergetool
# Resolve conflicts in editor
git commit
```

### Open Notebook Won't Generate Podcast
**Problem:** Podcast generation fails or times out

**Solutions:**
- Check Open Notebook logs: `docker logs open-notebook-ephemeral`
- Verify OpenEDAI Speech is running: `docker ps`
- Test TTS manually: `curl http://localhost:8000/v1/models`
- Check API key in `.env.open-notebook`
- Verify URLs in learning file are accessible
- Try smaller content (URLs may be timing out)

### AnythingLLM Not Finding Notes
**Problem:** Queries return no results

**Solutions:**
- Check Obsidian vault is mounted: `docker exec anythingllm ls /obsidian`
- Verify workspace is synced: Re-sync in UI
- Check embedding model is running
- Wait for initial indexing (can take 5-10 minutes)
- Try re-creating workspace

### MkDocs Not Updating
**Problem:** Changes in Obsidian not showing on mobile

**Solutions:**
```bash
# Pull latest changes to MkDocs folder
cd /Volumes/docker/container_configs/mkdocs/obsidian-vault
git pull origin main

# Restart MkDocs container
docker restart mkdocs-vault
```

### n8n Workflow Failing
**Problem:** Workflow shows errors

**Solutions:**
- Check n8n execution log for specific error
- Verify paths exist: `/Users/bud/ObsidianVault`, etc.
- Check file permissions (Docker needs read access)
- Test individual nodes in isolation
- Verify API endpoints are accessible: `curl http://localhost:5055`

### Podcast Stack Orphaned
**Problem:** Containers still running after generation

**Solutions:**
```bash
# Manual cleanup
docker-compose -f docker-compose.podcast.yml down

# Check Alpine utility script is running
docker logs alpine-utility

# Verify healthcheck script has orphan cleanup code
```

### iPhone Can't Access MkDocs
**Problem:** Can't connect via Tailscale

**Solutions:**
- Verify Tailscale is connected on iPhone
- Check Tailscale IP: `tailscale status` on Mac Mini
- Try Mac Mini hostname: `http://homelab-docker:8085`
- Verify MkDocs container is running: `docker ps | grep mkdocs`
- Check firewall: Allow port 8085
- Test from Mac Mini first: `curl http://localhost:8085`

---

## Future Enhancements (Ideas for Later)

### Phase 2 Features (After 1-2 months of use)
- [ ] Obsidian publish to personal website (MkDocs to static site)
- [ ] Automatic project template creation from meeting notes
- [ ] Calendar integration (read-only from work calendar API if available)
- [ ] Voice notes integration (Whisper STT → Obsidian)
- [ ] Automatic task prioritization (AI suggests focus)
- [ ] Spaced repetition for learning notes
- [ ] Graph view analysis (find disconnected notes)

### Advanced Automations
- [ ] Weekly code commit summary (if coding projects in Obsidian)
- [ ] Meeting prep generator (AI creates agenda from previous meetings)
- [ ] Automatic project archival (>3 months old, move to archive)
- [ ] Budget tracker integration (pull from your existing dashboard)
- [ ] Home Assistant integration (task completion triggers automations)
- [ ] Fitness tracking (workout logs → analysis)

### Mobile Improvements
- [ ] Shortcuts app integration (iOS quick capture → Obsidian)
- [ ] Siri integration ("Add task to AWS project")
- [ ] Widget for today's tasks
- [ ] Offline MkDocs (PWA with service worker)

---

## Comparison to Original Tools

### vs Notion
**Advantages:**
- ✅ Self-hosted (your data, your control)
- ✅ Local-first (works offline)
- ✅ Version control (Git history)
- ✅ Faster (no network latency)
- ✅ More privacy
- ✅ Customizable (plugins, themes)
- ✅ Markdown files (portable forever)

**Disadvantages:**
- ❌ More setup required
- ❌ No real-time collaboration
- ❌ No mobile editing (by design)
- ❌ Steeper learning curve

### vs NotebookLM
**Advantages:**
- ✅ Self-hosted (no Google)
- ✅ Uses your own LLMs (Ollama)
- ✅ Fully customizable
- ✅ On-demand (save resources)
- ✅ Multiple TTS voices available

**Disadvantages:**
- ❌ Podcast quality may not match Google's voices
- ❌ More manual setup
- ❌ Requires more technical knowledge

**Net Result:** Similar functionality, full control, privacy-focused.

---

## Success Metrics (After 1 Month)

### Productivity Indicators
- [ ] Using Dashboard daily as single source for tasks
- [ ] Daily journals consistently filled out
- [ ] All work projects documented in Obsidian
- [ ] 90%+ of meetings have transcript notes
- [ ] At least 2 study podcasts generated per week
- [ ] Zero lost notes (Git commits working)
- [ ] Mobile reference via MkDocs used weekly

### System Health
- [ ] Zero data loss incidents
- [ ] Git sync working automatically
- [ ] n8n workflows running reliably
- [ ] Podcast generation successful >90% of time
- [ ] No orphaned containers found
- [ ] System resource usage stable
- [ ] No manual intervention needed for automations

### Workflow Adoption
- [ ] Obsidian is default note-taking app
- [ ] Dashboard opened every morning
- [ ] AnythingLLM used multiple times per week
- [ ] Apple Notes inbox processed daily
- [ ] Performance review easier due to work logs

---

## Final Notes

This system is designed to:
1. Replace Notion and NotebookLM
2. Keep all your data self-hosted
3. Provide single dashboard for tasks
4. Generate study podcasts on-demand
5. Maintain comprehensive work history
6. Be accessible on phone (read-only)
7. Automate the boring stuff

**Remember:** 
- Start simple (Obsidian + Dashboard)
- Add features gradually
- Don't over-engineer before you know what you need
- The goal is productivity, not perfection

**When you start:**
- Test each phase before moving to next
- Document your changes
- Back up before major changes
- Ask Claude Code for help with specific implementations

**Most importantly:**
- This is YOUR system
- Customize it to YOUR workflow
- If something doesn't work, change it
- The plan is a guide, not a rulebook

Good luck! 🚀

---

*Last Updated: December 4, 2024*
*Status: Ready for implementation when back from re:Invent*
*Location: Las Vegas → Home (Texas)*
