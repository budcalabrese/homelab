# Synology Critical Services Runbook

**Status**: Proposed
**Last Reviewed**: March 24, 2026

This runbook covers the operational target for the critical service stack that will run on the Synology NAS.

Use this document during implementation, cutover, backup setup, and restore testing.

## Human Summary

This is the important part:

- `PostgreSQL`, `Gitea`, `n8n`, and `Karakeep` should run on the Synology
- all live database and search-engine files must be on Synology local disk
- `Gitea` and `Karakeep` are the highest-priority services to protect
- backups are only considered valid after a restore test succeeds

## Agent Reference

Use this file as the operational source of truth for:

- stack names
- expected storage paths
- backup paths
- repo script locations
- env variable mapping
- service validation checks
- cutover and rollback checklist

## Target Synology Stack

| Service | Role | Live State Location | Backup Requirement |
| --- | --- | --- | --- |
| `postgres` | shared relational database | Synology local disk | logical dump + restore test |
| `gitea` | git hosting and code backup | Synology local disk | DB dump + repos + config |
| `n8n` | automation control plane | PostgreSQL on Synology local disk | DB dump + workflow export + key backup |
| `karakeep` | bookmark manager | Synology local disk | data backup + restore test |
| `karakeep-meilisearch` | search index | Synology local disk | index backup if needed; rebuild if possible |
| `karakeep-chrome` | browser helper | ephemeral | no critical backup |

## Storage Rules

### Allowed On Synology Local Disk

- PostgreSQL `PGDATA`
- Gitea repositories and service data
- Karakeep app data
- Meilisearch data
- AudioBookShelf config if moved later

### Allowed On SMB Or Shared Storage

- exported backups
- media libraries
- large shared file collections
- non-live archival data

### Not Allowed On SMB

- SQLite database files
- PostgreSQL data directory
- Meilisearch data directory
- any app directory that contains active journal, WAL, or lock files

## Suggested Path Layout

These are the proposed standard paths for this homelab.

### Local Service State

```text
/volume1/docker/container_configs/postgres/data
/volume1/docker/container_configs/gitea
/volume1/docker/container_configs/n8n
/volume1/docker/container_configs/karakeep/data
/volume1/docker/container_configs/karakeep/meili_data
```

### Backup Output

```text
/volume1/backups/postgres
/volume1/backups/gitea
/volume1/backups/n8n
/volume1/backups/karakeep
```

### Proposed Stack Names

| Stack | Purpose |
| --- | --- |
| `infra-postgres` | PostgreSQL and optional admin-only helpers |
| `apps-gitea` | Gitea |
| `apps-n8n` | n8n |
| `apps-karakeep` | Karakeep, Meilisearch, and Chrome helper |

### Proposed Repo Script Locations

| Script | Planned Repo Location | Purpose |
| --- | --- | --- |
| PostgreSQL backup | `homelab/scripts/synology/backup_postgres.sh` | dump PostgreSQL databases to Synology backup path |
| PostgreSQL restore test | `homelab/scripts/synology/restore_test_postgres.sh` | restore a dump into a test database |
| Gitea backup | `homelab/scripts/synology/backup_gitea.sh` | back up Gitea repositories and config |
| Karakeep backup | `homelab/scripts/synology/backup_karakeep.sh` | back up Karakeep and Meilisearch state |

### Shared Environment Template

Planned template:

- `env/.env.synology-critical.template`

## Portainer Guidance

- Portainer can run alongside Synology Container Manager
- Do not use both tools as active managers for the same stack long-term
- New critical Synology-managed stacks should be created in Portainer
- Existing stable Synology media stacks can remain where they are until there is a separate migration reason

## Pre-Cutover Checklist

- [ ] Confirm service support for target backend and migration method
- [ ] Confirm Synology local path exists for live state
- [ ] Confirm backup destination exists
- [ ] Confirm enough free space for backups and restores
- [ ] Confirm credentials are stored outside the repo
- [ ] Confirm maintenance window and write freeze
- [ ] Confirm rollback steps are written down before changing production

## PostgreSQL Baseline

### Required Setup

- dedicated database per service
- dedicated user per service
- strong passwords stored outside git
- local Synology storage for `PGDATA`
- automated nightly logical backups

### Proposed Container Mapping

| Host Path | Container Path | Notes |
| --- | --- | --- |
| `/volume1/docker/container_configs/postgres/data` | `/var/lib/postgresql/data` | required local storage |
| `/volume1/backups/postgres` | `/backups` | dump destination |

### Environment Variable Map

| Variable | Value |
| --- | --- |
| `POSTGRES_USER` | `postgres` |
| `POSTGRES_PASSWORD` | from secrets/env |
| `POSTGRES_DB` | optional bootstrap DB only |

### Planned Databases

| Service | Database | User |
| --- | --- | --- |
| `gitea` | `gitea` | `gitea` |
| `n8n` | `n8n` | `n8n` |

### Minimum Backup Set

- `pg_dump -Fc` per database
- `pg_dumpall --globals-only` for roles and grants
- retention policy with multiple restore points

### Validation

- PostgreSQL starts cleanly
- `pg_isready` passes
- backup job writes expected files
- test restore completes successfully

## Gitea Runbook

### Criticality

`Gitea` is a top-priority service because it contains code backups and sensitive repositories.

### Required Backup Set

- PostgreSQL dump for the `gitea` database after migration
- repository data
- attachments, packages, and LFS data if used
- app configuration and secrets needed to start the service

### Proposed Container Mapping

| Host Path | Container Path | Notes |
| --- | --- | --- |
| `/volume1/docker/container_configs/gitea` | `/data` | keep on Synology local disk |

### Environment Variable Map

Recommended core database settings:

