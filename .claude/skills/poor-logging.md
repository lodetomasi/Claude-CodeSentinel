---
name: poor-logging
type: skill
category: observability
progressive_disclosure: true
---

# Poor Logging Detection Skill

## Activation
Triggered when @observability-agent analyzes logging practices.

## Anti-Patterns

### 1. Console Output Instead of Logger

**Java:**
```java
// BAD - System.out/err
public void processOrder(Order order) {
    System.out.println("Processing order: " + order.getId());  // BAD
    System.err.println("Error processing order");  // BAD
}

// GOOD - Proper logger
private static final Logger log = LoggerFactory.getLogger(OrderService.class);

public void processOrder(Order order) {
    log.info("Processing order: {}", order.getId());
    log.error("Error processing order", exception);
}
```

**Python:**
```python
# BAD - print statements
def process_order(order):
    print(f"Processing order: {order.id}")  # BAD

# GOOD - logging module
import logging

logger = logging.getLogger(__name__)

def process_order(order):
    logger.info(f"Processing order: {order.id}")
```

**JavaScript:**
```javascript
// BAD - console.log
function processOrder(order) {
    console.log(`Processing order: ${order.id}`);  // BAD
}

// GOOD - winston or similar
const logger = require('winston');

function processOrder(order) {
    logger.info(`Processing order: ${order.id}`);
}
```

### 2. Silent Failures (Empty Catch Blocks)

```java
// BAD - Silent failure
try {
    paymentService.charge(order);
} catch (Exception e) {
    // Silent failure - no one knows payment failed!
}

// BAD - Only print stack trace
try {
    paymentService.charge(order);
} catch (Exception e) {
    e.printStackTrace();  // Goes to stderr, often lost
}

// GOOD - Log with context
try {
    paymentService.charge(order);
} catch (PaymentException e) {
    log.error("Payment failed for order {}: {}",
        order.getId(), e.getMessage(), e);
    // Consider: alert, metrics, retry, fallback
}
```

### 3. Missing Context

```java
// BAD - No context
log.error("Update failed");  // What update? For what?

// GOOD - Rich context
log.error("Failed to update order status from {} to {} for order {}",
    oldStatus, newStatus, orderId, exception);
```

### 4. Wrong Log Levels

```java
// BAD - Wrong levels
log.error("User logged in");  // Not an error!
log.debug("Payment processing failed");  // Should be ERROR
log.info("Starting background job");  // Too noisy, should be DEBUG

// GOOD - Appropriate levels
log.info("User {} logged in", userId);
log.error("Payment processing failed for order {}", orderId, ex);
log.debug("Starting background job for user {}", userId);
```

### 5. String Concatenation Instead of Placeholders

```java
// BAD - String concatenation (computed even if log level disabled)
log.debug("Processing order: " + order.getId() + " for user: " + user.getName());

// GOOD - Parameterized (lazy evaluation)
log.debug("Processing order: {} for user: {}", order.getId(), user.getName());
```

### 6. Logging Sensitive Data

```java
// BAD - Logging sensitive data
log.info("User login: {}, password: {}", username, password);  // SECURITY RISK
log.info("Credit card: {}", creditCardNumber);  // SECURITY RISK
log.debug("API key: {}", apiKey);  // SECURITY RISK

// GOOD - Sanitized logging
log.info("User login: {}", username);
log.info("Credit card ending: {}", creditCardNumber.substring(12));
log.debug("API key hash: {}", hashApiKey(apiKey));
```

### 7. No Structured Logging

```java
// BAD - Unstructured
log.info("Order 123 processed successfully for user john@example.com with total $99.99");
// Hard to parse, search, aggregate

// GOOD - Structured (with MDC or structured logger)
MDC.put("orderId", "123");
MDC.put("userId", "john@example.com");
MDC.put("orderTotal", "99.99");
log.info("Order processed successfully");
MDC.clear();

// Or with JSON logging
log.info("Order processed",
    kv("orderId", 123),
    kv("userId", "john@example.com"),
    kv("orderTotal", 99.99)
);
```

### 8. Logging in Loops

```java
// BAD - Logging in tight loop
for (Order order : orders) {  // 10,000 orders
    log.info("Processing order {}", order.getId());  // 10,000 log lines!
}

// GOOD - Batch logging
log.info("Processing {} orders", orders.size());
int processed = 0;
for (Order order : orders) {
    processOrder(order);
    if (++processed % 100 == 0) {
        log.debug("Processed {} / {} orders", processed, orders.size());
    }
}
log.info("Completed processing {} orders", processed);
```

