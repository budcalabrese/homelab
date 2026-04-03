# Homelab Documentation

This directory contains comprehensive documentation for the homelab setup, organized by category.

## Documentation Structure

```
docs/
├── services/      Service configurations and workflows
├── hardware/      Physical device documentation
├── planning/      Strategic planning and architecture
├── api/          API documentation and references
└── README.md     This file
```

---

## Services

Configuration and workflow documentation for homelab services.

Only active services and active workflows should be documented here. Retired systems should be removed instead of kept alongside current operations docs.

### Docker Container Services
- **[synology-docker-config.md](services/synology-docker-config.md)** - Synology NAS Container Manager configuration
  - Media server stack (Sonarr, Radarr, Jackett, etc.)
  - Deluge torrent client with plugins
  - Port mappings and volume mounts
  - Infrastructure-as-code documentation
- **[synology-critical-services-runbook.md](services/synology-critical-services-runbook.md)** - Operational runbook for critical Synology-hosted services
  - PostgreSQL, Gitea, n8n, and Karakeep
  - storage rules and backup requirements
  - cutover and rollback checklist
- **[inventory.md](services/inventory.md)** - Service inventory (ports, paths, dependencies)
- **[../service-placement-migration-plan.md](service-placement-migration-plan.md)** - Migration plan for moving critical database-backed services to Synology local storage
  - PostgreSQL on Synology local disk
  - Gitea, n8n, and Karakeep placement
  - backup and restore requirements

### Automation Workflows
- **[karakeep-podcast-workflow.md](services/karakeep-podcast-workflow.md)** - Automated bookmark-to-podcast workflow
  - Complete system architecture
  - n8n workflow design (opt-in with `#consume` tag)
  - Open Notebook integration
  - AudioBookShelf setup
  - Lifecycle management (capture → podcast → cleanup)

- **[open-notebook-setup.md](services/open-notebook-setup.md)** - Complete Open Notebook configuration with local AI models
  - Qwen2.5 for text generation
  - OpenEDAI Speech for TTS
  - Custom profiles for fully local podcast generation
  - Performance metrics and troubleshooting

### Architecture Diagrams
- **[media-streaming-architecture.png](services/media-streaming-architecture.png)** - Home media streaming service architecture diagram

---

## Hardware

Physical device documentation and setup procedures.

- **[smart-home-devices.md](hardware/smart-home-devices.md)** - Smart home device configurations
  - THIRDREALITY Zigbee smart bulbs (factory reset procedures)
  - IKEA TRADFRI light bulbs (factory reset procedures)

---

## Planning

Strategic planning documents and architecture decisions.

- **[buds-productivity-system-plan.md](planning/buds-productivity-system-plan.md)** - Overall productivity system design and workflow planning
- **[github-repo-structure-plan.md](planning/github-repo-structure-plan.md)** - Repository structure and organization plan
- **[homelab-platform-target-state.md](planning/homelab-platform-target-state.md)** - Long-term host placement and infrastructure direction
  - Synology as durable service host
  - Mac Minis as compute nodes
  - UNAS 4 as secondary backup target
- **[synology-migration-implementation-backlog.md](planning/synology-migration-implementation-backlog.md)** - Ordered implementation backlog for Synology migration
  - Phase 0 blockers
  - foundation, backup, rehearsal, and cutover sequencing

---

## API

API documentation and reference materials.

- **[karakeep-api-reference.md](api/karakeep-api-reference.md)** - Karakeep REST API documentation
  - Authentication
  - Bookmark endpoints (CRUD operations)
  - Tag management
  - Search and filtering
  - Code examples

---

## Quick Links

### Setup Documentation
- [Main README](../README.md) - Homelab overview and quick start
- [Environment Templates](../env/) - `.env.*.template` files for service configuration

### Operations
- [Restore Runbook](restore.md) - Step-by-step restore guide
- [Phase 0 Blockers](phase-0-blockers.md) - Pre-execution gate for Synology critical-services migration

### Configuration Files
- [compose.yml](../compose.yml) - Docker Compose configuration for all services
- [Scripts](../scripts/) - Helper scripts for common tasks

---

## Documentation Standards

All documentation follows these conventions:
- Markdown format with GitHub-flavored syntax
- Code examples with syntax highlighting
- Clear section headers for easy navigation
- Links to related documentation
- Last updated dates and version info
- Troubleshooting sections where applicable

---

**Last Updated:** March 24, 2026
