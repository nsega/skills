---
name: gcp-error-reporting
description: Integrate Google Cloud Error Reporting with Claude Code for automated error diagnosis. Use when you need to fetch errors from GCP Error Reporting, search the codebase for related code, and provide quick diagnosis of production issues.
allowed-tools:
  - Bash
  - WebFetch
  - Grep
  - Glob
  - Read
  - Task
---

# GCP Error Reporting Integration

This skill enables Claude Code to integrate with Google Cloud Error Reporting to automatically fetch, analyze, and diagnose production errors by correlating them with your codebase.

## Overview

Google Cloud Error Reporting aggregates and displays errors from cloud services. This skill helps you:
1. **Fetch errors** from GCP Error Reporting API
2. **Search codebase** for files, functions, and code mentioned in stack traces
3. **Diagnose issues** by analyzing error context and related code
4. **Provide recommendations** for fixes based on error patterns

---

## Prerequisites

Before using this skill, ensure you have:

### 1. GCP Authentication

**Option A: Service Account (Recommended for Production)**
```bash
# Set the service account key file path
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

**Option B: User Credentials (Development)**
```bash
# Authenticate with your Google account
gcloud auth application-default login
```

### 2. Required Permissions

The authenticated account needs these IAM permissions:
- `errorreporting.errorEvents.list`
- `errorreporting.groups.list`
- `errorreporting.groups.get`

Or use the predefined role: `roles/errorreporting.viewer`

### 3. Enable Error Reporting API

```bash
gcloud services enable clouderrorreporting.googleapis.com --project=YOUR_PROJECT_ID
```

---

## Usage Workflow

### Phase 1: Fetch Errors from GCP

When the user asks to analyze GCP errors, follow this workflow:

#### 1.1 Get Project Configuration

Ask the user for:
- **GCP Project ID**: The project to fetch errors from
- **Time Range** (optional): How far back to look (default: 24 hours)
- **Service Filter** (optional): Specific service to analyze
- **Max Errors** (optional): Maximum number of error groups to analyze (default: 10)

#### 1.2 Fetch Error Groups

Use the GCP Error Reporting API to fetch error groups:

```bash
# Get authentication token
ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

# Fetch error groups from the last 24 hours
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://clouderrorreporting.googleapis.com/v1beta1/projects/PROJECT_ID/groupStats?timeRange.period=PERIOD_1_HOUR&pageSize=10"
```

**API Response Structure:**
```json
{
  "errorGroupStats": [
    {
      "group": {
        "name": "projects/PROJECT_ID/groups/GROUP_ID",
        "groupId": "GROUP_ID"
      },
      "count": "150",
      "affectedUsersCount": "75",
      "timedCounts": [...],
      "firstSeenTime": "2025-11-01T10:00:00Z",
      "representative": {
        "message": "Error message here",
        "serviceContext": {
          "service": "service-name",
          "version": "1.0.0"
        },
        "context": {
          "httpRequest": {...},
          "user": "...",
          "reportLocation": {
            "filePath": "src/handlers/api.js",
            "lineNumber": 142,
            "functionName": "handleRequest"
          }
        }
      }
    }
  ]
}
```

#### 1.3 Fetch Detailed Error Events

For high-priority error groups, fetch detailed events:

```bash
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://clouderrorreporting.googleapis.com/v1beta1/projects/PROJECT_ID/events?groupId=GROUP_ID&pageSize=5"
```

**Detailed Event Structure:**
```json
{
  "errorEvents": [
    {
      "eventTime": "2025-11-01T10:15:00Z",
      "message": "TypeError: Cannot read property 'id' of undefined",
      "serviceContext": {
        "service": "api-service",
        "version": "1.2.3"
      },
      "context": {
        "reportLocation": {
          "filePath": "src/handlers/user.js",
          "lineNumber": 89,
          "functionName": "getUserById"
        },
        "httpRequest": {
          "method": "GET",
          "url": "https://api.example.com/users/123",
          "responseStatusCode": 500
        },
        "sourceReferences": [
          {
            "repository": "https://github.com/org/repo",
            "revisionId": "abc123def456"
          }
        ]
      }
    }
  ]
}
```

---

### Phase 2: Search Codebase

For each error, extract relevant information and search the codebase:

#### 2.1 Extract Search Targets

From the error data, extract:
1. **File paths** from `reportLocation.filePath`
2. **Function names** from `reportLocation.functionName`
3. **Line numbers** from `reportLocation.lineNumber`
4. **Error messages** for keyword extraction
5. **Stack traces** (if available in message)

#### 2.2 Locate Files

Use the Glob tool to find exact or similar file paths:

```markdown
**Strategy A: Exact Match**
- If filePath is "src/handlers/user.js", search for "**/handlers/user.js"

