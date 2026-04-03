# Homelab Platform Target State

**Status**: Planning
**Last Reviewed**: March 24, 2026

This document describes the intended platform layout for the homelab over the next hardware refresh cycle.

If it conflicts with active repo instructions or current runtime needs, follow `AGENTS.md`, the root `README.md`, and the active migration runbooks.

## Human Summary

Simple version:

- `Synology` is the long-term home for critical services and durable state
- `Mac Mini M4` stays useful for Plex, Ollama, and current compute workloads
- `Mac Mini M5` will become a newer AI and compute node when added
- `UNAS 4` is planned as a second backup and storage target, not the primary fix for the current issue

Design rule:

- live database files go on local disk where the service runs
- SMB is for shared files, backups, and bulk storage, not active database state

Target direction:

- critical apps on Synology
- compute-heavy apps on Macs
- secondary backups on UNAS 4

## Agent Reference

Use this file as the planning source of truth for:

- long-term host roles
- future migration decisions
- storage placement rules
- backup strategy direction
- hardware refresh assumptions

## Planning Horizon

- Current: Synology NAS + Mac Mini M4
- Next planned addition: Mac Mini M5 around June 2026
- Later planned addition: Ubiquiti UNAS 4 around October to December 2026

## Planning Goals

- Keep critical state on the longest-lived infrastructure
- Separate system-of-record workloads from interactive daily-use compute
- Improve backup depth with a second storage target
- Preserve portability through documented deployment and restore workflows

## Role Of Each Platform

### Synology NAS

Primary role:

- always-on infrastructure host
- durable storage host
- home for critical low-resource applications

Preferred workloads:

- PostgreSQL
- Gitea
- n8n
- Karakeep
- AudioBookShelf if still file-backed
- existing media automation stack
- Syncthing

Storage rules:

- local Synology disk for live app state and database engine data
- exports, snapshots, and backups managed from Synology

### Mac Mini M4

Primary role:

- current interactive compute host
- local AI and media-serving host

Preferred workloads:

- Plex
- Ollama
- development services
- temporary experimentation workloads

Avoid:

- making the M4 the long-term system of record for irreplaceable data

### Future Mac Mini M5

Primary role:

- newer AI and compute node
- hardware acceleration target for newer local model workflows

Preferred workloads:

- Ollama or successor model-serving stack
- local AI inference workloads
- experimental and high-performance automation tasks

Avoid:

- tying irreplaceable homelab data to an easily replaceable workstation-class host

### Future UNAS 4

Primary role:

- secondary storage target
- backup destination for Synology
- secondary file store for sensitive data

Expected usage:

- receive backups from Synology
- provide additional capacity as the media archive grows
- reduce single-device backup risk

Notes:

- do not treat the initial UNAS 4 deployment as the primary fix for current database corruption
- use it to improve resilience after the platform placement work is complete

## Target Service Placement

| Service Group | Preferred Host | Reason |
| --- | --- | --- |
| Critical Git and bookmarks | Synology | Long-lived, always-on, local-disk state |
| Automation control plane | Synology | Better fit than daily workstation |
| Media download stack | Synology | Already aligned with NAS-local storage |
| AI/model serving | Mac Mini M4 or M5 | Better CPU/GPU and memory profile |
| Plex and related playback services | Mac Mini | Existing fit and user-facing performance |
| Backup target storage | UNAS 4 | Secondary copy and capacity expansion |

## Management Philosophy

### Synology

- Use Portainer as the primary management UI for new and migrated Synology stacks
- Avoid long-term dual management of the same services in both Portainer and Synology Container Manager
- Migrate older Synology services into Portainer gradually and only when there is a clear payoff

### Mac Hosts

- Keep Docker Compose as the source of truth for Mac-hosted workloads
- Treat the Macs as replaceable compute nodes rather than the permanent state anchor

## Backup Philosophy

- Critical services require both backup automation and tested restore procedures
- PostgreSQL backups should be logical dumps with retention
- File-backed critical apps require application data backups plus restore validation
- The long-term goal is at least two independent backup targets for critical data

## Design Principles

- Live database files must not sit on SMB-mounted paths
- Portability comes from infrastructure-as-code and restore documentation, not from moving raw live database directories between hosts
- Critical data belongs on the host expected to remain in service the longest
- Host refreshes should be operational events, not disaster recovery events

## Known Future Projects

- migrate critical database-backed services to Synology local storage
- standardize Synology stack management in Portainer
- review `Jackett` to `Prowlarr` migration as a separate project
- introduce UNAS 4 as secondary backup target
- reassess backup retention once UNAS 4 is online

## Success Criteria

- Synology becomes the durable platform for irreplaceable services
- Mac Minis become portable compute nodes
- database corruption risk from SMB-mounted live state is removed
- a second backup target exists for critical data
- service placement is documented clearly enough to support future migrations
