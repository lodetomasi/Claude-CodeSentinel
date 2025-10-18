---
name: retry-analysis
type: skill
category: resilience
---

# Retry Analysis Skill

## When to Retry

### Transient Failures (Should Retry)
- Network timeouts
- Connection refused (temporary)
- HTTP 503 Service Unavailable
- HTTP 429 Too Many Requests
- Database connection pool exhausted (temporary)
- Rate limit exceeded

### Non-Transient Failures (Don't Retry)
- HTTP 400 Bad Request
- HTTP 401 Unauthorized
- HTTP 404 Not Found
- Validation errors
- Business logic errors
- Permanent data errors

## Detection Patterns

### Missing Retry Logic

**Java/Spring:**
```java
// BAD - No retry
public User getUser(Long id) {
    return restTemplate.getForObject(userServiceUrl + id, User.class);
    // Single attempt - fails on transient error
}

// GOOD - With retry (Spring Retry)
@Retryable(
    value = {HttpServerErrorException.class, ResourceAccessException.class},
    maxAttempts = 3,
    backoff = @Backoff(delay = 1000, multiplier = 2)
)
public User getUser(Long id) {
    return restTemplate.getForObject(userServiceUrl + id, User.class);
}

// With recovery
@Retryable(maxAttempts = 3, backoff = @Backoff(delay = 1000))
public User getUser(Long id) {
    return restTemplate.getForObject(userServiceUrl + id, User.class);
}

@Recover
public User recover(Exception e, Long id) {
    log.error("Failed to get user after retries", e);
    return getUserFromCache(id);  // Fallback
}
```

**Python:**
```python
# BAD - No retry
def send_email(email):
    email_service.send(email)
    # Single attempt - fails on transient error

# GOOD - With retry (tenacity)
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=1, max=10),
    retry=retry_if_exception_type((ConnectionError, TimeoutError))
)
def send_email(email):
    email_service.send(email)
```

**JavaScript:**
```javascript
// BAD - No retry
async function fetchData(url) {
    const response = await axios.get(url);
    return response.data;
}

// GOOD - With retry (axios-retry)
const axiosRetry = require('axios-retry');

axiosRetry(axios, {
    retries: 3,
    retryDelay: axiosRetry.exponentialDelay,
    retryCondition: (error) => {
        return axiosRetry.isNetworkOrIdempotentRequestError(error) ||
               error.response?.status === 503;
    }
});

async function fetchData(url) {
    const response = await axios.get(url);
    return response.data;
}
```

## Retry Strategies

### 1. Exponential Backoff
```
Attempt 1: Wait 1s
Attempt 2: Wait 2s
Attempt 3: Wait 4s
Attempt 4: Wait 8s
```

**Why:** Prevents overwhelming failing service

### 2. Jittered Backoff
```
Attempt 1: Wait 1s + random(0-500ms)
Attempt 2: Wait 2s + random(0-1000ms)
```

**Why:** Prevents thundering herd when many clients retry simultaneously

### 3. Fixed Delay
```
Attempt 1: Wait 5s
Attempt 2: Wait 5s
Attempt 3: Wait 5s
```

**Why:** Simple, predictable, but may overwhelm service

## Idempotency Check

### Safe to Retry (Idempotent)
```java
// GET requests (read-only)
@GetMapping("/users/{id}")
public User getUser(@PathVariable Long id) {
    return userService.getUser(id);
}

// PUT with idempotency (same result if repeated)
@PutMapping("/users/{id}")
public User updateUser(@PathVariable Long id, @RequestBody User user) {
    user.setId(id);
    return userService.saveUser(user);  // Same result if called twice
}

// DELETE (idempotent - deleting twice = same result)
@DeleteMapping("/users/{id}")
public void deleteUser(@PathVariable Long id) {
    userService.deleteUser(id);  // Already deleted = no-op
}
```

### Unsafe to Retry (Non-Idempotent)
```java
// BAD - Retrying this creates duplicate orders!
@PostMapping("/orders")
public Order createOrder(@RequestBody OrderRequest request) {
    return orderService.createOrder(request);
    // If timeout after creation but before response:
    // Retry creates duplicate order!
}

// GOOD - Idempotent with client token
@PostMapping("/orders")
public Order createOrder(@RequestBody OrderRequest request) {
    String idempotencyKey = request.getIdempotencyKey();
    Order existing = orderService.findByIdempotencyKey(idempotencyKey);
    if (existing != null) {
        return existing;  // Already created
    }
    return orderService.createOrder(request, idempotencyKey);
    // Safe to retry - same token returns same order
}
```

## Configuration Guidelines

### Max Attempts
- **3-5 attempts**: Typical for network operations
- **1-2 attempts**: Non-critical operations
- **Infinite retries**: Message queue consumers (with backoff)

### Backoff Timing
- **Initial delay**: 1-2 seconds
- **Max delay**: 30-60 seconds
- **Multiplier**: 2x (exponential)

### Timeout + Retry
```java
// Configure both timeout and retry
@Retryable(maxAttempts = 3, backoff = @Backoff(delay = 1000))
public User getUser(Long id) {
    // Also has 5s timeout per attempt
    return restTemplate.getForObject(url, User.class);
}

// Total time: 3 attempts × 5s timeout + 1s + 2s backoff = 18s max
```

## Anti-Patterns

### 1. Retrying Non-Transient Errors
```java
// BAD - Retrying 404
@Retryable(value = HttpClientErrorException.class)
public User getUser(Long id) {
    return restTemplate.getForObject(url, User.class);
    // Retries 404 Not Found - waste of time!
}

// GOOD - Only retry transient errors
@Retryable(value = HttpServerErrorException.class)
public User getUser(Long id) {
    return restTemplate.getForObject(url, User.class);
}
```

### 2. No Backoff
```java
// BAD - Immediate retry (hammers failing service)
@Retryable(maxAttempts = 3, backoff = @Backoff(delay = 0))

// GOOD - Exponential backoff
@Retryable(maxAttempts = 3, backoff = @Backoff(delay = 1000, multiplier = 2))
```

### 3. Infinite Retries Without Backoff
```java
// BAD - Infinite retries, no backoff
while (true) {
    try {
        return callService();
    } catch (Exception e) {
        // Retry immediately forever - CPU/network waste
    }
}

// GOOD - Limited retries with backoff
@Retryable(maxAttempts = 5, backoff = @Backoff(delay = 1000, multiplier = 2))
```

## Severity Guidelines

**HIGH:**
- Critical operation without retry (payments, orders)
- External service call without retry
- Network operation without error handling

**MEDIUM:**
- Non-critical operation without retry
- Retry without backoff
- Retrying non-idempotent operations

**LOW:**
- Read-only operations without retry
- Internal service calls without retry

## Fix Template

```java
// Spring Retry
@EnableRetry
@Configuration
public class RetryConfig {
    // Global configuration
}

@Service
public class ExternalService {
    @Retryable(
        value = {HttpServerErrorException.class, ResourceAccessException.class},
        maxAttempts = 3,
        backoff = @Backoff(
            delay = 1000,
            multiplier = 2,
            maxDelay = 10000
        )
    )
    public Data fetchData(String id) {
        return restTemplate.getForObject(url + id, Data.class);
    }

    @Recover
    public Data recover(Exception e, String id) {
        log.error("Failed after retries: {}", id, e);
        return getFromCache(id);
    }
}
```
