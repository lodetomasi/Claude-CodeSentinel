---
name: hardcoded-secrets
type: skill
category: security
progressive_disclosure: true
---

# Hardcoded Secrets Detection

## Activation
Triggered when @security-agent scans for credential leaks.

## Detection Patterns

### Regex Patterns
```regex
password.*=.*["']
secret.*=.*["']
api.*key.*=.*["']
token.*=.*["']
private.*key.*=.*["']
aws.*secret.*=.*["']
database.*password.*=.*["']
```

### Language-Specific Patterns

**Java:**
```java
// UNSAFE - Hardcoded credentials
private static final String PASSWORD = "mysecretpass123";
private String apiKey = "sk_live_abc123xyz";
String dbUrl = "jdbc:mysql://localhost/db?password=secret";

// SAFE - Environment variables
private String password = System.getenv("DB_PASSWORD");
private String apiKey = System.getProperty("api.key");
```

**Python:**
```python
# UNSAFE - Hardcoded credentials
PASSWORD = "mysecretpass123"
API_KEY = "sk_live_abc123xyz"
SECRET_KEY = "django-insecure-hardcoded-key"

# SAFE - Environment variables
PASSWORD = os.getenv("DB_PASSWORD")
API_KEY = os.environ["API_KEY"]
SECRET_KEY = env("SECRET_KEY")
```

**JavaScript:**
```javascript
// UNSAFE - Hardcoded credentials
const password = "mysecretpass123";
const apiKey = "sk_live_abc123xyz";
const config = { secret: "hardcoded-secret" };

// SAFE - Environment variables
const password = process.env.DB_PASSWORD;
const apiKey = process.env.API_KEY;
```

**Go:**
```go
// UNSAFE - Hardcoded credentials
const Password = "mysecretpass123"
apiKey := "sk_live_abc123xyz"

// SAFE - Environment variables
password := os.Getenv("DB_PASSWORD")
apiKey := os.Getenv("API_KEY")
```

## Exclusions (Don't Flag)

### Test Files
- Paths: test/, spec/, mock/, __tests__/
- Files: *_test.go, *_test.py, *.test.js, *Test.java

### Example/Documentation
- Files: example.*, sample.*, demo.*
- Obvious placeholders: "your-password-here", "REPLACE_ME"

### Common False Positives
```java
// Don't flag - variable name, not value
String password = request.getParameter("password");

// Don't flag - placeholder
String message = "Enter your password:";

// Don't flag - test fixture
@Test
public void testLogin() {
    String testPassword = "test123";  // OK in tests
}
```

## Detection Context

### Check for:
1. **File location** - Is it production code?
2. **Value entropy** - Is it a real secret or placeholder?
3. **Git history** - Was secret recently added?
4. **Pattern matching** - Does value look like real API key?

### Real API Key Patterns
- AWS: `AKIA[0-9A-Z]{16}`
- Stripe: `sk_live_[0-9a-zA-Z]{24,}`
- GitHub: `ghp_[0-9a-zA-Z]{36}`
- JWT: `eyJ[0-9a-zA-Z_-]*\.eyJ[0-9a-zA-Z_-]*`

## Severity Guidelines

**CRITICAL:**
- Production API keys (AWS, Stripe, GitHub)
- Database passwords in production code
- Private keys / certificates
- OAuth secrets
- Encryption keys

**HIGH:**
- API keys for paid services
- Authentication tokens
- Service account credentials
- SMTP passwords

**MEDIUM:**
- Development/staging credentials
- Internal service passwords
- API keys for free services

**LOW:**
- Test fixtures (in test files)
- Example code credentials
- Obvious placeholders

## Fix Templates

### Java
```java
// Bad
private String apiKey = "sk_live_abc123xyz";

// Good - Environment variable
private String apiKey = System.getenv("API_KEY");

// Good - Properties file (excluded from git)
Properties props = new Properties();
props.load(new FileInputStream("config.properties"));
String apiKey = props.getProperty("api.key");

// Good - Vault/Secrets manager
String apiKey = vaultClient.getSecret("api-key");
```

### Python
```python
# Bad
API_KEY = "sk_live_abc123xyz"

# Good - Environment variable
import os
API_KEY = os.getenv("API_KEY")

# Good - python-decouple
from decouple import config
API_KEY = config("API_KEY")

# Good - Secrets manager
import boto3
client = boto3.client('secretsmanager')
API_KEY = client.get_secret_value(SecretId='api-key')['SecretString']
```

### JavaScript
```javascript
// Bad
const apiKey = "sk_live_abc123xyz";

// Good - Environment variable
const apiKey = process.env.API_KEY;

// Good - dotenv
require('dotenv').config();
const apiKey = process.env.API_KEY;

// Good - Config service
const apiKey = await secretsManager.getSecret('api-key');
```

## Remediation Steps

1. **Remove from code**
```bash
# Remove secret from current code
git rm config/secrets.yml
# Commit removal
git commit -m "Remove hardcoded secrets"
```

2. **Remove from git history** (if already committed)
```bash
# Use git-filter-repo or BFG Repo Cleaner
git filter-repo --path config/secrets.yml --invert-paths
```

3. **Rotate credentials**
- Change the exposed password/key immediately
- Update in secrets management system
- Deploy with new credentials

4. **Use secrets management**
- AWS Secrets Manager
- HashiCorp Vault
- Azure Key Vault
- Environment variables

## Output Format
```json
{
  "severity": "CRITICAL",
  "category": "HARDCODED_SECRETS",
  "secret_type": "API_KEY",
  "evidence": "apiKey = \"sk_live_abc123xyz\"",
  "recommendation": "Move to environment variable or secrets manager",
  "urgent_action": "Rotate this credential immediately - it's exposed in git history"
}
```
