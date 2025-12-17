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

### Docker Container Services
- **[synology-docker-config.md](services/synology-docker-config.md)** - Synology NAS Container Manager configuration
  - Media server stack (Sonarr, Radarr, Jackett, etc.)
  - Deluge torrent client with plugins
  - Port mappings and volume mounts
  - Infrastructure-as-code documentation

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
- [CLAUDE.md](../CLAUDE.md) - Instructions for Claude Code sessions
- [Environment Templates](../env/) - `.env.*.template` files for service configuration

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

**Last Updated:** December 16, 2025
