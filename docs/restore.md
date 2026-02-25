# Restore Runbook

This is a minimal, practical restore guide for the homelab stack.

**Assumptions**
- Backups exist under `${BACKUPS_ROOT}`.
- Service data lives under `${DOCKER_CONFIG_ROOT}`.
- Environment files are present in `env/` and **not** in git.

**Pre-restore checklist**
1. Confirm `env/.env` and service env files exist and are correct.
2. Stop the stack:
   ```bash
   docker compose down
   ```
3. Identify the backup snapshot you want to restore.

**Restore order (recommended)**
1. Storage-heavy services (Gitea, Karakeep, AudioBookShelf, n8n)
2. Supporting services (Meilisearch, Open Notebook, OpenEDAI Speech)
3. Everything else

**Service restore steps**

### Gitea

**Backup artifacts locations:**
- Database: `${BACKUPS_ROOT}/gitea/database/gitea-db-YYYY-MM-DD_HH-MM-SS.db`
- Repositories: `${BACKUPS_ROOT}/gitea/repositories/gitea-repos-YYYY-MM-DD_HH-MM-SS.zip`

**Restore commands:**
1. Stop Gitea container:
   ```bash
   docker stop gitea
   ```

2. Restore database:
   ```bash
   # Find latest backup
   LATEST_DB=$(ls -t ${BACKUPS_ROOT}/gitea/database/gitea-db-*.db | head -1)

   # Copy to Gitea data directory
   cp "$LATEST_DB" ${DOCKER_CONFIG_ROOT}/gitea/gitea/gitea.db

   # Set correct ownership (adjust UID if needed)
   chown 1000:1000 ${DOCKER_CONFIG_ROOT}/gitea/gitea/gitea.db
   ```

3. Restore repositories:
   ```bash
   # Find latest backup
   LATEST_REPOS=$(ls -t ${BACKUPS_ROOT}/gitea/repositories/gitea-repos-*.zip | head -1)

   # Extract to Gitea git directory
   cd ${DOCKER_CONFIG_ROOT}/gitea/git
   unzip -o "$LATEST_REPOS"

   # Set correct ownership
   chown -R 1000:1000 ${DOCKER_CONFIG_ROOT}/gitea/git/repositories
   ```

4. Start Gitea:
   ```bash
   docker start gitea
   ```

5. Validate:
   - Web UI: http://localhost:3002
   - SSH: `ssh -p 2222 git@localhost`
   - Check repository access and commit history

**Verification checklist:**
- [ ] All repositories visible in web UI
- [ ] Can clone a repository via HTTPS
- [ ] Can clone a repository via SSH
- [ ] Recent commits are present
- [ ] Issues and pull requests intact

---

### Garage Tracker

**Backup artifact location:**
- Database: `${BACKUPS_ROOT}/garage-tracker/garage-YYYY-MM-DD_HH-MM-SS.db`

**Restore commands:**
1. Stop Garage Tracker container:
   ```bash
   docker stop garage-tracker
   ```

2. Restore database:
   ```bash
   # Find latest backup
   LATEST_GARAGE=$(ls -t ${BACKUPS_ROOT}/garage-tracker/garage-*.db | head -1)

   # Copy to Garage Tracker data directory
   cp "$LATEST_GARAGE" ${DOCKER_CONFIG_ROOT}/garage-tracker/garage.db

   # Set correct ownership (adjust UID if needed)
   chown 1000:1000 ${DOCKER_CONFIG_ROOT}/garage-tracker/garage.db
   ```

3. Start Garage Tracker:
   ```bash
   docker start garage-tracker
   ```

4. Validate:
   - Web UI: http://localhost:8080 (check actual port in compose.yml)
   - Verify vehicle records are present
   - Check recent maintenance entries

**Verification checklist:**
- [ ] All vehicles visible
- [ ] Maintenance history intact
- [ ] Recent entries present

---

### Karakeep

**Backup artifact location:**
- Full backup: `${BACKUPS_ROOT}/karakeep/karakeep_backup_YYYY-MM-DD_HH-MM-SS/`

**Restore commands:**
1. Stop Karakeep and dependencies:
   ```bash
   docker stop karakeep karakeep-meilisearch karakeep-chrome
   ```

2. Restore data directory:
   ```bash
   # Find latest backup
   LATEST_KARAKEEP=$(ls -td ${BACKUPS_ROOT}/karakeep/karakeep_backup_* | head -1)

   # Clear existing data (CAUTION!)
   rm -rf ${DOCKER_CONFIG_ROOT}/karakeep/data/*

   # Restore from backup
   cp -r "$LATEST_KARAKEEP"/* ${DOCKER_CONFIG_ROOT}/karakeep/data/

   # Set correct ownership (adjust UID if needed)
   chown -R 1000:1000 ${DOCKER_CONFIG_ROOT}/karakeep/data
   ```

3. Start dependencies first:
   ```bash
   docker start karakeep-meilisearch
   docker start karakeep-chrome
   sleep 5  # Wait for services to initialize
   ```

