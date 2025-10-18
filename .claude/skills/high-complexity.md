---
name: high-complexity
type: skill
category: code_quality
progressive_disclosure: true
---

# High Complexity Detection Skill

## Activation
Triggered when @code-quality-agent encounters methods with high cyclomatic complexity.

## Cyclomatic Complexity Definition
Number of independent paths through code:
- Start with 1
- +1 for each: if, else, for, while, case, catch, &&, ||, ?:

## Thresholds

### Method Complexity
- **1-5**: Simple, easy to test
- **6-10**: Moderate, acceptable
- **11-15**: Complex, should refactor
- **16-20**: Very complex, hard to maintain
- **21+**: Extremely complex, refactor immediately

### File Size
- **< 200 lines**: Good
- **200-500 lines**: Acceptable
- **500-1000 lines**: Large, consider splitting
- **1000+ lines**: God class, refactor

### Method Length
- **< 20 lines**: Good
- **20-50 lines**: Acceptable
- **50-100 lines**: Long, consider splitting
- **100+ lines**: Too long, refactor

## Detection Examples

### Java - High Complexity Method
```java
// BAD - Complexity = 18
public void validateAndProcessOrder(Order order) {
    if (order == null) {  // 1
        throw new IllegalArgumentException();
    }

    if (order.getItems().isEmpty()) {  // 2
        throw new IllegalArgumentException();
    }

    for (Item item : order.getItems()) {  // 3
        if (item.getQuantity() <= 0) {  // 4
            throw new IllegalArgumentException();
        }

        if (item.getPrice() == null || item.getPrice().compareTo(BigDecimal.ZERO) <= 0) {  // 5, 6
            throw new IllegalArgumentException();
        }

        if (item.getProduct() == null) {  // 7
            throw new IllegalArgumentException();
        }
    }

    if (order.getCustomer() == null) {  // 8
        throw new IllegalArgumentException();
    }

    if (order.getCustomer().getEmail() == null || !order.getCustomer().getEmail().contains("@")) {  // 9, 10
        throw new IllegalArgumentException();
    }

    if (order.getShippingAddress() == null) {  // 11
        throw new IllegalArgumentException();
    }

    if (order.getTotal().compareTo(MAX_ORDER_AMOUNT) > 0) {  // 12
        if (!order.getCustomer().isPremium()) {  // 13
            throw new IllegalArgumentException();
        }
    }

    if (order.getPaymentMethod() == null) {  // 14
        throw new IllegalArgumentException();
    }

    if (order.getPaymentMethod().equals("CREDIT_CARD")) {  // 15
        if (order.getCreditCard() == null) {  // 16
            throw new IllegalArgumentException();
        }
    } else if (order.getPaymentMethod().equals("PAYPAL")) {  // 17
        if (order.getPaypalEmail() == null) {  // 18
            throw new IllegalArgumentException();
        }
    }

    // Process order...
}

// GOOD - Refactored (Complexity = 3 per method)
public void validateAndProcessOrder(Order order) {
    validateOrder(order);  // Complexity = 1
    validateItems(order);  // Complexity = 3
    validateCustomer(order.getCustomer());  // Complexity = 3
    validatePayment(order);  // Complexity = 3
    processOrder(order);  // Complexity = 1
}

private void validateOrder(Order order) {
    if (order == null) {
        throw new IllegalArgumentException("Order cannot be null");
    }
}

private void validateItems(Order order) {
    if (order.getItems().isEmpty()) {
        throw new IllegalArgumentException("Order must have items");
    }

    for (Item item : order.getItems()) {
        validateItem(item);
    }
}

private void validateItem(Item item) {
    if (item.getQuantity() <= 0) {
        throw new IllegalArgumentException("Item quantity must be positive");
    }
    if (item.getPrice() == null || item.getPrice().compareTo(BigDecimal.ZERO) <= 0) {
        throw new IllegalArgumentException("Item price must be positive");
    }
    if (item.getProduct() == null) {
        throw new IllegalArgumentException("Item must have a product");
    }
}

private void validateCustomer(Customer customer) {
    if (customer == null) {
        throw new IllegalArgumentException("Customer cannot be null");
    }
    if (customer.getEmail() == null || !customer.getEmail().contains("@")) {
        throw new IllegalArgumentException("Customer email is invalid");
    }
}

private void validatePayment(Order order) {
    if (order.getPaymentMethod() == null) {
        throw new IllegalArgumentException("Payment method required");
    }

    if (order.getPaymentMethod().equals("CREDIT_CARD")) {
        validateCreditCard(order.getCreditCard());
    } else if (order.getPaymentMethod().equals("PAYPAL")) {
        validatePaypal(order.getPaypalEmail());
    }
}
```

### Python - Deeply Nested Code
```python
# BAD - Deep nesting (6 levels)
def process_data(data):
    if data:  # Level 1
        for item in data:  # Level 2
            if item.is_valid():  # Level 3
                if item.category == 'A':  # Level 4
                    for sub_item in item.sub_items:  # Level 5
                        if sub_item.status == 'active':  # Level 6
                            process_sub_item(sub_item)

# GOOD - Flattened with early returns
def process_data(data):
    if not data:
        return

    for item in data:
        process_item(item)

def process_item(item):
    if not item.is_valid():
        return

    if item.category != 'A':
        return

    for sub_item in item.sub_items:
        process_sub_item_if_active(sub_item)

def process_sub_item_if_active(sub_item):
    if sub_item.status == 'active':
        process_sub_item(sub_item)
```

