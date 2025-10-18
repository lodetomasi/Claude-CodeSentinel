---
name: race-conditions
type: skill
category: concurrency
progressive_disclosure: true
---

# Race Condition Detection Skill

## Activation
Triggered when @concurrency-agent detects shared mutable state in multi-threaded context.

## Detection Levels

### Level 1: Pattern Recognition (Quick)
Look for:
- Non-final instance fields in singleton beans
- Static mutable fields
- Shared collections without synchronization
- Non-atomic read-modify-write operations

### Level 2: Context Analysis (Medium)
Determine if code is multi-threaded:
- Singleton beans (@Service, @Component)
- HTTP request handlers (multi-threaded by default)
- @Async methods
- Thread creation (new Thread, ExecutorService)

### Level 3: Risk Assessment (Deep)
Assess actual risk:
- Read-only shared state = LOW risk
- Writes to shared state = HIGH risk
- Financial/critical data = CRITICAL

## Detection Patterns

### Java - Spring Beans
```java
// BAD - Race condition in singleton
@Service
public class CounterService {
    private int count = 0;  // Shared mutable state!

    public void increment() {
        count++;  // Not atomic: read, add, write
    }

    public int getCount() {
        return count;  // Inconsistent reads possible
    }
}

// GOOD - AtomicInteger
@Service
public class CounterService {
    private final AtomicInteger count = new AtomicInteger(0);

    public void increment() {
        count.incrementAndGet();  // Atomic operation
    }

    public int getCount() {
        return count.get();
    }
}

// GOOD - Synchronized
@Service
public class CounterService {
    private int count = 0;

    public synchronized void increment() {
        count++;
    }

    public synchronized int getCount() {
        return count;
    }
}
```

### Java - Check-Then-Act Race
```java
// BAD - Check-then-act race condition
@Service
public class CacheService {
    private Map<String, Object> cache = new HashMap<>();

    public Object get(String key) {
        if (!cache.containsKey(key)) {  // Check
            Object value = loadFromDatabase(key);
            cache.put(key, value);  // Act
            return value;
        }
        return cache.get(key);
    }
}

// GOOD - ConcurrentHashMap with atomic operation
@Service
public class CacheService {
    private Map<String, Object> cache = new ConcurrentHashMap<>();

    public Object get(String key) {
        return cache.computeIfAbsent(key, this::loadFromDatabase);
    }
}
```

### Python - Global State
```python
# BAD - Global mutable state (GIL doesn't help here)
counter = 0

def increment():
    global counter
    counter += 1  # Not atomic even with GIL

# GOOD - Thread-safe with Lock
import threading

counter = 0
counter_lock = threading.Lock()

def increment():
    global counter
    with counter_lock:
        counter += 1

# BETTER - Use thread-safe data structures
from queue import Queue
from threading import Lock

class Counter:
    def __init__(self):
        self._value = 0
        self._lock = Lock()

    def increment(self):
        with self._lock:
            self._value += 1
```

### JavaScript - Node.js
```javascript
// Generally SAFE - Single-threaded event loop
let count = 0;
function increment() {
    count++;  // Safe in single-threaded Node
}

// UNSAFE - Worker threads
const { Worker } = require('worker_threads');
let sharedCount = 0;  // BAD - shared between workers

// GOOD - Use SharedArrayBuffer with Atomics
const sharedBuffer = new SharedArrayBuffer(4);
const sharedArray = new Int32Array(sharedBuffer);
Atomics.add(sharedArray, 0, 1);  // Atomic increment
```

### Go - Goroutine Race
```go
// BAD - Race condition
var counter int

func increment() {
    counter++  // Not safe for concurrent access
}

// GOOD - Mutex
var (
    counter int
    mu      sync.Mutex
)

func increment() {
    mu.Lock()
    counter++
    mu.Unlock()
}

// BETTER - Atomic operations
var counter int64

func increment() {
    atomic.AddInt64(&counter, 1)
}

// BEST - Channel-based synchronization
func counterService(increments <-chan struct{}) {
    counter := 0
    for range increments {
        counter++
    }
}
```

## Common Race Condition Patterns

### 1. Non-atomic Increment
```java
count++;  // Actually 3 operations:
// 1. Read count
// 2. Add 1
// 3. Write count
// Another thread can interfere between these steps
```

### 2. Check-Then-Act
```java
if (map.containsKey(key)) {  // Check
    map.put(key, value);     // Act - race here!
}
```

### 3. Compound Actions
```java
if (count > 0) {    // Check
    count--;        // Act - race here!
    doSomething();
}
```

### 4. Missing Volatile
```java
private boolean stopped = false;  // Not volatile!

// Thread 1
public void stop() {
    stopped = true;  // May not be visible to Thread 2
}

// Thread 2
public void run() {
    while (!stopped) {  // May loop forever
        doWork();
    }
}
```

## Severity Guidelines

**CRITICAL:**
- Race condition with data corruption
- Financial transactions
- User data consistency
- Guaranteed failure under load

**HIGH:**
- Probable race condition
- Missing synchronization in multi-threaded code
- Shared mutable state in singleton beans
- Check-then-act patterns

**MEDIUM:**
- Potential race in rare conditions
- Missing volatile (but low traffic)
- Suboptimal synchronization

**LOW:**
- Read-only shared state
- Over-synchronization (performance issue only)
- Theoretical race with negligible probability

## Fix Strategies

### 1. Immutability (Best)
```java
// Make fields final and immutable
private final ImmutableList<String> items = ImmutableList.of(...);
```

### 2. Atomic Operations
```java
private final AtomicInteger count = new AtomicInteger(0);
private final AtomicReference<User> user = new AtomicReference<>();
```

### 3. Synchronized Methods
```java
public synchronized void update() { ... }
```

### 4. Explicit Locks
```java
private final ReentrantLock lock = new ReentrantLock();

public void update() {
    lock.lock();
    try {
        // Critical section
    } finally {
        lock.unlock();
    }
}
```

### 5. Concurrent Collections
```java
private final Map<String, Object> cache = new ConcurrentHashMap<>();
```

### 6. Thread-Local Storage
```java
private final ThreadLocal<SimpleDateFormat> formatter =
    ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd"));
```

## Testing for Race Conditions

```java
// Use tools like JCStress, ThreadSanitizer
// Run with -XX:+UnlockDiagnosticVMOptions -XX:+StressGCM
// Stress test with many threads
ExecutorService executor = Executors.newFixedThreadPool(100);
for (int i = 0; i < 10000; i++) {
    executor.submit(() -> service.increment());
}
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "RACE_CONDITION",
  "pattern": "shared_mutable_state",
  "evidence": "private int count = 0; in @Service class",
  "impact": "Lost updates under concurrent access. With 100 concurrent requests, count could be 1-100 instead of exactly 100.",
  "fix": "Use AtomicInteger or synchronized methods"
}
```