| Variable | Value |
| --- | --- |
| `GITEA__database__DB_TYPE` | `postgres` |
| `GITEA__database__HOST` | `postgres:5432` |
| `GITEA__database__NAME` | `gitea` |
| `GITEA__database__USER` | `gitea` |
| `GITEA__database__PASSWD` | from secrets/env |
| `GITEA__database__SSL_MODE` | `disable` on trusted local network unless TLS is configured |
| `USER_UID` | `501` unless changed for Synology runtime requirements |
| `USER_GID` | `20` unless changed for Synology runtime requirements |

Recommended service settings to confirm separately:

| Variable | Value |
| --- | --- |
| `GITEA__server__ROOT_URL` | Synology-accessible URL |
| `GITEA__server__SSH_DOMAIN` | Synology host or DNS name |
| `GITEA__server__SSH_PORT` | mapped SSH port |

### Cutover Checklist

- [ ] stop writes to Gitea
- [ ] take full pre-cutover backup
- [ ] verify backup files exist
- [ ] migrate to PostgreSQL using the vendor-supported path
- [ ] start Gitea
- [ ] validate login and repository access before reopening

### Validation

- [ ] web UI loads
- [ ] admin login works
- [ ] repositories are present
- [ ] clone works
- [ ] push works
- [ ] recent commits are visible

### Rollback

- stop Gitea
- restore previous config
- restore tested backup set
- validate clone and login before declaring rollback complete

## n8n Runbook

### Required Backup Set

- PostgreSQL dump for the `n8n` database after migration
- workflow exports
- encryption key and required config

### Proposed Container Mapping

| Host Path | Container Path | Notes |
| --- | --- | --- |
| `/volume1/docker/container_configs/n8n` | `/home/node/.n8n` | keep config and key on Synology local disk |

### Environment Variable Map

| Variable | Value |
| --- | --- |
| `DB_TYPE` | `postgresdb` |
| `DB_POSTGRESDB_HOST` | `postgres` |
| `DB_POSTGRESDB_PORT` | `5432` |
| `DB_POSTGRESDB_DATABASE` | `n8n` |
| `DB_POSTGRESDB_USER` | `n8n` |
| `DB_POSTGRESDB_PASSWORD` | from secrets/env |
| `N8N_ENCRYPTION_KEY` | existing secret from env |
| `N8N_HOST` | Synology-accessible host name |
| `N8N_PORT` | `5678` |
| `N8N_PROTOCOL` | `http` or `https` |
| `WEBHOOK_URL` | full external URL for callbacks |

### Cutover Checklist

- [ ] export workflows
- [ ] confirm encryption key is backed up
- [ ] stop n8n
- [ ] take backup
- [ ] repoint to PostgreSQL
- [ ] start and validate one manual workflow execution

### Validation

- [ ] UI loads
- [ ] workflows present
- [ ] credentials decrypt correctly
- [ ] manual workflow run succeeds
- [ ] pruning errors stop

## Karakeep Runbook

### Criticality

`Karakeep` is a top-priority service because bookmark data is hard or impossible to replace.

### Required Backup Set

- Karakeep primary data directory
- Meilisearch data directory
- app config and secrets

### Proposed Container Mapping

| Service | Host Path | Container Path |
| --- | --- | --- |
| `karakeep` | `/volume1/docker/container_configs/karakeep/data` | `/data` |
| `karakeep-meilisearch` | `/volume1/docker/container_configs/karakeep/meili_data` | `/meili_data` |

### Environment Variable Map

Karakeep:

| Variable | Value |
| --- | --- |
| `DATA_DIR` | `/data` |
| `MEILI_ADDR` | `http://meilisearch:7700` |
| `BROWSER_WEB_URL` | `http://chrome:9222` |
| `NEXTAUTH_SECRET` | from secrets/env |
| `OLLAMA_BASE_URL` | keep existing value if still using Mac-hosted Ollama |
| `INFERENCE_TEXT_MODEL` | existing configured model |
| `INFERENCE_IMAGE_MODEL` | existing configured model |
| `INFERENCE_LANG` | `en` unless changed |

Meilisearch:

| Variable | Value |
| --- | --- |
| `MEILI_MASTER_KEY` | from secrets/env |
| `MEILI_NO_ANALYTICS` | `true` |

### Cutover Checklist

- [ ] confirm current data path
- [ ] stop Karakeep stack
- [ ] back up Karakeep data and Meilisearch data
- [ ] move live data to Synology local disk
- [ ] start Meilisearch first
- [ ] start Karakeep
- [ ] validate bookmark and search behavior

### Validation

- [ ] login works
- [ ] bookmark count looks correct
- [ ] bookmarks open correctly
- [ ] search returns expected results
- [ ] new bookmark save works

### Rollback

- stop Karakeep stack
- restore prior Karakeep data
- restore prior Meilisearch data if required
- restart and verify bookmarks are present

## Backup Testing Standard

Backups are not complete until restore testing is performed.

Minimum standard:

- `Gitea`: restore into a throwaway environment and verify login, clone, and repository list
- `Karakeep`: restore into a throwaway environment and verify bookmarks and search
- `PostgreSQL`: restore at least one dump into a test database

## Cutover Sequence

Recommended order:

1. Portainer
2. PostgreSQL
3. backup automation
4. test restore
5. `n8n`
6. `Gitea`
7. `Karakeep`

## Open Decisions

- whether `AudioBookShelf` moves in the same project or a later one
- whether older Synology-managed media services are later migrated into Portainer

## Related Documentation

- [Service Placement Migration Plan](../service-placement-migration-plan.md)
- [Homelab Platform Target State](../planning/homelab-platform-target-state.md)
- [Synology NAS Docker Configuration](./synology-docker-config.md)
- [Restore Runbook](../restore.md)
