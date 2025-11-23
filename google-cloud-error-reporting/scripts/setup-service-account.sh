#!/bin/bash
#
# GCP Error Reporting - Setup Service Account
# This script creates a service account with Error Reporting viewer permissions
#
# Usage: ./setup-service-account.sh PROJECT_ID [SERVICE_ACCOUNT_NAME] [KEY_FILE_PATH]
#
# Examples:
#   ./setup-service-account.sh my-project-123
#   ./setup-service-account.sh my-project-123 error-viewer ~/gcp-error-key.json
#

set -e

# Configuration
PROJECT_ID="${1}"
SERVICE_ACCOUNT_NAME="${2:-error-reporter-viewer}"
KEY_FILE_PATH="${3:-$HOME/gcp-error-key.json}"

# Validate inputs
if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID is required"
    echo "Usage: $0 PROJECT_ID [SERVICE_ACCOUNT_NAME] [KEY_FILE_PATH]"
    exit 1
fi

echo "Setting up GCP Error Reporting service account..."
echo "Project ID: $PROJECT_ID"
echo "Service Account: $SERVICE_ACCOUNT_NAME"
echo "Key File: $KEY_FILE_PATH"
echo ""

# Create service account
echo "Creating service account..."
gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
  --display-name="Error Reporting Viewer for Claude Code" \
  --project="$PROJECT_ID" || echo "Service account may already exist, continuing..."

SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant Error Reporting Viewer role
echo "Granting Error Reporting Viewer role..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
  --role="roles/errorreporting.viewer"

# Create and download key
echo "Creating service account key..."
gcloud iam service-accounts keys create "$KEY_FILE_PATH" \
  --iam-account="$SERVICE_ACCOUNT_EMAIL" \
  --project="$PROJECT_ID"

echo ""
echo "✓ Service account setup complete!"
echo ""
echo "Next steps:"
echo "1. Set the environment variable:"
echo "   export GOOGLE_APPLICATION_CREDENTIALS=\"$KEY_FILE_PATH\""
echo ""
echo "2. Test the setup:"
echo "   gcloud auth application-default print-access-token"
echo ""
echo "3. Fetch errors:"
echo "   ./fetch-errors.sh $PROJECT_ID"
