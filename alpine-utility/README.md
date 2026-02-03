# Alpine Utility Container

A lightweight Alpine Linux container with SSH access and Docker CLI for running automation tasks from n8n.

## Features

- SSH server (port 2223)
- Docker CLI with full socket access (for container control)
- Automated backup scripts for Karakeep and Gitea
- Budget export automation scripts
- Monitoring script (`/scripts/docker-monitor.sh`)
- Podcast file copy script (`/tmp/copy-podcast.sh`)
- Multiple volume mounts for data access and backups
- Lightweight: ~128MB memory usage

## Setup Instructions

### 1. Set SSH Password

Add this to your `env/.env` file:
```bash
ALPINE_UTILITY_PASSWORD=your-secure-password-here
```

### 2. Create Config Directory

```bash
mkdir -p /Volumes/docker/container_configs/alpine-utility
```

### 3. Build and Start the Container

```bash
cd /Users/bud/home_space/homelab
docker compose up -d --build alpine-utility
```

### 4. Run One-Time Setup Script

This script stores persistent configurations that survive container rebuilds:

```bash
cd /Users/bud/home_space/homelab
./alpine-utility/setup-persistent-config.sh
```

This will:
- Create the podcast copy script in `/config/scripts/copy-podcast.sh`
- Generate SSH keys for n8n (if not already present)
- Store n8n's public key in `/config/ssh/authorized_keys`
- Test SSH connectivity from n8n to alpine-utility

### 5. Test Everything Works

```bash
# Test password SSH from host
ssh -p 2223 root@localhost
# Password: your ALPINE_UTILITY_PASSWORD

# Test monitoring script
docker exec alpine-utility /scripts/docker-monitor.sh

# Test SSH key auth from n8n
docker exec n8n ssh -p 22 root@alpine-utility echo "SSH works!"

# Test podcast copy script (with base64-encoded show notes)
echo "VGVzdCBzaG93IG5vdGVz" | docker exec -i alpine-utility sh -c 'TMPF=/tmp/test-$$.b64 && cat > $TMPF && /tmp/copy-podcast.sh "Test" "/dev/null" $TMPF'
```

## Using with n8n

### SSH Authentication

The alpine-utility container uses SSH key authentication for automation (configured automatically by the setup script):
- **From n8n**: Uses SSH keys (port 22, container network)
- **From host**: Uses password (port 2223)

### Calling Scripts from n8n

Use SSH nodes:

```bash
# Monitoring script example
ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility /scripts/docker-monitor.sh

# Podcast copy script example
ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility /tmp/copy-podcast.sh "Episode Name" "/path/to/audio.mp3" "Show notes"
```

**Important**: Use `root@alpine-utility:22` from n8n (not `alpine@localhost:2223`)

## Podcast File Copy Script

The alpine-utility container includes a script at `/tmp/copy-podcast.sh` that copies podcast files from the Open Notebook container to AudioBookshelf.

### Usage

The script is called from the n8n "Karakeep Daily Podcast Generation" workflow via SSH with base64-encoded show notes:

```bash
# Show notes are base64-encoded and piped via stdin to avoid shell escaping issues
echo 'BASE64_ENCODED_SHOW_NOTES' | ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility \
  'TMPF=/tmp/shownotes-$$.b64 && cat > $TMPF && /tmp/copy-podcast.sh "Episode Name" "/path/in/container/audio.mp3" $TMPF'
```

**Why base64 encoding?** Show notes contain special characters (bullets •, newlines, URLs) that cannot be safely passed as shell arguments. The workflow:
1. Base64-encodes the show notes in n8n
2. Pipes the base64 string via SSH stdin
3. Writes it to a temporary file on alpine-utility
4. Passes the temp file path to the script
5. Script decodes and writes the show notes

### What it does

