# VictoriaLogs Monitoring Setup Guide

Quick start guide for setting up VictoriaLogs monitoring with AI-powered daily network health reports.

## What's Included

- **VictoriaLogs**: Centralized log aggregation (7-day retention)
- **N8N Workflow**: Daily digest with AI analysis via Ollama
- **Email Reports**: Automated security and network health assessments

---

## 🚀 Setup Steps

### 1. Start VictoriaLogs

```bash
cd /Users/bud/home_space/homelab
docker compose up -d victoria-logs
```

**Verify it's running:**
```bash
curl http://localhost:9428/health
# Should return: OK
```

### 2. Check Logs Are Being Collected

Wait a few minutes, then query:

```bash
curl -X POST http://localhost:9428/select/logsql/query \
  -d 'query=_time:5m | fields _time, _stream, log | limit 10'
```

You should see recent container logs.

### 3. Import N8N Workflow

1. Open n8n: http://localhost:5678
2. Click "+ Add workflow" → "Import from File"
3. Select: `homelab/n8n-workflows/victoria-logs-daily-digest.json`
4. Click "Import"

### 4. Test the Workflow

1. Open the imported workflow
2. Click "Execute Workflow" (manually run it)
3. Watch the nodes execute
4. Check the final "Send Email" node output

**You'll see the digest preview with:**
- Threat level
- Network health status
- Container issues
- AI recommendations

### 5. Set Up Email (Optional but Recommended)

Replace the "Send Email (Replace This)" node with a real email sender:

#### Option A: Gmail

1. Add Gmail credentials in n8n Settings → Credentials
2. Delete the noOp node
3. Add "Gmail" node
4. Map: `{{ $json.emailSubject }}` and `{{ $json.emailBody }}`

#### Option B: SMTP/SendGrid

1. Add SMTP credentials
2. Delete the noOp node
3. Add "Send Email" node
4. Same mapping

### 6. Activate the Workflow

Once you're happy with the test:

1. Toggle "Active" switch (top-right)
2. You'll get a daily email at 8 PM

---

## 📊 What You'll Get

Every evening at 8 PM, you'll receive an email with:

### 📋 Executive Summary
- Overall health status
- Key concerns
- Action needed?

### 🔒 Security Assessment
- Threat Level (Low/Medium/High/Critical)
- Authentication failures
- Security alerts
- Recommended actions

### 🌐 Network Health
- Status (Excellent/Good/Fair/Poor)
- Latency analysis
- Connection reliability
- Performance issues

### 🐳 Container Health
- Problematic containers
- Restart analysis
- Resource warnings

### 💡 Recommended Actions
- Prioritized, specific, actionable items

**All analyzed by your local Ollama AI!**

---

## 🔍 Future Enhancements

Once this is working, we can add:

1. **Unifi syslog forwarding** - Forward Unifi logs to VictoriaLogs
2. **Zeek network monitoring** - Deep packet inspection
3. **Real-time alerts** - Immediate notification for critical threats
4. **Grafana dashboards** - Visual log analysis
5. **Home Assistant integration** - Smart device log analysis

---

## 🛠️ Troubleshooting

### VictoriaLogs not starting

Check logs:
```bash
docker compose logs victoria-logs
```

### No logs appearing

Ensure containers are logging:
```bash
docker compose logs --tail 10
```

### N8N workflow fails

**Check Ollama is running:**
```bash
curl http://localhost:11434/api/tags
```

**Ensure qwen2.5:7b is installed:**
```bash
ollama pull qwen2.5:7b
```

### Email not sending

1. Check n8n execution logs
2. Verify email credentials
3. Test email node separately

---

## 📚 Related Documentation

- [n8n Workflows README](../../n8n-workflows/README.md) - Complete workflow documentation
- [VictoriaLogs Documentation](https://docs.victoriametrics.com/victorialogs/)
- [n8n Documentation](https://docs.n8n.io/)

---

**Last Updated:** December 18, 2025
**Setup Time:** ~15 minutes
