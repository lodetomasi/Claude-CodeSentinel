---
name: full-review
description: Complete multi-agent code review analyzing all 10 categories (45-60 minutes)
model: claude-sonnet-4-5-20250929
---

# Full Code Review Command

Execute comprehensive analysis with all 9 specialized agents across 10 categories.

## Intelligent Project Root Auto-Detection

```bash
# Function to find project root intelligently
find_project_root() {
    local current_dir="$(pwd)"
    local checked_dirs=""

    echo "🔍 Auto-detecting project root..."
    echo ""

    # Strategy 1: Look for .git directory (most reliable)
    local dir="$current_dir"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ]; then
            echo "  ✓ Found .git repository at: $dir"
            echo "$dir"
            return 0
        fi
        checked_dirs="$checked_dirs\n  - Checked: $dir"
        dir="$(dirname "$dir")"
    done

    # Strategy 2: Look for project indicators in current or parent directory
    for check_dir in "." ".." "../.." ; do
        local abs_dir="$(cd "$check_dir" 2>/dev/null && pwd)"
        [ -z "$abs_dir" ] && continue

        # Check for various project root indicators
        if [ -f "$abs_dir/package.json" ] || \
           [ -f "$abs_dir/pom.xml" ] || \
           [ -f "$abs_dir/build.gradle" ] || \
           [ -f "$abs_dir/requirements.txt" ] || \
           [ -f "$abs_dir/go.mod" ] || \
           [ -f "$abs_dir/Cargo.toml" ] || \
           [ -f "$abs_dir/composer.json" ] || \
           [ -f "$abs_dir/Gemfile" ] || \
           [ -f "$abs_dir/CLAUDE.md" ] || \
           [ -f "$abs_dir/README.md" ]; then

            # Found project indicator
            local indicator=""
            [ -f "$abs_dir/package.json" ] && indicator="package.json"
            [ -f "$abs_dir/pom.xml" ] && indicator="pom.xml"
            [ -f "$abs_dir/requirements.txt" ] && indicator="requirements.txt"
            [ -f "$abs_dir/go.mod" ] && indicator="go.mod"
            [ -f "$abs_dir/CLAUDE.md" ] && indicator="CLAUDE.md"

            echo "  ✓ Found project indicator ($indicator) at: $abs_dir"
            echo "$abs_dir"
            return 0
        fi
    done

    # Strategy 3: Check if we're in a subdirectory with framework indicators
    local current_basename="$(basename "$current_dir")"
    if [[ "$current_basename" == *"claude"* ]] || \
       [[ "$current_basename" == *"sentinel"* ]] || \
       [[ "$current_basename" == *"framework"* ]] || \
       [[ "$current_basename" == *"CodeSentinel"* ]] || \
       [[ "$current_dir" == *"/.claude"* ]]; then
        # Check if we ARE the framework (has .claude/agents directory)
        if [ -d "$current_dir/.claude/agents" ]; then
            # We're the framework itself, check parent for a project
            local parent_dir="$(dirname "$current_dir")"
            if [ -d "$parent_dir/.git" ] || \
               [ -f "$parent_dir/package.json" ] || \
               [ -f "$parent_dir/pom.xml" ] || \
               [ -f "$parent_dir/requirements.txt" ] || \
               [ -f "$parent_dir/go.mod" ]; then
                echo "  ✓ Framework detected, parent is a project: $parent_dir"
                echo "$parent_dir"
                return 0
            else
                # Parent is not a project, analyze framework itself
                echo "  ✓ Framework standalone mode: $current_dir"
                echo "$current_dir"
                return 0
            fi
        fi
    fi

    # Default: use current directory
    echo "  ⚠ No clear project root found, using current directory"
    echo "$current_dir"
    return 0
}

# Function to get framework directory name for exclusion
get_framework_dirname() {
    local current_dir="$(pwd)"
    local basename="$(basename "$current_dir")"

    # If we're in .claude directory, get parent name
    if [[ "$current_dir" == *"/.claude"* ]]; then
        local framework_dir="$(dirname "$(echo "$current_dir" | sed 's|/.claude.*|/.claude|')")"
        basename="$(basename "$framework_dir")"
    fi

    echo "$basename"
}

# Auto-detect project root
export TARGET_PATH="$(find_project_root)"
export FRAMEWORK_PATH="$(pwd)"
export FRAMEWORK_DIRNAME="$(get_framework_dirname)"

# Build exclusion patterns
EXCLUDE_PATTERNS="--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=vendor --exclude-dir=dist --exclude-dir=build"

# Add framework directory to exclusions if we're analyzing parent
if [ "$TARGET_PATH" != "$FRAMEWORK_PATH" ]; then
    EXCLUDE_PATTERNS="$EXCLUDE_PATTERNS --exclude-dir=$FRAMEWORK_DIRNAME --exclude-dir=.claude"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "🎯 PROJECT ROOT: $TARGET_PATH"
echo "🔧 FRAMEWORK: $FRAMEWORK_PATH"
if [ "$TARGET_PATH" != "$FRAMEWORK_PATH" ]; then
    echo "🚫 EXCLUDING: $FRAMEWORK_DIRNAME/ (framework directory)"
fi
echo "════════════════════════════════════════════════════════════"
echo ""

# Verify we can access the target
if [ ! -d "$TARGET_PATH" ]; then
    echo "❌ Error: Cannot access target directory: $TARGET_PATH"
    exit 1
fi

# Show what we'll analyze
echo "📊 Project Overview:"
echo "  Total files: $(find "$TARGET_PATH" -type f -name "*.java" -o -name "*.py" -o -name "*.js" -o -name "*.go" 2>/dev/null | grep -v "/$FRAMEWORK_DIRNAME/" | wc -l)"
echo "  Java: $(find "$TARGET_PATH" -name "*.java" 2>/dev/null | grep -v "/$FRAMEWORK_DIRNAME/" | wc -l) files"
echo "  Python: $(find "$TARGET_PATH" -name "*.py" 2>/dev/null | grep -v "/$FRAMEWORK_DIRNAME/" | wc -l) files"
echo "  JavaScript: $(find "$TARGET_PATH" -name "*.js" -o -name "*.jsx" 2>/dev/null | grep -v "/$FRAMEWORK_DIRNAME/" | wc -l) files"
echo "  TypeScript: $(find "$TARGET_PATH" -name "*.ts" -o -name "*.tsx" 2>/dev/null | grep -v "/$FRAMEWORK_DIRNAME/" | wc -l) files"
echo "  Go: $(find "$TARGET_PATH" -name "*.go" 2>/dev/null | grep -v "/$FRAMEWORK_DIRNAME/" | wc -l) files"
echo ""
```

