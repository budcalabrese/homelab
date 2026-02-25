# Homelab Audit Notes

**Date**: February 20, 2026
**Status**: All critical work complete ✅

---

## Work Completed

### Phase 1: Data Integrity
- Fixed invalid exception handling in budget app
- Implemented atomic JSON writes (budget + learning apps)
- Added error recovery to learning app
- **Commits**: 6fbefc1

### Phase 2: Backup Script Robustness
- Added strict mode (`set -euo pipefail`) to all 5 backup scripts
- Implemented mutual exclusion locks
- Added disk space prechecks
- Fixed Karakeep deletion pattern
- Fixed GF script schema (needs/wants)
- **Commits**: a1a4f32

### Phase 3: Documentation & Services
- Updated n8n SSH documentation
- Synced port table (added garage-tracker, victoria-logs)
- Activated Centralized Error Notification workflow
- Added timeout to transcript API
- **Commits**: c9df57a, 1f7de2e

### Verification & Hardening (ChatGPT Follow-up)
- **CRITICAL**: Fixed trap override bug in gitea/garage backups
- Added temp file cleanup on error (both Python apps)
- Added directory creation to budget app
- **Commits**: Pending (Friday end-of-day)

---

## Next Steps for Monday (ChatGPT)

### Starting Point

All critical and high-priority fixes are complete. The homelab is stable and secure.

### Recommended Next Audits

**Pick ONE area to focus on:**

1. **Backup Verification** (Most Valuable)
   - Implement automated backup testing (restore to temp location, validate)
   - Add backup health monitoring dashboard
   - Review retention periods (7-day Karakeep, 30-day Gitea/Garage optimal?)

2. **Service Health Monitoring** (Operational Excellence)
   - Prioritize which 11 services need health checks most
   - Design health check commands per service
   - Consider monitoring dashboard beyond docker-monitor.sh

3. **n8n Workflow Cleanup** (Technical Debt)
   - Replace deprecated `executeCommand` nodes with SSH nodes
   - Standardize error handling across all workflows
   - Review cron expressions for edge cases

4. **Security Hardening** (Defense in Depth)
   - Audit Docker network isolation
   - Review n8n credential rotation strategy
   - Check for exposed endpoints that should be restricted

5. **Code Quality** (Developer Experience)
   - Create shared JSON utility library for Python apps
   - Standardize logging patterns
   - Review Docker image pinning strategy

### Optional Low-Priority Items

- Add health checks to 11 services (deferred - containers stable)
- Dynamic disk space thresholds (current static values work fine)
- Replace hardcoded IPs in workflows (wait for DNS implementation)

---

## Files Modified This Session

### Homelab Repo
- `alpine-utility/scripts/export_karakeep_backup.sh`
- `alpine-utility/scripts/export_monthly_snapshot.sh`
- `alpine-utility/scripts/export_monthly_snapshot_gf.sh`
- `alpine-utility/scripts/export_gitea_backup.sh` (trap fix pending commit)
- `alpine-utility/scripts/export_garage_backup.sh` (trap fix pending commit)
- `n8n-workflows/README.md`
- `n8n-workflows/Centralized Error Notification.json`
- `README.md`
- `docs/audit_notes.md`

### Coding Repo
- `python-budget-tracker/budget_dashboard_streamlit.py` (hardening pending commit)
- `python-learning-dashboard/python-learning-dashboard.py` (hardening pending commit)
- `youtube-transcripts-api/youtube-transcripts-api.py`

---

**Token Usage**: 48% (98k/200k remaining)
**End of Day**: Friday, February 20, 2026

---

## Follow-Up Audit: Backup Verification Deep Dive

**Date**: February 25, 2026  
**Scope**: `alpine-utility/scripts/*backup*.sh`, monthly snapshot scripts, backup workflows, restore docs

### 1) Current Backup Strategy Review (5 active backup/export scripts)

1. `alpine-utility/scripts/export_karakeep_backup.sh`
   - Full directory copy from `/mnt/karakeep` to `/mnt/backups/karakeep` with lock and disk precheck.
   - Retention implemented as count-based cleanup (`tail -n +8`), described as "last 7 backups" (`alpine-utility/scripts/export_karakeep_backup.sh:65`).
2. `alpine-utility/scripts/export_gitea_backup.sh`
   - Stops container, copies SQLite DB, zips repositories, restarts container in trap.
   - Retention implemented by keeping latest 30 files per artifact type (`alpine-utility/scripts/export_gitea_backup.sh:85`, `alpine-utility/scripts/export_gitea_backup.sh:90`).
3. `alpine-utility/scripts/export_garage_backup.sh`
   - Stops container, copies SQLite DB, restarts via trap.
   - Retention implemented by keeping latest 30 files (`alpine-utility/scripts/export_garage_backup.sh:70`).
4. `alpine-utility/scripts/export_monthly_snapshot.sh`
   - Exports budget JSON + CSV with lock and disk precheck.
   - No retention/pruning (indefinite accumulation by design).
5. `alpine-utility/scripts/export_monthly_snapshot_gf.sh`
   - Same pattern as main monthly snapshot; currently optional/inactive in workflow export.

