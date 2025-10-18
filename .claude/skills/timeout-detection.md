---
name: timeout-detection
type: skill
category: resilience
progressive_disclosure: true
---

# Timeout Detection Skill

## Activation
Triggered when @resilience-agent encounters external service calls.

## Detection Patterns

### HTTP Clients

**Java - RestTemplate**
```java
// BAD - No timeout
RestTemplate restTemplate = new RestTemplate();
User user = restTemplate.getForObject(url, User.class);  // Hangs indefinitely

// GOOD - With timeouts
RestTemplate restTemplate = new RestTemplateBuilder()
    .setConnectTimeout(Duration.ofSeconds(5))
    .setReadTimeout(Duration.ofSeconds(30))
    .build();
```

**Java - HttpClient**
```java
// BAD - No timeout
HttpClient client = HttpClient.newHttpClient();

// GOOD - With timeout
HttpClient client = HttpClient.newBuilder()
    .connectTimeout(Duration.ofSeconds(5))
    .build();

HttpRequest request = HttpRequest.newBuilder()
    .uri(URI.create(url))
    .timeout(Duration.ofSeconds(30))
    .build();
```

**Python - requests**
```python
# BAD - No timeout
response = requests.get(url)  # Hangs forever

# GOOD - With timeout
response = requests.get(url, timeout=(5, 30))  # (connect, read)

# GOOD - Same timeout for both
response = requests.get(url, timeout=30)
```

**JavaScript - fetch**
```javascript
// BAD - No timeout
const response = await fetch(url);

// GOOD - With AbortController
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), 30000);

try {
    const response = await fetch(url, {
        signal: controller.signal
    });
} finally {
    clearTimeout(timeoutId);
}
```

**JavaScript - axios**
```javascript
// BAD - No timeout
const response = await axios.get(url);

// GOOD - With timeout
const response = await axios.get(url, {
    timeout: 30000  // 30 seconds
});
```

**Go - http.Client**
```go
// BAD - No timeout
resp, err := http.Get(url)

// GOOD - With timeout
client := &http.Client{
    Timeout: 30 * time.Second,
}
resp, err := client.Get(url)

// BETTER - Separate connect and read timeouts
client := &http.Client{
    Transport: &http.Transport{
        DialContext: (&net.Dialer{
            Timeout: 5 * time.Second,   // Connect timeout
        }).DialContext,
        ResponseHeaderTimeout: 30 * time.Second,  // Read timeout
    },
}
```

### Database Connections

**Java - JDBC**
```java
// BAD - No timeout
Connection conn = DriverManager.getConnection(url, user, password);
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery(sql);

// GOOD - With timeouts
Connection conn = DriverManager.getConnection(url, user, password);
Statement stmt = conn.createStatement();
stmt.setQueryTimeout(30);  // 30 seconds
ResultSet rs = stmt.executeQuery(sql);

// GOOD - Connection pool with timeouts
HikariConfig config = new HikariConfig();
config.setConnectionTimeout(5000);  // 5 seconds
config.setValidationTimeout(3000);
HikariDataSource ds = new HikariDataSource(config);
```

**Python - psycopg2**
```python
# BAD - No timeout
conn = psycopg2.connect(database="test", user="postgres")

# GOOD - With timeout
conn = psycopg2.connect(
    database="test",
    user="postgres",
    connect_timeout=5
)

# Set statement timeout
cursor = conn.cursor()
cursor.execute("SET statement_timeout = 30000")  # 30 seconds
```

**JavaScript - pg (PostgreSQL)**
```javascript
// BAD - No timeout
const client = new Client();
await client.connect();

// GOOD - With timeout
const client = new Client({
    connectionTimeoutMillis: 5000,
    query_timeout: 30000
});
```

**Go - database/sql**
```go
// GOOD - With timeout using context
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

rows, err := db.QueryContext(ctx, query)
```

### Message Queues

**Java - RabbitMQ**
```java
// GOOD - With timeout
ConnectionFactory factory = new ConnectionFactory();
factory.setConnectionTimeout(5000);
factory.setHandshakeTimeout(10000);
factory.setShutdownTimeout(5000);
```

**Python - pika**
```python
# GOOD - With timeout
parameters = pika.ConnectionParameters(
    connection_attempts=3,
    retry_delay=2,
    socket_timeout=5
)
```

### External Services (AWS, etc.)

**Java - AWS SDK**
```java
// BAD - Default timeout (60s)
AmazonS3 s3 = AmazonS3ClientBuilder.defaultClient();

// GOOD - Custom timeout
ClientConfiguration config = new ClientConfiguration();
config.setConnectionTimeout(5000);
config.setSocketTimeout(30000);
AmazonS3 s3 = AmazonS3ClientBuilder.standard()
    .withClientConfiguration(config)
    .build();
```

## Recommended Timeout Values

### General Guidelines
- **Connect timeout**: 5-10 seconds (establishing connection)
- **Read timeout**: 30-60 seconds (waiting for response)
- **Database queries**: 30-60 seconds
- **API calls**: 10-30 seconds
- **File uploads**: 5-10 minutes
- **Batch operations**: 5-15 minutes

### Context-Specific
- **User-facing requests**: Lower timeouts (30s max)
- **Background jobs**: Higher timeouts acceptable (5-10 min)
- **Health checks**: Very short (2-5 seconds)
- **Circuit breaker**: Short timeouts to fail fast (5-10 seconds)

## Severity Guidelines

**CRITICAL:**
- No timeout on critical external dependency
- Payment/financial service calls
- User authentication calls
- Can cause thread pool exhaustion

**HIGH:**
- No timeout on external service calls
- Database queries without timeout
- User-facing endpoints

**MEDIUM:**
- No timeout but low-risk operation
- Internal service calls
- Admin operations

**LOW:**
- Timeout would be beneficial but not critical
- Batch jobs with long-running operations
- Development/test environments

## Impact Analysis

### Without Timeout
```
Service A -> Service B (down/slow)
- Thread blocks waiting forever
- Thread pool exhausts (200 threads blocked)
- New requests rejected
- Cascading failure to dependent services
```

### With Timeout
```
Service A -> Service B (down/slow)
- Thread waits max 30 seconds
- Fails fast with timeout exception
- Thread returns to pool
- Circuit breaker can open
- Service A remains available
```

## Fix Templates

### Java
```java
// For RestTemplate
@Bean
public RestTemplate restTemplate() {
    return new RestTemplateBuilder()
        .setConnectTimeout(Duration.ofSeconds(5))
        .setReadTimeout(Duration.ofSeconds(30))
        .build();
}

// For database
@Bean
public DataSource dataSource() {
    HikariConfig config = new HikariConfig();
    config.setConnectionTimeout(5000);
    config.setMaxLifetime(600000);
    return new HikariDataSource(config);
}
```

### Python
```python
# For requests - create session
session = requests.Session()
adapter = HTTPAdapter(
    max_retries=Retry(total=3),
)
session.mount('http://', adapter)
session.mount('https://', adapter)

# Use with timeout
response = session.get(url, timeout=(5, 30))
```

### JavaScript
```javascript
// Create axios instance with defaults
const api = axios.create({
    timeout: 30000,
    timeoutErrorMessage: 'Request timeout'
});
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "MISSING_TIMEOUT",
  "service_type": "HTTP_CLIENT",
  "evidence": "RestTemplate restTemplate = new RestTemplate();",
  "impact": "Indefinite hang possible. Can exhaust thread pool under slow network conditions.",
  "recommendation": "Add connect timeout (5s) and read timeout (30s)"
}
```