## Log Levels Guide

### ERROR
- Application errors requiring immediate attention
- Failed operations affecting users
- Exceptions that should not happen
```java
log.error("Payment processing failed", exception);
log.error("Database connection lost");
```

### WARN
- Unexpected but recoverable situations
- Deprecated API usage
- Configuration issues
```java
log.warn("Retry attempt {} failed, will retry", attemptNumber);
log.warn("Cache unavailable, using database");
```

### INFO
- Important business events
- Application lifecycle events
- Key milestones
```java
log.info("Order {} created for user {}", orderId, userId);
log.info("Application started in {}ms", startupTime);
```

### DEBUG
- Detailed flow information
- Variable values
- Development troubleshooting
```java
log.debug("Validating order with {} items", items.size());
log.debug("Cache hit for key {}", cacheKey);
```

### TRACE
- Very detailed diagnostic information
- Method entry/exit
- Loop iterations
```java
log.trace("Entering method processOrder with {}", order);
```

## Detection Patterns

### Find Console Output
```regex
Java: System\.out\.println|System\.err\.println
Python: \bprint\(
JavaScript: console\.log|console\.error|console\.warn
```

### Find Empty Catch Blocks
```regex
catch.*\{[\s]*\}
catch.*\{[\s]*//.*\}
```

### Find Potential Sensitive Data Logging
```regex
log.*password|log.*secret|log.*apikey|log.*token
log.*creditcard|log.*ssn
```

## Severity Guidelines

**HIGH:**
- Silent failures (empty catch blocks)
- Logging sensitive data (passwords, API keys)
- System.out in production code
- No error logging in critical operations

**MEDIUM:**
- Wrong log levels
- Missing context in error logs
- String concatenation in logs
- No structured logging

**LOW:**
- Logging in loops
- Too verbose logging
- Minor improvements

## Best Practices

### 1. Correlation IDs
```java
// Add correlation ID for request tracing
MDC.put("correlationId", UUID.randomUUID().toString());
try {
    // All logs in this request will have same correlationId
    processRequest();
} finally {
    MDC.clear();
}
```

### 2. Exception Logging
```java
// Include exception object
log.error("Failed to process order {}", orderId, exception);

// Not just message
log.error("Failed to process order {}: {}", orderId, exception.getMessage());  // Missing stack trace
```

### 3. Asynchronous Logging
```java
// Use async appenders for performance
<appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
    <appender-ref ref="FILE" />
</appender>
```

### 4. Log Rotation
```xml
<!-- Configure log rotation -->
<rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
    <fileNamePattern>logs/app.%d{yyyy-MM-dd}.log</fileNamePattern>
    <maxHistory>30</maxHistory>
    <totalSizeCap>10GB</totalSizeCap>
</rollingPolicy>
```

## Fix Templates

### Java - SLF4J
```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class OrderService {
    private static final Logger log = LoggerFactory.getLogger(OrderService.class);

    public void processOrder(Order order) {
        log.info("Processing order {}", order.getId());
        try {
            // Business logic
            log.debug("Order validated successfully");
        } catch (ValidationException e) {
            log.error("Order validation failed for order {}", order.getId(), e);
            throw e;
        }
    }
}
```

### Python
```python
import logging

logger = logging.getLogger(__name__)

def process_order(order):
    logger.info(f"Processing order {order.id}")
    try:
        # Business logic
        logger.debug("Order validated successfully")
    except ValidationException as e:
        logger.error(f"Order validation failed for order {order.id}", exc_info=True)
        raise
```

### JavaScript
```javascript
const winston = require('winston');

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.json(),
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' })
    ]
});

function processOrder(order) {
    logger.info(`Processing order ${order.id}`);
    try {
        // Business logic
        logger.debug('Order validated successfully');
    } catch (error) {
        logger.error(`Order validation failed for order ${order.id}`, error);
        throw error;
    }
}
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "POOR_LOGGING",
  "issue_type": "console_output",
  "evidence": "System.out.println(\"Processing order: \" + order.getId())",
  "impact": "Logs not captured in production monitoring. Cannot search, alert, or analyze.",
  "recommendation": "Replace with proper logger: log.info(\"Processing order: {}\", order.getId())"
}
```
