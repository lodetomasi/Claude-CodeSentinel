# 🧙 Galadhrim - The Code Sentinels
## *AI-Powered Code Review Framework for Claude Code*

## Repository Purpose
Next-generation AI-powered code review framework with Chain-of-Thought reasoning detecting 65+ issue types across 10 categories.
Like the vigilant sentinels of Lothlórien, Galadhrim watches over your code with elven precision and wisdom.
Features: intelligent agent coordination, modular skills, advanced tools, and optimized token management.

## Project Structure
```
.claude/
├── agents/          # 10 specialized AI agents with CoT
├── commands/        # Main analysis command
├── patterns/        # Language-specific detection patterns
└── skills/          # Modular capabilities (pattern-matcher, context-manager)
reports/             # Generated analysis reports
```

## Quick Start Command
- `/project:full-review` - Complete analysis (45-60 min) with all 10 agents

The framework automatically detects languages, runs pattern scanning, coordinates agents, and generates reports.

## Standard Workflow
1. **Discovery** (3 min): Detect languages, frameworks, LOC count
2. **Pattern Scan** (5 min): Grep hotspots - reduces analysis scope 10x
3. **Agent Analysis** (40 min): 9 agents analyze hotspots in parallel
4. **Assembly** (5 min): Merge findings, deduplicate, prioritize
5. **Report** (3 min): Generate markdown with evidence + fixes

## Supported Languages
- **Java**: Spring Boot, Hibernate, JPA, Feign, Maven, Gradle
- **Python**: Django, Flask, FastAPI, SQLAlchemy, Celery
- **JavaScript/Node.js**: Express, React, Sequelize, Mongoose
- **Go**: Gin, Echo, Gorm, standard library

Auto-detected via file extensions and import statements.

## Issue Categories (40+ types detected)

### 1. Security (8 types)
SQL injection, XSS/CSRF, hardcoded secrets, auth bypass, authorization gaps, weak crypto, sensitive data exposure, insecure deserialization

### 2. Performance (7 types)
N+1 queries, missing batch operations, inefficient algorithms, no caching, missing pagination, synchronous blocking, connection pool issues

### 3. Concurrency (6 types)
Race conditions, deadlock risks, missing synchronization, thread pool issues, resource leaks, shared mutable state

### 4. Architecture (5 types)
God classes (>500 LOC), circular dependencies, layer violations, missing abstractions, tight coupling

### 5. Resilience (6 types)
Missing timeouts, no circuit breakers, no retry logic, missing fallback, no bulkhead isolation, no graceful degradation

### 6. Data Integrity (7 types)
Missing transactions, no optimistic locking, dirty reads possible, missing cascade, no validation, inconsistent state, lost updates

### 7. Observability (6 types)
Missing structured logging, no correlation IDs, silent failures, no metrics/instrumentation, debug logs in production, missing health checks

### 8. API Design (8 types)
Inconsistent naming, wrong HTTP status codes, missing pagination, no versioning, missing rate limiting, no HATEOAS, inconsistent errors, no request validation

### 9. Testing Gaps (5 types)
Critical paths untested, missing integration tests, no edge case coverage, flaky tests, no contract tests

### 10. Code Quality (7 types)
High cyclomatic complexity (>10), deep nesting (>4 levels), long methods (>50 lines), code duplication, dead code, magic numbers, poor naming

## Output Format
Reports saved to: `reports/[type]-review-[timestamp].md`

Each finding includes:
```json
{
  "id": "SEC-CRIT-001",
  "type": "SECURITY",
  "severity": "CRITICAL|HIGH|MEDIUM|LOW",
  "category": "SQL_INJECTION",
  "file": "path/to/file.java",
  "line": 45,
  "evidence": "String query = \"SELECT * FROM users WHERE id = \" + userId;",
  "description": "SQL query constructed using string concatenation with user input",
  "impact": "Attacker can inject arbitrary SQL commands, read/modify all data",
  "recommendation": "Use PreparedStatement:\nString query = \"SELECT * FROM users WHERE id = ?\";\nPreparedStatement stmt = conn.prepareStatement(query);\nstmt.setString(1, userId);"
}
```

## Critical Rules - ALWAYS FOLLOW

### Analysis Rules
1. ALWAYS run pattern scan before deep analysis (reduces files 10x)
2. NEVER report findings without actual code evidence
3. VERIFY CRITICAL findings - target 95% accuracy
4. CONSIDER framework defaults (Spring Security auto-config, Django ORM protection)
5. ADAPT severity to context:
   - Production code: Hardcoded password = CRITICAL
   - Development tool: Hardcoded password = HIGH
   - Test code: Hardcoded password = LOW
