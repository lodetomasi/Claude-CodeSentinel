---
name: quick-scan
description: Fast pattern-based scan to identify hotspots (5 minutes)
model: claude-sonnet-4-5-20250929
---

# Quick Scan Command

Execute rapid pattern scanning without deep analysis. Identifies hotspots for targeted deep analysis.

## Execution Steps (think)

### Step 1: Language Detection (30 seconds)
```bash
echo "=== Language Detection ==="
echo "Java files: $(find . -name "*.java" 2>/dev/null | wc -l)"
echo "Python files: $(find . -name "*.py" 2>/dev/null | wc -l)"
echo "JavaScript files: $(find . -name "*.js" 2>/dev/null | wc -l)"
echo "Go files: $(find . -name "*.go" 2>/dev/null | wc -l)"
echo ""
```

### Step 2: Security Patterns (1 minute)
```bash
echo "=== Security Hotspots ==="

# SQL injection
echo "SQL Injection patterns:"
grep -rn "query.*\+\|SELECT.*\+" --include="*.java" --include="*.py" --include="*.js" 2>/dev/null | head -10

# Hardcoded secrets
echo "Hardcoded secrets:"
grep -rn "password.*=.*['\"].*['\"]" --include="*.java" --include="*.py" --include="*.js" --include="*.properties" 2>/dev/null | head -10

# Auth missing
echo "Missing authentication:"
grep -rn "@RequestMapping\|@GetMapping\|@PostMapping" --include="*.java" 2>/dev/null | grep -v "@Secured\|@PreAuthorize" | head -10
```

### Step 3: Performance Patterns (1 minute)
```bash
echo "=== Performance Hotspots ==="

# N+1 queries
echo "N+1 query patterns:"
grep -rn "\.findAll()\|\.all()" --include="*.java" --include="*.py" 2>/dev/null | head -10

# Missing batch operations
echo "Missing batch operations:"
grep -rn "for.*{.*\.save(" --include="*.java" --include="*.py" 2>/dev/null | head -10

# Nested loops
echo "Nested loops (O(n²)+):"
grep -rn "for.*for.*for" --include="*.java" --include="*.py" --include="*.js" 2>/dev/null | head -10
```

### Step 4: Concurrency Patterns (1 minute)
```bash
echo "=== Concurrency Hotspots ==="

# Shared mutable state
echo "Shared mutable state:"
grep -rn "^[[:space:]]*private.*=" --include="*.java" 2>/dev/null | grep -v "final\|static final" | head -10

# Thread creation
echo "Thread creation:"
grep -rn "new Thread\|Thread\.start" --include="*.java" 2>/dev/null | head -10
```

### Step 5: Resilience Patterns (1 minute)
```bash
echo "=== Resilience Hotspots ==="

# Missing timeouts
echo "Missing timeouts:"
grep -rn "RestTemplate\|requests\.get\|fetch(" --include="*.java" --include="*.py" --include="*.js" 2>/dev/null | head -10

# No circuit breaker
echo "Missing circuit breakers:"
grep -rn "@HystrixCommand\|@CircuitBreaker" --include="*.java" 2>/dev/null
if [ $? -ne 0 ]; then echo "No circuit breakers found"; fi
```

### Step 6: Observability Patterns (30 seconds)
```bash
echo "=== Observability Hotspots ==="

# Poor logging
echo "System.out/print usage:"
grep -rn "System\.out\|print(" --include="*.java" --include="*.py" 2>/dev/null | wc -l

# Silent failures
echo "Empty catch blocks:"
grep -rn "catch.*{[[:space:]]*}" --include="*.java" --include="*.py" 2>/dev/null | wc -l
```

## Output Format

Generate summary report in this format:
```markdown
# Quick Scan Results

**Executed:** [timestamp]
**Repository:** [path]

## Hotspots Summary

| Category | Files Flagged | Pattern Matches |
|----------|---------------|-----------------|
| Security | X files | Y patterns |
| Performance | A files | B patterns |
| Concurrency | M files | N patterns |
| Resilience | P files | Q patterns |
| Observability | R files | S patterns |

## Top 20 Files for Deep Analysis

1. **src/UserController.java** (3 security, 1 performance, 1 observability)
2. **src/OrderService.py** (2 performance, 1 resilience)
3. [... continue ...]

## Pattern Details

### Security Hotspots
- SQL Injection: X occurrences in Y files
- Hardcoded Secrets: A occurrences in B files
- Missing Auth: M occurrences in N files

### Performance Hotspots
- N+1 Queries: X occurrences
- Missing Batch Ops: Y occurrences
- Nested Loops: Z occurrences

[... continue for all categories ...]

## Recommended Next Steps

1. **CRITICAL Priority**: Files with security patterns (SQL injection, secrets)
2. **HIGH Priority**: Files with multiple hotspot types (cross-cutting issues)
3. **MEDIUM Priority**: Performance and resilience issues

**Commands to run:**
- `/project:security-only` - Deep dive into security issues (15 min)
- `/project:full-review` - Comprehensive analysis (45-60 min)
- Focus manual review on top 10 files first
```

## Time Estimate
**Total: 3-5 minutes**
- Language detection: 30 seconds
- Pattern scanning: 3-4 minutes
- Report generation: 30 seconds

## Success Criteria
- All languages detected correctly
- At least 10 hotspot files identified
- Clear prioritization for deep analysis