## Enhanced Workflow with Progress Tracking

```bash
# Initialize progress tracking
START_TIME=$(date +%s)
TOTAL_AGENTS=10
COMPLETED_AGENTS=0
TOTAL_FINDINGS=0

# Define colors for phases and agents
declare -A PHASE_COLORS=(
    ["Discovery"]="\033[1;94m"        # Bright Blue
    ["Pattern Scan"]="\033[1;93m"     # Bright Yellow
    ["Agent Analysis"]="\033[1;95m"   # Bright Magenta
    ["Assembly"]="\033[1;92m"         # Bright Green
    ["Report"]="\033[1;96m"           # Bright Cyan
)

declare -A AGENT_COLORS=(
    ["security-agent"]="\033[1;31m"        # Bold Red
    ["performance-agent"]="\033[1;33m"     # Bold Yellow
    ["concurrency-agent"]="\033[1;35m"     # Bold Magenta
    ["data-integrity-agent"]="\033[1;36m"  # Bold Cyan
    ["architecture-agent"]="\033[1;34m"    # Bold Blue
    ["resilience-agent"]="\033[1;32m"      # Bold Green
    ["observability-agent"]="\033[1;37m"   # Bold White
    ["api-design-agent"]="\033[1;95m"      # Light Magenta
    ["code-quality-agent"]="\033[1;93m"    # Light Yellow
)

RESET="\033[0m"

report_progress() {
    local phase=$1
    local details=$2
    local agent=${3:-}  # Optional agent parameter
    local current_time=$(date +%s)
    local elapsed=$((current_time - START_TIME))
    local eta=$(estimate_remaining_time $COMPLETED_AGENTS $TOTAL_AGENTS $elapsed)

    # Get color for phase or agent
    local color="${PHASE_COLORS[$phase]}"
    [ -n "$agent" ] && color="${AGENT_COLORS[$agent]}"
    [ -z "$color" ] && color="\033[1;37m"  # Default to white

    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${color}⚡ PROGRESS UPDATE [$(date +%H:%M:%S)]${RESET}"
    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "📍 Phase: ${color}$phase${RESET}"
    [ -n "$agent" ] && echo -e "🤖 Agent: ${color}$agent${RESET}"
    echo -e "📝 Status: $details"
    echo -e "⏱️ Elapsed: $(format_time $elapsed)"
    echo -e "🎯 Agents: $COMPLETED_AGENTS/$TOTAL_AGENTS complete"
    echo -e "📊 Findings so far: $TOTAL_FINDINGS"
    echo -e "⏳ ETA: $(format_time $eta)"
    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

estimate_remaining_time() {
    local completed=$1
    local total=$2
    local elapsed=$3
    [ $completed -eq 0 ] && echo "900" && return  # 15 min default
    local avg_per_agent=$((elapsed / completed))
    local remaining=$((total - completed))
    echo $((remaining * avg_per_agent))
}

format_time() {
    local seconds=$1
    printf "%02d:%02d" $((seconds/60)) $((seconds%60))
}

# Initialize v3.0 features
echo -e "\033[1;96m🚀 Initializing Claude-CodeSentinel v3.0 features...\033[0m"

# Function to launch agent with color
launch_agent() {
    local agent_name=$1
    local task=$2
    local color="${AGENT_COLORS[$agent_name]}"
    [ -z "$color" ] && color="\033[1;37m"  # Default to white

    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${color}🚀 LAUNCHING AGENT: $agent_name${RESET}"
    echo -e "${color}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "📋 Task: $task"
    echo -e "${color}▶ Starting analysis...${RESET}"
    echo ""
}

# Function to show agent completion
complete_agent() {
    local agent_name=$1
    local findings=$2
    local color="${AGENT_COLORS[$agent_name]}"
    [ -z "$color" ] && color="\033[1;37m"

    COMPLETED_AGENTS=$((COMPLETED_AGENTS + 1))
    TOTAL_FINDINGS=$((TOTAL_FINDINGS + findings))

    echo -e "${color}✅ $agent_name completed with $findings findings${RESET}"
    echo ""
}

# Initialize findings cache
init_findings_cache() {
    echo -e "\033[1;92m[CACHE] Initializing findings cache...\033[0m"
    mkdir -p /tmp/codesentinel
    echo '{"findings": [], "stats": {}}' > /tmp/codesentinel/cache.json
}

# Check for incremental mode
check_incremental_mode() {
    if [ -n "$(git status --porcelain)" ]; then
        echo "[INCREMENTAL] Working directory changes detected"
        export INCREMENTAL_MODE=true
        export CHANGED_FILES=$(git diff --name-only HEAD)
    elif [ -n "$PR_NUMBER" ]; then
        echo "[INCREMENTAL] PR mode for #$PR_NUMBER"
        export INCREMENTAL_MODE=true
        export CHANGED_FILES=$(git diff --name-only main...HEAD)
    else
        echo "[FULL] Running complete analysis"
        export INCREMENTAL_MODE=false
    fi
}

# Initialize
init_findings_cache
check_incremental_mode
```

