# Homelab Logging Architecture

Centralized log collection and analysis for network infrastructure and Docker containers.

---

## Architecture Overview

```
Unifi Devices (Router/Switch/AP)
    └─> CEF Syslog via UDP (port 5140)
         └─> Fluent Bit (syslog input + custom parser)
              └─> VictoriaLogs (storage & query)
                   └─> n8n + Ollama (AI analysis)
                        └─> Email Reports
```

---

## Components

### 1. Fluent Bit (Log Collector)
- **Container:** `fluent-bit`
- **Port:** `5140/udp` (syslog input)
- **Config:** [`fluent-bit/fluent-bit.conf`](fluent-bit/fluent-bit.conf)
- **Parser:** [`fluent-bit/parsers.conf`](fluent-bit/parsers.conf)
- **Purpose:** Receives CEF syslog from Unifi devices, parses, and forwards to VictoriaLogs

**How It Works:**
1. **UDP Input:** Listens on port 5140 using `syslog` input mode
   - Handles non-newline-terminated UDP packets (UniFi sends 83-byte packets without trailing `\n`)
   - Uses custom `unifi-cef` parser to extract fields
2. **Parsing:** Regex extracts timestamp, hostname, and CEF message
   - Preserves full CEF format in `message` field for downstream analysis
3. **Enrichment:** Adds `source=unifi-siem` tag via modify filter
4. **Forwarding:** Sends structured JSON to VictoriaLogs via HTTP POST

**Critical Requirement:**
> **⚠️ Docker Desktop Setting Required (macOS):**
> Enable "Use kernel networking for UDP" in Docker Desktop → Settings → Resources → Network
> This is required for bridge networking to properly handle external UDP traffic to containers

### 2. VictoriaLogs (Storage & Query Engine)
- **Container:** `victoria-logs`
- **Web UI:** http://localhost:9428
- **API Endpoint:** `http://victoria-logs:9428/insert/jsonline`
- **Retention:** 7 days
- **Storage:** `/Volumes/docker/container_configs/victoria-logs/`

**Features:**
- Fast log ingestion via HTTP API
- LogsQL query language (similar to LogQL)
- Time-series optimized storage
- Low resource footprint

**Query Examples:**
```bash
# Get all logs from last hour
curl -X POST 'http://localhost:9428/select/logsql/query' \
  -d 'query=_time:1h | limit 50'

# Search for specific text
curl -X POST 'http://localhost:9428/select/logsql/query' \
  -d 'query=* | grep "error" | limit 20'

# Filter by source
curl -X POST 'http://localhost:9428/select/logsql/query' \
  -d 'query=source:unifi-siem | limit 10'
```

### 3. n8n + Ollama (AI Analysis)
- **Workflow:** `victoria-logs-daily-digest.json` (planned)
- **Schedule:** Daily at 8 PM
- **AI Model:** Qwen2.5:7b (via Ollama)

**Analysis Workflow:**
1. Query VictoriaLogs for last 24 hours of logs
2. Send to Ollama for AI-powered analysis
3. Generate security threat assessment
4. Identify network health issues
5. Recommend actions
6. Send formatted email report

---

## Log Sources

### Current Sources

#### Unifi Network Devices
- **Type:** CEF payload in syslog header over UDP
- **Transport:** UDP (non-newline-terminated packets)
- **Categories:**
  - Device events (reboots, firmware updates)
  - Client activity (connections, disconnections)
  - Security detections (intrusion attempts)
  - Admin activity (configuration changes)
  - Triggers (alerts, threshold violations)
  - Critical events

**Configuration Location:**
- Unifi Controller → Settings → System → Integrations → SIEM Server
- **Host:** `192.168.0.9` (Mac Mini IP)
- **Port:** `5140`

### Future Sources (Planned)

- Docker container logs (all homelab services)
- Home Assistant logs (smart home events)
- Zeek network monitoring (deep packet inspection)
- macOS system logs (host-level monitoring)

---

## Data Flow Details

### Syslog Ingestion (Step-by-Step)
1. **UniFi generates event** → Device/client/admin activity triggers CEF syslog
2. **UDP transmission** → 83-byte CEF packet sent to `192.168.0.9:5140` (no trailing newline)
3. **Fluent Bit receives** → Syslog input plugin captures packet via UDP
4. **Parser execution** → `unifi-cef` regex extracts:
   - `time`: Syslog timestamp (e.g., "Feb 12 15:36:46")
   - `host`: Full hostname including spaces (e.g., "Titanium House")
   - `message`: Full CEF payload (e.g., "CEF:0|Ubiquiti|UniFi OS|4.4.11|admins|1|msg=User login")
5. **Filter enrichment** → Adds `source=unifi-siem` tag
6. **JSON conversion** → Structured log record created
7. **HTTP forward** → POST to VictoriaLogs at `/insert/jsonline`
8. **Storage** → VictoriaLogs indexes and stores with 7-day retention

### Log Query & Retrieval
1. **User/n8n queries** → HTTP POST to `/select/logsql/query`
2. **LogsQL parsing** → VictoriaLogs parses query
3. **Time-series scan** → Efficient retrieval from storage
4. **Results returned** → JSON format
5. **AI analysis** (optional) → Ollama processes results
6. **Presentation** → Web UI, email, or API response