6. SKIP files with zero hotspots detected
7. FOCUS on changed files first if git diff available

### Quality Rules
8. Code evidence must be actual code from the file, not paraphrased
9. Recommendations must include working code examples
10. Impact must be specific: "500 queries instead of 2" not "performance issue"
11. Severity must follow guidelines consistently
12. Deduplication by: `sha256(file + line + category)`

### Performance Rules
13. Use tiered analysis:
    - Tier 1: Pattern scan (all files, 0 tokens)
    - Tier 2: Standard check (50% of files)
    - Tier 3: Deep analysis (10% of files - hotspots only)
14. Semantic segmentation for files >500 LOC (split by methods/classes)
15. Progressive skill disclosure (load skills only when needed)
16. Compact mode if context approaching limit

## Token Budget Strategy

Use appropriate thinking levels:
- **"think"** (4K tokens): Discovery phase, simple pattern matching
- **"think hard"** (8K tokens): Pattern analysis, hotspot identification
- **"think harder"** (16K tokens): Single agent deep analysis
- **"ultrathink"** (32K tokens): Multi-agent coordination, complex architecture

Example: "Think hard about the pattern scan results, then ultrathink the agent coordination strategy."

## Agent Context Management

When agents analyze code:
1. **Stay within layers**: Controller → Service → Repository (no jumping)
2. **Max cross-layer context**: 200 tokens (minimal handoff info)
3. **Focus order**: Hotspot files → High LOC files → Everything else
4. **Segmentation**: Split files >500 LOC by methods/classes
5. **Skip intelligently**: Test files (unless testing-gaps analysis), generated code, vendor libraries

## Framework-Specific Intelligence

### Java/Spring Boot
- Check for Spring Security auto-configuration before flagging auth gaps
- Recognize @Transactional = transaction management present
- JPA EntityManager usage = consider lazy loading issues
- @Async methods = check thread pool configuration

### Python/Django
- Django ORM = parameterized queries by default (safe)
- Django views = multi-threaded in production (check state)
- Django admin = auth handled (unless custom views)
- settings.py DEBUG=True = flag for production

### JavaScript/Node.js
- Express = single-threaded (concurrency issues rare)
- Promises without .catch() = unhandled rejections
- Sequelize/Mongoose = ORM protections (usually safe)
- require vs import = check consistency

### Go
- Goroutines = check synchronization with channels/mutexes
- defer for resource cleanup = good pattern
- error return values = check if ignored
- Panic recovery = verify in critical paths

## Testing Commands (for validation)
```bash
# Count LOC by language
find . -name "*.java" | xargs wc -l | tail -1
find . -name "*.py" | xargs wc -l | tail -1
find . -name "*.js" | xargs wc -l | tail -1

# Quick hotspot identification
grep -r "password.*=" --include="*.java" -n | head -10
grep -r "query.*+" --include="*.py" -n | head -10
grep -r "for.*for.*for" --include="*.js" -n | head -10

# Framework detection
grep -r "import.*springframework" --include="*.java" -l | head -1
grep -r "from django" --include="*.py" -l | head -1
grep -r "require.*express" --include="*.js" -l | head -1
```

## Expected Performance

- **Quick Scan**: 3-5 minutes, identifies all hotspots
- **Security Only**: 15-20 minutes, deep security analysis
- **Full Review**: 45-60 minutes, all categories analyzed
- **Cost per review**: $2-5 API cost (mostly Sonnet, Opus for complex only)
- **Accuracy**: 95% for CRITICAL, 85% for HIGH, 75% for MEDIUM/LOW

## Report Statistics

Typical findings distribution:
- CRITICAL: 2-5% (immediate action required)
- HIGH: 10-15% (fix before release)
- MEDIUM: 30-40% (fix in next sprint)
- LOW: 45-55% (improvement suggestions)

## Extensibility

To add new language support:
1. Create `patterns/[language]-patterns.yaml`
2. Add detection logic in orchestrator discovery phase
3. Add framework-specific rules in CLAUDE.md
4. Test with sample repository

To add new agent:
1. Create `.claude/agents/[name]-agent.md` with YAML header
2. Define categories, patterns, severity rules
3. Add to orchestrator delegation logic
4. Create supporting skills if needed

## Important Notes

- Analysis is **local only** - no code sent externally except to Claude API
- Reports contain **actual code snippets** - review before sharing
- False positives possible - **verify CRITICAL findings** before acting
- Framework protections often prevent issues - **check before flagging**
- Context matters - **production vs dev vs test code** severity differs