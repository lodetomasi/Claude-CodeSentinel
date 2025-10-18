---
name: batch-operations
type: skill
category: performance
---

# Batch Operations Detection Skill

## Problem
Processing items one-by-one in loops causes:
- N database round-trips instead of 1
- High latency (N × network_time)
- Connection pool exhaustion
- Poor throughput

## Detection Patterns

### Java/Spring Data JPA

```java
// BAD - N database calls
public void updateUsers(List<User> users) {
    for (User user : users) {
        userRepository.save(user);  // 100 users = 100 DB calls!
    }
}

// GOOD - Batch save
public void updateUsers(List<User> users) {
    userRepository.saveAll(users);  // 1 DB call (or few batches)
}

// Configure batch size
spring.jpa.properties.hibernate.jdbc.batch_size=50
spring.jpa.properties.hibernate.order_inserts=true
spring.jpa.properties.hibernate.order_updates=true
```

### Python/Django

```python
# BAD - N database calls
def create_users(user_data_list):
    for user_data in user_data_list:
        User.objects.create(**user_data)  # 100 users = 100 DB calls!

# GOOD - Bulk create
def create_users(user_data_list):
    users = [User(**data) for data in user_data_list]
    User.objects.bulk_create(users)  # 1 DB call

# GOOD - Bulk update
User.objects.filter(status='pending').update(status='active')  # 1 DB call
```

### JavaScript/Sequelize

```javascript
// BAD - N database calls
async function createUsers(userDataList) {
    for (const userData of userDataList) {
        await User.create(userData);  // 100 users = 100 DB calls!
    }
}

// GOOD - Bulk create
async function createUsers(userDataList) {
    await User.bulkCreate(userDataList);  // 1 DB call
}
```

### SQL - Batch Updates

```sql
-- BAD - Multiple individual updates
UPDATE products SET price = 10.99 WHERE id = 1;
UPDATE products SET price = 15.99 WHERE id = 2;
UPDATE products SET price = 20.99 WHERE id = 3;
-- N updates = N round-trips

-- GOOD - Single update with CASE
UPDATE products
SET price = CASE id
    WHEN 1 THEN 10.99
    WHEN 2 THEN 15.99
    WHEN 3 THEN 20.99
END
WHERE id IN (1, 2, 3);
-- 1 update = 1 round-trip
```

## Batch Processing Strategies

### 1. Chunk Processing
```java
// Process in batches of 100
List<User> allUsers = getUsers();  // 10,000 users

int batchSize = 100;
for (int i = 0; i < allUsers.size(); i += batchSize) {
    int end = Math.min(i + batchSize, allUsers.size());
    List<User> batch = allUsers.subList(i, end);
    userRepository.saveAll(batch);  // 100 DB calls instead of 10,000
}
```

### 2. Bulk Insert with JDBC
```java
// High-performance bulk insert
String sql = "INSERT INTO users (name, email) VALUES (?, ?)";
try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
    for (User user : users) {
        pstmt.setString(1, user.getName());
        pstmt.setString(2, user.getEmail());
        pstmt.addBatch();

        if (++count % 100 == 0) {
            pstmt.executeBatch();  // Execute every 100
        }
    }
    pstmt.executeBatch();  // Execute remaining
}
```

### 3. Batch Delete
```java
// BAD - N deletes
for (Long id : idsToDelete) {
    userRepository.deleteById(id);
}

// GOOD - Batch delete
userRepository.deleteAllById(idsToDelete);

// Or with query
@Query("DELETE FROM User u WHERE u.id IN :ids")
void deleteByIds(@Param("ids") List<Long> ids);
```

## Performance Impact

### Example: Saving 1000 Records

**Without Batching:**
```
1000 records × 10ms per INSERT = 10,000ms (10 seconds)
```

**With Batching (batch_size=100):**
```
10 batches × 50ms per batch = 500ms (0.5 seconds)
Improvement: 20x faster
```

## Framework-Specific Patterns

### Spring Data JPA
```java
// Enable batching
@Configuration
public class JpaConfig {
    @Bean
    public LocalContainerEntityManagerFactoryBean entityManagerFactory() {
        LocalContainerEntityManagerFactoryBean em = new LocalContainerEntityManagerFactoryBean();
        Properties properties = new Properties();
        properties.setProperty("hibernate.jdbc.batch_size", "50");
        properties.setProperty("hibernate.order_inserts", "true");
        properties.setProperty("hibernate.order_updates", "true");
        properties.setProperty("hibernate.jdbc.batch_versioned_data", "true");
        em.setJpaProperties(properties);
        return em;
    }
}

// Use batch operations
userRepository.saveAll(users);  // Automatically batched
```

### Django ORM
```python
# Bulk create
User.objects.bulk_create([User(name=f'User{i}') for i in range(1000)])

# Bulk update
users = User.objects.filter(active=True)
for user in users:
    user.status = 'verified'
User.objects.bulk_update(users, ['status'])

# Update without loading objects
User.objects.filter(active=True).update(status='verified')
```

### MongoDB
```javascript
// Bulk operations
const bulk = db.collection('users').initializeUnorderedBulkOp();
for (const user of users) {
    bulk.insert(user);
}
await bulk.execute();

// Or with insertMany
await db.collection('users').insertMany(users);
```

## Detection Rules

### Look for:
1. **Loop with save()** - `for (item : items) { repo.save(item) }`
2. **Loop with create()** - `for (data : dataList) { Model.create(data) }`
3. **Loop with delete()** - `for (id : ids) { repo.deleteById(id) }`
4. **Multiple individual SQL statements**

### Check for batching:
- saveAll() / bulkCreate() / insertMany()
- bulk_create() / bulk_update()
- executeBatch()
- Hibernate batch configuration

## Severity Guidelines

**HIGH:**
- Loop with save() processing 100+ items
- Critical path with N database calls
- Production performance impact

**MEDIUM:**
- Loop with save() processing 10-100 items
- Background job with N database calls
- Admin operations

**LOW:**
- Small batches (< 10 items)
- One-time migration scripts
- Development utilities

## Fix Templates

### Java
```java
// Replace this:
for (User user : users) {
    userRepository.save(user);
}

// With this:
userRepository.saveAll(users);
```

### Python
```python
# Replace this:
for user_data in user_data_list:
    User.objects.create(**user_data)

# With this:
User.objects.bulk_create([User(**data) for data in user_data_list])
```

### JavaScript
```javascript
// Replace this:
for (const userData of userDataList) {
    await User.create(userData);
}

// With this:
await User.bulkCreate(userDataList);
```

## Batch Size Recommendations

- **Small objects**: 100-500 per batch
- **Large objects**: 10-50 per batch
- **Memory constraint**: Adjust based on heap size
- **Network latency**: Larger batches for high latency

## Output Format
```json
{
  "severity": "HIGH",
  "category": "MISSING_BATCH_OPERATION",
  "evidence": "for (User user : users) { userRepository.save(user); }",
  "estimated_items": "100-1000",
  "impact": "100 database round-trips instead of 1. Estimated time: 1000ms vs 50ms (20x slower)",
  "recommendation": "Use userRepository.saveAll(users) for batch insert"
}
```
