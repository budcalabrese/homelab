# Alpine Utility Container

A lightweight Alpine Linux container with SSH access and Docker CLI for running automation tasks from n8n.

## Features

- SSH server (port 2222)
- Docker CLI with read-only socket access
- Monitoring script (`/scripts/docker-monitor.sh`)
- Lightweight: ~128MB memory usage

## Setup Instructions

### 1. Set SSH Password

Add this to your `.env` file:
```bash
ALPINE_UTILITY_PASSWORD=your-secure-password-here
```

### 2. Build and Start the Container

```bash
cd /Users/bud/home_space/home/homelab/homelab-docker
docker compose up -d alpine-utility
```

### 3. Create Config Directory

```bash
mkdir -p /Volumes/docker/container_configs/alpine-utility
```

### 4. Test SSH Connection

```bash
ssh -p 2222 root@localhost
# Password: your-secure-password-here
```

### 5. Test the Monitoring Script

```bash
ssh -p 2222 root@localhost "/scripts/docker-monitor.sh"
```

You should see JSON output with container statuses.

## Using with n8n

### 1. Configure n8n SSH Credentials

In n8n:
1. Go to Settings → Credentials
2. Create new "SSH" credential
3. Configure:
   - Host: `alpine-utility` (or `host.docker.internal` if n8n can't resolve)
   - Port: `22` (internal port, or `2222` if connecting from outside)
   - Username: `root`
   - Password: (use the password from your .env file)

### 2. Import the Workflow

1. In n8n, go to Workflows → Add Workflow → Import from File
2. Import `n8n-workflow-example.json`
3. Update the email settings in the "Send Email" node
4. Configure your SMTP credentials in n8n

### 3. Customize the Schedule

The example workflow runs daily at 9 AM. Edit the Schedule Trigger node to change:
- Daily: `0 9 * * *`
- Every 6 hours: `0 */6 * * *`
- Every hour: `0 * * * *`

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

- SSH is exposed on port 2222
- Docker socket is mounted read-only (`:ro`)
- Change the default password in `.env`
- Consider using SSH keys instead of password authentication for production

## Troubleshooting

**Can't connect via SSH:**
```bash
# Check if container is running
docker ps | grep alpine-utility

# Check logs
docker logs alpine-utility
```

**n8n can't connect:**
- If using `alpine-utility` hostname doesn't work, try `host.docker.internal:2222`
- Make sure n8n container can reach the alpine-utility container (same network)

**Script permissions:**
```bash
# Make script executable
docker exec alpine-utility chmod +x /scripts/docker-monitor.sh
```
