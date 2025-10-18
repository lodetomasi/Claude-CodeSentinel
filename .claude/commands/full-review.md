---
name: full-review
description: Complete multi-agent code review analyzing all 10 categories (45-60 minutes)
model: claude-sonnet-4-5-20250929
---

# Full Code Review Command

Execute comprehensive analysis with all 9 specialized agents across 10 categories.

## Workflow Phases

### Phase 1: Discovery (3 min) - think

Delegate to @orchestrator for discovery:
````
Execute discovery phase:
- Detect languages and frameworks
- Count total LOC
- Identify architectural layers
- Generate project manifest
````

### Phase 2: Pattern Scan (5 min) - think hard

Execute `/project:quick-scan` command.

Save results to `reports/hotspots-[timestamp].txt` for reference.

### Phase 3: Multi-Agent Analysis (40 min) - ultrathink

**Coordinate 9 agents in parallel based on hotspots:**

**Security Analysis** (Delegate to @security-agent)
````
Analyze files with security patterns:
- SQL injection candidates
- Hardcoded secrets
- Missing authentication
- Cryptographic weaknesses
Target: 5-20 findings
````

**Performance Analysis** (Delegate to @performance-agent)
````
Analyze files with performance patterns:
- N+1 query hotspots
- Missing batch operations
- Inefficient algorithms
- Missing caching opportunities
Target: 10-30 findings
````

**Concurrency Analysis** (Delegate to @concurrency-agent)
````
Analyze files with concurrency patterns:
- Race condition risks
- Shared mutable state
- Thread safety issues
- Resource leaks
Target: 5-15 findings
````

**Architecture Review** (Delegate to @architecture-agent)
````
Analyze structural issues:
- Files >500 LOC (god classes)
- Circular dependencies
- Layer violations
- High coupling
Target: 8-20 findings
````

**Resilience Analysis** (Delegate to @resilience-agent)
````
Analyze fault tolerance:
- Missing timeouts
- No circuit breakers
- Missing retry logic
- No fallback mechanisms
Target: 10-25 findings
````

**Data Integrity Analysis** (Delegate to @data-integrity-agent)
````
Analyze data consistency:
- Missing transactions
- No optimistic locking
- Validation gaps
- Lost update risks
Target: 8-20 findings
````

**Observability Analysis** (Delegate to @observability-agent)
````
Analyze monitoring/logging:
- Poor logging practices
- Silent failures
- Missing metrics
- No health checks
Target: 15-40 findings
````

**API Design Review** (Delegate to @api-design-agent)
````
Analyze REST APIs:
- Inconsistent naming
- Wrong HTTP status codes
- Missing pagination
- No versioning
Target: 10-25 findings
````

**Code Quality Review** (Delegate to @code-quality-agent)
````
Analyze maintainability:
- High cyclomatic complexity
- Long methods
- Code duplication
- Dead code
Target: 20-50 findings
````

**Agent Coordination Rules:**
- Agents run independently (parallel where possible)
- Each agent max 50K token context
- Skip files with zero hotspots (except god class check)
- Use semantic segmentation for files >500 LOC
- Time limit: 6-8 minutes per agent max

### Phase 4: Assembly & Deduplication (5 min)

Collect all findings from agents.

**Deduplication Process:**
````
For each finding:
  hash = sha256(file + ":" + line + ":" + category)
  if hash exists:
    keep finding with higher severity
    merge unique recommendations
  else:
    add to unique findings
````

**Sorting:**
1. By severity: CRITICAL → HIGH → MEDIUM → LOW
2. Within severity: Security → Performance → Others
3. Within type: By file path (alphabetical)

**Statistics Generation:**
- Total findings count
- Breakdown by severity (counts + percentages)
- Breakdown by category
- Top 10 files by issue count
- Quick wins identification (HIGH severity + low effort)

### Phase 5: Report Generation (3 min)

Generate comprehensive report: `reports/code-review-[timestamp].md`

**Report Structure:**
````markdown
# Code Review Report

Generated: [ISO timestamp]
Repository: [path]
Analyzed: [X files, Y LOC]
Languages: [Java, Python, etc.]
Frameworks: [Spring Boot, Django, etc.]
Analysis Time: [Z minutes]

---

## Executive Summary

### Findings Overview
- CRITICAL: X issues (require immediate action)
- HIGH: Y issues (fix before release)
- MEDIUM: Z issues (address in next sprint)
- LOW: W issues (improvement suggestions)

### Category Breakdown
[Table with counts per category per severity]

### Top 5 Risk Areas
1. [File with most CRITICAL]
2. [File with most HIGH]
3. [File with most total issues]
4. [File with diverse issue types]
5. [File with architectural concerns]

---

## Quick Wins (High Impact, Low Effort)

[8-10 fixes that provide maximum value with minimal work]

---

## Critical Findings

[Detailed findings with:
- File:line location
- Code evidence
- Impact description
- Working fix with code]

---

## High Priority Findings

[Similar format, slightly less detail]

---

## Medium Priority Findings

[Grouped by category, less detail]

---

## Low Priority Findings

[Brief list format]

---

## Statistics

[Detailed tables and charts]

---

## Recommendations

### Immediate (This Week)
[Action items for CRITICAL issues]

### Short Term (This Sprint)
[Action items for HIGH issues]

### Medium Term (Next Sprint)
[Action items for MEDIUM issues]

### Long Term (Roadmap)
[Strategic improvements]

---

## Appendix: Methodology

[Explain analysis approach, accuracy rates, limitations]
````

Display report path to user.

## Timing Expectations

- Discovery: 2-3 minutes
- Pattern Scan: 4-6 minutes
- Agent Analysis: 35-45 minutes
- Assembly: 3-5 minutes
- Report: 2-3 minutes

**Total: 46-62 minutes**

## Success Criteria

✓ All 9 agents completed successfully
✓ Minimum 90% file coverage
✓ At least 1 finding per major category
✓ CRITICAL findings include working fixes
✓ Report generated with all sections
✓ Statistics are mathematically correct
✓ Deduplication removed duplicates

## Output Message
````
✓ Full code review completed in [X] minutes

Report: reports/code-review-[timestamp].md

Summary:
- CRITICAL: X issues
- HIGH: Y issues
- MEDIUM: Z issues
- LOW: W issues

Top priority: [Most critical finding summary]

Next steps:
1. Review CRITICAL findings immediately
2. Plan fixes for HIGH priority issues
3. Consider quick wins for fast improvements
````
