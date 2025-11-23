#!/bin/bash
#
# GCP Error Reporting - Fetch Errors Script
# This script fetches error groups from Google Cloud Error Reporting
#
# Usage: ./fetch-errors.sh PROJECT_ID [TIME_PERIOD] [PAGE_SIZE]
#
# Examples:
#   ./fetch-errors.sh my-project-123
#   ./fetch-errors.sh my-project-123 PERIOD_1_DAY 20
#   ./fetch-errors.sh my-project-123 PERIOD_6_HOURS 10
#

set -e

# Configuration
PROJECT_ID="${1}"
TIME_PERIOD="${2:-PERIOD_1_DAY}"
PAGE_SIZE="${3:-10}"

# Validate inputs
if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID is required"
    echo "Usage: $0 PROJECT_ID [TIME_PERIOD] [PAGE_SIZE]"
    exit 1
fi

# Valid time periods
VALID_PERIODS="PERIOD_1_HOUR PERIOD_6_HOURS PERIOD_1_DAY PERIOD_1_WEEK PERIOD_30_DAYS"
if ! echo "$VALID_PERIODS" | grep -q "$TIME_PERIOD"; then
    echo "Error: Invalid TIME_PERIOD: $TIME_PERIOD"
    echo "Valid periods: $VALID_PERIODS"
    exit 1
fi

# Get access token
echo "Fetching access token..." >&2
ACCESS_TOKEN=$(gcloud auth application-default print-access-token 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Failed to get access token. Please authenticate first:" >&2
    echo "  gcloud auth application-default login" >&2
    exit 1
fi

# Build API URL
API_URL="https://clouderrorreporting.googleapis.com/v1beta1/projects/${PROJECT_ID}/groupStats"
API_URL="${API_URL}?timeRange.period=${TIME_PERIOD}&pageSize=${PAGE_SIZE}"

echo "Fetching error groups from project: $PROJECT_ID" >&2
echo "Time period: $TIME_PERIOD" >&2
echo "Max results: $PAGE_SIZE" >&2
echo "" >&2

# Fetch errors
RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "$API_URL")

# Check for errors in response
if echo "$RESPONSE" | grep -q '"error"'; then
    echo "API Error:" >&2
    echo "$RESPONSE" | jq -r '.error.message' >&2
    exit 1
fi

# Output the response
echo "$RESPONSE" | jq '.'

# Summary
ERROR_COUNT=$(echo "$RESPONSE" | jq -r '.errorGroupStats | length')
echo "" >&2
echo "Found $ERROR_COUNT error groups" >&2
