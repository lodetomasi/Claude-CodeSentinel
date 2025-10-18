---
name: performance-only
description: Performance-focused deep analysis (15-20 minutes)
model: claude-sonnet-4-5-20250929
---

# Performance-Only Review

Fast performance audit focusing on database queries, algorithms, and caching.

## Execution Steps

### Step 1: Performance Pattern Scan (3 min) - think
```bash
echo "=== Performance Pattern Scan ==="

# N+1 queries
echo "N+1 query patterns:"
grep -rn "\.findAll()\|\.all()\|\.find()" --include="*.java" --include="*.py" --include="*.js" 2>/dev/null | wc -l

# Missing batch operations
echo "Missing batch operations:"
grep -rn "for.*{.*\.save\|for.*{.*repository\.save" --include="*.java" --include="*.py" 2>/dev/null | wc -l

# Nested loops (O(n²)+)
echo "Nested loops:"
grep -rn "for.*for.*for" --include="*.java" --include="*.py" --include="*.js" 2>/dev/null | wc -l

# Missing pagination
echo "Missing pagination:"
grep -rn "\.findAll()\|\.all()" --include="*.java" --include="*.py" 2>/dev/null | grep -v "Pageable\|PageRequest\|limit\|slice" | wc -l

# Missing caching
echo "Cache usage:"
grep -rn "@Cacheable\|@cache\|cache\.get" --include="*.java" --include="*.py" 2>/dev/null | wc -l
```

### Step 2: Deep Performance Analysis (15 min) - think hard

Delegate to @performance-agent:
```
Analyze files with performance patterns from Step 1.

Focus on:
- CRITICAL and HIGH severity only
- Quantify impact (queries, time, scale)
- Provide optimized code examples

Categories:
1. N+1 Queries (highest priority)
2. Missing Batch Operations
3. Inefficient Algorithms
4. Missing Caching
5. Missing Pagination
6. Synchronous Blocking
7. Connection Pool Issues

Time budget: 15 minutes maximum
```

### Step 3: Performance Report (2 min)

Generate: `reports/performance-audit-[timestamp].md`
```markdown
# Performance Audit Report

Generated: [timestamp]
Repository: [path]
Focus: Performance bottlenecks

---

## Executive Summary

- CRITICAL issues: X (10x+ performance impact)
- HIGH issues: Y (2x-10x performance impact)
- Total potential speedup: Zx faster

---

## Critical Performance Issues

### PERF-CRIT-001: N+1 Query in Order Listing
**File:** src/service/OrderService.java:123
**Impact:** 500 queries instead of 2
**Current Performance:** 15 seconds
**Expected After Fix:** <1 second
**Scale:** Gets worse linearly with data (500ms per order)

**Evidence:**
```java
List<Order> orders = orderRepository.findAll();  // 1 query
for (Order order : orders) {
    order.getItems().size();  // 500 queries if 500 orders
}
```

**Fix:**
```java
@Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items")
List<Order> findAllWithItems();
```

**Expected Impact:**
- Before: 1 + 500 = 501 queries, ~15 seconds
- After: 1 query, <1 second
- Improvement: 15x faster

---

## High Priority Issues

[Similar format]

---

## Quick Performance Wins

[Fixes that take <1 hour but provide significant speedup]

1. **Add @BatchSize to Order.items** (5 min, 10x speedup)
2. **Cache category list** (10 min, eliminate 1000 queries/hour)
3. **Add pagination to /orders endpoint** (15 min, prevent OOM)

---

## Performance Metrics

- Hotspot files analyzed: X
- Performance issues found: Y
- Critical (10x+ impact): A
- High (2x-10x impact): B
- Potential aggregate speedup: Zx

---

## Load Testing Recommendations

Test these scenarios after fixes:
1. 100 concurrent users on /orders endpoint
2. Database with 10K orders
3. Measure p95, p99 response times
```

## Time Estimate

**Total: 15-20 minutes**

## Output Message
```
✓ Performance audit completed in [X] minutes

Report: reports/performance-audit-[timestamp].md

Findings:
- CRITICAL: X issues (10x+ slowdown)
- HIGH: Y issues (2x-10x slowdown)

Biggest issue: N+1 query causing 15 second response time
Potential speedup: Zx faster after fixes

Quick wins: [Count] fixes taking <1 hour total
```
