# Bud's Productivity System

Self-hosted system for task management, knowledge management, learning, and work tracking.

## The Stack

| Service | Purpose | Where |
|---------|---------|-------|
| Obsidian | Notes, tasks, journals, projects | Mac Mini + GitHub |
| n8n | Automation | Docker |
| Gitea | Local Git server | Docker |
| AudioBookShelf | Podcast library | Docker |
| Open WebUI | Chat with Ollama | Docker |
| Ollama | Local LLM | Mac Mini (native) |
| Open Notebook | Podcast generator | Docker |
| OpenEDAI Speech | TTS for podcasts | Docker |
| Tailscale | Remote access | Docker |

---

## Obsidian Vault Structure

```
ObsidianVault/
├── Dashboard.md              ← Homepage (Notion-style weekly view)
├── Daily Notes/
│   └── YYYY-MM-DD.md         (unified — work + personal + homelab)
├── Projects/
│   ├── Work/
│   └── Personal/
├── Meetings/
│   ├── Work/
│   └── Personal/
├── Learning/
│   └── [Topic]/
│       └── resources.md      (add #generate-podcast to trigger podcast)
└── Templates/
    ├── Daily Note.md
    ├── Project.md
    └── Meeting.md
```

---

## Tag System

Three primary tags for all tasks/content:

- `#work` — Professional tasks, AWS projects, certifications, work deadlines
- `#personal` — Fitness, errands, appointments, personal life
- `#home` — Homelab, Docker, infrastructure, home improvements

**Principle:** Daily Notes stay unified (all categories mixed). Projects and Meetings are organized into Work/Personal subfolders. Dashboard Dataview queries pull tasks by tag regardless of location.

**Special tags:**
- `#this-week monday/tuesday/...` — Appears on Dashboard for that day
- `#weekly-focus` — Appears in Weekly Focus section
- `#deadline` — Appears in Deadlines section
- `#side-quest` — Low-priority backlog
- `#generate-podcast` — Triggers Open Notebook podcast generation for that file

---

## Dashboard Layout (Dashboard.md)

```markdown
# THIS WEEK
## MONDAY / TUESDAY / ... (manual tasks + #this-week queries)

## DEADLINES
```dataview TASK WHERE contains(text, "#deadline")```

## WORK TASKS
```dataview TASK WHERE contains(text, "#work") AND !completed```

## PERSONAL TASKS / HOMELAB TASKS
(similar Dataview queries)

## WEEKLY FOCUS / SIDE QUESTS (manual sections)

## ACTIVE WORK PROJECTS / ACTIVE PERSONAL PROJECTS
(Dataview TABLE from Projects/ WHERE status = "In Progress")
```

**Required plugins:** Dataview, Tasks, Calendar, Templater

---

## Templates

### Project File
```markdown
# [Project Name] - [Quarter/Year]
**Type**: Work | Personal | Homelab
**Status**: Planning | In Progress | On Hold | Completed
**Tags**: #work | #personal | #home

## Overview
## Related Meetings
## Tasks
- [ ] Task #work #this-week monday
## Research Notes
## Architecture/Design
## Timeline
```

### Daily Note
```markdown
# {{date:YYYY-MM-DD}}
## Work / ## Personal / ## Homelab / ## Tomorrow / ## Links
```

### Meeting Note
```markdown
# [Topic] - {{date:YYYY-MM-DD}}
**Type**: Work | Personal
## Attendees / ## Key Takeaways / ## Action Items / ## Transcript / ## Related
```

---

## Core Workflows

### Daily Work
- Morning: Open Dashboard.md → see today's tasks
- During day: Meetings auto-captured via Plaud Note → n8n → Obsidian
- Evening: Update journal, check off tasks, git push

### Learning + Podcast Generation
1. Create `Learning/[Topic]/resources.md` with study URLs and add `#generate-podcast`
2. n8n detects tag → calls Open Notebook API → MP3 lands in AudioBookShelf
3. Listen during gym/commute

---

## Git Sync Strategy

### Obsidian Vault
- **Primary remote**: GitHub (cloud backup, accessible anywhere)
- **Secondary remote**: Gitea (local, faster on LAN)

```bash
git remote add origin git@github.com:budcalabrese/obsidian-vault.git
git remote add gitea ssh://git@localhost:2222/bud/obsidian-vault.git
git config alias.pushall '!git push origin main && git push gitea main'
```

**Sync script** (`~/sync-obsidian.sh`):
```bash
#!/bin/bash
cd ~/ObsidianVault
git pull origin main && git add . && git commit -m "Auto-sync: $(date +%Y-%m-%d)" && git pushall
```

### iPhone (Mobile Capture)
- Quick capture → Apple Notes with `#obsidian-inbox` tag → process next day on Mac
- Read-only reference → MkDocs via Tailscale (`http://192.168.0.9:8085`)
- Fallback → GitHub web interface

### Docker Configs
- Committed to Gitea: `compose.yml`, `.env.*.template`, scripts
- Never committed: actual `.env` files (stored in `homelab-secrets` Gitea repo)
