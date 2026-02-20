# Homelab Audit Notes

**Source**: ChatGPT external audit (February 20, 2026)
**Status**: Tracking implementation progress

---

## Phase 1: Data Integrity (CRITICAL - ✅ COMPLETE)

### Budget & Learning App Data Protection

- [x] **Fix invalid exception class in budget app**
  - File: `coding/python-budget-tracker/budget_dashboard_streamlit.py:77`
  - Issue: `json.JSONEncodeError` is not a valid stdlib exception
  - Fix: Use `TypeError`/`ValueError` instead
  - **Status**: ✅ Fixed - commit 6fbefc1

- [x] **Implement atomic JSON writes (budget app)**
  - File: `coding/python-budget-tracker/budget_dashboard_streamlit.py:75-76`
  - Issue: Direct write can corrupt data if interrupted
  - Fix: Write to temp file + `os.replace()` for atomic operation
  - **Status**: ✅ Fixed - commit 6fbefc1

- [x] **Implement atomic JSON writes (learning app)**
  - File: `coding/python-learning-dashboard/python-learning-dashboard.py:94-95`
  - Issue: Same corruption risk
  - Fix: Write to temp file + `os.replace()`
  - **Status**: ✅ Fixed - commit 6fbefc1

- [x] **Add error handling to learning dashboard load/save**
  - File: `coding/python-learning-dashboard/python-learning-dashboard.py:79-95`
  - Issue: Malformed JSON can crash app
  - Fix: Wrap in try/except with recovery/default data
  - **Status**: ✅ Fixed - commit 6fbefc1

---

## Phase 2: Backup Robustness (HIGH PRIORITY - ✅ COMPLETE)

### Script Safety & Reliability

- [x] **Add strict mode to all backup scripts**
  - Files: All `homelab/alpine-utility/scripts/*.sh`
  - Fix: Add `set -euo pipefail` to catch failures early
  - Scripts updated:
    - `export_karakeep_backup.sh`
    - `export_monthly_snapshot.sh`
    - `export_monthly_snapshot_gf.sh`
    - `export_gitea_backup.sh` (upgraded from `set -e`)
    - `export_garage_backup.sh` (upgraded from `set -e`)
  - **Status**: ✅ Fixed - commit a1a4f32

- [x] **Add disk space prechecks**
  - Files: All export scripts
  - Issue: No check before writing backups = risk of partial backups on full disk
  - Fix: Check free space, fail early with clear message
  - Thresholds set:
    - Karakeep: 1GB
    - Monthly snapshots: 100MB
    - Gitea: 5GB
    - Garage: 500MB
  - **Status**: ✅ Fixed - commit a1a4f32

- [x] **Add mutual exclusion locks**
  - Files: All `homelab/alpine-utility/scripts/*.sh`
  - Issue: Concurrent runs can corrupt backups or restart services unexpectedly
  - Fix: Add atomic mkdir lock strategy with trap cleanup
  - **Status**: ✅ Fixed - commit a1a4f32

- [x] **Fix GF script legacy schema**
  - File: `homelab/alpine-utility/scripts/export_monthly_snapshot_gf.sh:62, :84`
  - Issue: Still uses old expenses schema
  - Fix: Mirror main script's needs/wants + legacy fallback logic
  - **Status**: ✅ Fixed - commit a1a4f32

- [x] **Fix Karakeep deletion pattern**
  - File: `homelab/alpine-utility/scripts/export_karakeep_backup.sh:48`
  - Issue: `ls -t | tail -n +8` too broad, could delete non-backup dirs
  - Fix: Restrict to `karakeep_backup_*` pattern
  - **Status**: ✅ Fixed - commit a1a4f32

---

## Phase 3: Documentation & Nice-to-Haves (MEDIUM PRIORITY - ✅ COMPLETE)

### Documentation Sync

- [x] **Update n8n SSH documentation**
  - Files: `homelab/n8n-workflows/README.md:134`, `homelab/AGENTS.md:37-43`
  - Issue: Docs still show `alpine-utility:22` key auth, but we use `host.docker.internal:2223` password auth
  - Fix: Update README to match current approach
  - **Status**: ✅ Fixed - commit c9df57a (AGENTS.md was already correct)

- [x] **Sync port tables in README**
  - File: `homelab/README.md:93-112`
  - Issue: Missing `garage-tracker` (8504) and `victoria-logs` (9428)
  - Fix: Add missing services to port table
  - **Status**: ✅ Fixed - commit c9df57a

- [x] **Fix learning dashboard filename references**
  - File: `coding/python-learning-dashboard/README.md:27, :75`
  - Issue: References wrong filename
  - **Status**: ✅ Already fixed in previous work

### Service Improvements

- [x] **Activate Centralized Error Notification workflow**
  - File: `homelab/n8n-workflows/Centralized Error Notification.json:81`
  - Issue: `"active": false` means silent failures
  - Fix: Activated the workflow for global error monitoring
  - **Status**: ✅ Fixed - commit c9df57a

- [x] **Add timeout to transcript API**
  - File: `coding/youtube-transcripts-api/youtube-transcripts-api.py:124`
  - Issue: No timeout on subtitle fetch = potential hang
  - Fix: Add `requests.get(subtitle_url, timeout=(5, 20))`
  - **Status**: ✅ Fixed - commit 1f7de2e

