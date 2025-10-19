---
name: pattern-matcher
description: Advanced pattern matching capability for code analysis
tools:
  - grep
  - bash
---

# Pattern Matcher Skill v1.0

## Purpose
Provides reusable pattern matching capabilities for all agents to detect code issues efficiently.

## Capabilities

### 1. Multi-Language Pattern Detection

```bash
function detect_patterns() {
    local pattern_type=$1
    local language=$2

    case $pattern_type in
        "security")
            grep -r "password\\|secret\\|token\\|api[_-]key" --include="*.$language" -n 2>/dev/null
            ;;
        "performance")
            grep -r "SELECT.*SELECT\\|for.*await\\|N\\+1" --include="*.$language" -n 2>/dev/null
            ;;
        "concurrency")
            grep -r "synchronized\\|lock\\|mutex\\|async" --include="*.$language" -n 2>/dev/null
            ;;
        *)
            echo "Unknown pattern type: $pattern_type"
            ;;
    esac
}
```

### 2. Context-Aware Pattern Matching

For each detected pattern, provide:
- **Line context**: 3 lines before and after
- **File metrics**: Size, complexity, last modified
- **Cross-reference**: Related patterns in same file
- **Severity scoring**: Based on pattern combinations

### 3. Pattern Aggregation

```bash
function aggregate_patterns() {
    # Collect all pattern matches
    local all_patterns=$(mktemp)

    # Security patterns
    grep -r "password\\|secret" --include="*.java" >> "$all_patterns"
    grep -r "eval\\|exec" --include="*.py" >> "$all_patterns"
    grep -r "innerHTML\\|eval" --include="*.js" >> "$all_patterns"

    # Sort by frequency and severity
    sort "$all_patterns" | uniq -c | sort -rn
    rm "$all_patterns"
}
```

### 4. Progressive Pattern Loading

Load patterns based on:
1. **Language detected** - Only load relevant patterns
2. **File size** - Use simpler patterns for large files
3. **Previous findings** - Focus on problem areas
4. **Agent request** - Load specific pattern sets

### 5. Pattern Caching

Cache results for:
- Files unchanged since last scan
- Common pattern combinations
- Frequently accessed codebases

## Usage by Agents

```markdown
# In any agent file
skills:
  - pattern-matcher

# Then use in agent logic
Use pattern-matcher skill to detect security patterns in Java files
Aggregate findings using pattern-matcher aggregation
Apply context-aware matching for detailed analysis
```

## Pattern Categories

### Security Patterns
- Hardcoded credentials
- SQL injection vectors
- Command injection risks
- Path traversal vulnerabilities
- Weak cryptography

### Performance Patterns
- N+1 queries
- Nested loops O(n²)
- Synchronous blocking
- Missing indexes
- Large result sets

### Architecture Patterns
- God classes (>500 LOC)
- Circular dependencies
- Layer violations
- Missing abstractions
- Tight coupling

### Quality Patterns
- Dead code
- Duplicate code
- Complex methods
- Deep nesting
- Magic numbers

## Performance Optimization

- Use `--include` to filter files
- Limit with `head` for initial scan
- Use `grep -l` for file listing only
- Parallelize with `xargs -P`
- Cache frequent searches

## Integration Points

This skill integrates with:
- All analysis agents (security, performance, etc.)
- Orchestrator for initial scanning
- Commands for quick detection
- Reports for evidence gathering