### Phase 1: Discovery (3 min) - think

```bash
report_progress "Discovery" "Detecting languages and frameworks..."
```

Delegate to @orchestrator for discovery:
````
Execute discovery phase:
- Detect languages and frameworks
- Count total LOC
- Identify architectural layers
- Generate project manifest
````

### Phase 2: Pattern Scan (5 min) - think hard

Execute integrated pattern scanning:

```bash
echo "=== Pattern Scanning Phase ==="
echo ""
echo "Detecting languages and frameworks..."
echo "TypeScript files: $(find . -name "*.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)"
echo "JavaScript files: $(find . -name "*.js" -not -path "*/node_modules/*" 2>/dev/null | wc -l)"
echo "Java files: $(find . -name "*.java" 2>/dev/null | wc -l)"
echo "Python files: $(find . -name "*.py" 2>/dev/null | wc -l)"
echo ""

echo "Scanning for security patterns..."
grep -r "password\|secret\|token\|api[_-]key" --include="*.ts" --include="*.js" --include="*.java" --include="*.py" -n 2>/dev/null | head -10

echo ""
echo "Scanning for SQL injection patterns..."
grep -r "SELECT.*WHERE.*[\+\$]" --include="*.ts" --include="*.js" --include="*.java" --include="*.py" -n 2>/dev/null | head -10

echo ""
echo "Scanning for N+1 query patterns..."
grep -r "for.*await\|forEach.*query\|map.*fetch" --include="*.ts" --include="*.js" -n 2>/dev/null | head -10

echo ""
echo "Scanning for performance issues..."
grep -r "for.*for.*for\|while.*while" --include="*.ts" --include="*.js" --include="*.java" --include="*.py" -n 2>/dev/null | head -5
```

Identify and prioritize hotspot files based on pattern matches.
Save results internally for agent delegation.

### Phase 3: Multi-Agent Analysis (40 min) - ultrathink

```bash
report_progress "Agent Analysis" "Coordinating 9 specialized agents..."
```

**Coordinate 9 agents in parallel based on hotspots:**

**Security Analysis** (Delegate to @security-agent)

```bash
launch_agent "security-agent" "Analyzing security vulnerabilities"
```

````text
Analyze files with security patterns:
- SQL injection candidates
- Hardcoded secrets
- Missing authentication
- Cryptographic weaknesses
Target: 5-20 findings
````

```bash
complete_agent "security-agent" 15  # Example: 15 findings
```

**Performance Analysis** (Delegate to @performance-agent)

```bash
launch_agent "performance-agent" "Analyzing performance bottlenecks"
```

````text
Analyze files with performance patterns:
- N+1 query hotspots
- Missing batch operations
- Inefficient algorithms
- Missing caching opportunities
Target: 10-30 findings
````

```bash
complete_agent "performance-agent" 23  # Example: 23 findings
```

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