**Strategy B: Partial Match**
- If file not found, search for "**/user.js"
- Then search for "**/handlers/*.js"

**Strategy C: Pattern Match**
- Extract meaningful parts: "user", "handler"
- Search for files containing these terms
```

#### 2.3 Search for Functions and Code

Use the Grep tool to locate:

1. **Function definitions**:
   ```
   Pattern: "function getUserById|const getUserById|getUserById.*=|def getUserById"
   ```

2. **Error-related code**:
   - Search for error message keywords
   - Search for exception handling patterns
   - Look for similar error patterns

3. **Related imports/dependencies**:
   - Find what the problematic file imports
   - Locate related service calls

#### 2.4 Read Relevant Code

Use the Read tool to:
1. Read the exact file and line number where error occurred
2. Read surrounding context (±50 lines)
3. Read imported/related files
4. Read tests for the failing code

---

### Phase 3: Diagnose and Report

#### 3.1 Error Analysis

For each error, analyze:

**Error Context:**
- Error type and message
- Frequency and trend (increasing/decreasing)
- Affected users count
- HTTP context (if web request)
- Time pattern (specific times, random, continuous)

**Code Context:**
- What the code is trying to do
- Dependencies and imports
- Null/undefined checks present
- Error handling present
- Recent changes (if git info available)

**Root Cause Hypothesis:**
- Most likely cause based on error + code
- Missing null checks
- API contract changes
- Data validation issues
- Race conditions
- Configuration issues

#### 3.2 Diagnosis Report Format

Provide a structured diagnosis for each error:

```markdown
## Error #1: TypeError in getUserById

### Summary
- **Service**: api-service v1.2.3
- **Location**: src/handlers/user.js:89
- **Frequency**: 150 occurrences, affecting 75 users
- **First Seen**: 2025-11-01 10:00:00 UTC
- **Trend**: Increasing (50% in last hour)

### Error Details
```
TypeError: Cannot read property 'id' of undefined
  at getUserById (src/handlers/user.js:89:15)
  at handleRequest (src/handlers/api.js:142:20)
```

### Code Analysis
**File**: src/handlers/user.js:89

The error occurs when accessing `user.id` but `user` is undefined.

```javascript
async function getUserById(userId) {
  const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);
  return { id: user.id, name: user.name }; // Line 89 - crashes if user is null
}
```

**Issue**: Missing null check after database query.

### Root Cause
The database query returns `null` when no user is found, but the code assumes a user is always returned.

### Recommended Fix
Add null validation:

```javascript
async function getUserById(userId) {
  const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);
  if (!user) {
    throw new Error(`User not found: ${userId}`);
  }
  return { id: user.id, name: user.name };
}
```

### Priority
**HIGH** - Affecting 75 users with increasing frequency

