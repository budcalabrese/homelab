# Alpine Utility Container

Lightweight Alpine Linux container that acts as the homelab's automation bastion host. Runs backup scripts, monitoring, and podcast file operations — primarily called by n8n workflows via SSH.

## What It Does

- **Backups**: Karakeep, Gitea, and budget data (triggered by n8n on schedule)
- **Monitoring**: `docker-monitor.sh` checks all container health, reports JSON
- **Podcast delivery**: `copy-podcast.sh` moves files from Open Notebook → AudioBookShelf
- **SSH access**: Port 2223 from host (password), port 22 from n8n (key-based)

## Persistent Storage Architecture

Scripts are ephemeral but configs survive rebuilds via `/config` volume:

```
/Volumes/docker/container_configs/alpine-utility/  ← host (persists)
├── scripts/copy-podcast.sh    ← restored to /tmp/ on startup
└── ssh/authorized_keys        ← restored to /root/.ssh/ on startup
```

On container start, `init-scripts.sh` restores both files automatically. No manual steps needed after a rebuild.

## First-Time Setup

1. Add to `env/.env`:
   ```
   ALPINE_UTILITY_PASSWORD=your-secure-password
   ```

2. Build and start:
   ```bash
   docker compose up -d --build alpine-utility
   ```

3. Run the one-time setup script (generates SSH keys for n8n, stores them persistently):
   ```bash
   ./alpine-utility/setup-persistent-config.sh
   ```

4. Verify:
   ```bash
   docker logs alpine-utility --tail 20
   # Should show: Podcast script: Ready / SSH keys: 1 key(s) configured
   ```

## SSH Access

| Method | From | Port | Auth |
|--------|------|------|------|
| Manual | Host terminal | 2223 | Password (`ALPINE_UTILITY_PASSWORD` from env/.env) |
| Automation | n8n container | 2223 via `host.docker.internal` | Password (same as above) |

```bash
# From host
ssh -p 2223 root@localhost
# Password: value of ALPINE_UTILITY_PASSWORD from env/.env

# From n8n SSH nodes
# Credential: "SSH Password account"
# Host: host.docker.internal
# Port: 2223
# Password: value of ALPINE_UTILITY_PASSWORD from env/.env
```

## Calling Scripts from n8n

Use the SSH node (`n8n-nodes-base.ssh`) with credential "SSH Password account" (ID: JFyXom4nOrhtezt1):

```bash
# Monitoring
/scripts/docker-monitor.sh

# Podcast copy (show notes are base64-encoded to handle special characters)
echo '{{ $json.showNotesB64 }}' | ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility \
  'TMPF=/tmp/shownotes-$$.b64 && cat > $TMPF && /tmp/copy-podcast.sh "{{ $json.episodeName }}" "{{ $json.audioFile }}" $TMPF'
```

## Updating Scripts

**Backup/monitoring scripts** (`/scripts/`) are git-tracked and live-mounted — edit files in `alpine-utility/scripts/`, changes are immediate.

**Podcast copy script** is stored persistently in `/config/scripts/copy-podcast.sh`:
```bash
docker exec -it alpine-utility nano /config/scripts/copy-podcast.sh
docker compose restart alpine-utility  # reloads to /tmp/
```

**Monitoring script** (`docker-monitor.sh`) is baked into the image — edit source then rebuild:
```bash
docker compose up -d --build alpine-utility
```

## Adding SSH Keys

```bash
docker exec alpine-utility sh -c 'echo "ssh-ed25519 AAAA..." >> /config/ssh/authorized_keys'
docker compose restart alpine-utility
```

## Troubleshooting

**Can't SSH in:**
```bash
docker ps | grep alpine-utility     # is it running?
docker logs alpine-utility          # check startup errors
```

**n8n SSH fails with "All configured authentication methods failed":**
1. Check password in n8n credential matches env/.env:
   ```bash
   grep ALPINE_UTILITY_PASSWORD /Users/bud/home_space/homelab/env/.env
   ```
2. Update n8n credential "SSH Password account" with the correct password
3. Verify connection:
   ```bash
   docker logs alpine-utility | tail -20  # check for "Failed password" messages
   ```

**Podcast script missing after rebuild:**
```bash
docker exec alpine-utility ls /tmp/copy-podcast.sh
# If missing, check: ls /Volumes/docker/container_configs/alpine-utility/scripts/
# If that's also missing: re-run ./alpine-utility/setup-persistent-config.sh
```

**Script edits not sticking:**
Edit `/config/scripts/copy-podcast.sh` (persistent), not `/tmp/copy-podcast.sh` (ephemeral).
