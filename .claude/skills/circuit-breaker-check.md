---
name: circuit-breaker-check
type: skill
category: resilience
progressive_disclosure: true
---

# Circuit Breaker Detection Skill

## Activation
Triggered when @resilience-agent encounters external service integration.

## Concept
Circuit breaker prevents cascading failures by:
1. **Closed**: Normal operation, requests pass through
2. **Open**: After N failures, stop calling service (fail fast)
3. **Half-Open**: After timeout, try one request to test recovery

## Detection Patterns

### When Circuit Breaker is Needed
- External HTTP service calls
- Microservice-to-microservice communication
- Third-party API integrations
- Database calls to separate databases
- Message queue operations

### Frameworks to Check For

**Java:**
- Resilience4j: `@CircuitBreaker`
- Hystrix (deprecated): `@HystrixCommand`
- Spring Cloud Circuit Breaker

**Python:**
- pybreaker: `@CircuitBreaker`
- pybreaker decorator

**JavaScript:**
- opossum: `new CircuitBreaker()`
- brakes

**Go:**
- gobreaker: `breaker.NewCircuitBreaker()`
- sony/gobreaker

## Examples

### Java - Resilience4j
```java
// BAD - No circuit breaker
@Service
public class UserService {
    private final RestTemplate restTemplate;

    public User getUser(Long id) {
        return restTemplate.getForObject(
            userServiceUrl + id,
            User.class
        );
        // If userService is down:
        // - Every call waits for timeout (30s)
        // - 100 concurrent requests = 100 threads blocked
        // - Thread pool exhaustion
        // - Service cascades failure
    }
}

// GOOD - With circuit breaker
@Service
public class UserService {
    private final RestTemplate restTemplate;

    @CircuitBreaker(name = "userService", fallbackMethod = "getUserFallback")
    public User getUser(Long id) {
        return restTemplate.getForObject(
            userServiceUrl + id,
            User.class
        );
    }

    public User getUserFallback(Long id, Exception e) {
        log.warn("User service unavailable, using fallback", e);
        return User.defaultUser(id);  // Return cached/default user
    }
}

// Configuration
@Configuration
public class CircuitBreakerConfig {
    @Bean
    public Customizer<Resilience4JCircuitBreakerFactory> defaultCustomizer() {
        return factory -> factory.configureDefault(id -> new Resilience4JConfigBuilder(id)
            .circuitBreakerConfig(CircuitBreakerConfig.custom()
                .failureRateThreshold(50)           // Open after 50% failures
                .waitDurationInOpenState(Duration.ofSeconds(30))  // Stay open 30s
                .slidingWindowSize(10)              // Measure last 10 calls
                .minimumNumberOfCalls(5)            // Need 5 calls before measuring
                .build())
            .build());
    }
}
```

### Python - pybreaker
```python
# BAD - No circuit breaker
import requests

def get_user(user_id):
    response = requests.get(f"{USER_SERVICE_URL}/{user_id}")
    return response.json()

# GOOD - With circuit breaker
from pybreaker import CircuitBreaker

user_service_breaker = CircuitBreaker(
    fail_max=5,           # Open after 5 failures
    timeout_duration=30,  # Stay open 30 seconds
    name='user_service'
)

@user_service_breaker
def get_user(user_id):
    response = requests.get(f"{USER_SERVICE_URL}/{user_id}", timeout=5)
    response.raise_for_status()
    return response.json()

# With fallback
def get_user_with_fallback(user_id):
    try:
        return get_user(user_id)
    except CircuitBreakerError:
        logger.warning(f"Circuit breaker open for user service")
        return get_user_from_cache(user_id)
    except Exception as e:
        logger.error(f"Failed to get user: {e}")
        return None
```

