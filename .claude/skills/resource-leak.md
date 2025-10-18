---
name: resource-leak
type: skill
category: concurrency
---

# Resource Leak Detection Skill

## Detection Patterns

### 1. File Streams Not Closed

**Java:**
```java
// BAD - Resource leak
public String readFile(String path) throws IOException {
    FileInputStream fis = new FileInputStream(path);
    byte[] data = new byte[fis.available()];
    fis.read(data);
    return new String(data);
    // fis never closed - LEAK!
}

// GOOD - Try-with-resources (Java 7+)
public String readFile(String path) throws IOException {
    try (FileInputStream fis = new FileInputStream(path)) {
        byte[] data = new byte[fis.available()];
        fis.read(data);
        return new String(data);
    }  // Automatically closed
}

// GOOD - Finally block (older code)
public String readFile(String path) throws IOException {
    FileInputStream fis = null;
    try {
        fis = new FileInputStream(path);
        byte[] data = new byte[fis.available()];
        fis.read(data);
        return new String(data);
    } finally {
        if (fis != null) {
            fis.close();
        }
    }
}
```

**Python:**
```python
# BAD - Resource leak
def read_file(path):
    f = open(path, 'r')
    content = f.read()
    return content
    # f never closed - LEAK!

# GOOD - Context manager
def read_file(path):
    with open(path, 'r') as f:
        content = f.read()
        return content
    # Automatically closed
```

### 2. Database Connections Not Closed

**Java:**
```java
// BAD - Connection leak
public List<User> getUsers() throws SQLException {
    Connection conn = dataSource.getConnection();
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT * FROM users");
    // Process results...
    // conn, stmt, rs never closed - LEAK!
}

// GOOD - Try-with-resources
public List<User> getUsers() throws SQLException {
    try (Connection conn = dataSource.getConnection();
         Statement stmt = conn.createStatement();
         ResultSet rs = stmt.executeQuery("SELECT * FROM users")) {

        List<User> users = new ArrayList<>();
        while (rs.next()) {
            users.add(mapUser(rs));
        }
        return users;
    }  // All closed automatically
}
```

**Python:**
```python
# BAD - Connection leak
def get_users():
    conn = psycopg2.connect(database="mydb")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    return users
    # conn, cursor never closed - LEAK!

# GOOD - Context manager
def get_users():
    with psycopg2.connect(database="mydb") as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT * FROM users")
            users = cursor.fetchall()
            return users
    # Automatically closed
```

### 3. Thread Pool Not Shutdown

**Java:**
```java
// BAD - Thread leak
public class TaskProcessor {
    private ExecutorService executor = Executors.newFixedThreadPool(10);

    public void processTasks(List<Task> tasks) {
        for (Task task : tasks) {
            executor.submit(() -> process(task));
        }
        // executor never shutdown - threads leak!
    }
}

// GOOD - Proper shutdown
public class TaskProcessor implements AutoCloseable {
    private ExecutorService executor = Executors.newFixedThreadPool(10);

    public void processTasks(List<Task> tasks) {
        for (Task task : tasks) {
            executor.submit(() -> process(task));
        }
    }

    @Override
    public void close() {
        executor.shutdown();
        try {
            if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
    }
}
```

### 4. HTTP Client Not Closed

**Java:**
```java
// BAD - Connection leak
public String fetchData(String url) {
    CloseableHttpClient client = HttpClients.createDefault();
    HttpGet request = new HttpGet(url);
    CloseableHttpResponse response = client.execute(request);
    // Process response...
    // client, response never closed - LEAK!
}

// GOOD - Try-with-resources
public String fetchData(String url) throws IOException {
    try (CloseableHttpClient client = HttpClients.createDefault();
         CloseableHttpResponse response = client.execute(new HttpGet(url))) {

        return EntityUtils.toString(response.getEntity());
    }
}
```

**Python:**
```python
# BAD - Session leak
def fetch_data(url):
    session = requests.Session()
    response = session.get(url)
    return response.json()
    # session never closed - LEAK!

# GOOD - Context manager
def fetch_data(url):
    with requests.Session() as session:
        response = session.get(url)
        return response.json()
    # Automatically closed
```

### 5. Lock Not Released

**Java:**
```java
// BAD - Lock leak
Lock lock = new ReentrantLock();

public void doWork() {
    lock.lock();
    // Do work...
    if (error) {
        return;  // Lock never released - LEAK!
    }
    lock.unlock();
}

// GOOD - Finally block
public void doWork() {
    lock.lock();
    try {
        // Do work...
    } finally {
        lock.unlock();  // Always released
    }
}
```

## Detection Rules

### Look for:
1. **new FileInputStream/OutputStream** without try-with-resources
2. **dataSource.getConnection()** without try-with-resources
3. **Executors.newXXX()** without shutdown
4. **new Thread()** created but not managed
5. **lock()** without finally { unlock() }

### Check for AutoCloseable/Closeable:
- InputStream/OutputStream
- Reader/Writer
- Connection/Statement/ResultSet
- Socket/ServerSocket
- ExecutorService
- CloseableHttpClient/CloseableHttpResponse

## Severity Guidelines

**CRITICAL:**
- Database connection leak
- Thread pool not shutdown
- Production connection pool exhausted

**HIGH:**
- File descriptor leak
- HTTP client connection leak
- Lock not released

**MEDIUM:**
- Resource leak in error path only
- Small file streams not closed

**LOW:**
- Resource leak in test code
- Very short-lived applications

## Impact

### Connection Leak Example
```
Connection pool size: 20
Leaked connections per request: 1
Requests: 20
Result: Pool exhausted, service unavailable

Symptoms:
- "Cannot get connection from pool"
- Application hangs
- Manual restart required
```

### File Descriptor Leak
```
OS limit: 1024 file descriptors
Leaked FDs per operation: 1
Operations: 1000
Result: "Too many open files" error

Symptoms:
- Cannot open new files
- Cannot accept connections
- Application crashes
```

## Fix Template

```java
// Java - Always use try-with-resources
try (Resource1 r1 = new Resource1();
     Resource2 r2 = new Resource2()) {

    // Use resources
} // Automatically closed in reverse order
```

```python
# Python - Always use context managers
with resource1() as r1, resource2() as r2:
    # Use resources
# Automatically closed
```
