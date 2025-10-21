# 🧙 Galadhrim Integration Guide

## Come Integrare il Framework nel Tuo Progetto

Questa guida spiega come integrare Galadhrim come sottocartella nel tuo progetto. Il framework rileva automaticamente la root del progetto senza bisogno di configurazione!

## Setup Rapido (2 minuti) 🚀

### 1. Aggiungi il Framework al Tuo Progetto

#### Opzione A: Clone Diretto
```bash
# Dalla radice del tuo progetto
git clone https://github.com/lodetomasi/Galadhrim-CodeSentinel.git .galadhrim
cd .galadhrim
```

#### Opzione B: Git Submodule (Raccomandato)
```bash
# Dalla radice del tuo progetto
git submodule add https://github.com/lodetomasi/Galadhrim-CodeSentinel.git .galadhrim
git submodule init
git submodule update
```

### 2. Esegui l'Analisi

Da Claude Code, entra nella directory del framework:

```
cd .galadhrim
/full-review
```

**Fatto!** Il framework rileverà automaticamente il progetto padre e lo analizzerà.

## Come Funziona l'Auto-Detection 🔍

Il framework usa una logica intelligente per trovare la root del progetto:

1. **Cerca .git**: Risale le directory fino a trovare un repository git
2. **Indicatori di progetto**: Cerca file come `package.json`, `pom.xml`, `requirements.txt`, `go.mod`, `CLAUDE.md`
3. **Detection del framework**: Se rileva di essere in una directory "galadhrim" o simile, usa automaticamente il padre
4. **Esclusione automatica**: Esclude se stesso dall'analisi

## Struttura del Progetto

```
tuo-progetto/
├── src/                      # ✅ Verrà analizzato
├── lib/                      # ✅ Verrà analizzato
├── tests/                    # ✅ Verrà analizzato
├── CLAUDE.md                 # ✅ Istruzioni specifiche (opzionale)
├── .galadhrim/               # 🚫 NON analizzato (auto-escluso)
│   ├── .claude/              # Logica del framework
│   └── reports/              # Report generati qui
└── ...
```

## Output dell'Auto-Detection

Quando esegui `/full-review`, vedrai:

```
🔍 Auto-detecting project root...

  ✓ Found .git repository at: /path/to/your/project

════════════════════════════════════════════════════════════
🎯 PROJECT ROOT: /path/to/your/project
🔧 FRAMEWORK: /path/to/your/project/.galadhrim
🚫 EXCLUDING: .galadhrim/ (framework directory)
════════════════════════════════════════════════════════════

📊 Project Overview:
  Total files: 245
  Java: 120 files
  Python: 80 files
  JavaScript: 45 files
```

## Integrazione con CLAUDE.md del Progetto

Il framework rispetta automaticamente il file `CLAUDE.md` nella radice del tuo progetto:

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
.galadhrim/reports/

# Se usi submodule
[submodule ".galadhrim"]
    path = .galadhrim
    url = https://github.com/lodetomasi/Galadhrim-CodeSentinel.git
```

### 2. Team Workflow

1. **Setup Iniziale** (una volta):
   ```bash
   git submodule add [url] .galadhrim
   ```

2. **Altri Developer**:
   ```bash
   git submodule init
   git submodule update
   ```

3. **Aggiornamenti Framework**:
   ```bash
   cd .galadhrim
   git pull origin main
   ```

## Scenari Supportati

### Progetto con Git
```
my-project/
├── .git/                    # ← Framework trova questo
├── src/
└── .galadhrim/              # ← Framework qui
```

### Progetto Node.js
```
my-app/
├── package.json             # ← Framework trova questo
├── src/
└── .galadhrim/
```

### Progetto Java
```
my-service/
├── pom.xml                  # ← Framework trova questo
├── src/
└── .galadhrim/
```

### Progetto Python
```
my-api/
├── requirements.txt         # ← Framework trova questo
├── app/
└── .galadhrim/
```

## Troubleshooting

### Il framework non trova il progetto corretto

Il framework mostra sempre quale directory analizzerà. Se non è corretta:

1. **Verifica gli indicatori**: Assicurati che il progetto abbia almeno uno di: `.git`, `package.json`, `pom.xml`, `requirements.txt`, `go.mod`, `CLAUDE.md`, `README.md`

2. **Override manuale** (se necessario):
   ```bash
   export TARGET_PATH="/path/to/project"
   /full-review
   ```

### Report non trovati

I report sono salvati in `.galadhrim/reports/`:
```bash
ls -la .galadhrim/reports/
```

## Comandi Utili

```bash
# Analisi completa (da Claude Code)
/full-review

# Pulisci report vecchi
rm reports/*.md

# Aggiorna framework
git pull origin main

# Verifica dove il framework analizzerà
cd .galadhrim && pwd && cd .. && pwd
```

## Vantaggi dell'Auto-Detection

✅ **Zero configurazione**: Funziona subito senza setup

✅ **Intelligente**: Rileva automaticamente la root del progetto

✅ **Auto-esclusione**: Non analizza mai se stesso

✅ **Multi-linguaggio**: Supporta Java, Python, JavaScript, Go

✅ **Flessibile**: Si adatta a qualsiasi struttura di progetto

## Note Importanti

1. **Il framework NON analizza se stesso** automaticamente
2. **I report contengono snippet di codice** - verifica prima di condividere
3. **Performance**: 45-60 minuti per analisi completa di progetti grandi
4. **Costo API**: $2-5 per review completa

---

*🧙 Galadhrim v2.0 - The Code Sentinels - AI-Powered Code Review Framework with Intelligent Auto-Detection*