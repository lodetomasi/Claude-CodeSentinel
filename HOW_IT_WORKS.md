# 🎯 Come Funziona REALMENTE Claude-CodeSentinel

## La Verità sui Custom Slash Commands in Claude Code

### ✅ Come Funziona Effettivamente:

1. **Struttura Richiesta**
   ```
   your-project/
   ├── .claude/
   │   └── commands/
   │       ├── quick-scan.md
   │       ├── full-review.md
   │       └── [altri comandi].md
   └── [il tuo codice...]
   ```

2. **Riconoscimento Automatico**
   - Claude Code cerca automaticamente `.claude/commands/` nella root del progetto
   - Ogni file `.md` diventa un comando slash
   - Nome file = nome comando (es: `quick-scan.md` → `/quick-scan`)

3. **Come Usarlo**
   - Apri il tuo progetto in Claude Code
   - I comandi sono immediatamente disponibili
   - Digita `/` per vedere la lista dei comandi
   - Usa `/quick-scan`, `/full-review`, etc.

## 📋 Setup Completo Passo-Passo

### Opzione A: Setup Manuale (Raccomandato)
```bash
# 1. Vai nel TUO progetto
cd /path/to/your/project

# 2. Copia solo le cartelle necessarie
cp -r /path/to/Claude-CodeSentinel/.claude .
cp -r /path/to/Claude-CodeSentinel/patterns .
cp /path/to/Claude-CodeSentinel/CLAUDE.md .

# 3. Crea la cartella reports
mkdir -p reports
```

### Opzione B: Git Submodule
```bash
# Nel tuo progetto
cd /path/to/your/project

# Aggiungi come submodule
git submodule add https://github.com/lodetomasi/Claude-CodeSentinel.git .code-sentinel

# Link simbolici alle cartelle necessarie
ln -s .code-sentinel/.claude .claude
ln -s .code-sentinel/patterns patterns
ln -s .code-sentinel/CLAUDE.md CLAUDE.md
```

## 🔧 Verifica Setup

Esegui questo comando per verificare:
```bash
# Dovrebbe mostrare:
ls -la .claude/commands/*.md | wc -l
# Output: 5 (i 5 comandi disponibili)
```

## 🚀 Comandi Disponibili

Una volta configurato, in Claude Code puoi usare:

| Comando | Descrizione | Tempo |
|---------|-------------|-------|
| `/quick-scan` | Scansione veloce pattern-based | 5 min |
| `/full-review` | Analisi completa multi-agente | 45-60 min |
| `/security-only` | Focus su vulnerabilità security | 15 min |
| `/performance-only` | Focus su problemi performance | 15 min |
| `/resilience-only` | Focus su fault tolerance | 15 min |

## ⚠️ Importante da Sapere

### Cosa NON Fa:
- ❌ NON funziona da terminale normale
- ❌ NON è uno script standalone
- ❌ NON si installa globalmente

### Cosa FA:
- ✅ Funziona DENTRO Claude Code (l'IDE di Anthropic)
- ✅ I comandi appaiono automaticamente
- ✅ Analizza il codice nel progetto corrente
- ✅ Genera report in `reports/`

## 🎯 Esempio Pratico Completo

```bash
# Il tuo progetto Spring Boot
cd ~/projects/my-spring-app

# Setup del framework
git clone https://github.com/lodetomasi/Claude-CodeSentinel.git temp
mv temp/.claude .
mv temp/patterns .
mv temp/CLAUDE.md .
rm -rf temp
mkdir reports

# Struttura finale
my-spring-app/
├── src/
├── pom.xml
├── .claude/          # ← Framework installato
│   ├── agents/
│   ├── commands/    # ← I tuoi slash commands
│   └── skills/
├── patterns/
├── CLAUDE.md
└── reports/         # ← Dove vanno i report
```

Poi in Claude Code:
1. Apri `my-spring-app`
2. Digita `/quick-scan`
3. Il framework analizza il codice
4. Trovi il report in `reports/`

## 🔍 Troubleshooting

**I comandi non appaiono?**
- Verifica che `.claude/commands/` sia nella root del progetto
- Verifica che i file `.md` abbiano il frontmatter YAML corretto
- Riavvia Claude Code

**"Unknown slash command"?**
- I comandi custom NON funzionano con `SlashCommand` tool
- Devono essere invocati manualmente dall'utente nell'interfaccia

**Report non generato?**
- Verifica che esista la cartella `reports/`
- Controlla i permessi di scrittura

## 📝 Note Finali

Il framework è essenzialmente una collezione di:
- **Prompt strutturati** (agents)
- **Workflow predefiniti** (commands)
- **Pattern di ricerca** (patterns)
- **Moduli di detection** (skills)

Che Claude Code carica e usa quando invochi i comandi slash. È come avere un "esperto di code review" sempre disponibile nel tuo IDE!