4. Start Karakeep:
   ```bash
   docker start karakeep
   ```

5. Validate:
   - Web UI: http://localhost:3000
   - Check bookmark count matches expected
   - Verify search functionality works
   - Test bookmark creation and deletion

**Verification checklist:**
- [ ] Bookmarks visible in UI
- [ ] Search returns expected results
- [ ] Can add new bookmark
- [ ] Collections/tags intact

---

### Budget Dashboard

**Backup artifact locations:**
- JSON data: `${BACKUPS_ROOT}/budget-dashboard/budget_data_MM_DD_YYYY.json`
- CSV export: `${BACKUPS_ROOT}/budget-dashboard/budget_snapshot_MM_DD_YYYY.csv`

**Restore commands:**
1. Stop Budget Dashboard container:
   ```bash
   docker stop budget-dashboard
   ```

2. Restore JSON data file:
   ```bash
   # Find latest backup
   LATEST_BUDGET=$(ls -t ${BACKUPS_ROOT}/budget-dashboard/budget_data_*.json | head -1)

   # Copy to Budget Dashboard data directory
   cp "$LATEST_BUDGET" ${DOCKER_CONFIG_ROOT}/budget-dashboard/budget_data.json

   # Set correct ownership
   chown 1000:1000 ${DOCKER_CONFIG_ROOT}/budget-dashboard/budget_data.json
   ```

3. Start Budget Dashboard:
   ```bash
   docker start budget-dashboard
   ```

4. Validate:
   - Web UI: http://localhost:8501 (check actual port)
   - Verify income/expenses are present
   - Check account balances
   - Confirm recent transactions visible

**Verification checklist:**
- [ ] All paychecks visible
- [ ] Bills and expenses present
- [ ] Debt balances correct
- [ ] Savings entries intact

---

### n8n

**Note:** n8n data is typically not backed up by the automated scripts. Workflows are version-controlled in the `n8n-workflows/` directory.

**Manual restore (if needed):**
1. Restore `${DOCKER_CONFIG_ROOT}/n8n/` directory from manual backup
2. Start n8n:
   ```bash
   docker start n8n
   ```
3. Validate:
   - Web UI: http://localhost:5678
   - All workflows present
   - Credentials configured (may need manual re-entry)
   - Test workflow execution

**Alternative:** Import workflows from `n8n-workflows/*.json` files via n8n UI

---

AudioBookShelf
1. Restore `${DOCKER_CONFIG_ROOT}/audiobookshelf/*`.
2. Start AudioBookShelf:
   ```bash
   docker compose up -d audiobookshelf
   ```
3. Validate: http://localhost:13378

Open Notebook
1. Restore:
   - `${DOCKER_CONFIG_ROOT}/open-notebook/notebook_data`
   - `${DOCKER_CONFIG_ROOT}/open-notebook/surreal_single_data`
2. Start Open Notebook:
   ```bash
   docker compose up -d open-notebook
   ```
3. Validate: http://localhost:8503

OpenEDAI Speech
1. Restore:
   - `${DOCKER_CONFIG_ROOT}/openedai-speech/voices`
   - `${DOCKER_CONFIG_ROOT}/openedai-speech/config`
2. Start OpenEDAI Speech:
   ```bash
   docker compose up -d openedai-speech
   ```
3. Validate: http://localhost:8000/v1/models

**Full stack restore**
After key services are validated:
```bash
docker compose up -d
```

**Post-restore checks**
1. `docker compose ps` - Verify all containers running
2. Verify critical URLs: Gitea, Karakeep, n8n, AudioBookShelf, Open Notebook
3. Run a manual backup to confirm scripts still work
4. Run backup verification: `docker exec alpine-utility /scripts/verify_backups.sh`

---

## Backup Verification Drill

**Purpose:** Monthly 10-15 minute drill to ensure backups are restorable

**Schedule:** First Monday of each month

**Procedure:**

1. **Run automated verification:**
   ```bash
   docker exec alpine-utility /scripts/verify_backups.sh
   ```

2. **Check verification report:**
   ```bash
   cat /Volumes/backups/health/backup_verification_latest.json
   ```

3. **Verify all checks passed:**
   - Gitea: DB integrity + repo zip integrity
   - Garage: DB integrity
   - Karakeep: Directory non-empty + DB integrity
   - Budget: JSON valid + CSV valid

4. **Test one random restore** (rotate monthly):
   - Month 1: Gitea database only
   - Month 2: Garage database
   - Month 3: Karakeep full restore
   - Month 4: Budget JSON restore

5. **Document results:**
   - Add entry to `docs/backup_drill_log.md`
   - Note any issues found
   - Record time to complete

**Success criteria:**
- All integrity checks pass
- Selected restore completes without errors
- Restored data matches expected content
- Total time < 15 minutes

**If verification fails:**
1. Check disk space: `df -h /Volumes/backups`
2. Check backup script logs in n8n
3. Manually run failed backup script
4. Re-run verification
5. If still failing, investigate backup script issues