---
```

#### 3.3 Batch Diagnosis

When analyzing multiple errors:
1. **Group by similarity**: Common root causes, same file/function
2. **Prioritize by impact**:
   - User impact (affected users count)
   - Frequency trend
   - Severity (crashes vs warnings)
3. **Identify patterns**: Similar errors across services
4. **Recommend systematic fixes**: Framework-level solutions

---

## Advanced Features

### Stack Trace Parsing

When error messages contain full stack traces, parse them to extract:

```python
# Example stack trace format
"""
Error: Database connection failed
    at DatabaseClient.connect (/app/src/db/client.js:45:12)
    at UserService.getUser (/app/src/services/user.js:23:18)
    at RequestHandler.handle (/app/src/handlers/request.js:89:25)
"""
```

**Extraction Strategy:**
1. Split by lines starting with "at "
2. Extract file paths using regex: `/([^(]+):(\d+):(\d+)/`
3. Extract function names before the path
4. Search codebase for each file in the trace

### Correlation with Git History

If the project is a git repository:

```bash
# Find recent changes to the error file
git log --oneline -10 -- src/handlers/user.js

# Find who last modified the error line
git blame src/handlers/user.js -L 89,89

# Check if error timing correlates with deployment
git log --since="2025-11-01 09:00" --until="2025-11-01 11:00"
```

### Pattern Detection

Look for common error patterns:
- **Null pointer errors**: Missing null/undefined checks
- **Type errors**: Incorrect type assumptions
- **Network errors**: Timeout, connection refused
- **Authentication errors**: Token expiration, permissions
- **Rate limiting**: 429 responses
- **Database errors**: Connection pool exhaustion

### Automated Search Strategy

Use the Task tool with subagent_type=Explore for complex searches:

```markdown
When the error location is unclear or involves multiple files, delegate to the Explore agent:

"Find all files that import or use the 'getUserById' function,
and identify all locations where user objects are accessed without null checks"
```

---

## Configuration Examples

### Service Account Setup

Create a service account for automated error monitoring:

```bash
# Create service account
gcloud iam service-accounts create error-reporter-viewer \
  --display-name="Error Reporting Viewer for Claude"

# Grant permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:error-reporter-viewer@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/errorreporting.viewer"

# Create and download key
gcloud iam service-accounts keys create ~/gcp-error-key.json \
  --iam-account=error-reporter-viewer@PROJECT_ID.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/gcp-error-key.json"
```

### Multiple Project Monitoring

To monitor errors across multiple GCP projects:

```bash
# Create a shell script or configuration
cat > ~/.gcp-error-projects <<EOF
project1-id
project2-id
project3-id
EOF

# Claude can iterate through projects
while read project; do
  echo "Fetching errors from $project..."
  # Fetch and analyze errors
done < ~/.gcp-error-projects
```

---

## Example Usage Scenarios

### Scenario 1: Quick Error Triage

**User**: "Check GCP Error Reporting for any new errors in my-api-project"

**Claude Process**:
1. Fetch error groups from last 24 hours
2. List top 5 errors by frequency
3. For each error:
   - Show basic info (count, service, message)
   - Identify the file and function
   - Quick severity assessment

### Scenario 2: Deep Dive on Specific Error

**User**: "Analyze the TypeError in user service that's been happening since this morning"

**Claude Process**:
1. Fetch error groups filtered by time range
2. Find the TypeError in user service
3. Fetch detailed event samples
4. Search codebase for the exact location
5. Read surrounding code context
6. Check git history for recent changes
7. Provide full diagnosis with fix recommendation

### Scenario 3: Service Health Check

**User**: "Give me a health report for the payment-service errors"

**Claude Process**:
1. Fetch all errors for payment-service
2. Group by error type
3. Analyze trends (increasing/stable/decreasing)
4. Identify critical vs non-critical errors
5. Search codebase for each error location
6. Provide summary report with priorities

### Scenario 4: Post-Deploy Monitoring

**User**: "We just deployed v2.1.0 to production. Check for any new errors"

**Claude Process**:
1. Fetch errors from last 1 hour
2. Filter by service version "2.1.0"
3. Compare error rates to previous period
4. Identify new error types not seen before
5. Quick diagnosis of any new errors
6. Alert if error rate spike detected

---

## Best Practices

### 1. API Rate Limiting

GCP Error Reporting API has rate limits:
- **Requests per minute**: 60
- **Requests per day**: 50,000

**Strategy**:
- Cache error groups for repeated analysis
- Batch requests when possible
- Use pagination efficiently

### 2. Error Prioritization

Focus on high-impact errors first:
1. **Critical**: Affecting many users, increasing trend
2. **High**: Moderate users, stable or increasing
3. **Medium**: Few users, stable
4. **Low**: Rare, decreasing

### 3. Codebase Search Optimization

- Start with exact file paths from error reports
- Fall back to fuzzy search if exact match fails
- Use function name + file name for better accuracy
- Search in test files for additional context

### 4. Privacy and Security

- **Never log sensitive data** from error contexts (tokens, passwords, PII)
- **Sanitize error messages** before displaying to user
- **Limit error event details** shown in reports
- **Use service accounts** with minimal required permissions

### 5. Automated Monitoring

For continuous monitoring:
1. Set up periodic checks (e.g., hourly)
2. Define alert thresholds
3. Track error trends over time
4. Integrate with incident management

---

## API Reference

### Error Reporting API Endpoints

**List Error Groups**:
```
GET https://clouderrorreporting.googleapis.com/v1beta1/projects/{projectId}/groupStats
```

**Query Parameters**:
- `timeRange.period`: PERIOD_1_HOUR, PERIOD_6_HOURS, PERIOD_1_DAY, PERIOD_1_WEEK, PERIOD_30_DAYS
- `pageSize`: Max 100
- `serviceFilter.service`: Filter by service name
- `groupId`: Specific group ID

**Get Error Events**:
```
GET https://clouderrorreporting.googleapis.com/v1beta1/projects/{projectId}/events
```

**Query Parameters**:
- `groupId`: Required - the error group ID
- `pageSize`: Max 100
- `serviceFilter.service`: Service name filter

### Authentication Headers

All API requests require:
```
Authorization: Bearer {ACCESS_TOKEN}
```

Get token:
```bash
gcloud auth application-default print-access-token
```

---

## Troubleshooting

### Error: "Permission Denied"

**Cause**: Insufficient IAM permissions

**Fix**:
```bash
# Grant Error Reporting Viewer role
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:your-email@example.com" \
  --role="roles/errorreporting.viewer"
```

### Error: "API Not Enabled"

**Cause**: Error Reporting API not enabled for project

**Fix**:
```bash
gcloud services enable clouderrorreporting.googleapis.com --project=PROJECT_ID
```

### Error: File Not Found in Codebase

**Cause**: File path in error report doesn't match local codebase structure

**Strategies**:
1. Check if error is from a different version/branch
2. Search for function name instead of file path
3. Look for similar file names
4. Check deployment configuration for path mappings

### No Recent Errors Found

**Possible Reasons**:
1. No errors in specified time range (good!)
2. Service name filter too restrictive
3. Errors not being reported to GCP (check error reporting setup)
4. Looking at wrong project

---

## Integration with CI/CD

### Pre-Deploy Error Check

Before deploying, check for existing error patterns:

```bash
# In CI/CD pipeline
claude-code --skill gcp-error-reporting \
  "Check production errors for patterns we might have fixed in this deploy"
```

### Post-Deploy Validation

After deployment, monitor for new errors:

```bash
# Wait 10 minutes after deploy
sleep 600

# Check for new errors
claude-code --skill gcp-error-reporting \
  "Check for any new errors since the v2.1.0 deployment"
```

---

## Tips for Effective Diagnosis

1. **Read the full error message**: Don't just look at the error type
2. **Check error frequency trends**: Sudden spikes indicate recent changes
3. **Correlate with deployments**: Compare error timing with deploy times
4. **Look at affected users**: High count = urgent fix needed
5. **Search for related errors**: Similar errors might share root cause
6. **Check error context**: HTTP requests, user data can reveal patterns
7. **Review recent code changes**: Git blame and recent commits
8. **Test locally**: Try to reproduce with similar inputs
9. **Check dependencies**: External API changes can cause errors
10. **Look at tests**: Missing test cases might indicate gaps

---

## Extending This Skill

### Add Slack Notifications

Integrate with Slack to send error alerts:
- Post high-priority errors to a channel
- Include diagnosis summary
- Link to GCP Console for details

### Create Error Dashboards

Generate visual reports:
- Error trends over time
- Service health scores
- Top errors by impact

### Automatic Fix Proposals

For common error patterns:
- Generate fix PRs automatically
- Suggest code improvements
- Create tickets in issue tracker

### Link to Monitoring Systems

Correlate with other observability data:
- Logs (Cloud Logging)
- Metrics (Cloud Monitoring)
- Traces (Cloud Trace)
- APM data

---

## Resources

- [GCP Error Reporting Documentation](https://cloud.google.com/error-reporting/docs)
- [Error Reporting API Reference](https://cloud.google.com/error-reporting/docs/reference/rest)
- [Error Reporting Best Practices](https://cloud.google.com/error-reporting/docs/best-practices)
- [Setting up Error Reporting](https://cloud.google.com/error-reporting/docs/setup)
- [IAM Permissions Reference](https://cloud.google.com/error-reporting/docs/access-control)
