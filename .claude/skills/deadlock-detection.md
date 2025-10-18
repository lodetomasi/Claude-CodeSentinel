---
name: deadlock-detection
type: skill
category: concurrency
---

# Deadlock Detection Skill

## Concept
Deadlock occurs when two or more threads wait for each other to release locks.

## Common Deadlock Patterns

### 1. Lock Order Inversion

**Java:**
```java
// BAD - Potential deadlock
class BankAccount {
    private final Object lock = new Object();

    public void transfer(BankAccount to, int amount) {
        synchronized (this.lock) {           // Thread 1: locks A
            synchronized (to.lock) {          // Thread 1: waits for B
                this.balance -= amount;
                to.balance += amount;
            }
        }
    }
}

// Thread 1: accountA.transfer(accountB, 100)  // locks A, waits for B
// Thread 2: accountB.transfer(accountA, 50)   // locks B, waits for A
// DEADLOCK!

// GOOD - Consistent lock ordering
public void transfer(BankAccount to, int amount) {
    BankAccount first = this.id < to.id ? this : to;
    BankAccount second = this.id < to.id ? to : this;

    synchronized (first.lock) {
        synchronized (second.lock) {
            this.balance -= amount;
            to.balance += amount;
        }
    }
}
```

### 2. Nested Locks

```java
// BAD - Nested locks (risk of deadlock)
class Service {
    private final Object lock1 = new Object();
    private final Object lock2 = new Object();

    public void method1() {
        synchronized (lock1) {
            synchronized (lock2) {  // Order: lock1 -> lock2
                // Work
            }
        }
    }

    public void method2() {
        synchronized (lock2) {
            synchronized (lock1) {  // Order: lock2 -> lock1 (DEADLOCK!)
                // Work
            }
        }
    }
}

// GOOD - Single lock or consistent ordering
class Service {
    private final Object lock = new Object();  // Single lock

    public void method1() {
        synchronized (lock) {
            // Work
        }
    }

    public void method2() {
        synchronized (lock) {
            // Work
        }
    }
}
```

### 3. Database Deadlocks

```java
// BAD - Different transaction order
// Thread 1:
UPDATE accounts SET balance = balance - 100 WHERE id = 1;  // Lock row 1
UPDATE accounts SET balance = balance + 100 WHERE id = 2;  // Wait for row 2

// Thread 2:
UPDATE accounts SET balance = balance - 50 WHERE id = 2;   // Lock row 2
UPDATE accounts SET balance = balance + 50 WHERE id = 1;   // Wait for row 1
// DEADLOCK!

// GOOD - Consistent ordering
UPDATE accounts SET balance = balance - amount
WHERE id IN (1, 2)
ORDER BY id;  // Always process in same order
```

## Detection Strategies

### 1. Thread Dump Analysis
```bash
# Generate thread dump
jstack <pid>

# Look for:
# "waiting to lock <0x00000007d5f7e8a0>" (a java.lang.Object)
# "locked <0x00000007d5f7e8b0>" (a java.lang.Object)
```

### 2. Lock Timeout
```java
// Use tryLock with timeout
Lock lock = new ReentrantLock();

if (lock.tryLock(5, TimeUnit.SECONDS)) {
    try {
        // Critical section
    } finally {
        lock.unlock();
    }
} else {
    // Handle timeout - potential deadlock
    log.error("Failed to acquire lock - possible deadlock");
}
```

### 3. Deadlock Detection Tools
- Java: jconsole, VisualVM
- Python: threading module debugging
- Go: `go test -race`

## Prevention Strategies

### 1. Lock Ordering
Always acquire locks in a consistent global order.

### 2. Lock Timeout
Use tryLock() with timeout instead of blocking lock().

### 3. Avoid Nested Locks
Minimize nested synchronized blocks.

### 4. Use Higher-Level Concurrency Utilities
```java
// Instead of raw locks, use:
ConcurrentHashMap
CopyOnWriteArrayList
BlockingQueue
ExecutorService
```

## Severity Guidelines

**CRITICAL:**
- Identified deadlock in production
- Nested locks with inconsistent ordering
- Database deadlock in critical path

**HIGH:**
- Potential deadlock pattern
- Complex lock dependencies
- Multiple locks without ordering

**MEDIUM:**
- Nested locks with consistent ordering
- Lock timeout not configured

## Fix Template

```java
// Deadlock-safe pattern
class SafeTransfer {
    private static final Object tieLock = new Object();

    public void transfer(Account from, Account to, int amount) {
        Account first, second;

        if (from.id < to.id) {
            first = from;
            second = to;
        } else if (from.id > to.id) {
            first = to;
            second = from;
        } else {
            // Same account - use tie-breaking lock
            synchronized (tieLock) {
                from.balance -= amount;
                from.balance += amount;
            }
            return;
        }

        synchronized (first) {
            synchronized (second) {
                from.balance -= amount;
                to.balance += amount;
            }
        }
    }
}
```
