---
name: weak-crypto
type: skill
category: security
---

# Weak Cryptography Detection Skill

## Detection Patterns

### Weak Hash Algorithms

**Java:**
```java
// BAD - MD5 (broken)
MessageDigest md = MessageDigest.getInstance("MD5");

// BAD - SHA1 (deprecated)
MessageDigest md = MessageDigest.getInstance("SHA-1");

// GOOD - SHA-256 or better
MessageDigest md = MessageDigest.getInstance("SHA-256");

// BETTER - For passwords, use bcrypt/scrypt/argon2
BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
String hashedPassword = encoder.encode(password);
```

**Python:**
```python
# BAD - MD5
import hashlib
hashlib.md5(data).hexdigest()

# BAD - SHA1
hashlib.sha1(data).hexdigest()

# GOOD - SHA256
hashlib.sha256(data).hexdigest()

# BETTER - For passwords
from bcrypt import hashpw, gensalt
hashed = hashpw(password.encode('utf-8'), gensalt())
```

### Weak Encryption Algorithms

**Java:**
```java
// BAD - DES (broken)
Cipher cipher = Cipher.getInstance("DES");

// BAD - 3DES (deprecated)
Cipher cipher = Cipher.getInstance("DESede");

// GOOD - AES
Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");

// Key generation
KeyGenerator keyGen = KeyGenerator.getInstance("AES");
keyGen.init(256);  // 256-bit key
SecretKey key = keyGen.generateKey();
```

### Weak Random Number Generation

**Java:**
```java
// BAD - Predictable
Random random = new Random();
int token = random.nextInt();

// GOOD - Cryptographically secure
SecureRandom random = new SecureRandom();
byte[] token = new byte[32];
random.nextBytes(token);
```

**Python:**
```python
# BAD - Predictable
import random
token = random.randint(0, 1000000)

# GOOD - Cryptographically secure
import secrets
token = secrets.token_hex(32)
```

## Severity Guidelines

**CRITICAL:**
- MD5/SHA1 for passwords
- DES/3DES for encryption
- Weak random for security tokens

**HIGH:**
- MD5/SHA1 for general hashing
- Insecure random number generation
- Weak key sizes (< 128-bit)

**MEDIUM:**
- Deprecated algorithms
- Missing salt in password hashing

## Recommended Algorithms

### Hashing
- **General**: SHA-256, SHA-384, SHA-512
- **Passwords**: bcrypt, scrypt, Argon2

### Encryption
- **Symmetric**: AES-256 (GCM mode)
- **Asymmetric**: RSA 2048+ bits, ECC

### Random
- **Java**: SecureRandom
- **Python**: secrets module
- **JavaScript**: crypto.randomBytes()
