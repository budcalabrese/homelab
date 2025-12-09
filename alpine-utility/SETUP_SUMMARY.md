# Alpine Utility Setup Complete! ✅

## What Was Created

1. **Alpine Utility Container** - Lightweight Linux container with:
   - SSH server (accessible on port 2223)
   - Docker CLI with read-only access to your Docker daemon
   - Monitoring script at `/scripts/docker-monitor.sh`
   - ~128MB memory footprint

2. **Docker Monitoring Script** - Returns JSON with:
   - Container statuses (running/stopped)
   - Health check statuses
   - Restart counts
   - Recent errors and warnings (last 24 hours)
   - Summary statistics

3. **n8n Workflow Template** - Ready to import workflow that:
   - Connects via SSH to run the monitoring script
   - Parses the output and detects issues
   - Formats a nice HTML email report
   - Sends you daily summaries

## Quick Start Guide

### 1. Update Your SSH Password

Edit your `.env` file and change:
```bash
ALPINE_UTILITY_PASSWORD=changeme-please-update-this
```

To something secure, then restart:
```bash
docker compose restart alpine-utility
```

### 2. Test SSH Connection

From your terminal:
```bash
ssh -p 2223 root@localhost
# Use the password from your .env file
```

Or test the script directly:
```bash
docker exec alpine-utility /scripts/docker-monitor.sh
```

### 3. Set Up n8n Workflow

**Option A: Import the workflow**
1. Open n8n at http://localhost:5678
2. Go to Workflows → Import from File
3. Select `alpine-utility/n8n-workflow-example.json`

**Option B: Manual setup in n8n**
1. Create SSH credentials in n8n:
   - Host: `alpine-utility` (or `host.docker.internal` if needed)
   - Port: `22` (internal port)
   - Username: `root`
   - Password: (from your .env)

2. Create a new workflow with:
   - **Schedule Trigger** - When to run (e.g., daily at 9 AM)
   - **SSH Node** - Execute command: `/scripts/docker-monitor.sh`
   - **Code Node** - Parse JSON and format email
   - **Email Node** - Send the report

### 4. Configure Email in n8n

You'll need to set up SMTP credentials in n8n. Common options:
- **Gmail**: Use App Passwords (requires 2FA enabled)
- **SendGrid**: Free tier available
- **Mailgun**: Free tier available
- **Your ISP's SMTP server**

## File Locations

```
homelab-docker/
├── compose.yml                          # Updated with alpine-utility service
├── .env                                 # Contains ALPINE_UTILITY_PASSWORD
└── alpine-utility/
    ├── Dockerfile                       # Container definition
    ├── entrypoint.sh                    # Sets password from env
    ├── docker-monitor.sh                # Monitoring script
    ├── n8n-workflow-example.json        # Import this into n8n
    ├── README.md                        # Detailed documentation
    └── SETUP_SUMMARY.md                 # This file
```

## Usage Examples

### Run monitoring script manually:
```bash
docker exec alpine-utility /scripts/docker-monitor.sh
```

### SSH into the container:
```bash
ssh -p 2223 root@localhost
```

### Check specific container logs:
```bash
ssh -p 2223 root@localhost "docker logs n8n --tail 50"
```

### List all containers:
```bash
ssh -p 2223 root@localhost "docker ps -a"
```

## What the Monitoring Script Detects

- ❌ Stopped containers
- 🏥 Unhealthy containers (failed health checks)
- 🔄 Containers with excessive restarts (>5)
- ⚠️ Recent errors in logs (last 24 hours)
- ⚠️ Recent warnings in logs (last 24 hours)

## Sample Email Report

The n8n workflow creates emails like this:

```
Docker Health Report
Report Time: 2025-11-30T09:00:00Z
Summary: 19/20 containers running

⚠️ Stopped Containers
• old-container-name

🚨 Issues Detected
youtube-transcripts-api - unhealthy
Container health check failing

✅ All Systems Healthy (when no issues)

[Table showing all containers with status, health, restarts]
```

## Security Notes

- SSH is only exposed on localhost port 2223
- Docker socket is mounted read-only (`:ro`)
- Change the default password immediately!
- The container can read Docker info but can't modify containers
- For production, consider using SSH keys instead of passwords

## Troubleshooting

**n8n can't connect via SSH:**
- Try using `host.docker.internal` instead of `alpine-utility` as hostname
- Use port `2223` if connecting from outside Docker network
- Use port `22` if connecting from inside Docker network (container-to-container)

**Script shows no data:**
```bash
# Check if Docker socket is accessible
docker exec alpine-utility docker ps
```

**Permission denied:**
```bash
# Make sure script is executable
docker exec alpine-utility chmod +x /scripts/docker-monitor.sh
```

## Next Steps

1. Change the default password in `.env`
2. Import the workflow into n8n
3. Configure your email credentials in n8n
4. Test the workflow manually
5. Set your preferred schedule (daily, every 6 hours, etc.)

## Need Help?

- Check the logs: `docker logs alpine-utility`
- Test SSH: `ssh -p 2223 root@localhost`
- Test script: `docker exec alpine-utility /scripts/docker-monitor.sh`
- n8n documentation: https://docs.n8n.io/

Enjoy your automated Docker monitoring! 🎉
