#!/bin/bash

# Backup Verification Script
# Verifies backup integrity and freshness for all backup artifacts
# Outputs machine-readable JSON for monitoring and alerting
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

# Configuration
BACKUP_ROOT="/mnt/backups"
HEALTH_DIR="${BACKUP_ROOT}/health"
HEALTH_JSON="${HEALTH_DIR}/backup_verification_latest.json"
TEMP_BASE="/tmp/backup-verify"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
TEMP_DIR="${TEMP_BASE}/${TIMESTAMP}"

# Alert thresholds (in hours)
DAILY_BACKUP_THRESHOLD=26
MONTHLY_BACKUP_THRESHOLD=960  # 40 days

# Exit code tracking
EXIT_CODE=0

# Create temp workspace and health directory
mkdir -p "$TEMP_DIR"
mkdir -p "$HEALTH_DIR"

# Cleanup on exit
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# JSON output structure
declare -A RESULTS

# Helper function to check file freshness (in hours)
check_freshness() {
    local file=$1
    local threshold=$2

    if [ ! -f "$file" ]; then
        echo "missing"
        return 1
    fi

    local file_time=$(stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null)
    local current_time=$(date +%s)
    local age_hours=$(( (current_time - file_time) / 3600 ))

    if [ $age_hours -gt $threshold ]; then
        echo "stale:${age_hours}h"
        return 1
    fi

    echo "fresh:${age_hours}h"
    return 0
}

# Helper function to get newest file matching pattern
get_newest_file() {
    local dir=$1
    local pattern=$2

    ls -t "${dir}/${pattern}" 2>/dev/null | head -1 || echo ""
}

echo "========================================"
echo "Backup Verification - ${TIMESTAMP}"
echo "========================================"

# 1. Verify Gitea Backups
echo ""
echo "[1/5] Verifying Gitea backups..."

GITEA_DB_DIR="${BACKUP_ROOT}/gitea/database"
GITEA_REPO_DIR="${BACKUP_ROOT}/gitea/repositories"
GITEA_STATUS="pass"
GITEA_DETAILS=""

# Check Gitea database backup
NEWEST_GITEA_DB=$(get_newest_file "$GITEA_DB_DIR" "gitea-db-*.db")
if [ -n "$NEWEST_GITEA_DB" ]; then
    echo "  Latest DB backup: $(basename "$NEWEST_GITEA_DB")"

    # Check freshness
    FRESHNESS=$(check_freshness "$NEWEST_GITEA_DB" $DAILY_BACKUP_THRESHOLD) || {
        echo "  ❌ DB backup is $FRESHNESS"
        GITEA_STATUS="fail"
        GITEA_DETAILS="${GITEA_DETAILS}DB is $FRESHNESS. "
        EXIT_CODE=1
    }

    if [ "$GITEA_STATUS" = "pass" ]; then
        echo "  ✓ DB freshness: $FRESHNESS"
    fi

    # Verify SQLite integrity
    echo "  Testing SQLite integrity..."
    cp "$NEWEST_GITEA_DB" "${TEMP_DIR}/gitea_test.db"

    INTEGRITY_CHECK=$(sqlite3 "${TEMP_DIR}/gitea_test.db" "PRAGMA integrity_check;" 2>&1) || {
        echo "  ❌ SQLite integrity check failed"
        GITEA_STATUS="fail"
        GITEA_DETAILS="${GITEA_DETAILS}DB integrity check failed. "
        EXIT_CODE=1
    }

    if [ "$INTEGRITY_CHECK" = "ok" ]; then
        echo "  ✓ SQLite integrity: ok"
    else
        echo "  ❌ SQLite integrity: $INTEGRITY_CHECK"
        GITEA_STATUS="fail"
        GITEA_DETAILS="${GITEA_DETAILS}DB integrity: $INTEGRITY_CHECK. "
        EXIT_CODE=1
    fi