---

## File Structure

```
logging/
├── README.md                    # This file - architecture overview
├── fluent-bit/
│   ├── fluent-bit.conf          # Main Fluent Bit configuration
│   └── parsers.conf             # Custom UniFi CEF parser
└── (future: filters, transforms, additional parsers)
```

---

## Configuration Files

### fluent-bit.conf
Production configuration for UniFi CEF syslog parsing:

```ini
[SERVICE]
    Flush        1
    Daemon       Off
    Log_Level    info
    Parsers_File /fluent-bit/etc/parsers.conf
    Parsers_File /fluent-bit/etc/custom-parsers.conf

[INPUT]
    Name         syslog
    Mode         udp
    Listen       0.0.0.0
    Port         5140
    Parser       unifi-cef
    Tag          unifi

[FILTER]
    Name         modify
    Match        unifi
    Add          source unifi-siem
    Rename       message _msg

[OUTPUT]
    Name         http
    Match        unifi
    Host         victoria-logs
    Port         9428
    URI          /insert/jsonline
    Format       json_lines
```

**Key Configuration Choices:**
- **Syslog input mode:** Handles non-newline-terminated UDP packets (unlike raw `udp` input)
- **Custom parser:** Extracts structured fields while preserving full CEF message
- **Source tagging:** Identifies logs as coming from UniFi SIEM
- **HTTP output:** Efficient JSON line protocol to VictoriaLogs

### parsers.conf
Custom parser for UniFi CEF format:

```ini
[PARSER]
    Name        unifi-cef
    Format      regex
    Regex       ^(?<time>[A-Z][a-z]{2} [ 0-9][0-9] [0-9]{2}:[0-9]{2}:[0-9]{2}) (?<host>.+?) (?<message>CEF:.*)$
    Time_Key    time
    Time_Format %b %d %H:%M:%S
    Time_Keep   On
```

**Parser Explanation:**
- Captures syslog timestamp (RFC3164 format)
- Extracts full hostname including spaces (non-greedy match up to CEF marker)
- Preserves entire CEF message starting from "CEF:" for downstream parsing
- Keeps original timestamp for correlation
- Renamed to `_msg` field via modify filter for VictoriaLogs UI compatibility

---

## Troubleshooting

### Check if Fluent Bit is receiving logs
```bash
docker logs fluent-bit --tail 50
# Look for info-level output showing received messages
```

### Query VictoriaLogs directly
```bash
# Get all logs
curl -s 'http://localhost:9428/select/logsql/query' -d 'query=*' | jq

# Count logs by hour
curl -s 'http://localhost:9428/metrics' | grep vl_rows_ingested_total
```

### Test syslog sending
```bash
# Send test message
echo "<14>$(date '+%b %d %H:%M:%S') test-host Test message" | nc -u localhost 5140

# Check if it arrived (wait 2 seconds)
sleep 2
curl -s 'http://localhost:9428/select/logsql/query' -d 'query=* | limit 1'
```

### Common Issues

**No logs appearing:**
1. Check Fluent Bit is running: `docker ps | grep fluent-bit`
2. Verify port is listening: `netstat -an | grep 5140`
3. Check Unifi SIEM config is saved and active
4. Look for errors: `docker logs fluent-bit --tail 100`

**Parser errors in Fluent Bit:**
- Check `docker logs fluent-bit` for parsing warnings
- Verify custom parser file is mounted correctly in compose.yml
- Test parser with: `printf 'Feb 12 15:36:46 Titanium House CEF:0|test' | nc -u -w1 192.168.0.9 5140`

**VictoriaLogs web UI shows "No logs":**
- API queries work but UI doesn't (known issue in some versions)
- Use API queries or wait for time range to sync
- Try changing time range to "Last 1 Hour" or "Last 24 Hours"

---

## Metrics & Monitoring

### VictoriaLogs Metrics
```bash
curl -s 'http://localhost:9428/metrics' | grep vl_rows
```

Key metrics:
- `vl_rows_ingested_total` - Total logs ingested
- `vl_rows_dropped_total` - Logs rejected/dropped
- `vl_active_merges` - Background merge operations
- `vl_storage_size_bytes` - Disk usage

### Resource Usage
- **Fluent Bit:** ~50-100 MB RAM, minimal CPU
- **VictoriaLogs:** ~500 MB - 1 GB RAM, 7-day retention

---

## Future Enhancements

### Short-term
- [x] Identify Unifi syslog format and add parsing
- [ ] Add CEF field extraction for deeper analysis
- [ ] Create n8n daily digest workflow
- [ ] Set up email alerting for critical events

### Long-term
- [ ] Docker container logs ingestion
- [ ] Grafana dashboards for visualization
- [ ] Real-time alerting (Slack/Discord)
- [ ] Home Assistant integration
- [ ] Zeek network monitoring
- [ ] Anomaly detection via AI

---

## Related Documentation

- [VictoriaLogs Documentation](https://docs.victoriametrics.com/victorialogs/)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [n8n Workflows README](../n8n-workflows/README.md)
- [Homelab AGENTS.md](../AGENTS.md) - AI assistant guidelines

---

**Last Updated:** February 12, 2026
**Status:** ✅ Operational - UniFi SIEM successfully integrated with VictoriaLogs
