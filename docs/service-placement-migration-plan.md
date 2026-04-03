# Service Placement Migration Plan

**Status**: Proposed
**Last Reviewed**: March 24, 2026

This document is the execution plan for moving critical services away from SMB-backed live database files and onto safer local-disk storage on the Synology NAS.

If this document conflicts with active runtime constraints, follow `AGENTS.md`, the root `README.md`, current service documentation, and vendor-supported migration procedures.

## Human Summary

What is changing:

- `Gitea`, `n8n`, `Karakeep`, and `PostgreSQL` move to the Synology
- live database storage moves off SMB and onto Synology local disk
- the Mac Mini stays focused on Plex, Ollama, and interactive compute

Why:

- SMB is the wrong place for live database files
- `Gitea` and `Karakeep` contain irreplaceable data
- the Synology is the best long-term always-on host

What matters most:

- `Gitea` and `Karakeep` are the highest priority
- `PostgreSQL` data must stay on Synology local disk
- `Meilisearch` must also move off SMB
- backups must be tested, not just created

Migration order:

1. Portainer on Synology
2. PostgreSQL on Synology local disk
3. test backups and restore
4. `n8n`
5. `Gitea`
6. `Karakeep`
7. `AudioBookShelf` decision

## Agent Reference

Use this file as the operational source of truth for:

- target host placement
- migration sequencing
- required validations
- rollback expectations
- backup requirements

## Goal

Move irreplaceable and database-backed services to a placement model that avoids SQLite or other database engine files living on SMB-mounted storage.

Primary goals:

- Protect `Gitea` and `Karakeep` as the two highest-priority systems of record
- Eliminate live database files on `/Volumes/...` SMB mounts
- Use Synology local disk for long-lived service state
- Keep service definitions and recovery steps portable across future hardware changes

## Scope

In scope for this migration:

- `postgres`
- `gitea`
- `n8n`
- `karakeep`
- `karakeep-meilisearch`
- `audiobookshelf` review and placement decision
- backup and restore runbooks for critical state

Out of scope for the initial migration:

- full `arr` stack modernization
- `Jackett` to `Prowlarr` migration
- moving all Synology containers into Portainer in one change window
- Mac Mini replacement planning
- UNAS 4 deployment

## Architectural Decision

### Approved Direction

- Run `PostgreSQL` on the Synology NAS
- Store PostgreSQL data on Synology local storage, not SMB
- Move `Gitea`, `n8n`, and likely `Karakeep` to run on the Synology
- Keep the Mac Mini focused on compute-heavy and interactive workloads such as Plex and Ollama

### Hard Rules

- No live database files on SMB-mounted paths
- No PostgreSQL `PGDATA` on SMB-mounted paths
- No Meilisearch data on SMB-mounted paths
- Irreplaceable services require tested backups before cutover
- Critical migrations are sequential, not parallel

## Target Placement

| Service | Target Host | Storage for Live State | Notes |
| --- | --- | --- | --- |
| PostgreSQL | Synology | Synology local disk | Shared DB for supported services |
| Gitea | Synology | PostgreSQL on Synology local disk; repo data on Synology local disk | Highest priority |
| n8n | Synology | PostgreSQL on Synology local disk | Keep workflow exports too |
| Karakeep | Synology | Synology local disk | Do not assume PostgreSQL support without vendor confirmation |
| Karakeep Meilisearch | Synology | Synology local disk | Must not stay on SMB |
| AudioBookShelf | TBD, likely Synology | Local disk for `/config` | Treat as file-backed until proven otherwise |

## Why Synology Is The Durable Host

- Always-on appliance model fits low-CPU and low-memory infrastructure services
- Critical data remains on the longest-lived platform in the homelab
- Future Mac Mini replacements become easier because system-of-record services do not depend on the active daily workstation
- Backups and snapshots can be centered around NAS-local storage instead of SMB client mounts

## Risks

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Data loss during migration | Medium | Critical | Full backup plus restore test before cutover |
| Unsupported DB backend for service | Medium | High | Validate official support before migration |
| Rollback failure after state divergence | Medium | High | Freeze writes, validate before reopening service |
| Portainer and Container Manager drift | Medium | Medium | Use one primary control plane per host |
| Meilisearch left on SMB | Medium | High | Move Meilisearch state to Synology local disk |
| Backup exists but restore fails | Medium | Critical | Mandatory test restore for Gitea and Karakeep |

