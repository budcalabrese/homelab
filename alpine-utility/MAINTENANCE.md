# Alpine Utility Container - Maintenance Guide

## Container Philosophy

The alpine-utility container follows these principles:

1. **Ephemeral by design** - Can be killed and rebuilt anytime
2. **Persistent configuration** - Important configs survive rebuilds
3. **Automatic restoration** - Configurations restored on startup
4. **No manual intervention** - Weekly rebuilds "just work"

## Persistent Storage Architecture

### Volume Mounts

```yaml
volumes:
  - /Volumes/docker/container_configs/alpine-utility:/config  # Persistent configs
  - /Volumes/docker/container_configs/audiobookshelf/podcasts:/mnt/audiobookshelf  # Podcast delivery
  - /var/run/docker.sock:/var/run/docker.sock:ro  # Docker access
```

### Directory Structure

```
/Volumes/docker/container_configs/alpine-utility/  # Host persistent storage
├── scripts/
│   └── copy-podcast.sh           # Podcast file copy script (persistent)
└── ssh/
    └── authorized_keys           # n8n public SSH key (persistent)

/tmp/                             # Container ephemeral storage
└── copy-podcast.sh               # Runtime copy (restored from /config/scripts/)

/root/.ssh/                       # Container ephemeral storage
└── authorized_keys               # Runtime copy (restored from /config/ssh/)
```

### What Happens on Container Start

1. **Entrypoint script** ([entrypoint.sh](entrypoint.sh)):
   - Sets root password from `ALPINE_UTILITY_PASSWORD` env var
   - Calls initialization script

2. **Initialization script** ([init-scripts.sh](init-scripts.sh)):
   - Restores `/tmp/copy-podcast.sh` from `/config/scripts/copy-podcast.sh`
   - Restores `/root/.ssh/authorized_keys` from `/config/ssh/authorized_keys`
   - Reports status of restored components

## Weekly Rebuild Workflow

### Automatic Behavior

```bash
# Your weekly rebuild command
docker compose up -d --build alpine-utility
```

**What happens automatically:**
1. ✅ New container is built from Dockerfile
2. ✅ Init script runs on startup
3. ✅ Podcast script restored to `/tmp/copy-podcast.sh`
4. ✅ SSH keys restored to `/root/.ssh/authorized_keys`
5. ✅ n8n can immediately connect via SSH
6. ✅ Podcast workflow continues working

**No manual steps required!**

### Verification Commands

```bash
# Check container started successfully
docker ps | grep alpine-utility

# Check initialization logs
docker logs alpine-utility --tail 30

# Expected output:
# ✓ Restoring podcast copy script...
# ✓ Restoring SSH authorized_keys...
# Status:
#   - Podcast script: Ready
#   - SSH keys: 1 key(s) configured

# Test SSH from n8n
docker exec n8n ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility echo "Test successful"

# Test monitoring script
docker exec alpine-utility /scripts/docker-monitor.sh | jq '.summary'

# Test podcast copy script exists
docker exec alpine-utility ls -l /tmp/copy-podcast.sh
```

## SSH Key Management

### Two Authentication Methods

1. **Password authentication** (manual access from host):
   - Used for: Manual SSH from your Mac
   - Port: 2223 (host-exposed)
   - User: root
   - Password: From `ALPINE_UTILITY_PASSWORD` in env/.env
   - Example: `ssh -p 2223 root@localhost`

2. **Key-based authentication** (automation from n8n):
   - Used for: n8n workflows, automated tasks
   - Port: 22 (internal Docker network)
   - User: root
   - Key: n8n's ed25519 key pair
   - Example: `ssh -p 22 root@alpine-utility` (from n8n container)

### n8n SSH Keys Location

- **Private key**: `/home/node/.ssh/id_ed25519` (inside n8n container)
- **Public key**: `/home/node/.ssh/id_ed25519.pub` (inside n8n container)
- **Persists in**: n8n's `/home/node/.n8n` volume (survives n8n rebuilds)

### alpine-utility SSH Keys Location

- **Runtime**: `/root/.ssh/authorized_keys` (ephemeral, in container)
- **Persistent storage**: `/config/ssh/authorized_keys` (survives rebuilds)
- **Restored by**: Init script on container startup

### If SSH Keys Are Lost

This should never happen if you're using volumes correctly, but if it does:

```bash
# Re-run the setup script
cd /Users/bud/home_space/homelab
./alpine-utility/setup-persistent-config.sh
```

This will:
- Generate new SSH keys in n8n (if missing)
- Store public key in alpine-utility's `/config/ssh/authorized_keys`
- Test the connection

## Updating Scripts

### Update Podcast Copy Script

**Option 1: Edit persistent storage directly**

```bash
# Edit the file on the host
nano /Volumes/docker/container_configs/alpine-utility/scripts/copy-podcast.sh

# Restart container to reload
docker compose restart alpine-utility
```

**Option 2: Update via docker exec**

```bash
# Edit in running container
docker exec -it alpine-utility nano /config/scripts/copy-podcast.sh

# Reload (copies to /tmp)
docker compose restart alpine-utility
```

