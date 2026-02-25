# Homelab Audit Notes

**Last Updated**: February 25, 2026

---

## Next Priority Actions

### Recommended Next Audits

**Pick ONE area to focus on:**

1. **Service Health Monitoring** (Operational Excellence)
   - Prioritize which 11 services need health checks most
   - Design health check commands per service
   - Consider monitoring dashboard beyond docker-monitor.sh

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

- Add health checks to 11 services (deferred - containers stable)
- Dynamic disk space thresholds (current static values work fine)
- Replace hardcoded IPs in workflows (wait for DNS implementation)