## Migration Order

Recommended sequence:

1. Stand up Portainer on Synology
2. Stand up PostgreSQL on Synology local disk
3. Implement and test PostgreSQL backup and restore
4. Migrate `n8n` first as a lower-risk rehearsal
5. Migrate `Gitea`
6. Migrate `Karakeep` and `Karakeep Meilisearch`
7. Decide final placement for `AudioBookShelf`
8. Observe for 48 hours after each critical cutover

`Gitea` is more critical than `n8n`, but `n8n` is a safer first migration to validate the operating pattern. If you want the highest-value service fixed first, swap steps 4 and 5 and accept higher first-change risk.

## Detailed Work Plan

### Phase 1: Synology Control Plane

- Install Portainer on Synology
- Confirm Portainer and Synology Container Manager can coexist
- Decide Portainer is the primary management UI for new Synology-managed stacks
- Leave existing stable Synology services untouched during this phase

Exit criteria:

- Portainer reachable
- Admin access confirmed
- Existing Synology services remain healthy

### Phase 2: PostgreSQL Foundation

- Deploy PostgreSQL on Synology local storage
- Create dedicated databases and users for `Gitea` and `n8n`
- Set backup destination and retention policy
- Run a manual backup and a full test restore

Exit criteria:

- `pg_isready` healthy
- test database restore succeeds
- backup files are written to expected location

### Phase 3: n8n Migration

- Export workflows and credentials-related documentation
- Verify encryption key handling
- Back up current n8n state
- Reconfigure `n8n` to use PostgreSQL
- Start service and validate workflows

Validation:

- UI loads
- workflow list present
- credentials still decrypt correctly
- one manual workflow execution succeeds
- pruning errors stop

Rollback:

- stop `n8n`
- restore previous config
- restore original data
- restart on prior state

### Phase 4: Gitea Migration

- Take full backup of repositories, attachments, and current database state
- Confirm vendor-supported migration path for current Gitea version
- Repoint `Gitea` to PostgreSQL
- Validate repository operations before reopening normal use

Validation:

- web UI login works
- repository list is intact
- clone works
- push works
- issues/wiki/releases open correctly if used

Rollback:

- stop `Gitea`
- restore pre-cutover config
- restore data from tested backup set
- reopen only after validation

### Phase 5: Karakeep Migration

- Validate current Karakeep database support and storage model
- If still file-backed, move the full Karakeep stack to Synology local disk
- Move `Meilisearch` state to Synology local disk in the same phase
- Validate bookmark presence, search, and queued processing

Validation:

- login works
- bookmarks present
- search works
- new bookmark save works
- queued jobs complete

Rollback:

- restore prior Karakeep data directory
- restore prior Meilisearch data if needed
- restart stack and validate bookmark access

### Phase 6: AudioBookShelf Placement Decision

- Confirm whether official PostgreSQL support exists
- If not, move `/config` to Synology local disk and keep media paths separate
- Validate library visibility and playback metadata

## Backup Requirements

### Gitea

Required backups:

- PostgreSQL dump after migration
- repositories
- attachments and LFS if used
- app config

Required restore test:

- restore into a throwaway stack and confirm clone and login

### Karakeep

Required backups:

- primary Karakeep data directory
- Meilisearch data
- app config and secrets

Required restore test:

- restore into a throwaway stack and confirm bookmarks and search

### n8n

Required backups:

- PostgreSQL dump after migration
- exported workflows
- encryption key and required config

## Documentation Deliverables

During migration, update:

- `docs/services/inventory.md`
- `docs/services/synology-docker-config.md`
- `docs/restore.md`
- service-specific runbooks as needed

## Definition Of Done

The migration is complete when all of the following are true:

- `Gitea` and `Karakeep` no longer store live database state on SMB
- `n8n` no longer stores live database state on SMB
- PostgreSQL is running on Synology local disk
- Meilisearch state is on Synology local disk
- backups are automated
- restore tests have passed for `Gitea` and `Karakeep`
- documentation reflects the new source of truth