else
    echo "  ❌ No Gitea DB backup found"
    GITEA_STATUS="fail"
    GITEA_DETAILS="No DB backup found. "
    EXIT_CODE=1
fi

# Check Gitea repository backup
NEWEST_GITEA_REPO=$(get_newest_file "$GITEA_REPO_DIR" "gitea-repos-*.zip")
if [ -n "$NEWEST_GITEA_REPO" ]; then
    echo "  Latest repo backup: $(basename "$NEWEST_GITEA_REPO")"

    # Check freshness
    FRESHNESS=$(check_freshness "$NEWEST_GITEA_REPO" $DAILY_BACKUP_THRESHOLD) || {
        echo "  ❌ Repo backup is $FRESHNESS"
        GITEA_STATUS="fail"
        GITEA_DETAILS="${GITEA_DETAILS}Repo is $FRESHNESS. "
        EXIT_CODE=1
    }

    if [[ "$GITEA_STATUS" != "fail" || "$FRESHNESS" == fresh:* ]]; then
        echo "  ✓ Repo freshness: $FRESHNESS"
    fi

    # Test zip integrity
    echo "  Testing zip integrity..."
    if unzip -t "$NEWEST_GITEA_REPO" >/dev/null 2>&1; then
        echo "  ✓ Zip integrity: ok"
    else
        echo "  ❌ Zip integrity check failed"
        GITEA_STATUS="fail"
        GITEA_DETAILS="${GITEA_DETAILS}Repo zip corrupted. "
        EXIT_CODE=1
    fi
else
    echo "  ❌ No Gitea repo backup found"
    GITEA_STATUS="fail"
    GITEA_DETAILS="${GITEA_DETAILS}No repo backup found. "
    EXIT_CODE=1
fi

RESULTS[gitea]="${GITEA_STATUS}|${GITEA_DETAILS}"

# 2. Verify Garage Tracker Backups
echo ""
echo "[2/5] Verifying Garage Tracker backups..."

GARAGE_DIR="${BACKUP_ROOT}/garage-tracker"
GARAGE_STATUS="pass"
GARAGE_DETAILS=""

NEWEST_GARAGE=$(get_newest_file "$GARAGE_DIR" "garage-*.db")
if [ -n "$NEWEST_GARAGE" ]; then
    echo "  Latest backup: $(basename "$NEWEST_GARAGE")"

    # Check freshness
    FRESHNESS=$(check_freshness "$NEWEST_GARAGE" $DAILY_BACKUP_THRESHOLD) || {
        echo "  ❌ Backup is $FRESHNESS"
        GARAGE_STATUS="fail"
        GARAGE_DETAILS="Backup is $FRESHNESS. "
        EXIT_CODE=1
    }

    if [ "$GARAGE_STATUS" = "pass" ]; then
        echo "  ✓ Freshness: $FRESHNESS"
    fi

    # Verify SQLite integrity
    echo "  Testing SQLite integrity..."
    cp "$NEWEST_GARAGE" "${TEMP_DIR}/garage_test.db"

    INTEGRITY_CHECK=$(sqlite3 "${TEMP_DIR}/garage_test.db" "PRAGMA integrity_check;" 2>&1) || {
        echo "  ❌ SQLite integrity check failed"
        GARAGE_STATUS="fail"
        GARAGE_DETAILS="${GARAGE_DETAILS}Integrity check failed. "
        EXIT_CODE=1
    }

    if [ "$INTEGRITY_CHECK" = "ok" ]; then
        echo "  ✓ SQLite integrity: ok"
    else
        echo "  ❌ SQLite integrity: $INTEGRITY_CHECK"
        GARAGE_STATUS="fail"
        GARAGE_DETAILS="${GARAGE_DETAILS}Integrity: $INTEGRITY_CHECK. "
        EXIT_CODE=1
    fi
else
    echo "  ❌ No Garage backup found"
    GARAGE_STATUS="fail"
    GARAGE_DETAILS="No backup found. "
    EXIT_CODE=1
