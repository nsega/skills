# Example Diagnosis Workflow

This document demonstrates a complete workflow for diagnosing a GCP error using Claude Code with the gcp-error-reporting skill.

## Scenario

A production API service is experiencing errors. The team needs to quickly identify and fix the issue.

---

## Step 1: Fetch Recent Errors

**User Command:**
```
Use the gcp-error-reporting skill to check for errors in my-api-project from the last 6 hours
```

**Claude's Actions:**

1. Fetch error groups using the GCP Error Reporting API
2. Parse the response
3. List errors sorted by priority

**Claude's Response:**

```markdown
## Error Report for my-api-project (Last 6 Hours)

Found 3 error groups:

### 🔴 Error #1: TypeError - HIGH PRIORITY
- **Message**: Cannot read property 'id' of undefined
- **Service**: api-service v1.2.3
- **Location**: /app/src/handlers/user.js:89 (getUserById)
- **Occurrences**: 150 (↑ increasing trend)
- **Affected Users**: 75
- **First Seen**: 2025-11-01 10:15:32 UTC
- **Status Code**: 500

### 🟡 Error #2: Database Connection Timeout - MEDIUM PRIORITY
- **Message**: Database connection timeout
- **Service**: api-service v1.2.3
- **Location**: /app/src/db/client.js:45 (connect)
- **Occurrences**: 45 (↑ increasing trend)
- **Affected Users**: 23
- **First Seen**: 2025-11-01 10:22:15 UTC
- **Status Code**: 503

### 🟢 Error #3: ValidationError - LOW PRIORITY
- **Message**: Invalid email format
- **Service**: api-service v1.2.3
- **Location**: /app/src/validators/email.js:12 (validateEmail)
- **Occurrences**: 12 (↓ decreasing trend)
- **Affected Users**: 8
- **First Seen**: 2025-11-01 10:35:47 UTC
- **Status Code**: 400

Would you like me to perform a detailed analysis of Error #1?
```

---

## Step 2: Deep Dive on High Priority Error

**User Command:**
```
Yes, analyze Error #1 in detail
```

**Claude's Actions:**

1. Extract file path: `/app/src/handlers/user.js`
2. Extract line number: 89
3. Extract function name: `getUserById`
4. Extract stack trace
5. Search codebase for the file
6. Read the code around line 89
7. Analyze the error context
8. Check for related files

**Claude's Search Process:**

```markdown
Searching codebase...
1. Looking for exact file match: **/handlers/user.js
2. Found: src/handlers/user.js
3. Reading file and analyzing code at line 89
4. Searching for related files (imports, tests)
5. Analyzing git history for recent changes
```

**Claude's Response:**

```markdown
## Detailed Analysis: TypeError in getUserById

### Error Summary
- **Type**: TypeError
- **Message**: Cannot read property 'id' of undefined
- **Impact**: 150 occurrences affecting 75 users in last 6 hours
- **Trend**: ↑ Increasing (100 in last hour vs 50 in previous hour)
- **Severity**: HIGH - Critical production issue

### Stack Trace
```
TypeError: Cannot read property 'id' of undefined
    at getUserById (/app/src/handlers/user.js:89:15)
    at async handleRequest (/app/src/handlers/api.js:142:20)
    at async processRequest (/app/src/middleware/router.js:56:12)