### JavaScript - Long Switch Statement
```javascript
// BAD - Long switch (Complexity = 12)
function calculateDiscount(customerType, orderTotal, loyaltyYears) {
    let discount = 0;

    switch (customerType) {
        case 'REGULAR':
            if (orderTotal > 1000) {
                discount = 0.05;
            } else if (orderTotal > 500) {
                discount = 0.03;
            }
            break;
        case 'PREMIUM':
            if (loyaltyYears > 5) {
                discount = 0.20;
            } else if (loyaltyYears > 2) {
                discount = 0.15;
            } else {
                discount = 0.10;
            }
            break;
        case 'VIP':
            if (loyaltyYears > 10) {
                discount = 0.30;
            } else if (loyaltyYears > 5) {
                discount = 0.25;
            } else {
                discount = 0.20;
            }
            break;
        // More cases...
    }

    return discount;
}

// GOOD - Strategy pattern
const discountStrategies = {
    REGULAR: (orderTotal) => {
        if (orderTotal > 1000) return 0.05;
        if (orderTotal > 500) return 0.03;
        return 0;
    },
    PREMIUM: (orderTotal, loyaltyYears) => {
        if (loyaltyYears > 5) return 0.20;
        if (loyaltyYears > 2) return 0.15;
        return 0.10;
    },
    VIP: (orderTotal, loyaltyYears) => {
        if (loyaltyYears > 10) return 0.30;
        if (loyaltyYears > 5) return 0.25;
        return 0.20;
    }
};

function calculateDiscount(customerType, orderTotal, loyaltyYears) {
    const strategy = discountStrategies[customerType];
    return strategy ? strategy(orderTotal, loyaltyYears) : 0;
}
```

## Complexity Calculation

### Count Decision Points
```java
// Complexity = 8
public boolean isEligible(User user) {
    return user != null &&           // 1 (&&)
           user.getAge() >= 18 &&    // 2 (&&)
           user.isVerified() &&      // 3 (&&)
           (user.hasSubscription()   // 4 (||)
            || user.hasFreeTrial()) &&
           !user.isBanned();         // No additional complexity for negation
}
```

### Count Control Flow
```java
// Complexity = 6
public void processOrder(Order order) {
    if (order.isPaid()) {        // 1
        if (order.hasItems()) {  // 2
            ship(order);
        } else {               // Already counted in if
            cancel(order);
        }
    }

    for (Item item : order.getItems()) {  // 3
        if (item.isBackordered()) {       // 4
            notifyCustomer(item);
        }
    }

    try {
        saveOrder(order);
    } catch (Exception e) {  // 5
        rollback(order);
    }
}
```

## Refactoring Strategies

### 1. Extract Method
```java
// Before: Complexity = 15
public void processUser(User user) {
    // 50 lines of validation
    // 30 lines of processing
    // 20 lines of notification
}

// After: Complexity = 3 per method
public void processUser(User user) {
    validateUser(user);   // Complexity = 5
    processUserData(user); // Complexity = 4
    notifyUser(user);     // Complexity = 3
}
```

### 2. Replace Conditional with Polymorphism
```java
// Before
if (type == "A") {
    // Handle A
} else if (type == "B") {
    // Handle B
}

// After
interface Handler {
    void handle();
}
Map<String, Handler> handlers = ...;
handlers.get(type).handle();
```

### 3. Early Return Pattern
```java
// Before: Nested if
if (condition1) {
    if (condition2) {
        if (condition3) {
            doSomething();
        }
    }
}

// After: Early returns
if (!condition1) return;
if (!condition2) return;
if (!condition3) return;
doSomething();
```

### 4. Guard Clauses
```java
// Before
public void process(Order order) {
    if (order != null) {
        if (order.isValid()) {
            // Main logic (20 lines)
        }
    }
}

// After
public void process(Order order) {
    if (order == null) return;
    if (!order.isValid()) return;

    // Main logic (20 lines)
}
```

## Severity Guidelines

**CRITICAL:**
- Cyclomatic complexity > 25
- Methods > 200 lines
- Nesting depth > 6 levels
- Untestable code

**HIGH:**
- Complexity 15-25
- Methods 100-200 lines
- Nesting depth 5-6 levels
- Difficult to test

**MEDIUM:**
- Complexity 10-14
- Methods 50-100 lines
- Nesting depth 4 levels
- Moderately complex

**LOW:**
- Complexity 6-9
- Methods 30-50 lines
- Minor improvements possible

## Impact

### High Complexity Issues
- **Testing**: Need 2^N test cases for N decision points
- **Bugs**: Error rate increases exponentially with complexity
- **Maintenance**: Each change risks breaking multiple paths
- **Onboarding**: New developers take 3x longer to understand

### Example
```
Complexity 20:
- Theoretical test cases: 2^20 = 1,048,576
- Realistic coverage: 10-20 test cases (1% coverage)
- Bug density: 3-5 bugs per method
- Time to understand: 30-60 minutes
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "HIGH_COMPLEXITY",
  "complexity": 18,
  "method_length": 87,
  "nesting_depth": 6,
  "evidence": "public void validateAndProcessOrder(Order order) { /* 87 lines */ }",
  "impact": "Cyclomatic complexity of 18 (threshold: 10). Need 262,144 theoretical test paths. High bug density area. Difficult to understand and maintain.",
  "recommendation": "Extract methods: validateOrder(), validateItems(), validateCustomer(), validatePayment(), processOrder(). Each method will have complexity < 5."
}
```
