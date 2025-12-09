# Homelab Documentation

This directory contains comprehensive documentation for the homelab setup and workflows.

## Documentation Overview

### System Architecture & Planning

- **[buds-productivity-system-plan.md](buds-productivity-system-plan.md)** - Overall productivity system design and workflow planning
- **[github-repo-structure-plan.md](github-repo-structure-plan.md)** - Repository structure and organization plan

### Application Setup Guides

- **[open-notebook-setup.md](open-notebook-setup.md)** - Complete Open Notebook configuration with local AI models
  - Qwen2.5 for text generation
  - OpenEDAI Speech for TTS
  - Custom profiles for fully local podcast generation
  - Performance metrics and troubleshooting

- **[karakeep-api-reference.md](karakeep-api-reference.md)** - Karakeep REST API documentation
  - Authentication
  - Bookmark endpoints (CRUD operations)
  - Tag management
  - Search and filtering
  - Code examples

### Workflow Documentation

- **[karakeep-podcast-workflow.md](karakeep-podcast-workflow.md)** - Automated bookmark-to-podcast workflow
  - Complete system architecture
  - n8n workflow design
  - Open Notebook integration
  - AudioBookShelf setup
  - Lifecycle management (capture → podcast → cleanup)

## Quick Links

### Setup Documentation
- [Main README](../README.md) - Homelab overview and quick start
- [CLAUDE.md](../CLAUDE.md) - Instructions for Claude Code sessions
- [Environment Templates](../) - `.env.*.template` files for service configuration

### Configuration Files
- [compose.yml](../compose.yml) - Docker Compose configuration for all services
- [Scripts](../scripts/) - Helper scripts for common tasks

## Documentation Standards

All documentation follows these conventions:
- Markdown format with GitHub-flavored syntax
- Code examples with syntax highlighting
- Clear section headers for easy navigation
- Links to related documentation
- Last updated dates and version info
- Troubleshooting sections where applicable

---

**Last Updated:** December 8, 2024
