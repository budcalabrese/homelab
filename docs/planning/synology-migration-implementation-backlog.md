# Synology Migration Implementation Backlog

**Status**: Planning
**Last Reviewed**: March 24, 2026

This document converts the Synology migration plan into a concrete execution backlog.

Use it to sequence implementation work before production cutover.

## Human Summary

This is the order to work in:

1. resolve Phase 0 blockers
2. build the Synology PostgreSQL foundation
3. build and test backups
4. rehearse migrations
5. migrate `n8n`
6. migrate `Gitea`
7. migrate `Karakeep`

## Backlog

### Phase 0 - Blockers

1. Confirm `Karakeep` storage/backend behavior
2. Locate and preserve the current `N8N_ENCRYPTION_KEY`
3. Create Synology PostgreSQL stack definition
4. Create shared Docker network plan
5. Create backup and restore-test scripts
6. Document and rehearse `Gitea` migration
7. Validate Synology paths and permissions
8. Validate service-to-service connectivity

### Phase 1 - Synology Foundation

1. Install and document Portainer on Synology
2. Create Synology local path structure under `/volume1/docker/container_configs`
3. Create backup path structure under `/volume1/backups`
4. Deploy PostgreSQL on Synology local disk
5. Create `gitea` and `n8n` databases and users
6. Verify health and network access

### Phase 2 - Backup Implementation

1. Implement PostgreSQL dump automation
2. Implement PostgreSQL restore-test automation
3. Implement Gitea data backup automation
4. Implement Karakeep data backup automation
5. Define retention policy
6. run at least one full restore test

### Phase 3 - Migration Rehearsal

1. Rehearse `n8n` migration on non-production data or a copied dataset
2. Rehearse `Gitea` migration on a throwaway instance
3. Rehearse `Karakeep` relocation to Synology local disk
4. validate rollback for at least one service

### Phase 4 - Production Migration

1. Migrate `n8n`
2. validate `n8n`
3. Migrate `Gitea`
4. validate `Gitea`
5. Migrate `Karakeep`
6. validate `Karakeep`

### Phase 5 - Post-Cutover

1. Monitor for 48 hours after each critical migration
2. Update service inventory and restore docs
3. Decide `AudioBookShelf` final placement
4. Decide whether older Synology workloads should later move into Portainer

## Priority Notes

- `Gitea` and `Karakeep` are the most important data-protection targets
- `n8n` is the safest first migration to validate the operating model
- `AudioBookShelf` is important but should not block fixing the higher-risk critical services

## Definition Of Ready

Do not begin production migration until:

- [Phase 0 Blockers](../phase-0-blockers.md) are closed
- PostgreSQL stack is deployed on Synology local disk
- backups exist and at least one restore test has passed
- migration steps are documented per service

## Related Documentation

- [Phase 0 Blockers](../phase-0-blockers.md)
- [Service Placement Migration Plan](../service-placement-migration-plan.md)
- [Synology Critical Services Runbook](../services/synology-critical-services-runbook.md)