### JavaScript - opossum
```javascript
// BAD - No circuit breaker
async function getUser(userId) {
    const response = await axios.get(`${USER_SERVICE_URL}/${userId}`);
    return response.data;
}

// GOOD - With circuit breaker
const CircuitBreaker = require('opossum');

const options = {
    timeout: 3000,              // Request timeout
    errorThresholdPercentage: 50, // Open after 50% errors
    resetTimeout: 30000         // Try again after 30s
};

const breaker = new CircuitBreaker(getUser, options);

// Fallback
breaker.fallback((userId) => {
    console.log('Circuit breaker open, using fallback');
    return getUserFromCache(userId);
});

// Events
breaker.on('open', () => console.log('Circuit breaker opened'));
breaker.on('halfOpen', () => console.log('Circuit breaker half-open'));
breaker.on('close', () => console.log('Circuit breaker closed'));

async function getUser(userId) {
    const response = await axios.get(`${USER_SERVICE_URL}/${userId}`);
    return response.data;
}

// Use the circuit breaker
const user = await breaker.fire(userId);
```

### Go - gobreaker
```go
// BAD - No circuit breaker
func getUser(userID string) (*User, error) {
    resp, err := http.Get(fmt.Sprintf("%s/%s", userServiceURL, userID))
    if err != nil {
        return nil, err
    }
    // ...
}

// GOOD - With circuit breaker
import "github.com/sony/gobreaker"

var userServiceBreaker *gobreaker.CircuitBreaker

func init() {
    settings := gobreaker.Settings{
        Name:        "UserService",
        MaxRequests: 3,          // Half-open: allow 3 requests
        Interval:    60,         // Reset counts every 60s
        Timeout:     30,         // Open state duration: 30s
        ReadyToTrip: func(counts gobreaker.Counts) bool {
            failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
            return counts.Requests >= 5 && failureRatio >= 0.5  // 50% failures
        },
    }
    userServiceBreaker = gobreaker.NewCircuitBreaker(settings)
}

func getUser(userID string) (*User, error) {
    result, err := userServiceBreaker.Execute(func() (interface{}, error) {
        resp, err := http.Get(fmt.Sprintf("%s/%s", userServiceURL, userID))
        if err != nil {
            return nil, err
        }
        defer resp.Body.Close()

        if resp.StatusCode != http.StatusOK {
            return nil, fmt.Errorf("unexpected status: %d", resp.StatusCode)
        }

        var user User
        if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
            return nil, err
        }
        return &user, nil
    })

    if err != nil {
        // Fallback
        return getUserFromCache(userID), nil
    }

    return result.(*User), nil
}
```

## Configuration Guidelines

### Failure Threshold
- **50-60%**: Balanced (open after half requests fail)
- **20-30%**: Aggressive (fail fast, protect quickly)
- **70-80%**: Conservative (tolerate more failures)

### Open State Duration
- **30 seconds**: Typical for most services
- **10 seconds**: Fast recovery for stable services
- **60+ seconds**: Slow recovery for unstable services

### Minimum Calls
- **5-10 calls**: Typical (need sample before measuring)
- Prevents opening on first few failures

## Benefits

### Without Circuit Breaker
```
User Service Down:
- Every request waits 30s (timeout)
- 100 requests/sec × 30s = 3000 threads blocked
- Thread pool exhausted
- API Gateway fails
- All services affected
```

### With Circuit Breaker
```
User Service Down:
- First 5 calls fail (50% threshold)
- Circuit opens
- All subsequent calls fail fast (< 1ms)
- 100 requests/sec × 0.001s = 0.1 threads
- API Gateway remains available
- Other services unaffected
- After 30s, try again (half-open)
```

## Severity Guidelines

**HIGH:**
- External service calls without circuit breaker
- Microservice communication
- Third-party API integrations
- Critical dependencies

**MEDIUM:**
- Internal service calls
- Non-critical dependencies
- Admin operations

**LOW:**
- Batch jobs
- Background processing
- Low-traffic endpoints

## Detection Checklist

For each external service call:
1. Is there a circuit breaker annotation/wrapper?
2. Is there a fallback mechanism?
3. Are circuit breaker metrics monitored?
4. Is the configuration appropriate for the service?

## Output Format
```json
{
  "severity": "HIGH",
  "category": "MISSING_CIRCUIT_BREAKER",
  "service": "UserService HTTP client",
  "evidence": "restTemplate.getForObject(userServiceUrl + id, User.class)",
  "impact": "Cascading failure if UserService is down. Thread pool exhaustion under service outage. 100 concurrent requests can block 100 threads for 30s each.",
  "recommendation": "Add @CircuitBreaker with fallback method returning cached/default data"
}
```
