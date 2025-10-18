# 🎯 Example Vulnerable Code - Test Suite for Claude-CodeSentinel

## ⚠️ WARNING

**This code is INTENTIONALLY VULNERABLE for testing purposes only.**
**DO NOT use any of this code in production environments.**

## Purpose

This directory contains example code with various security vulnerabilities, performance issues, and bad practices specifically designed to test the Claude-CodeSentinel framework's detection capabilities.

## Test Files

### 1. `UserController.java` (Java/Spring)

**Issues Included:**
- 🔴 **CRITICAL Security:**
  - SQL Injection (multiple instances)
  - Hardcoded database credentials
  - Missing authentication checks
  - Password stored/returned in plain text

- 🟡 **HIGH Performance:**
  - N+1 query problem
  - No connection pooling
  - Synchronous blocking operations
  - Resource leaks

- 🟡 **HIGH Resilience:**
  - No timeout on external calls
  - No error handling
  - Silent failures

- 🟡 **HIGH Data Integrity:**
  - Missing transactions
  - No input validation

### 2. `user_service.py` (Python)

**Issues Included:**
- 🔴 **CRITICAL Security:**
  - SQL Injection vulnerabilities
  - Command injection
  - Insecure deserialization (pickle)
  - Weak hashing (MD5)
  - Hardcoded credentials
  - Plain text passwords

- 🟡 **HIGH Performance:**
  - N+1 queries
  - No pagination (loading all records)
  - No batch operations
  - No caching

- 🟡 **HIGH Concurrency:**
  - Race conditions
  - Shared mutable state
  - Resource leaks

### 3. `userApi.js` (JavaScript/Node.js)

**Issues Included:**
- 🔴 **CRITICAL Security:**
  - SQL Injection
  - XSS vulnerability
  - Path traversal
  - Weak password hashing (SHA1)
  - Missing authentication

- 🟡 **HIGH Performance:**
  - N+1 query problem
  - Synchronous file operations
  - No connection pooling
  - Sequential async operations

- 🟡 **HIGH Concurrency:**
  - Race conditions
  - Unhandled Promise rejections
  - Callback hell

## Expected Detection Results

When running Claude-CodeSentinel on this code, you should see:

### Quick Scan (`/quick-scan`)
- **Time**: ~5 minutes
- **Expected**: 20+ hotspots identified
- **Categories**: Security, Performance, Concurrency, Resilience

### Full Review (`/full-review`)
- **Time**: ~45-60 minutes
- **Expected**: 50+ issues detected
- **Severity Distribution**:
  - CRITICAL: 8-10 issues
  - HIGH: 15-20 issues
  - MEDIUM: 10-15 issues
  - LOW: 10+ issues

### Security Only (`/security-only`)
- **Time**: ~15 minutes
- **Expected**: 15+ security vulnerabilities
- **Focus**: SQL injection, hardcoded secrets, weak crypto

### Performance Only (`/performance-only`)
- **Time**: ~15 minutes
- **Expected**: 10+ performance issues
- **Focus**: N+1 queries, missing pagination, no caching

## How to Test

1. **Copy framework to this directory:**
   ```bash
   cp -r ../.claude .
   cp -r ../patterns .
   cp ../CLAUDE.md .
   ```

2. **Open in Claude Code and run:**
   ```
   /quick-scan
   ```
   or
   ```
   /full-review
   ```

3. **Check results in `reports/` directory**

## Test Coverage Matrix

| Issue Type | Java | Python | JavaScript |
|------------|------|--------|------------|
| SQL Injection | ✅ | ✅ | ✅ |
| Hardcoded Secrets | ✅ | ✅ | ✅ |
| N+1 Queries | ✅ | ✅ | ✅ |
| Race Conditions | ✅ | ✅ | ✅ |
| No Timeout | ✅ | ✅ | ✅ |
| Resource Leaks | ✅ | ✅ | ✅ |
| No Error Handling | ✅ | ✅ | ✅ |
| No Validation | ✅ | ✅ | ✅ |
| Weak Crypto | - | ✅ | ✅ |
| XSS | - | - | ✅ |
| Command Injection | - | ✅ | - |
| Insecure Deserialize | - | ✅ | - |

## Notes

- Each file is ~200 lines with concentrated issues
- Issues are clearly commented with `// ISSUE:` or `# ISSUE:`
- Multiple severity levels represented
- Framework-specific patterns included
- Real-world bad practices demonstrated

## Learning Value

This test suite demonstrates:
1. Common security vulnerabilities in web applications
2. Performance anti-patterns
3. Concurrency issues in multi-threaded environments
4. Poor error handling and observability
5. Missing resilience patterns

Use this to:
- Test the Claude-CodeSentinel framework
- Learn about common coding mistakes
- Understand what NOT to do in production code

---

*Remember: This is vulnerable code for testing only. Never use these patterns in real applications!*