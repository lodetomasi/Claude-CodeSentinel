# Claude-CodeSentinel 🛡️

AI-powered code review framework for Claude Code that detects 40+ issue types across security, performance, architecture, and more.

## 🚀 Quick Start

```bash
# 1. Clone into your project
git clone https://github.com/lodetomasi/Claude-CodeSentinel.git .claude-sentinel

# 2. Open project in Claude Code

# 3. Run analysis
/quick-scan     # 5-min fast scan
/full-review    # 60-min deep analysis
```

## 📋 Available Commands

| Command | Time | Description |
|---------|------|-------------|
| `/quick-scan` | 5 min | Fast pattern-based hotspot detection |
| `/full-review` | 45-60 min | Complete multi-agent analysis |
| `/security-only` | 15 min | Security vulnerability deep dive |
| `/performance-only` | 15 min | Performance bottleneck analysis |
| `/resilience-only` | 15 min | Fault tolerance assessment |

## 🎯 What It Detects

- **Security**: SQL injection, XSS, hardcoded secrets, auth bypass
- **Performance**: N+1 queries, missing caching, inefficient algorithms
- **Concurrency**: Race conditions, deadlocks, resource leaks
- **Architecture**: God classes, circular dependencies, layer violations
- **Resilience**: Missing timeouts, circuit breakers, retry logic
- **Data Integrity**: Missing transactions, dirty reads, lost updates
- **Observability**: Poor logging, silent failures, missing metrics
- **API Design**: Wrong HTTP status, missing pagination, no validation
- **Code Quality**: High complexity, deep nesting, code duplication

## 📊 Supported Languages

- **Java** (Spring Boot, Hibernate, JPA)
- **Python** (Django, Flask, FastAPI)
- **JavaScript** (Express, React, Node.js)
- **Go** (Gin, Echo, standard library)

## 📁 Project Structure

```
.claude/
├── agents/      # 10 specialized AI agents
├── commands/    # 5 workflow commands
└── skills/      # 20+ detection capabilities

patterns/        # Language-specific grep patterns
reports/         # Generated analysis reports
```

## 📈 Example Output

Reports are saved to `reports/[timestamp]-review.md` with:
- Severity-ranked findings (CRITICAL → LOW)
- Actual code evidence
- Quantified impact analysis
- Working fix recommendations

## 📚 Documentation

For detailed documentation, framework rules, and extension guide, see [CLAUDE.md](CLAUDE.md).

## 🔧 Requirements

- Claude Code v1.x
- Git repository
- Supported language codebase

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

---

*Built for Claude Code | Detects 65+ issue types | 95% accuracy for critical findings*