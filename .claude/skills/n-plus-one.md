---
name: n-plus-one
type: skill
category: performance
progressive_disclosure: true
---

# N+1 Query Detection Skill

## Activation
Triggered when @performance-agent encounters collection loading patterns.

## Detection Levels

### Level 1: Pattern (Quick)
Find: findAll/all/find followed by loop with relationship access

```regex
Java: \.findAll\(\).*for.*\.get[A-Z]
Python: \.all\(\).*for.*\.[a-z_]+
JavaScript: \.find\(\).*\.map\(.*\.[a-z]
```

### Level 2: Verification (Medium)
Check next 10 lines after collection load for:
- .getRelationship() calls
- Lazy loading access
- No JOIN FETCH/include/prefetch

### Level 3: Impact Calculation (Deep)
Estimate:
- Collection size (from context)
- Queries: 1 + N
- Time impact: N × roundtrip time

## Detection Patterns

### Java/JPA
```java
// BAD - N+1 queries
List<Order> orders = orderRepository.findAll();  // 1 query
for (Order order : orders) {
    Customer customer = order.getCustomer();  // N queries (lazy load)
    System.out.println(customer.getName());
}
// Total: 1 + N queries

// GOOD - Single query with JOIN FETCH
@Query("SELECT o FROM Order o JOIN FETCH o.customer")
List<Order> findAllWithCustomer();

// GOOD - EntityGraph
@EntityGraph(attributePaths = {"customer"})
List<Order> findAll();

// GOOD - Batch size (reduces but doesn't eliminate)
@BatchSize(size = 10)
private Customer customer;
```

### Python/Django
```python
# BAD - N+1 queries
orders = Order.objects.all()  # 1 query
for order in orders:
    print(order.customer.name)  # N queries (lazy load)

# GOOD - select_related for ForeignKey
orders = Order.objects.select_related('customer').all()

# GOOD - prefetch_related for ManyToMany
orders = Order.objects.prefetch_related('items').all()

# GOOD - Multiple relationships
orders = Order.objects.select_related('customer').prefetch_related('items').all()
```

### JavaScript/Sequelize
```javascript
// BAD - N+1 queries
const orders = await Order.findAll();  // 1 query
for (const order of orders) {
    const customer = await order.getCustomer();  // N queries
    console.log(customer.name);
}

// GOOD - include relationship
const orders = await Order.findAll({
    include: [{ model: Customer }]
});

// GOOD - Nested includes
const orders = await Order.findAll({
    include: [{
        model: Customer,
        include: [{ model: Address }]
    }]
});
```

### JavaScript/Mongoose
```javascript
// BAD - N+1 queries
const orders = await Order.find();  // 1 query
for (const order of orders) {
    await order.populate('customer');  // N queries
}

// GOOD - populate
const orders = await Order.find().populate('customer');

// GOOD - Multiple populates
const orders = await Order.find()
    .populate('customer')
    .populate('items');
```

## Severity Guidelines

**CRITICAL:**
- N > 100 (100+ extra queries)
- High-traffic endpoint
- Production performance impact observed

**HIGH:**
- N > 10 (10-100 extra queries)
- User-facing endpoint
- Noticeable latency

**MEDIUM:**
- N = 5-10
- Admin endpoint
- Moderate impact

**LOW:**
- N < 5
- Low-traffic endpoint
- Minor optimization opportunity

## Impact Calculation

```
Queries without optimization: 1 + N
Queries with optimization: 1

Example: N = 100
- Without: 101 queries × 5ms = 505ms
- With: 1 query × 10ms = 10ms
- Improvement: 495ms (98% faster)
```

## Fixes by Framework

### Java/JPA
1. **JOIN FETCH**
```java
@Query("SELECT DISTINCT o FROM Order o JOIN FETCH o.customer")
List<Order> findAllWithCustomer();
```

2. **EntityGraph**
```java
@EntityGraph(attributePaths = {"customer", "items"})
List<Order> findAll();
```

3. **Batch Size** (partial fix)
```java
@BatchSize(size = 25)
@OneToMany
private List<OrderItem> items;
```

### Python/Django
```python
# ForeignKey/OneToOne
.select_related('customer', 'shipping_address')

# ManyToMany/Reverse ForeignKey
.prefetch_related('items', 'tags')

# Nested
.select_related('customer__country')
```

### JavaScript
```javascript
// Sequelize
{ include: [{ model: Customer, include: [Address] }] }

// Mongoose
.populate('customer').populate('items')
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "N_PLUS_ONE_QUERY",
  "queries_count": "1 + 50 = 51 queries",
  "estimated_impact": "250ms extra latency",
  "fix": "Add JOIN FETCH/select_related/include"
}
```
