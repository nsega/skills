#!/bin/bash
#
# GCP Error Reporting - Fetch Error Events Script
# This script fetches detailed error events for a specific error group
#
# Usage: ./fetch-error-events.sh PROJECT_ID GROUP_ID [PAGE_SIZE]
#
# Examples:
#   ./fetch-error-events.sh my-project-123 abc123def456
#   ./fetch-error-events.sh my-project-123 abc123def456 5
#

set -e

# Configuration
PROJECT_ID="${1}"
GROUP_ID="${2}"
PAGE_SIZE="${3:-5}"

# Validate inputs
if [ -z "$PROJECT_ID" ] || [ -z "$GROUP_ID" ]; then
    echo "Error: PROJECT_ID and GROUP_ID are required"
    echo "Usage: $0 PROJECT_ID GROUP_ID [PAGE_SIZE]"
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
API_URL="https://clouderrorreporting.googleapis.com/v1beta1/projects/${PROJECT_ID}/events"
API_URL="${API_URL}?groupId=${GROUP_ID}&pageSize=${PAGE_SIZE}"

echo "Fetching error events for group: $GROUP_ID" >&2
echo "Project: $PROJECT_ID" >&2
echo "Max results: $PAGE_SIZE" >&2
echo "" >&2

# Fetch events
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
EVENT_COUNT=$(echo "$RESPONSE" | jq -r '.errorEvents | length')
echo "" >&2
echo "Found $EVENT_COUNT error events" >&2
