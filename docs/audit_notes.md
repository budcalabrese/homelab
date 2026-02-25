# Homelab Audit Notes

**Last Updated**: February 25, 2026

---

## Next Priority Actions

### Recommended Next Audits

**Pick ONE area to focus on:**

1. **Service Health Monitoring** (Operational Excellence) - PLANNED

   **Approach:** Extend docker-monitor.sh with active health checks (Option A)
   - Philosophy: High-value, low-effort checks. Avoid over-engineering.
   - Current: Passive monitoring (container up/down + log errors)
   - Goal: Active health checks (functionality verification)

   **Tier 1: Critical Services** (Immediate - ~30 min)
   - n8n: `curl http://192.168.0.9:5678/healthz` (has built-in endpoint)
   - Karakeep: `curl http://192.168.0.9:3000/api/v1/bookmarks?limit=1` (test API)
   - Gitea: Already monitored ✅ (has `/api/healthz`)

   **Tier 2: Medium Priority** (Quick wins - if Tier 1 works well)
   - Open-WebUI: `curl http://192.168.0.9:3001/health`
   - AudioBookshelf: `curl http://192.168.0.9:13378/healthcheck`
   - SearXNG: `curl http://192.168.0.9:8080/healthz`

   **Tier 3: Python Dashboards** (Functional tests)
   - Budget Dashboard: `curl http://192.168.0.9:8050`
   - Garage Tracker: `curl http://192.168.0.9:8051`
   - Learning Dashboard: `curl http://192.168.0.9:8052`

   **Tier 4: Infrastructure** (Deferred - existing log monitoring sufficient)
   - Tailscale, MeTube (low criticality)

   **Implementation:**
   1. Add `check_service_health()` function to docker-monitor.sh
   2. Add "service_health" section to JSON output (after gitea health)
   3. Update n8n Docker Health Monitor workflow email formatter
   4. Test: Run script → verify JSON → trigger workflow → check email

   **Benefits:**
   - Single script maintains all monitoring
   - Existing n8n workflow already emails results
   - No new infrastructure needed
   - Low risk (doesn't break existing monitoring)

2. **Security Hardening** (Defense in Depth)
   - Audit Docker network isolation
   - Review n8n credential rotation strategy
   - Check for exposed endpoints that should be restricted

3. **Code Quality** (Developer Experience)
   - Create shared JSON utility library for Python apps
   - Standardize logging patterns
   - Review Docker image pinning strategy

### Backup System Improvements (P2/P3)

P2 (next week):
1. Raise Karakeep retention to 14 days
2. Raise Garage retention to 45-60 days
3. Fix Karakeep copy method to include dotfiles safely (prefer `rsync -a`)

P3 (later):
1. Add weekly backup health summary dashboard/email
2. Add annual archive strategy for monthly snapshots

### Known Risks/Gaps

1. Karakeep backup copy uses `cp -r "$DATA_DIR"/*` which can miss dotfiles and behaves poorly with empty directories ([export_karakeep_backup.sh:48](../alpine-utility/scripts/export_karakeep_backup.sh#L48))
2. Retention logic is count-based but described as days in some comments/docs

### Optional Low-Priority Items

- Dynamic disk space thresholds (current static values work fine)
- Replace hardcoded IPs in workflows (wait for DNS implementation)