fi

RESULTS[garage]="${GARAGE_STATUS}|${GARAGE_DETAILS}"

# 3. Verify Karakeep Backups
echo ""
echo "[3/5] Verifying Karakeep backups..."

KARAKEEP_DIR="${BACKUP_ROOT}/karakeep"
KARAKEEP_STATUS="pass"
KARAKEEP_DETAILS=""

NEWEST_KARAKEEP=$(ls -td "${KARAKEEP_DIR}"/karakeep_backup_* 2>/dev/null | head -1 || echo "")
if [ -n "$NEWEST_KARAKEEP" ]; then
    echo "  Latest backup: $(basename "$NEWEST_KARAKEEP")"

    # Check freshness (check directory modification time)
    FRESHNESS=$(check_freshness "$NEWEST_KARAKEEP" $DAILY_BACKUP_THRESHOLD) || {
        echo "  ❌ Backup is $FRESHNESS"
        KARAKEEP_STATUS="fail"
        KARAKEEP_DETAILS="Backup is $FRESHNESS. "
        EXIT_CODE=1
    }

    if [ "$KARAKEEP_STATUS" = "pass" ]; then
        echo "  ✓ Freshness: $FRESHNESS"
    fi

    # Check if backup directory is not empty
    if [ ! "$(ls -A "$NEWEST_KARAKEEP")" ]; then
        echo "  ❌ Backup directory is empty"
        KARAKEEP_STATUS="fail"
        KARAKEEP_DETAILS="${KARAKEEP_DETAILS}Empty backup directory. "
        EXIT_CODE=1
    else
        echo "  ✓ Backup directory contains files"
    fi

    # Check for SQLite DB if it exists and verify integrity
    KARAKEEP_DB=$(find "$NEWEST_KARAKEEP" -name "*.db" -type f | head -1)
    if [ -n "$KARAKEEP_DB" ]; then
        echo "  Testing SQLite DB integrity..."
        cp "$KARAKEEP_DB" "${TEMP_DIR}/karakeep_test.db"

        INTEGRITY_CHECK=$(sqlite3 "${TEMP_DIR}/karakeep_test.db" "PRAGMA integrity_check;" 2>&1) || {
            echo "  ❌ SQLite integrity check failed"
            KARAKEEP_STATUS="fail"
            KARAKEEP_DETAILS="${KARAKEEP_DETAILS}DB integrity failed. "
            EXIT_CODE=1
        }

        if [ "$INTEGRITY_CHECK" = "ok" ]; then
            echo "  ✓ SQLite integrity: ok"
        else
            echo "  ❌ SQLite integrity: $INTEGRITY_CHECK"
            KARAKEEP_STATUS="fail"
            KARAKEEP_DETAILS="${KARAKEEP_DETAILS}DB integrity: $INTEGRITY_CHECK. "
            EXIT_CODE=1
        fi
    fi
else
    echo "  ❌ No Karakeep backup found"
    KARAKEEP_STATUS="fail"
    KARAKEEP_DETAILS="No backup found. "
    EXIT_CODE=1
fi

RESULTS[karakeep]="${KARAKEEP_STATUS}|${KARAKEEP_DETAILS}"

# 4. Verify Budget Dashboard (Main) Monthly Snapshots
echo ""
echo "[4/5] Verifying Budget Dashboard monthly snapshots..."

BUDGET_DIR="${BACKUP_ROOT}/budget-dashboard"
BUDGET_STATUS="pass"
BUDGET_DETAILS=""

