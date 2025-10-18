---
name: sql-injection
type: skill
category: security
progressive_disclosure: true
---

# SQL Injection Detection Skill

## Activation
Triggered when @security-agent encounters database operations.

## Detection Levels

### Level 1: Pattern Matching (Quick - 0.5 min)
```regex
Java: query.*\+|Statement\.execute.*\+
Python: cursor\.execute.*%|f"SELECT|f"INSERT
JavaScript: query.*\+|\$\{.*\}.*SELECT
Go: fmt\.Sprintf.*SELECT
```

### Level 2: Context Analysis (Medium - 2 min)
Check if:
- User input reaches the query
- PreparedStatement/parameterization used
- ORM protections in place

### Level 3: Framework Intelligence (Deep - 1 min)
**Java/JPA:**
- PreparedStatement = SAFE
- @Query with concatenation = UNSAFE
- Native queries with params = SAFE

**Python/Django:**
- ORM methods = SAFE (auto-parameterized)
- .raw() with % = UNSAFE
- .execute() with params = SAFE

**JavaScript/Sequelize:**
- Model methods = SAFE
- sequelize.query with template literals = UNSAFE
- Bound parameters = SAFE

## Detection Patterns

### Java
```java
// UNSAFE - String concatenation
String query = "SELECT * FROM users WHERE id = " + userId;
Statement stmt = conn.createStatement();
stmt.executeQuery(query);

// UNSAFE - String interpolation in @Query
@Query("SELECT u FROM User u WHERE name = '" + name + "'")

// SAFE - PreparedStatement
String query = "SELECT * FROM users WHERE id = ?";
PreparedStatement stmt = conn.prepareStatement(query);
stmt.setLong(1, userId);
```

### Python
```python
# UNSAFE - String formatting
cursor.execute("SELECT * FROM users WHERE id = %s" % user_id)
cursor.execute(f"SELECT * FROM users WHERE name = '{name}'")

# SAFE - Parameterized query
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# SAFE - Django ORM
User.objects.filter(id=user_id)
```

### JavaScript
```javascript
// UNSAFE - Template literal
const query = `SELECT * FROM users WHERE id = ${userId}`;
db.query(query);

// SAFE - Parameterized query
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);

// SAFE - ORM
User.findOne({ where: { id: userId } });
```

### Go
```go
// UNSAFE - String concatenation
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userId)
db.Query(query)

// SAFE - Parameterized query
query := "SELECT * FROM users WHERE id = ?"
db.Query(query, userId)
```

## Severity Guidelines

**CRITICAL:**
- User input directly concatenated into SQL
- Exploitable injection in authentication/authorization
- Public-facing endpoint with SQL injection

**HIGH:**
- SQL injection in non-critical endpoints
- Partial input validation but still vulnerable
- Internal endpoints with SQL injection

**MEDIUM:**
- Potential SQL injection with limited impact
- Stored procedure with dynamic SQL

**LOW:**
- Admin-only endpoints with SQL injection
- SQL injection in development/test code

## Output Format
```json
{
  "severity": "CRITICAL",
  "category": "SQL_INJECTION",
  "evidence": "Code snippet showing concatenation",
  "fix": "Framework-specific PreparedStatement/parameterized query example"
}
```

## Fix Templates

### Java
```java
// Replace this:
String query = "SELECT * FROM users WHERE name = '" + name + "'";

// With this:
String query = "SELECT * FROM users WHERE name = ?";
PreparedStatement stmt = conn.prepareStatement(query);
stmt.setString(1, name);
```

### Python
```python
# Replace this:
cursor.execute(f"SELECT * FROM users WHERE name = '{name}'")

# With this:
cursor.execute("SELECT * FROM users WHERE name = %s", (name,))
```

### JavaScript
```javascript
// Replace this:
db.query(`SELECT * FROM users WHERE name = '${name}'`);

// With this:
db.query('SELECT * FROM users WHERE name = ?', [name]);
```
