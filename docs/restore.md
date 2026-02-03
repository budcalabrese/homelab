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

Gitea
1. Restore data into `${DOCKER_CONFIG_ROOT}/gitea`.
2. Start only Gitea:
   ```bash
   docker compose up -d gitea
   ```
3. Validate:
   - Web UI: http://localhost:3002
   - SSH: port 2222

Karakeep
1. Restore `${DOCKER_CONFIG_ROOT}/karakeep/data`.
2. Start dependencies first:
   ```bash
   docker compose up -d karakeep-meilisearch karakeep-chrome
   ```
3. Start Karakeep:
   ```bash
   docker compose up -d karakeep
   ```
4. Validate: http://localhost:3000

n8n
1. Restore `${DOCKER_CONFIG_ROOT}/n8n`.
2. Start n8n:
   ```bash
   docker compose up -d n8n
   ```
3. Validate: http://localhost:5678

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
1. `docker compose ps`
2. Verify critical URLs: Gitea, Karakeep, n8n, AudioBookShelf, Open Notebook
3. Run a manual backup to confirm scripts still work