# Check JSON backup
NEWEST_BUDGET_JSON=$(get_newest_file "$BUDGET_DIR" "budget_data_*.json")
if [ -n "$NEWEST_BUDGET_JSON" ]; then
    echo "  Latest JSON: $(basename "$NEWEST_BUDGET_JSON")"

    # Check freshness (40 days for monthly)
    FRESHNESS=$(check_freshness "$NEWEST_BUDGET_JSON" $MONTHLY_BACKUP_THRESHOLD) || {
        echo "  ⚠️  JSON backup is $FRESHNESS (monthly backup)"
        BUDGET_STATUS="warn"
        BUDGET_DETAILS="JSON is $FRESHNESS. "
    }

    if [ "$BUDGET_STATUS" = "pass" ]; then
        echo "  ✓ JSON freshness: $FRESHNESS"
    fi

    # Validate JSON syntax
    echo "  Validating JSON syntax..."
    if jq empty "$NEWEST_BUDGET_JSON" 2>/dev/null; then
        echo "  ✓ JSON syntax: valid"
    else
        echo "  ❌ JSON syntax: invalid"
        BUDGET_STATUS="fail"
        BUDGET_DETAILS="${BUDGET_DETAILS}Invalid JSON syntax. "
        EXIT_CODE=1
    fi
else
    echo "  ❌ No budget JSON backup found"
    BUDGET_STATUS="fail"
    BUDGET_DETAILS="No JSON backup found. "
    EXIT_CODE=1
fi

# Check CSV backup
NEWEST_BUDGET_CSV=$(get_newest_file "$BUDGET_DIR" "budget_snapshot_*.csv")
if [ -n "$NEWEST_BUDGET_CSV" ]; then
    echo "  Latest CSV: $(basename "$NEWEST_BUDGET_CSV")"

    # Check freshness
    FRESHNESS=$(check_freshness "$NEWEST_BUDGET_CSV" $MONTHLY_BACKUP_THRESHOLD) || {
        echo "  ⚠️  CSV backup is $FRESHNESS (monthly backup)"
        if [ "$BUDGET_STATUS" != "fail" ]; then
            BUDGET_STATUS="warn"
        fi
        BUDGET_DETAILS="${BUDGET_DETAILS}CSV is $FRESHNESS. "
    }

    if [ "$BUDGET_STATUS" = "pass" ]; then
        echo "  ✓ CSV freshness: $FRESHNESS"
    fi

    # Basic CSV validation (check header exists)
    echo "  Validating CSV structure..."
    if head -1 "$NEWEST_BUDGET_CSV" | grep -q "BUDGET DASHBOARD"; then
        echo "  ✓ CSV header: valid"
    else
        echo "  ❌ CSV header: invalid or missing"
        BUDGET_STATUS="fail"
        BUDGET_DETAILS="${BUDGET_DETAILS}Invalid CSV structure. "
        EXIT_CODE=1
    fi
else
    echo "  ❌ No budget CSV backup found"
    BUDGET_STATUS="fail"
    BUDGET_DETAILS="${BUDGET_DETAILS}No CSV backup found. "
    EXIT_CODE=1
fi

RESULTS[budget]="${BUDGET_STATUS}|${BUDGET_DETAILS}"

# 5. Verify Budget Dashboard GF Monthly Snapshots (if exists)
echo ""
echo "[5/5] Verifying Budget Dashboard GF monthly snapshots..."

BUDGET_GF_DIR="${BACKUP_ROOT}/budget-dashboard-gf"
BUDGET_GF_STATUS="pass"
BUDGET_GF_DETAILS=""

