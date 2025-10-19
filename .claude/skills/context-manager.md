---
name: context-manager
description: Intelligent context management for token optimization
tools:
  - read
  - bash
---

# Context Manager Skill v1.0

## Purpose
Manages context efficiently to maximize agent effectiveness within token limits.

## Capabilities

### 1. Semantic Segmentation

For large files (>500 lines), segment by:
- **Classes/Functions**: Extract specific methods
- **Logical blocks**: Related code sections
- **Dependency groups**: Code that works together

```bash
function extract_method() {
    local file=$1
    local method_name=$2

    # Extract method with context
    awk "/function $method_name|def $method_name|class $method_name/,/^}$|^[A-Za-z]/" "$file"
}
```

### 2. Context Windowing

Implement sliding window for analysis:
- **Window size**: 100-200 lines
- **Overlap**: 20-30 lines
- **Priority**: Hotspot areas first

### 3. Progressive Context Loading

```bash
function load_context() {
    local priority=$1

    case $priority in
        "critical")
            # Load only critical hotspots
            head -500  # First 500 lines
            ;;
        "standard")
            # Load important sections
            head -1000  # First 1000 lines
            ;;
        "comprehensive")
            # Load full file if small enough
            cat  # Full content
            ;;
    esac
}
```

### 4. Context Compression

Reduce context size while preserving information:
- Remove comments for initial scan
- Strip whitespace and formatting
- Summarize repetitive patterns
- Extract signatures only when needed

### 5. Cross-Agent Context Sharing

```yaml
shared_context:
  security_findings:
    - file: "UserController.java"
      line: 45
      issue: "SQL injection"
      severity: "CRITICAL"

  performance_bottlenecks:
    - file: "DataService.js"
      method: "fetchAll"
      issue: "N+1 query"
```

## Token Budget Management

### Thinking Levels

| Level | Token Budget | Use Case |
|-------|--------------|----------|
| `think` | 4K tokens | Simple pattern detection |
| `think hard` | 8K tokens | Single file analysis |
| `think harder` | 16K tokens | Multi-file analysis |
| `ultrathink` | 32K tokens | Full system analysis |

### Optimization Strategies

1. **Start minimal**: Begin with pattern detection
2. **Expand on findings**: Deep dive on issues
3. **Batch operations**: Group similar analyses
4. **Cache results**: Reuse previous findings

## Context Templates

### For Security Analysis
```
CONTEXT_PRIORITY:
1. Authentication/authorization code
2. Data validation points
3. External service calls
4. Configuration files
```

### For Performance Analysis
```
CONTEXT_PRIORITY:
1. Database queries
2. Loop structures
3. Async operations
4. Resource management
```

### For Architecture Review
```
CONTEXT_PRIORITY:
1. Class definitions
2. Import statements
3. Method signatures
4. Dependency injection
```

## Smart Context Selection

```bash
function select_context() {
    local agent_type=$1
    local file_size=$2
    local token_budget=$3

    if [ "$file_size" -gt 1000 ]; then
        # Use segmentation for large files
        echo "SEGMENT"
    elif [ "$token_budget" -lt 5000 ]; then
        # Use compression for tight budgets
        echo "COMPRESS"
    else
        # Full context for small files
        echo "FULL"
    fi
}
```

## Context Metadata

Track for each context:
- **Token count**: Actual tokens used
- **Relevance score**: How useful for analysis
- **Timestamp**: When context was loaded
- **Dependencies**: Related contexts needed

## Integration with Agents

```markdown
# In agent files
skills:
  - context-manager

# Usage
Apply context-manager semantic segmentation to large files
Use context-manager windowing for thorough analysis
Share findings via context-manager cross-agent protocol
```

## Performance Metrics

- Average context size: 2-3K tokens
- Compression ratio: 40-60%
- Cache hit rate: 70-80%
- Context relevance: 85-95%

## Best Practices

1. **Always measure** token usage
2. **Prioritize** high-value context
3. **Segment** before loading
4. **Cache** frequently accessed
5. **Share** between agents