Current storage footprint is small relative to capacity:
- `/Volumes/backups` is ~2% used (about 7.9 GiB used / 500 GiB total).
- Backup directories observed: gitea ~101M, karakeep ~43M, garage ~160K, budget ~116K.

### 2) Automated Backup Testing Approach (Recommended Design)

Add a new script: `alpine-utility/scripts/verify_backups.sh` and run daily after backups.

Proposed flow:
1. Create temp workspace under `/tmp/backup-verify/<timestamp>` with trap cleanup.
2. For each service, locate newest artifact and check freshness window.
3. Restore to temp location and verify integrity:
   - Gitea DB: `sqlite3 <db> "PRAGMA integrity_check;"` must return `ok`.
   - Gitea repos zip: `unzip -t` must pass.
   - Garage DB: `sqlite3 <db> "PRAGMA integrity_check;"` must return `ok`.
   - Karakeep: copy test + required file checks (and sqlite integrity if DB file exists).
   - Monthly budget artifacts: `jq empty` on JSON and minimum expected CSV header checks.
4. Emit machine-readable status JSON to `/mnt/backups/health/backup_verification_latest.json`.
5. Exit non-zero on any failed check so n8n/centralized error workflow can alert.

Why this matters:
- Current scripts prove "backup file was created," not "backup can be restored."
- A restore simulation is the fastest way to detect silent corruption early.

### 3) Retention Period Evaluation

Current policy:
- Karakeep: 7
- Gitea/Garage: 30
- Monthly snapshots: indefinite

Assessment and recommendation:
1. Karakeep 7-day retention is short for human-detected issues.
   - Recommend 14 days (or 21 if bookmarks are high-value).
2. Gitea 30 is reasonable.
   - Keep at 30; optionally add monthly immutable snapshot for repo history safety.
3. Garage 30 is acceptable but cheap to extend.
   - Recommend 45-60 days given tiny DB footprint.
4. Monthly snapshots indefinite is acceptable at current size.
   - Add annual archival/compression (or >5y prune) to avoid unbounded growth.

Implementation note:
- Scripts label retention as days, but cleanup is count-based (last N files). This is fine for daily jobs but should be documented explicitly to avoid false assumptions.

### 4) Backup Health Monitoring / Alerting

Recommended minimum monitoring stack:
1. New n8n workflow: `Backup Verification Daily`
   - Trigger: daily after backups (for example 05:15).
   - Action: SSH run `verify_backups.sh`.
   - Failure: route to centralized error notification + direct email summary.
2. Weekly summary workflow:
   - Read `backup_verification_latest.json` + recent history.
   - Email one compact status report: freshness, integrity, retention count, disk trend.
3. Optional dashboard:
   - Add a small Streamlit page or static HTML showing green/yellow/red per backup class.
   - Data source: JSON artifact in `/Volumes/backups/health/`.

Alert thresholds to implement:
- Daily backups older than 26 hours => warning.
- Monthly snapshot older than 40 days => warning.
- Integrity check fail => critical.
- Retention cleanup not reducing old files => warning.

### 5) Recovery Documentation Coverage

Current state:
- `docs/restore.md` exists and is useful for service bring-up order.
- It does not yet document exact backup artifact restore commands for Gitea/Garage/Karakeep exports.
- `alpine-utility/scripts/README.md` does not currently include `export_garage_backup.sh` (`alpine-utility/scripts/README.md:9`).

Recommended doc additions:
1. In `docs/restore.md`, add per-backup-artifact restore commands:
   - Gitea DB file + repos zip extraction paths.
   - Garage DB replacement and ownership checks.
   - Karakeep backup directory restore command and validation checklist.
2. Add "Backup verification drill" runbook (monthly, 10-15 min) that executes `verify_backups.sh` and confirms alerts.
3. Update `alpine-utility/scripts/README.md` to include Garage backup script and current schedule.

### Backup Risks/Gaps Still Open

1. No automated restore verification currently (highest risk).
2. Freshness drift can go unnoticed; observed artifacts suggest some jobs may not be running daily.
3. Karakeep backup copy uses `cp -r "$DATA_DIR"/*` which can miss dotfiles and behaves poorly with empty directories (`alpine-utility/scripts/export_karakeep_backup.sh:48`).
4. Retention logic is count-based but described as days in some comments/docs.
5. Monthly workflow cron expression in exported JSON (`28-31`) can run on multiple month-end days unless guarded by "is last day" logic (`n8n-workflows/budget-export-main.json:9`).

### Priority Action Plan

P1 (this week):
1. Implement `verify_backups.sh` + n8n daily verification workflow.
2. Add freshness/integrity JSON output and centralized alerting.
3. Update restore doc with artifact-level restore commands.

P2 (next week):
1. Raise Karakeep retention to 14 days.
2. Raise Garage retention to 45-60 days.
3. Fix Karakeep copy method to include dotfiles safely (prefer `rsync -a`).

P3 (later):
1. Add weekly backup health summary dashboard/email.
2. Add annual archive strategy for monthly snapshots.
