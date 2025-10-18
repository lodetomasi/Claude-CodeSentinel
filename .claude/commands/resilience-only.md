---
name: resilience-only
description: Resilience-focused analysis checking timeouts, circuit breakers, retries (15-20 minutes)
model: claude-sonnet-4-5-20250929
---

# Resilience-Only Review

Fast resilience audit focusing on fault tolerance patterns.

## Execution Steps

### Step 1: Resilience Pattern Scan (3 min) - think
```bash
echo "=== Resilience Pattern Scan ==="

# HTTP clients without timeout
echo "HTTP clients:"
grep -rn "RestTemplate\|HttpClient\|requests\.\|fetch\|axios" --include="*.java" --include="*.py" --include="*.js" 2>/dev/null | wc -l

# Circuit breakers
echo "Circuit breakers:"
grep -rn "@CircuitBreaker\|@HystrixCommand\|circuitbreaker\|pybreaker" --include="*.java" --include="*.py" 2>/dev/null
if [ $? -ne 0 ]; then echo "No circuit breakers found"; fi

# Retry logic
echo "Retry logic:"
grep -rn "@Retryable\|@retry\|tenacity\|retry" --include="*.java" --include="*.py" 2>/dev/null | wc -l

# Timeout configurations
echo "Timeout configs:"
grep -rn "timeout\|connectTimeout\|readTimeout" --include="*.java" --include="*.py" --include="*.properties" --include="*.yaml" 2>/dev/null | wc -l
```

### Step 2: Deep Resilience Analysis (15 min) - think hard

Delegate to @resilience-agent:
```
Analyze external service integrations and fault tolerance.

Categories:
1. Missing Timeouts (highest priority)
2. No Circuit Breakers
3. Missing Retry Logic
4. No Fallback Mechanisms
5. No Bulkhead Isolation
6. No Graceful Degradation

Time budget: 15 minutes
```

### Step 3: Resilience Report (2 min)

Generate: `reports/resilience-audit-[timestamp].md`
```markdown
# Resilience Audit Report

Generated: [timestamp]
Repository: [path]
Focus: Fault tolerance and resilience

---

## Executive Summary

- CRITICAL gaps: X (can cause cascading failures)
- HIGH gaps: Y (reduce availability)
- External dependencies analyzed: Z

---

## Critical Resilience Gaps

### RES-CRIT-001: No Timeout on Payment Service
**File:** src/service/PaymentService.java:45
**Risk:** Thread exhaustion, cascading failure
**Dependency:** External payment gateway

**Current Code:**
```java
RestTemplate restTemplate = new RestTemplate();
Payment payment = restTemplate.postForObject(url, request, Payment.class);
// If payment service hangs, this thread waits forever
```

**Failure Scenario:**
1. Payment service becomes slow (5s response time)
2. 200 concurrent payment requests
3. All 200 threads blocked waiting
4. Thread pool exhausted
5. All new requests rejected
6. Entire application appears down

**Fix:**
```java
RestTemplate restTemplate = new RestTemplateBuilder()
    .setConnectTimeout(Duration.ofSeconds(5))
    .setReadTimeout(Duration.ofSeconds(30))
    .build();
```

**Additional Recommendation - Circuit Breaker:**
```java
@CircuitBreaker(name = "paymentService", fallbackMethod = "paymentFallback")
@Retry(name = "paymentService", maxAttempts = 3)
public Payment processPayment(PaymentRequest request) {
    return restTemplate.postForObject(url, request, Payment.class);
}

public Payment paymentFallback(PaymentRequest request, Exception e) {
    log.error("Payment service unavailable, queuing for retry", e);
    paymentQueue.enqueue(request);
    return Payment.queued(request);
}
```

---

## Resilience Recommendations

### Immediate (This Week)
1. Add timeouts to all external service calls
2. Implement circuit breakers for critical dependencies
3. Add retry logic with exponential backoff

### Short Term (This Sprint)
1. Implement fallback mechanisms
2. Add bulkhead isolation (separate thread pools)
3. Implement graceful degradation

### Architecture Improvements
1. Consider async processing for non-critical operations
2. Implement event-driven patterns for decoupling
3. Add service mesh for resilience patterns (Istio, Linkerd)

---

## Dependency Map

| Service | Timeouts | Circuit Breaker | Retry | Fallback |
|---------|----------|----------------|-------|----------|
| Payment Gateway | ❌ | ❌ | ❌ | ❌ |
| Email Service | ✓ | ❌ | ✓ | ✓ |
| User Service | ❌ | ❌ | ❌ | ❌ |

---

## Testing Recommendations

Chaos engineering scenarios to test:
1. Introduce 5s latency to payment service
2. Return 503 errors from email service
3. Kill user service pods randomly
4. Measure: circuit breaker opens, retries work, fallbacks activate
```

## Output Message
```
✓ Resilience audit completed in [X] minutes

Report: reports/resilience-audit-[timestamp].md

Findings:
- CRITICAL: X dependencies without timeouts
- HIGH: Y dependencies without circuit breakers
- External services analyzed: Z

Top risk: [External service] can cause cascading failure

Recommendations:
1. Add timeouts (2 hours work, prevents outages)
2. Add circuit breakers (4 hours work, improves availability)
3. Implement retries (2 hours work, handles transient errors)
```
