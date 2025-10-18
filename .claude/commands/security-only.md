---
name: security-only
description: Security-focused deep analysis (15-20 minutes)
model: claude-sonnet-4-5-20250929
---

# Security-Only Review

Fast security audit without performance/architecture analysis.

## Execution Steps

### Step 1: Security Pattern Scan (3 min) - think
```bash
echo "=== Security Pattern Scan ==="

# SQL injection
echo "SQL Injection patterns:"
grep -rn "query.*\+\|SELECT.*\+\|cursor.execute.*%" --include="*.java" --include="*.py" --include="*.js" 2>/dev/null | wc -l

# Hardcoded secrets
echo "Hardcoded secrets:"
grep -rn "password\|secret\|api.*key.*=" --include="*.java" --include="*.py" --include="*.js" --include="*.properties" --include=".env" 2>/dev/null | wc -l

# Missing authentication
echo "Missing authentication:"
grep -rn "@RequestMapping\|@GetMapping\|@PostMapping\|@app.route" --include="*.java" --include="*.py" 2>/dev/null | grep -v "@Secured\|@PreAuthorize\|@login_required" | wc -l

# XSS risks
echo "XSS risks:"
grep -rn "innerHTML\|dangerouslySetInnerHTML\|\.write(" --include="*.js" --include="*.jsx" --include="*.java" 2>/dev/null | wc -l

# Weak crypto
echo "Weak crypto:"
grep -rn "MD5\|SHA1\|DES" --include="*.java" --include="*.py" --include="*.js" 2>/dev/null | wc -l
```

### Step 2: Deep Security Analysis (15 min) - think hard

Delegate all security analysis to @security-agent:
```
Analyze files with security patterns detected in Step 1.

Focus on:
- CRITICAL and HIGH severity only (skip LOW to save time)
- Verify exploitability for each finding
- Provide working fixes with code examples

Categories to analyze:
1. SQL Injection (highest priority)
2. Hardcoded Secrets (highest priority)
3. Authentication Bypass
4. Authorization Gaps
5. Weak Cryptography
6. XSS/CSRF
7. Sensitive Data Exposure
8. Insecure Deserialization

Time budget: 15 minutes maximum
```

### Step 3: Security Report (2 min)

Generate focused security report: `reports/security-audit-[timestamp].md`

**Report Structure:**
```markdown
# Security Audit Report

Generated: [timestamp]
Repository: [path]
Focus: Security vulnerabilities only

---

## Executive Summary

- CRITICAL vulnerabilities: X (fix immediately)
- HIGH vulnerabilities: Y (fix before release)
- MEDIUM/LOW: Not included in this rapid audit

---

## Critical Vulnerabilities

[Detailed findings with exploitation scenarios]

### SEC-CRIT-001: SQL Injection in User Login
**File:** src/auth/UserController.java:45
**Exploitability:** HIGH - User input directly in query
**Evidence:**
```java
String query = "SELECT * FROM users WHERE email = '" + email + "'";
```

**Attack Scenario:**
```
Email: ' OR '1'='1' --
Resulting query: SELECT * FROM users WHERE email = '' OR '1'='1' --'
Result: Returns all users, bypass authentication
```

**Fix:**
```java
String query = "SELECT * FROM users WHERE email = ?";
PreparedStatement stmt = conn.prepareStatement(query);
stmt.setString(1, email);
```

---

## High Priority Vulnerabilities

[Similar detailed format for HIGH severity]

---

## Remediation Priorities

1. **Immediate (Today)**
   - Fix all SQL injection vulnerabilities
   - Remove hardcoded passwords from code
   - Add authentication to public endpoints

2. **This Week**
   - Implement CSRF protection
   - Fix XSS vulnerabilities
   - Upgrade crypto to strong algorithms

3. **This Sprint**
   - Add authorization checks
   - Implement proper session management
   - Add security logging

---

## Security Metrics

- Files analyzed: X
- Vulnerabilities found: Y
- Critical: A (Z% of total)
- High: B (Y% of total)
- Most vulnerable file: [filename] (N issues)

---

## Compliance Notes

[If applicable, note compliance issues: OWASP Top 10, PCI-DSS, etc.]
```

## Time Estimate

**Total: 15-20 minutes**
- Pattern scan: 2-3 minutes
- Deep analysis: 12-15 minutes
- Report: 2-3 minutes

## Use Cases

- Pre-release security check
- Rapid security assessment
- Focus on highest-risk issues
- Time-constrained audits

## Limitations

- Only CRITICAL and HIGH findings
- No performance or architecture analysis
- May miss context-dependent vulnerabilities
- Not a replacement for penetration testing

## Output Message
```
✓ Security audit completed in [X] minutes

Report: reports/security-audit-[timestamp].md

Findings:
- CRITICAL: X vulnerabilities (fix NOW)
- HIGH: Y vulnerabilities (fix before release)

Most critical: [Brief description of worst finding]

⚠️  This is a code-level security audit. Consider:
- Penetration testing for runtime security
- Dependency vulnerability scanning
- Infrastructure security review
```
