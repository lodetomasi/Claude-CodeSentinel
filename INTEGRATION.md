# Claude-CodeSentinel Integration Guide

## Come Integrare il Framework nel Tuo Progetto

Questa guida spiega come integrare Claude-CodeSentinel come sottocartella nel tuo progetto per analizzare il codice dalla directory radice.

## Setup Rapido (3 minuti)

### 1. Aggiungi il Framework al Tuo Progetto

#### Opzione A: Clone Diretto
```bash
# Dalla radice del tuo progetto
git clone https://github.com/lodetomasi/Claude-CodeSentinel.git .claude-sentinel
cd .claude-sentinel
```

#### Opzione B: Git Submodule (Raccomandato)
```bash
# Dalla radice del tuo progetto
git submodule add https://github.com/lodetomasi/Claude-CodeSentinel.git .claude-sentinel
git submodule init
git submodule update
```

### 2. Configura il Target Path

```bash
# Entra nella directory del framework
cd .claude-sentinel

# Configura per analizzare la directory padre (il tuo progetto)
./setup-target.sh

# Seleziona opzione 1 (Parent directory) quando richiesto
```

### 3. Verifica la Configurazione

```bash
# Test della configurazione
./setup-target.sh -t

# Dovresti vedere:
# ✅ Target directory exists: /percorso/del/tuo/progetto
# 📊 Project Statistics:
#   Java files: XXX
#   Python files: XXX
#   ...
```

## Uso del Framework

### Esegui Analisi Completa

Da Claude Code, quando sei nella directory del framework:

```
/full-review
```

Il framework analizzerà automaticamente il progetto padre, NON se stesso.

## Struttura del Progetto

```
tuo-progetto/
├── src/                      # Il tuo codice (verrà analizzato)
├── lib/                      # Le tue librerie (verranno analizzate)
├── tests/                    # I tuoi test (verranno analizzati)
├── CLAUDE.md                 # Le tue istruzioni specifiche (opzionale)
├── .claude-sentinel/         # Framework (NON analizzato)
│   ├── .claude/              # Configurazione framework
│   │   ├── agents/           # 10 agenti specializzati
│   │   ├── commands/         # Comandi disponibili
│   │   ├── patterns/         # Pattern di rilevamento
│   │   ├── skills/           # Capacità modulari
│   │   └── target.config     # CONFIGURAZIONE TARGET ← Punta a ../
│   ├── reports/              # Report generati
│   └── setup-target.sh       # Script di configurazione
└── ...
```

## Configurazioni Avanzate

### Analizzare un Progetto Diverso

```bash
# Analizza un progetto fratello
./setup-target.sh -p ../../altro-progetto

# Analizza con path assoluto
./setup-target.sh -a /path/to/any/project
```

### Variabili d'Ambiente

```bash
# Override temporaneo del target
TARGET_PATH="/altro/progetto" /full-review

# Export permanente per la sessione
export TARGET_PATH="../mio-progetto"
```

### File di Configurazione

Modifica `.claude/target.config`:

```bash
# Path del target (relativo al framework)
TARGET_PATH="../"

# Escludi directory specifiche
EXCLUDE_DIRS="node_modules,vendor,.git,dist,build,target,.claude-sentinel"

# Includi solo directory specifiche (lascia vuoto per tutte)
INCLUDE_DIRS="src,lib,app"
```

## Integrazione con CLAUDE.md del Progetto

Il framework rispetta automaticamente il file `CLAUDE.md` nella radice del tuo progetto:

1. **Il tuo progetto ha CLAUDE.md**: Il framework lo legge e applica le istruzioni
2. **Il framework ha il suo CLAUDE.md**: Usato solo per la logica interna del framework
3. **Entrambi presenti**: Priorità al CLAUDE.md del progetto target

### Esempio CLAUDE.md del Progetto

```markdown
# Istruzioni Specifiche del Mio Progetto

## Contesto
- Applicazione e-commerce in Python/Django
- Database PostgreSQL con 50+ tabelle
- API REST per app mobile

## Focus Analisi
- Sicurezza: Priorità massima (gestione pagamenti)
- Performance: Query database critiche
- API: Validazione rigorosa input

## Esclusioni
- Ignora directory migrations/
- Ignora file di test legacy_tests/
```

## Best Practices

### 1. Organizzazione Repository

```bash
# .gitignore del progetto principale
.claude-sentinel/reports/
.claude-sentinel/.claude/target.config

# Se usi submodule
[submodule ".claude-sentinel"]
    path = .claude-sentinel
    url = https://github.com/lodetomasi/Claude-CodeSentinel.git
```

### 2. CI/CD Integration

```yaml
# GitHub Actions esempio
- name: Setup CodeSentinel
  run: |
    cd .claude-sentinel
    ./setup-target.sh -p ../

- name: Run Security Analysis
  run: |
    cd .claude-sentinel
    # Usa Claude Code API o CLI se disponibile
```

### 3. Team Workflow

1. **Setup Iniziale** (una volta):
   ```bash
   git submodule add [url] .claude-sentinel
   cd .claude-sentinel
   ./setup-target.sh
   ```

2. **Altri Developer**:
   ```bash
   git submodule init
   git submodule update
   cd .claude-sentinel
   ./setup-target.sh
   ```

3. **Aggiornamenti Framework**:
   ```bash
   cd .claude-sentinel
   git pull origin main
   ```

## Troubleshooting

### Il framework analizza se stesso invece del progetto

**Soluzione**:
```bash
cd .claude-sentinel
./setup-target.sh
# Seleziona opzione 1 (Parent directory)
```

### "Target directory does not exist"

**Verifica**:
```bash
# Controlla il path configurato
cat .claude/target.config

# Test configurazione
./setup-target.sh -t
```

### Report non trovati

I report sono salvati in `.claude-sentinel/reports/`. Assicurati di cercarli lì:
```bash
ls -la .claude-sentinel/reports/
```

### Pattern non rileva i miei file

Verifica le estensioni supportate:
```bash
# Il framework supporta: .java, .py, .js, .jsx, .ts, .tsx, .go
find ../ -name "*.tua-estensione" | head -5
```

## Comandi Utili

```bash
# Setup rapido per progetto padre
./setup-target.sh -p ../

# Verifica configurazione
./setup-target.sh -t

# Analisi completa (da Claude Code)
/full-review

# Pulisci report vecchi
rm reports/*.md

# Aggiorna framework
git pull origin main
```

## Supporto

- **Issues**: https://github.com/lodetomasi/Claude-CodeSentinel/issues
- **Documentazione**: CLAUDE.md (istruzioni framework)
- **Esempi**: reports/ (report di esempio)

## Note Importanti

1. **Il framework NON analizza se stesso** per default
2. **I report contengono snippet di codice** - verifica prima di condividere
3. **Configurazione locale** in `.claude/target.config` - non committare se contiene path sensibili
4. **Performance**: 45-60 minuti per analisi completa di progetti grandi
5. **Costo API**: $2-5 per review completa

---

*Claude-CodeSentinel v2.0 - AI-Powered Code Review Framework*