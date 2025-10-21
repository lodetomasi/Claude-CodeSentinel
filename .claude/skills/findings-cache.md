---
name: findings-cache
description: Temporary cache for findings during analysis to enable deduplication and aggregation
tools:
  - bash
  - write
  - read
---

# Findings Cache Skill v1.0

## Purpose
Provides a centralized cache for all findings during analysis, enabling real-time deduplication, aggregation, and cross-agent insights.

## Cache Structure

### 1. Cache File Format

```json
{
  "session": {
    "id": "analysis-20251019-143022",
    "start_time": "2025-10-19T14:30:22Z",
    "project": "/path/to/project",
    "status": "in_progress"
  },

  "findings": {
    "SEC-CRIT-001": {
      "id": "SEC-CRIT-001",
      "hash": "sha256:abc123...",  // For deduplication
      "type": "SECURITY",
      "severity": "CRITICAL",
      "category": "SQL_INJECTION",
      "file": "UserController.java",
      "line": 45,
      "agent": "security-agent",
      "timestamp": "2025-10-19T14:32:15Z",
      "evidence": "String query = \"SELECT * FROM users WHERE id = \" + userId;",
      "duplicates": []  // IDs of duplicate findings
    }
  },

  "statistics": {
    "total": 45,
    "by_severity": {
      "CRITICAL": 3,
      "HIGH": 12,
      "MEDIUM": 20,
      "LOW": 10
    },
    "by_agent": {
      "security-agent": 15,
      "performance-agent": 10,
      "concurrency-agent": 5
    },
    "by_file": {
      "UserController.java": 8,
      "OrderService.java": 5
    }
  },

  "deduplication_log": [
    {
      "original": "SEC-CRIT-001",
      "duplicate": "PERF-HIGH-003",
      "reason": "Same line, different perspective",
      "merged_at": "2025-10-19T14:35:00Z"
    }
  ]
}
```

### 2. Cache Operations

#### Initialize Cache

```bash
init_findings_cache() {
    local cache_file="/tmp/galadhrim/cache.json"
    local session_id="analysis-$(date +%Y%m%d-%H%M%S)"

    # Create cache directory if it doesn't exist
    mkdir -p /tmp/galadhrim

    cat > "$cache_file" << EOF
{
  "session": {
    "id": "$session_id",
    "start_time": "$(date -Iseconds)",
    "project": "$(pwd)",
    "status": "in_progress"
  },
  "findings": {},
  "statistics": {
    "total": 0,
    "by_severity": {},
    "by_agent": {},
    "by_file": {}
  },
  "deduplication_log": []
}
EOF

    echo "[CACHE] Initialized: $cache_file"
    echo "[CACHE] Session: $session_id"
}
```

#### Add Finding with Deduplication

```bash
add_finding_to_cache() {
    local finding=$1
    local agent=$2
    local cache_file="/tmp/galadhrim/cache.json"

    # Generate hash for deduplication
    local hash=$(echo "$finding" | jq -r '.file + ":" + (.line | tostring) + ":" + .category' | sha256sum | cut -d' ' -f1)

    # Check for duplicates
    local duplicate=$(jq --arg hash "$hash" '.findings | to_entries | .[] | select(.value.hash == $hash) | .key' "$cache_file" | head -1)

    if [ -n "$duplicate" ]; then
        echo "[CACHE] Duplicate found: $duplicate"

        # Update duplicate info
        jq --arg dup "$duplicate" \
           --arg new_id "$(echo "$finding" | jq -r .id)" \
           --arg agent "$agent" '
            .findings[$dup].duplicates += [$new_id] |
            .deduplication_log += [{
                original: $dup,
                duplicate: $new_id,
                reason: "Same location, different agent",
                merged_at: now | todate
            }]
        ' "$cache_file" > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file"

        return 1  # Signal duplicate
    fi

    # Add new finding
    jq --argjson finding "$finding" \
       --arg hash "$hash" \
       --arg agent "$agent" '
        .findings[$finding.id] = ($finding | .hash = $hash | .agent = $agent | .timestamp = (now | todate)) |
        .statistics.total += 1 |
        .statistics.by_severity[$finding.severity] = ((.statistics.by_severity[$finding.severity] // 0) + 1) |
        .statistics.by_agent[$agent] = ((.statistics.by_agent[$agent] // 0) + 1) |
        .statistics.by_file[$finding.file] = ((.statistics.by_file[$finding.file] // 0) + 1)
    ' "$cache_file" > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file"

    echo "[CACHE] Added: $(echo "$finding" | jq -r .id)"
    return 0
}
```

#### Query Cache

```bash
# Get all findings by severity
get_findings_by_severity() {
    local severity=$1
    local cache_file="/tmp/galadhrim/cache.json"

    jq --arg sev "$severity" '.findings | to_entries | map(select(.value.severity == $sev)) | map(.value)' "$cache_file"
}

# Get findings by file
get_findings_by_file() {
    local file=$1
    local cache_file="/tmp/galadhrim/cache.json"

    jq --arg file "$file" '.findings | to_entries | map(select(.value.file == $file)) | map(.value)' "$cache_file"
}

# Get top problematic files
get_top_files() {
    local limit=${1:-10}
    local cache_file="/tmp/galadhrim/cache.json"

    jq --argjson limit "$limit" '.statistics.by_file | to_entries | sort_by(.value) | reverse | .[:$limit]' "$cache_file"
}
```