```

### Code Analysis

**File**: src/handlers/user.js:85-95

```javascript
async function getUserById(userId) {
  logger.info(`Fetching user ${userId}`);

  // Query database for user
  const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);

  // Line 89 - ERROR OCCURS HERE
  return {
    id: user.id,           // ❌ Crashes if user is null/undefined
    name: user.name,
    email: user.email
  };
}
```

### Root Cause

The database query returns `null` when no user is found, but the code assumes a user object is always returned. When `user` is `null`, accessing `user.id` throws a TypeError.

**Why it's happening:**
1. Database query with WHERE clause returns `null` for non-existent IDs
2. No validation check after the query
3. Code directly accesses properties assuming user exists

**When it happens:**
- When users request non-existent user IDs
- When IDs are deleted but still referenced elsewhere
- When invalid IDs are passed to the API

### Related Code

**Caller**: src/handlers/api.js:142
```javascript
async function handleRequest(req, res) {
  const userId = req.params.id;  // No validation here either
  const user = await getUserById(userId);
  res.json(user);
}
```

**Database Client**: src/db/client.js:78
```javascript
async query(sql, params) {
  const [rows] = await this.pool.execute(sql, params);
  return rows[0] || null;  // Returns null if no rows found
}
```

### Recent Changes

Git history shows:
- Last modified: 2025-10-28 (4 days ago)
- Commit: "Refactor user queries to use prepared statements"
- Author: dev@example.com
- Change: Switched from ORM to raw SQL queries

**Analysis**: The refactoring changed from an ORM that threw exceptions for missing records to raw SQL that returns null. The null-check was not added during refactoring.

### Recommended Fix

**Option 1: Add null check with proper error (Recommended)**

```javascript
async function getUserById(userId) {
  logger.info(`Fetching user ${userId}`);

  const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);

  // Add null check
  if (!user) {
    throw new NotFoundError(`User not found: ${userId}`);
  }

  return {
    id: user.id,
    name: user.name,
    email: user.email
  };
}
```

**Option 2: Return null and handle in caller**

```javascript
async function getUserById(userId) {
  logger.info(`Fetching user ${userId}`);
  const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);

  if (!user) {
    return null;  // Let caller decide how to handle
  }

  return {
    id: user.id,
    name: user.name,
    email: user.email
  };
}
```

Then update the caller:
```javascript
async function handleRequest(req, res) {
  const userId = req.params.id;
  const user = await getUserById(userId);

  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  res.json(user);
}
```

### Additional Improvements

1. **Add input validation**:
```javascript
async function getUserById(userId) {
  // Validate userId is a valid format
  if (!userId || typeof userId !== 'string') {
    throw new ValidationError('Invalid user ID format');
  }

  // ... rest of function
}
```

2. **Add tests**:
```javascript
// tests/handlers/user.test.js
describe('getUserById', () => {
  it('should throw NotFoundError for non-existent user', async () => {
    await expect(getUserById('nonexistent'))
      .rejects.toThrow(NotFoundError);
  });

  it('should return user for valid ID', async () => {
    const user = await getUserById('valid-id');
    expect(user).toHaveProperty('id');
    expect(user).toHaveProperty('name');
  });
});
```

3. **Search for similar patterns**:

I found 8 other locations in the codebase with the same pattern:
- src/handlers/post.js:45 - `getPostById`
- src/handlers/comment.js:23 - `getCommentById`
- src/handlers/product.js:67 - `getProductById`
- ... (5 more)

All should be updated with null checks to prevent similar errors.

### Priority and Next Steps

**Priority**: 🔴 CRITICAL - Fix immediately

**Impact**:
- Affecting 75 users (and increasing)
- Degraded user experience (500 errors)
- May be causing cascading failures

**Recommended Actions**:
1. ✅ Apply fix to getUserById function
2. ✅ Add similar null checks to 8 other locations
3. ✅ Add tests for null cases
4. ✅ Deploy to production ASAP
5. ⏭️ Monitor error rate after deploy
6. ⏭️ Add integration tests for all API endpoints
7. ⏭️ Review all database query patterns

Would you like me to:
1. Create a fix branch and implement the changes?
2. Generate test cases for this function?
3. Search for and fix the other similar patterns?
```

---

## Step 3: Implement the Fix

**User Command:**
```
Yes, create a fix branch and implement the changes
```

**Claude's Actions:**

1. Create a new git branch
2. Apply the fix to user.js
3. Add tests
4. Run tests to verify
5. Commit changes
6. Show summary

**Claude's Response:**

```markdown
## Fix Implemented

Created branch: `fix/user-handler-null-check`

### Changes Made

**1. Updated src/handlers/user.js**
- Added null check after database query
- Throws NotFoundError for non-existent users
- Added input validation for userId

**2. Created tests/handlers/user.test.js**
- Test for non-existent user → NotFoundError
- Test for valid user → returns user object
- Test for invalid userId format → ValidationError

**3. Updated src/errors/index.js**
- Added NotFoundError class
- Proper HTTP status code (404)

### Test Results
```
✓ getUserById throws NotFoundError for non-existent user
✓ getUserById returns user for valid ID
✓ getUserById validates input format
✓ API handler returns 404 for missing user

4 tests passed
```

### Next Steps

1. **Review the changes**: Check the diff
2. **Deploy**: Merge and deploy to production
3. **Monitor**: Watch error rate decrease
4. **Follow up**: Fix similar patterns in other files

Would you like me to:
1. Fix the 8 similar patterns I found?
2. Create a pull request?
```

---

## Step 4: Monitor Results

**User Command (after deployment):**
```
Check if the error is resolved
```

**Claude's Actions:**

1. Fetch recent errors again
2. Compare before and after
3. Check if the TypeError still appears

**Claude's Response:**

```markdown
## Post-Fix Error Report

Checked errors from last 1 hour (after deployment):

### Results

✅ **Error #1 (TypeError) - RESOLVED**
- **Before**: 150 occurrences, 75 affected users
- **After**: 0 occurrences
- **Status**: No longer appearing in error reports

### New Observation

📊 **User-facing 404s (expected behavior)**
- Not logged as errors in Error Reporting (correct)
- Being handled gracefully by API
- Users see "User not found" message instead of 500 error

### Remaining Errors

Still monitoring:
- Error #2: Database timeouts (requires separate investigation)
- Error #3: Email validation (low priority, decreasing)

### Success Metrics

- ✅ 0 new occurrences of TypeError
- ✅ 75 users no longer experiencing 500 errors
- ✅ Proper 404 responses for missing users
- ✅ Error rate decreased by 73%

Great job! The fix is working as expected.

Should we now investigate the database timeout issue (Error #2)?
```

---

## Summary

This workflow demonstrates:

1. **Quick Triage**: Fetched and prioritized errors by impact
2. **Deep Analysis**: Located code, identified root cause, checked history
3. **Fix Implementation**: Created branch, wrote code and tests
4. **Verification**: Monitored results and confirmed resolution

The entire process, from detection to verification, can be completed in minutes with Claude Code using the gcp-error-reporting skill.