### Update Monitoring Script

The monitoring script is baked into the Docker image:

```bash
# Edit the source file
nano /Users/bud/home_space/homelab/alpine-utility/docker-monitor.sh

# Rebuild container
docker compose up -d --build alpine-utility
```

## Adding New SSH Keys

To grant SSH access to another container or service:

```bash
# Get the public key from the other container
docker exec <container-name> cat /path/to/id_rsa.pub

# Add to alpine-utility's authorized_keys (persistent)
docker exec alpine-utility sh -c 'echo "ssh-rsa AAAA..." >> /config/ssh/authorized_keys'

# Reload SSH keys
docker compose restart alpine-utility
```

## Security Checklist

- [ ] `ALPINE_UTILITY_PASSWORD` is strong and unique
- [ ] Password stored in `env/.env` (not committed to git)
- [ ] SSH port 2223 only exposed on localhost (not 0.0.0.0)
- [ ] Docker socket mounted read-only (`:ro`)
- [ ] SSH keys use ed25519 (modern, secure algorithm)
- [ ] `StrictHostKeyChecking=no` only used in automation (n8n)

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs alpine-utility

# Common issues:
# - /config volume not mounted
# - ALPINE_UTILITY_PASSWORD not set in env/.env
# - Port 2223 already in use
```

### SSH from n8n fails

```bash
# Check if keys were restored
docker exec alpine-utility cat /root/.ssh/authorized_keys

# Should show: ssh-ed25519 AAAA... n8n-to-alpine-utility

# If empty, init script didn't run or config is missing
docker logs alpine-utility --tail 30

# Re-run setup if needed
./alpine-utility/setup-persistent-config.sh
```

### Podcast copy script missing

```bash
# Check persistent storage
ls -l /Volumes/docker/container_configs/alpine-utility/scripts/

# If missing, re-run setup
./alpine-utility/setup-persistent-config.sh

# If exists but not in /tmp, check init logs
docker logs alpine-utility | grep -A 5 "Initialization"
```

### Changes to scripts don't persist

**Problem**: You edited `/tmp/copy-podcast.sh` directly in the container

**Solution**: Edit the persistent version instead:

```bash
# Wrong (ephemeral):
docker exec alpine-utility nano /tmp/copy-podcast.sh

# Right (persistent):
docker exec alpine-utility nano /config/scripts/copy-podcast.sh
# Then restart: docker compose restart alpine-utility
```

## Backup & Restore

### What to Backup

The persistent volume contains everything needed to restore functionality:

```bash
# Backup command
tar -czf alpine-utility-backup-$(date +%Y%m%d).tar.gz \
  /Volumes/docker/container_configs/alpine-utility/

# Includes:
# - /config/scripts/copy-podcast.sh
# - /config/ssh/authorized_keys
```

### Restore from Backup

```bash
# Stop container
docker compose stop alpine-utility

# Restore files
tar -xzf alpine-utility-backup-YYYYMMDD.tar.gz -C /

# Start container
docker compose up -d alpine-utility

# Verify
docker logs alpine-utility --tail 30
```

## Integration with n8n Workflows

### Karakeep Daily Podcast Workflow

Uses alpine-utility for file operations with base64-encoded show notes:

```bash
# Node: "Copy Files via Alpine Utility"
# Type: Execute Command
# Command:
echo '{{ $json.showNotesB64 }}' | ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility \
  'TMPF=/tmp/shownotes-$$.b64 && cat > $TMPF && /tmp/copy-podcast.sh "{{ $json.episodeName }}" "{{ $json.audioFile }}" $TMPF'
```

**Technical Details:**
- Show notes are base64-encoded in the "Prepare Copy Data" node
- Base64 string is piped via SSH stdin to avoid shell escaping issues
- Temp file created on alpine-utility with unique PID-based name
- Script reads, decodes, and writes show notes, then cleans up temp file
- This approach handles special characters (bullets •, newlines, URLs) correctly

### Docker Health Monitoring Workflow

Uses alpine-utility for monitoring:

```bash
# Node: "Run Docker Monitor"
# Type: Execute Command
# Command:
ssh -p 22 -o StrictHostKeyChecking=no root@alpine-utility \
  /scripts/docker-monitor.sh
```

## Future Enhancements

Potential improvements that maintain the ephemeral design:

1. **Multiple authorized keys**: Support for monitoring service, backup tools, etc.
2. **Script versioning**: Track changes to scripts in git
3. **Healthcheck endpoint**: HTTP endpoint for monitoring alpine-utility itself
4. **Metrics collection**: Resource usage, script execution counts
5. **Automated backups**: Scheduled backups of /config to off-site storage

## Questions?

- Check [README.md](README.md) for usage examples
- Check [SETUP_SUMMARY.md](SETUP_SUMMARY.md) for quick reference
- Review compose.yml for volume configuration
- Look at entrypoint.sh and init-scripts.sh for startup behavior

---

**Last Updated**: December 10, 2024
**Container Version**: 2.0 (with persistent configuration support)