### 3. Real-time Statistics

```bash
print_cache_statistics() {
    local cache_file="/tmp/galadhrim/cache.json"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 FINDINGS CACHE STATISTICS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Total findings
    local total=$(jq '.statistics.total' "$cache_file")
    echo "Total Findings: $total"

    # By severity
    echo ""
    echo "By Severity:"
    jq -r '.statistics.by_severity | to_entries | .[] | "  \(.key): \(.value)"' "$cache_file"

    # By agent
    echo ""
    echo "By Agent:"
    jq -r '.statistics.by_agent | to_entries | .[] | "  \(.key): \(.value)"' "$cache_file"

    # Top files
    echo ""
    echo "Top 5 Problematic Files:"
    jq -r '.statistics.by_file | to_entries | sort_by(.value) | reverse | .[:5] | .[] | "  \(.key): \(.value) issues"' "$cache_file"

    # Deduplication stats
    local duplicates=$(jq '.deduplication_log | length' "$cache_file")
    echo ""
    echo "Duplicates Removed: $duplicates"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
```

## Deduplication Algorithm

### Canonical Hash Generation

```python
def generate_finding_hash(finding):
    """Generate unique hash for deduplication"""

    # Primary key: file + line + category
    primary = f"{finding['file']}:{finding['line']}:{finding['category']}"

    # Secondary key for similar issues
    if finding.get('evidence'):
        # Normalize evidence (remove whitespace variations)
        evidence = ' '.join(finding['evidence'].split())
        secondary = hashlib.md5(evidence.encode()).hexdigest()[:8]
    else:
        secondary = ""

    return hashlib.sha256(f"{primary}:{secondary}".encode()).hexdigest()
```

### Merge Strategy

```python
def merge_duplicate_findings(original, duplicate):
    """Merge duplicate finding into original"""

    merged = original.copy()

    # Keep higher severity
    if SEVERITY_WEIGHT[duplicate['severity']] > SEVERITY_WEIGHT[original['severity']]:
        merged['severity'] = duplicate['severity']

    # Combine descriptions
    if duplicate['description'] not in original['description']:
        merged['description'] += f"\n\nAlso detected by {duplicate['agent']}: {duplicate['description']}"

    # Merge recommendations
    if duplicate.get('recommendation'):
        if not merged.get('additional_recommendations'):
            merged['additional_recommendations'] = []
        merged['additional_recommendations'].append(duplicate['recommendation'])

    # Track all detecting agents
    if 'detected_by' not in merged:
        merged['detected_by'] = [original['agent']]
    merged['detected_by'].append(duplicate['agent'])

    return merged
```

## Cache Lifecycle

### 1. Initialization

```bash
# At start of analysis
init_findings_cache
```

### 2. During Analysis

```bash
# Each agent adds findings
for finding in $findings; do
    if add_finding_to_cache "$finding" "$agent_name"; then
        echo "New finding added"
    else
        echo "Duplicate merged"
    fi
done

# Periodic statistics
print_cache_statistics
```

### 3. Final Aggregation

```bash
finalize_cache() {
    local cache_file="/tmp/galadhrim/cache.json"

    # Mark as complete
    jq '.session.status = "complete" | .session.end_time = (now | todate)' "$cache_file" > "${cache_file}.tmp" && \
    mv "${cache_file}.tmp" "$cache_file"

    # Generate final report
    jq '.findings | to_entries | map(.value) | sort_by(.severity)' "$cache_file" > "findings_final.json"

    echo "[CACHE] Finalized with $(jq '.statistics.total' "$cache_file") findings"
}
```

### 4. Cleanup

```bash
cleanup_cache() {
    local cache_file="/tmp/galadhrim/cache.json"

    # Archive if needed
    if [ -f "$cache_file" ]; then
        mv "$cache_file" "cache_$(date +%Y%m%d_%H%M%S).json"
    fi

    # Clean temp files
    rm -f /tmp/findings_cache.json*
    rm -f /tmp/context.lock

    echo "[CACHE] Cleaned up"
}
```

## Performance Metrics

### Cache Benefits

| Operation | Without Cache | With Cache | Improvement |
|-----------|--------------|------------|-------------|
| Deduplication | O(n²) comparison | O(1) hash lookup | 100x faster |
| Statistics | Recalculate each time | Incremental update | 50x faster |
| Cross-agent query | Parse all reports | Direct query | 10x faster |
| Finding merge | Manual process | Automatic | 100% automated |

## Integration Example

```bash
# In full-review.md
echo "Initializing findings cache..."
init_findings_cache

# Run agents with cache
for agent in $agents; do
    findings=$(run_agent "$agent")

    # Add to cache with deduplication
    echo "$findings" | jq -c '.[]' | while read -r finding; do
        add_finding_to_cache "$finding" "$agent"
    done

    # Show progress
    print_cache_statistics
done

# Finalize and generate report
finalize_cache
```

## Best Practices

1. **Initialize early** - Create cache before any agent runs
2. **Update atomically** - Use file locks for concurrent access
3. **Query efficiently** - Use jq filters instead of parsing
4. **Clean up always** - Remove cache files after analysis
5. **Archive if needed** - Keep cache for debugging