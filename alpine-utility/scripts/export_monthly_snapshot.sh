#!/bin/bash

# Monthly Budget Export Script
# This script exports budget data to CSV format for monthly snapshots
# Designed to be triggered by n8n on the last day of each month

# How to run #
# Switch to the directory, then provide the DATA_FILE_PATH when calling the script
# cd /Volumes/SSD/home_space/coding/python-budget-tracker
# DATA_FILE_PATH=/Volumes/docker/container_configs/budget-dashboard/app-data/budget_data.json ./export_monthly_snapshot.sh

# Configuration
# Paths are for alpine-utility container with mounted volumes

DATA_FILE="${DATA_FILE_PATH:-/mnt/budget-dashboard/budget_data.json}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-/mnt/backups/budget-dashboard}"
DATE_FORMAT=$(date +%m_%d_%Y)
TIMESTAMP=$(date +%Y-%m-%d)
OUTPUT_CSV="${SNAPSHOT_DIR}/budget_snapshot_${DATE_FORMAT}.csv"
OUTPUT_JSON="${SNAPSHOT_DIR}/budget_data_${DATE_FORMAT}.json"

# Create snapshot directory if it doesn't exist
mkdir -p "$SNAPSHOT_DIR"

# Check if data file exists
if [ ! -f "$DATA_FILE" ]; then
    echo "Error: Data file not found at $DATA_FILE"
    echo "Please set DATA_FILE_PATH environment variable or update the script"
    exit 1
fi

# Function to calculate sum of amounts in a JSON array
calculate_total() {
    local key=$1
    jq "[.${key}[]? | .amount // 0] | add // 0" "$DATA_FILE"
}

# Function to export items to CSV
export_items() {
    local category=$1
    local items=$(jq -r ".${category}[]? | @json" "$DATA_FILE" 2>/dev/null)

    if [ -n "$items" ]; then
        # Get keys from first item for header
        echo "$items" | head -1 | jq -r 'keys_unsorted | @csv'
        # Export all items
        echo "$items" | jq -r '[.[]] | @csv'
    fi
}

# Start building CSV
{
    echo "BUDGET DASHBOARD EXPORT - Monthly Snapshot"
    echo "Export Date: $TIMESTAMP"
    echo ""
    echo "SUMMARY"

    # Calculate totals
    paycheck_total=$(jq '[.paychecks[]? | .amount // 0] | add // 0' "$DATA_FILE")
    income_total=$(calculate_total "income")
    total_income=$(echo "$paycheck_total + $income_total" | bc)
    expenses_total=$(calculate_total "expenses")
    bills_total=$(calculate_total "bills")
    debt_total=$(calculate_total "debt")
    savings_total=$(calculate_total "savings")

    echo "Total Income,\$$total_income"
    echo "Total Bills,\$$bills_total"
    echo "Total Expenses,\$$expenses_total"
    echo "Total Debt Payments,\$$debt_total"
    echo "Total Savings,\$$savings_total"

    # Add target payment if set
    target_debt=$(jq -r '.target_payment.debt_name // ""' "$DATA_FILE")
    target_amount=$(jq -r '.target_payment.amount // 0' "$DATA_FILE")

    if [ -n "$target_debt" ] && [ "$target_debt" != "null" ]; then
        echo "Target Payment,$target_debt,\$$target_amount"
    fi

    echo ""

    # Export each category
    for category in paychecks income expenses bills debt debt_balances savings; do
        category_upper=$(echo "$category" | tr '[:lower:]' '[:upper:]')
        echo "$category_upper"

        items=$(export_items "$category")
        if [ -n "$items" ]; then
            echo "$items"
        fi
        echo ""
    done

} > "$OUTPUT_CSV"

# Copy the JSON data file as backup
cp "$DATA_FILE" "$OUTPUT_JSON"

# Check if both exports were successful
if [ -f "$OUTPUT_CSV" ] && [ -f "$OUTPUT_JSON" ]; then
    echo "✓ Monthly snapshot exported successfully!"
    echo "  CSV File: $OUTPUT_CSV"
    echo "  CSV Size: $(du -h "$OUTPUT_CSV" | cut -f1)"
    echo "  JSON Backup: $OUTPUT_JSON"
    echo "  JSON Size: $(du -h "$OUTPUT_JSON" | cut -f1)"
    exit 0
else
    echo "✗ Export failed"
    [ ! -f "$OUTPUT_CSV" ] && echo "  Missing: CSV file"
    [ ! -f "$OUTPUT_JSON" ] && echo "  Missing: JSON backup"
    exit 1
fi
