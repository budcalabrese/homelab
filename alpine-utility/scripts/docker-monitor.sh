#!/bin/bash

# Docker Health Monitor Script
# Returns JSON with container statuses and recent errors

# Get current timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Start JSON output
echo "{"
echo "  \"timestamp\": \"$TIMESTAMP\","
echo "  \"containers\": ["

# Get all containers
CONTAINERS=$(docker ps -a --format '{{.Names}}')
FIRST=true

for CONTAINER in $CONTAINERS; do
    if [ "$FIRST" = false ]; then
        echo "    ,"
    fi
    FIRST=false

    # Get container details
    STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER" 2>/dev/null || echo "unknown")
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo "none")
    HEALTH=$(echo "$HEALTH" | tr -d '\n\r' | xargs)

    # Check if container was restarted recently (within last hour)
    STARTED_AT=$(docker inspect --format='{{.State.StartedAt}}' "$CONTAINER" 2>/dev/null || echo "")
    NOW_EPOCH=$(date +%s)
    # Convert ISO 8601 to epoch (Alpine/BusyBox compatible)
    START_EPOCH=$(date -d "$STARTED_AT" +%s 2>/dev/null || echo "$NOW_EPOCH")
    UPTIME_HOURS=$(( ($NOW_EPOCH - $START_EPOCH) / 3600 ))

    # Only flag as restart issue if uptime is less than 1 hour (recent restart/instability)
    TOTAL_RESTARTS=$(docker inspect --format='{{.RestartCount}}' "$CONTAINER" 2>/dev/null || echo "0")
    if [ "$UPTIME_HOURS" -lt 1 ] && [ "$TOTAL_RESTARTS" -gt 0 ]; then
        RESTARTS=$TOTAL_RESTARTS
    else
        RESTARTS=0
    fi

    # Count errors and warnings
    ERROR_COUNT=$(docker logs "$CONTAINER" --since 24h --tail 100 2>&1 | grep -icE "(error|fatal|exception|failed)" 2>/dev/null || echo "0")
    ERROR_COUNT=$(echo "$ERROR_COUNT" | tr -d '\n\r' | xargs | sed 's/^0*//' | grep -E '^[0-9]+$' || echo "0")
    ERROR_COUNT=${ERROR_COUNT:-0}

    WARN_COUNT=$(docker logs "$CONTAINER" --since 24h --tail 100 2>&1 | grep -icE "(warn|warning)" 2>/dev/null || echo "0")
    WARN_COUNT=$(echo "$WARN_COUNT" | tr -d '\n\r' | xargs | sed 's/^0*//' | grep -E '^[0-9]+$' || echo "0")
    WARN_COUNT=${WARN_COUNT:-0}

    # Determine boolean values
    if [ "$ERROR_COUNT" -gt 0 ]; then
        HAS_ERRORS="true"
    else
        HAS_ERRORS="false"
    fi

    if [ "$WARN_COUNT" -gt 0 ]; then
        HAS_WARNS="true"
    else
        HAS_WARNS="false"
    fi

    # Build JSON object
    echo "    {"
    echo "      \"name\": \"$CONTAINER\","
    echo "      \"status\": \"$STATUS\","
    echo "      \"health\": \"$HEALTH\","
    echo "      \"restarts\": $RESTARTS,"
    echo "      \"error_count\": $ERROR_COUNT,"
    echo "      \"warning_count\": $WARN_COUNT,"
    echo "      \"has_errors\": $HAS_ERRORS,"
    echo "      \"has_warnings\": $HAS_WARNS"
    echo -n "    }"
done

echo ""
echo "  ],"

# Check Gitea health
GITEA_URL="http://192.168.0.9:3002/api/healthz"
GITEA_RESPONSE=$(curl -s -m 5 "$GITEA_URL" 2>/dev/null)
GITEA_STATUS=$(echo "$GITEA_RESPONSE" | jq -r '.status' 2>/dev/null)
GITEA_STATUS=${GITEA_STATUS:-error}
[ -z "$GITEA_STATUS" ] && GITEA_STATUS="error"
GITEA_CACHE=$(echo "$GITEA_RESPONSE" | jq -r '.checks."cache:ping"[0].status' 2>/dev/null)
GITEA_CACHE=${GITEA_CACHE:-error}
[ -z "$GITEA_CACHE" ] && GITEA_CACHE="error"
GITEA_DB=$(echo "$GITEA_RESPONSE" | jq -r '.checks."database:ping"[0].status' 2>/dev/null)
GITEA_DB=${GITEA_DB:-error}
[ -z "$GITEA_DB" ] && GITEA_DB="error"

# Determine if Gitea is healthy
if [ "$GITEA_STATUS" = "pass" ] && [ "$GITEA_CACHE" = "pass" ] && [ "$GITEA_DB" = "pass" ]; then
    GITEA_HEALTHY="true"
    GITEA_ERROR="false"
else
    GITEA_HEALTHY="false"
    GITEA_ERROR="true"
fi

echo "  \"gitea\": {"
echo "    \"url\": \"$GITEA_URL\","
echo "    \"status\": \"$GITEA_STATUS\","
echo "    \"cache_status\": \"$GITEA_CACHE\","
echo "    \"database_status\": \"$GITEA_DB\","
echo "    \"healthy\": $GITEA_HEALTHY,"
echo "    \"has_error\": $GITEA_ERROR"
echo "  },"

# Get overall stats
RUNNING=$(docker ps -q 2>/dev/null | wc -l | tr -d ' \n\r')
STOPPED=$(docker ps -a -q -f status=exited 2>/dev/null | wc -l | tr -d ' \n\r')
TOTAL=$(docker ps -a -q 2>/dev/null | wc -l | tr -d ' \n\r')

echo "  \"summary\": {"
echo "    \"total\": ${TOTAL:-0},"
echo "    \"running\": ${RUNNING:-0},"
echo "    \"stopped\": ${STOPPED:-0}"
echo "  }"
echo "}"