if [ -d "$BUDGET_GF_DIR" ]; then
    # Check JSON backup
    NEWEST_BUDGET_GF_JSON=$(get_newest_file "$BUDGET_GF_DIR" "budget_data_*_gf.json")
    if [ -n "$NEWEST_BUDGET_GF_JSON" ]; then
        echo "  Latest JSON: $(basename "$NEWEST_BUDGET_GF_JSON")"

        # Check freshness
        FRESHNESS=$(check_freshness "$NEWEST_BUDGET_GF_JSON" $MONTHLY_BACKUP_THRESHOLD) || {
            echo "  ⚠️  JSON backup is $FRESHNESS (monthly backup)"
            BUDGET_GF_STATUS="warn"
            BUDGET_GF_DETAILS="JSON is $FRESHNESS. "
        }

        if [ "$BUDGET_GF_STATUS" = "pass" ]; then
            echo "  ✓ JSON freshness: $FRESHNESS"
        fi

        # Validate JSON syntax
        if jq empty "$NEWEST_BUDGET_GF_JSON" 2>/dev/null; then
            echo "  ✓ JSON syntax: valid"
        else
            echo "  ❌ JSON syntax: invalid"
            BUDGET_GF_STATUS="fail"
            BUDGET_GF_DETAILS="${BUDGET_GF_DETAILS}Invalid JSON syntax. "
            EXIT_CODE=1
        fi
    else
        echo "  ⚠️  No budget GF JSON backup found (may not be in use)"
        BUDGET_GF_STATUS="skip"
        BUDGET_GF_DETAILS="No backups found (inactive). "
    fi

    # Check CSV backup
    NEWEST_BUDGET_GF_CSV=$(get_newest_file "$BUDGET_GF_DIR" "budget_snapshot_*_gf.csv")
    if [ -n "$NEWEST_BUDGET_GF_CSV" ]; then
        echo "  Latest CSV: $(basename "$NEWEST_BUDGET_GF_CSV")"

        # Check freshness
        FRESHNESS=$(check_freshness "$NEWEST_BUDGET_GF_CSV" $MONTHLY_BACKUP_THRESHOLD) || {
            echo "  ⚠️  CSV backup is $FRESHNESS (monthly backup)"
            if [ "$BUDGET_GF_STATUS" != "fail" ] && [ "$BUDGET_GF_STATUS" != "skip" ]; then
                BUDGET_GF_STATUS="warn"
            fi
            BUDGET_GF_DETAILS="${BUDGET_GF_DETAILS}CSV is $FRESHNESS. "
        }

        if [ "$BUDGET_GF_STATUS" = "pass" ]; then
            echo "  ✓ CSV freshness: $FRESHNESS"
        fi
    fi
else
    echo "  ⓘ Budget GF directory not found (inactive)"
    BUDGET_GF_STATUS="skip"
    BUDGET_GF_DETAILS="Directory not found (inactive). "
fi

RESULTS[budget_gf]="${BUDGET_GF_STATUS}|${BUDGET_GF_DETAILS}"

# Generate JSON output
echo ""
echo "========================================"
echo "Generating verification report..."

cat > "$HEALTH_JSON" <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "overall_status": "$([ $EXIT_CODE -eq 0 ] && echo "pass" || echo "fail")",
  "checks": {
    "gitea": {
      "status": "$(echo ${RESULTS[gitea]} | cut -d'|' -f1)",
      "details": "$(echo ${RESULTS[gitea]} | cut -d'|' -f2-)"
    },
    "garage": {
      "status": "$(echo ${RESULTS[garage]} | cut -d'|' -f1)",
      "details": "$(echo ${RESULTS[garage]} | cut -d'|' -f2-)"
    },
    "karakeep": {
      "status": "$(echo ${RESULTS[karakeep]} | cut -d'|' -f1)",
      "details": "$(echo ${RESULTS[karakeep]} | cut -d'|' -f2-)"
    },
    "budget": {
      "status": "$(echo ${RESULTS[budget]} | cut -d'|' -f1)",
      "details": "$(echo ${RESULTS[budget]} | cut -d'|' -f2-)"
    },
    "budget_gf": {
      "status": "$(echo ${RESULTS[budget_gf]} | cut -d'|' -f1)",
      "details": "$(echo ${RESULTS[budget_gf]} | cut -d'|' -f2-)"
    }
  }
}
EOF

echo "✓ Report saved to: $HEALTH_JSON"
echo "========================================"

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All backup verifications passed!"
else
    echo "❌ One or more backup verifications failed!"
fi

echo "========================================"

exit $EXIT_CODE
