# GCP Error Reporting Integration Skill

A Claude Code skill that integrates Google Cloud Error Reporting with automated codebase search and error diagnosis.

## Overview

This skill enables Claude Code to:
- 🔍 **Fetch errors** from Google Cloud Error Reporting API
- 🔎 **Search your codebase** for files and functions mentioned in error stack traces
- 🧠 **Diagnose issues** by analyzing error context and related code
- 💡 **Recommend fixes** based on error patterns and code analysis
- 📊 **Prioritize errors** by impact, frequency, and trends

## Quick Start

### 1. Install the Skill

If using Claude Code with the skills repository:

```bash
# Install from the marketplace
/plugin install example-skills@anthropic-agent-skills
```

Or copy this skill directory to your local skills folder.

### 2. Set Up GCP Authentication

**Option A: Use your own credentials (for development)**

```bash
gcloud auth application-default login
```

**Option B: Use a service account (for production)**

```bash
# Run the setup script
cd google-cloud-error-reporting/scripts
chmod +x setup-service-account.sh
./setup-service-account.sh YOUR_PROJECT_ID

# Follow the instructions to set GOOGLE_APPLICATION_CREDENTIALS
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/gcp-error-key.json"
```

### 3. Enable the Error Reporting API

```bash
gcloud services enable clouderrorreporting.googleapis.com --project=YOUR_PROJECT_ID
```

### 4. Use the Skill

In Claude Code, simply mention you want to analyze GCP errors:

```
Use the google-cloud-error-reporting skill to check for errors in my-api-project from the last 24 hours
```

## Example Usage

### Basic Error Check

```
Check GCP Error Reporting for any new errors in my-api-project
```

Claude will:
1. Fetch recent error groups
2. List them sorted by priority
3. Show summary of each error

### Deep Dive Analysis

```
Analyze the TypeError in user service that started this morning
```

Claude will:
1. Find the specific error group
2. Fetch detailed error events
3. Search your codebase for the error location
4. Read and analyze the code
5. Identify root cause
6. Recommend fixes

### Service Health Check

```
Give me a health report for the payment-service errors
```

Claude will:
1. Fetch all errors for the service
2. Group by error type
3. Analyze trends
4. Identify critical vs non-critical
5. Provide prioritized summary

### Post-Deploy Monitoring

```
We just deployed v2.1.0 to production. Check for any new errors
```

Claude will:
1. Fetch errors from the last hour
2. Filter by new version
3. Compare to baseline error rates
4. Alert on any new error patterns

## Features

### Smart Error Prioritization

Errors are automatically prioritized based on:
- **User Impact**: Number of affected users
- **Frequency**: Total occurrence count
- **Trend**: Increasing, stable, or decreasing
- **Severity**: HTTP status codes and error types

### Intelligent Codebase Search

The skill uses multiple strategies to locate code:
1. **Exact file path matching** from error reports
2. **Fuzzy file search** if exact path not found
3. **Function name search** across the codebase
4. **Stack trace parsing** to find all involved files
5. **Related code search** for imports and dependencies

### Comprehensive Diagnosis

For each error, the skill provides:
- Error summary with key metrics
- Full stack trace analysis
- Code context at error location
- Root cause hypothesis
- Recommended fix with code examples
- Related code that may need updating
- Similar patterns in the codebase

### Git Integration

When analyzing errors, the skill can:
- Check recent commits to error files
- Find who last modified the error line
- Correlate error timing with deployments
- Identify recently changed code

## Scripts

The `scripts/` directory contains helper scripts:

### fetch-errors.sh

Fetch error groups from GCP Error Reporting:

```bash
./scripts/fetch-errors.sh PROJECT_ID [TIME_PERIOD] [PAGE_SIZE]

# Examples:
./scripts/fetch-errors.sh my-project-123
./scripts/fetch-errors.sh my-project-123 PERIOD_1_DAY 20
./scripts/fetch-errors.sh my-project-123 PERIOD_6_HOURS 10
```

**Time Periods:**
- `PERIOD_1_HOUR` - Last 1 hour
- `PERIOD_6_HOURS` - Last 6 hours
- `PERIOD_1_DAY` - Last 24 hours (default)
- `PERIOD_1_WEEK` - Last 7 days
- `PERIOD_30_DAYS` - Last 30 days

### fetch-error-events.sh