1. Accepts a base64 file path as the third argument
2. Decodes the base64 show notes from the file
3. Copies MP3 file from Open Notebook container using `docker cp`
4. Creates a show notes text file with episode metadata and article links
5. Places both files in `/mnt/audiobookshelf/Daily-Digests/`
6. Cleans up the temporary base64 file
7. Returns success/failure status

### Script location

- **Persistent storage**: `/config/scripts/copy-podcast.sh` (survives rebuilds)
- **Runtime location**: `/tmp/copy-podcast.sh` (restored on container startup)
- Called by the n8n workflow's "Copy Files via Alpine Utility" node

## Monitoring Script Output

The script returns JSON with:
- Container name, status, health
- Restart count
- Recent errors (last 24 hours)
- Recent warnings (last 24 hours)
- Summary statistics

Example output:
```json
{
  "timestamp": "2025-11-30T12:00:00Z",
  "containers": [
    {
      "name": "open-webui",
      "status": "running",
      "health": "healthy",
      "restarts": 0,
      "errors": "",
      "warnings": ""
    }
  ],
  "summary": {
    "total": 20,
    "running": 19,
    "stopped": 1
  }
}
```

## Security Notes

- SSH is exposed on port 2223
- Docker socket has full read-write access (required for backup scripts to stop/start containers)
- Change the default password in `.env`
- Consider using SSH keys instead of password authentication for production
- Multiple data volumes are mounted (some read-only, some read-write)
- Backup scripts can control Docker containers (stop/start Gitea for consistent backups)

## Troubleshooting

**Can't connect via SSH:**
```bash
# Check if container is running
docker ps | grep alpine-utility

# Check logs
docker logs alpine-utility
```

**n8n can't connect:**
- Use `localhost:2223` from n8n Execute Command nodes
- Make sure to use `-o StrictHostKeyChecking=no` to avoid SSH key verification prompts
- Make sure n8n container can reach the alpine-utility container (same network)

**Podcast copy script fails:**
```bash
# Verify the script exists
docker exec alpine-utility ls -l /tmp/copy-podcast.sh

# Check persistent storage
docker exec alpine-utility ls -l /config/scripts/copy-podcast.sh

# Test the script manually (with base64-encoded show notes)
echo "VGVzdCBzaG93IG5vdGVz" | docker exec -i alpine-utility sh -c 'TMPF=/tmp/test-$$.b64 && cat > $TMPF && /tmp/copy-podcast.sh "Test-Episode" "/app/data/podcasts/test.mp3" $TMPF'

# Check AudioBookshelf mount
docker exec alpine-utility ls -l /mnt/audiobookshelf/Daily-Digests/
```

**SSH key authentication not working after rebuild:**
```bash
# Check if SSH keys were restored
docker exec alpine-utility cat /root/.ssh/authorized_keys

# If empty, run the setup script again
./alpine-utility/setup-persistent-config.sh
```

## Container Rebuilds

The alpine-utility container is designed to be rebuilt safely:

### What Persists Across Rebuilds

- ✅ SSH authorized_keys (restored from `/config/ssh/authorized_keys`)
- ✅ Podcast copy script (restored from `/config/scripts/copy-podcast.sh`)
- ✅ Password (from `env/.env` file)
- ✅ n8n SSH private key (in n8n's volume)

### Rebuild Procedure

```bash
cd /Users/bud/home_space/homelab
docker compose up -d --build alpine-utility
```

The container will automatically restore configurations on startup. No manual intervention needed!

### First-Time Setup After Rebuild

Only needed if you haven't run the setup script before:

```bash
./alpine-utility/setup-persistent-config.sh
```

### Verify After Rebuild

```bash
# Check initialization ran successfully
docker logs alpine-utility --tail 20

# Should show:
# ✓ Restoring podcast copy script...
# ✓ Restoring SSH authorized_keys...
# Status:
#   - Podcast script: Ready
#   - SSH keys: 1 key(s) configured

# Test SSH from n8n
docker exec n8n ssh -p 22 root@alpine-utility echo "SSH works!"
```