### Deferred Items (Low Priority)

- [ ] **Add health checks to services**
  - File: `homelab/compose.yml`
  - Missing health checks on: wyoming-whisper, wyoming-piper, wyoming-openwakeword, metube,
    karakeep-meilisearch, karakeep-chrome, karakeep, audiobookshelf, tailscale, alpine-utility, fluent-bit
  - Fix: Add lightweight HTTP/TCP/command probes per service
  - **Status**: Deferred - not critical, containers are running stable

### Workflow Improvements (LOW PRIORITY)

- [ ] **Replace deprecated executeCommand nodes**
  - Files: `homelab/n8n-workflows/Karakeep Daily Podcast Generation.json:356`,
    `homelab/n8n-workflows/budget-export-gf.json:32`
  - Issue: Using deprecated `n8n-nodes-base.executeCommand`
  - Fix: Replace with `n8n-nodes-base.ssh` nodes

- [ ] **Fix SSH routing in podcast workflow**
  - File: `homelab/n8n-workflows/Karakeep Daily Podcast Generation.json:353`
  - Issue: Embedded `ssh -p 22 root@alpine-utility` bypasses standard credential
  - Fix: Replace with direct SSH node using `host.docker.internal:2223` credential

---

## Non-Issues (Audit Findings We're NOT Fixing)

### Hardcoded Gitea Token
- **Finding**: Token in workflow JSON is a security risk
- **Decision**: Not critical in homelab context (isolated network, private repo)
- **Priority**: Low - only matters if we expose services externally

### Hardcoded IPs in Workflows
- **Finding**: `192.168.0.9` etc. hardcoded in workflows
- **Decision**: Appropriate for current architecture (no DNS setup)
- **Priority**: Revisit when implementing DNS

### API Error Leaking
- **Finding**: Transcript API exposes internal exception details
- **Decision**: Not a security issue, just verbose
- **Priority**: Low - cosmetic improvement

---

## Notes

- **Token Usage**: Monitor Claude context usage during Phase 1 implementation
- **Testing**: After each phase, rebuild affected containers and verify functionality
- **Commits**: Commit after each logical group of fixes (per-phase recommended)

**Last Updated**: 2026-02-20

---

## Next Steps for ChatGPT

### Current Progress
- ✅ Phase 1 Complete: Data integrity fixes (commit 6fbefc1)
- ✅ Phase 2 Complete: Backup script robustness (commit a1a4f32)
- ✅ Phase 3 Complete: Documentation sync & service improvements (commits c9df57a, 1f7de2e)

### What to Audit Next

**Priority 1: Verify Phase 1 & 2 Implementation**
1. Review the two commits (6fbefc1, a1a4f32) to confirm all fixes were correctly implemented
2. Check for any edge cases or missed scenarios in:
   - Atomic write implementation (are temp files cleaned up on error?)
   - Backup script lock cleanup (does trap handle all exit scenarios?)
   - Disk space checks (are thresholds appropriate for actual usage?)

**Priority 2: Phase 3 - Documentation Sync**
3. Review and update n8n workflow documentation
   - Files: `homelab/n8n-workflows/README.md`, `homelab/AGENTS.md`
   - Issue: SSH setup docs still reference old approach
   - Fix needed: Update to `host.docker.internal:2223` password auth

4. Review homelab README port table completeness
   - File: `homelab/README.md:93-112`
   - Missing services: garage-tracker (8504), victoria-logs (9428)
   - Verify all published ports from compose.yml are documented

**Priority 3: Service Health & Reliability**
5. Review n8n workflow active/inactive status
   - Should "Centralized Error Notification" workflow be activated?
   - Are all other workflows properly configured for failure handling?

6. Recommend which services should have health checks added
   - Priority services needing health checks
   - Suggested health check implementation per service

**Priority 4: Code Quality Review**
7. Review Python app improvements beyond Phase 1
   - Transcript API timeout implementation
   - Error message sanitization
   - Any other code quality patterns worth standardizing

**Questions for Next Audit:**
- Are there any architectural concerns with the current backup strategy?
- Should we implement a backup verification/testing process?
- Are the mutual exclusion locks sufficient, or should we add logging/monitoring?
- Any security concerns with the current n8n workflow setup beyond the Gitea token issue?

---

**Work Log:**
- 2026-02-20 16:00: Phase 1 complete (data integrity) - commits 6fbefc1
- 2026-02-20 16:15: Phase 2 complete (backup robustness) - commit a1a4f32
- 2026-02-20 16:30: Phase 3 complete (documentation & services) - commits c9df57a, 1f7de2e
- 2026-02-20 16:35: All critical and high priority items complete

**Summary of All Changes:**
- Fixed 4 data integrity issues (atomic writes, error handling)
- Improved 5 backup scripts (strict mode, locks, disk checks)
- Updated documentation (SSH setup, port table)
- Activated error notification workflow
- Added API timeout to prevent hangs

**What's Left:**
- Health checks on 11 services (deferred - low priority)
- Other low-priority items from original audit remain optional