Fetch detailed error events for a specific error group:

```bash
./scripts/fetch-error-events.sh PROJECT_ID GROUP_ID [PAGE_SIZE]

# Example:
./scripts/fetch-error-events.sh my-project-123 abc123def456 5
```

### setup-service-account.sh

Create a service account with Error Reporting permissions:

```bash
./scripts/setup-service-account.sh PROJECT_ID [SERVICE_ACCOUNT_NAME] [KEY_FILE]

# Example:
./scripts/setup-service-account.sh my-project-123
```

## Examples

See the `examples/` directory for:
- **sample-error-response.json** - Example GCP Error Reporting API response
- **diagnosis-workflow.md** - Complete walkthrough of error diagnosis process

## Requirements

### GCP Permissions

The authenticated account needs:
- `errorreporting.errorEvents.list`
- `errorreporting.groups.list`
- `errorreporting.groups.get`

Or the predefined role: `roles/errorreporting.viewer`

### Tools

- **gcloud CLI** - For authentication and API access
- **curl** - For API requests
- **jq** - For JSON parsing (optional, for manual script usage)

### Environment

- Google Cloud project with Error Reporting enabled
- Authentication configured (user credentials or service account)
- Network access to GCP APIs

## Best Practices

### 1. Start with Recent Errors

Focus on errors from the last 24 hours or less for quick triage:

```
Check for errors in the last 6 hours
```

### 2. Prioritize by Impact

Let Claude prioritize by affected users and frequency:

```
Show me the top 5 errors affecting the most users
```

### 3. Correlate with Deployments

Check for errors after deployments:

```
Check for new errors since we deployed v2.1.0 at 3pm
```

### 4. Use for Proactive Monitoring

Set up regular checks:

```
Daily at 9am: Check for any critical errors from the last 24 hours
```

### 5. Search for Patterns

Look for similar errors across services:

```
Find all null pointer errors across all services
```

## Troubleshooting

### "Permission Denied" Error

**Cause**: Insufficient IAM permissions

**Fix**:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/errorreporting.viewer"
```

### "API Not Enabled" Error

**Cause**: Error Reporting API not enabled

**Fix**:
```bash
gcloud services enable clouderrorreporting.googleapis.com --project=PROJECT_ID
```

### File Not Found in Codebase

**Cause**: File path in error doesn't match local structure

**Solutions**:
1. Error might be from a different version/branch
2. Search by function name instead
3. Check deployment configuration for path mappings

### No Errors Found

**Possible reasons**:
1. No errors in time range (good!)
2. Service filter too restrictive
3. Errors not being reported (check error reporting setup)
4. Wrong project

## Advanced Usage

### Custom Time Ranges

```
Check for errors between 2pm and 4pm today
```

### Filter by Service

```
Show me only errors from the payment-service
```

### Analyze Error Trends

```
Compare error rates from this week vs last week
```

### Batch Analysis

```
Analyze all errors across all my GCP projects
```

### Integration with CI/CD

```bash
# In your deployment pipeline
claude-code "Check production for errors after the v2.1.0 deploy"
```

## API Reference

The skill uses the Google Cloud Error Reporting API:

- **List Error Groups**: `GET /v1beta1/projects/{projectId}/groupStats`
- **Get Error Events**: `GET /v1beta1/projects/{projectId}/events`

Full API documentation: https://cloud.google.com/error-reporting/docs/reference/rest

## Contributing

To extend this skill:

1. **Add new error sources**: Integrate with other monitoring systems
2. **Enhance diagnosis**: Add more pattern detection
3. **Automate fixes**: Generate fix PRs for common patterns
4. **Add notifications**: Send alerts to Slack, email, etc.
5. **Create dashboards**: Generate visual error reports

## Resources

- [GCP Error Reporting Documentation](https://cloud.google.com/error-reporting/docs)
- [Error Reporting API Reference](https://cloud.google.com/error-reporting/docs/reference/rest)
- [Error Reporting Best Practices](https://cloud.google.com/error-reporting/docs/best-practices)
- [Claude Code Skills Documentation](https://docs.claude.com/en/docs/claude-code)

## License

This skill is provided as an example under the Apache 2.0 license. See the main repository LICENSE file for details.

## Support

For issues or questions:
- Open an issue in the skills repository
- Consult the GCP Error Reporting documentation
- Check the examples/ directory for common patterns
