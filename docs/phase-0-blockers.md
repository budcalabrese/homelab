# Phase 0 Blockers

**Status**: Open
**Last Reviewed**: March 24, 2026

This document is the execution gate for the Synology critical-services migration.

Do not start production migration work until every blocker in this file is resolved.

## Human Summary

Before doing any migration:

1. confirm how `Karakeep` stores data
2. locate and preserve the current `n8n` encryption key
3. create the Synology PostgreSQL stack and shared network
4. create backup and restore-test scripts
5. document and rehearse the `Gitea` migration
6. validate Synology paths, permissions, and service connectivity

If any of these are incomplete, the migration is not ready.

## Blockers

### 1. Karakeep Storage Model Must Be Confirmed

Why this blocks execution:

- the current plan assumes `Karakeep` may remain file-backed
- if that assumption is wrong or incomplete, the migration plan will drift mid-cutover

Required output:

- documented answer on whether `Karakeep` supports PostgreSQL for the current deployment path
- if not, explicit plan for moving `Karakeep` and `Meilisearch` state to Synology local disk

### 2. n8n Encryption Key Must Be Located And Preserved

Why this blocks execution:

- if the current `N8N_ENCRYPTION_KEY` is lost, credentials may not decrypt after migration

Required output:

- current key location identified
- key copied into the Synology migration secret set
- decryption tested after migration rehearsal

### 3. Synology PostgreSQL Stack Must Exist

Why this blocks execution:

- the current repo has planning docs but no actual Synology PostgreSQL stack definition

Required output:

- stack YAML or equivalent Portainer stack definition
- shared Docker network plan
- local Synology path mappings
- database initialization plan for `gitea` and `n8n`

### 4. Backup And Restore-Test Scripts Must Exist

Why this blocks execution:

- the runbook references backup and restore automation that does not yet exist
- backup quality is unproven until a restore test passes

Required output:

- PostgreSQL backup script
- PostgreSQL restore-test script
- Gitea backup script
- Karakeep backup script
- at least one successful restore test

### 5. Gitea Migration Procedure Must Be Documented And Rehearsed

Why this blocks execution:

- `Gitea` is one of the two highest-priority services
- the current plan identifies the target backend but not the exact migration commands

Required output:

- vendor-supported migration path confirmed for current Gitea version
- step-by-step migration commands documented
- throwaway migration rehearsal completed successfully

### 6. Synology Paths, Permissions, And Connectivity Must Be Validated

Why this blocks execution:

- the docs now define standard paths, but the live Synology host must match them
- cross-stack communication and file permissions can still fail even with the right design

Required output:

- Synology path structure created and verified
- permission model verified for target containers
- shared network verified
- connectivity tested between services

## Exit Criteria

Phase 0 is complete when:

- all six blockers are resolved
- the outputs are documented in the repo
- at least one restore test has succeeded
- the migration still matches the target-state plan

## Related Documentation

- [Service Placement Migration Plan](./service-placement-migration-plan.md)
- [Homelab Platform Target State](./planning/homelab-platform-target-state.md)
- [Synology Critical Services Runbook](./services/synology-critical-services-runbook.md)
