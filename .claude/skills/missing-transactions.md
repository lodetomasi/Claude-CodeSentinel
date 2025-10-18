---
name: missing-transactions
type: skill
category: data_integrity
progressive_disclosure: true
---

# Missing Transaction Detection Skill

## Activation
Triggered when @data-integrity-agent encounters multiple database operations.

## Concept
Transactions ensure ACID properties:
- **Atomicity**: All or nothing (no partial updates)
- **Consistency**: Database constraints maintained
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed data persists

## Detection Patterns

### When Transactions Are Needed
- Multiple database writes
- Read-modify-write operations
- Dependent operations (must succeed together)
- Financial operations
- Inventory updates
- Account balance changes

### Java/Spring
```java
// BAD - No transaction
@Service
public class OrderService {
    private final OrderRepository orderRepo;
    private final InventoryRepository inventoryRepo;
    private final PaymentRepository paymentRepo;

    public void createOrder(Order order) {
        orderRepo.save(order);              // 1. Save order
        inventoryRepo.decrementStock(order); // 2. Update inventory
        paymentRepo.createCharge(order);     // 3. Create payment

        // Problem: If step 3 fails:
        // - Order is saved
        // - Inventory is decremented
        // - Payment failed
        // Result: Inconsistent state!
    }
}

// GOOD - With transaction
@Service
public class OrderService {
    @Transactional  // All or nothing
    public void createOrder(Order order) {
        orderRepo.save(order);
        inventoryRepo.decrementStock(order);
        paymentRepo.createCharge(order);

        // If any step fails:
        // - All changes rolled back
        // - Database remains consistent
    }
}

// GOOD - Explicit transaction boundaries
@Service
public class OrderService {
    @Transactional(
        isolation = Isolation.READ_COMMITTED,
        propagation = Propagation.REQUIRED,
        rollbackFor = Exception.class,
        timeout = 30
    )
    public void createOrder(Order order) {
        // Transaction scope
    }
}
```

### Python/Django
```python
# BAD - No transaction
def create_order(order_data):
    order = Order.objects.create(**order_data)
    Inventory.objects.filter(
        product=order.product
    ).update(stock=F('stock') - order.quantity)
    Payment.objects.create(order=order, amount=order.total)

    # If payment creation fails, order and inventory already changed!

# GOOD - With transaction decorator
from django.db import transaction

@transaction.atomic
def create_order(order_data):
    order = Order.objects.create(**order_data)
    Inventory.objects.filter(
        product=order.product
    ).update(stock=F('stock') - order.quantity)
    Payment.objects.create(order=order, amount=order.total)
    # All or nothing

# GOOD - Context manager for partial transaction
def create_order(order_data):
    # Some code outside transaction

    with transaction.atomic():
        order = Order.objects.create(**order_data)
        Inventory.objects.filter(
            product=order.product
        ).update(stock=F('stock') - order.quantity)
        Payment.objects.create(order=order, amount=order.total)

    # Some code outside transaction
```

### JavaScript/Sequelize
```javascript
// BAD - No transaction
async function createOrder(orderData) {
    const order = await Order.create(orderData);
    await Inventory.decrement('stock', {
        where: { productId: order.productId }
    });
    await Payment.create({ orderId: order.id, amount: order.total });

    // If payment fails, order and inventory already changed!
}

// GOOD - With transaction
async function createOrder(orderData) {
    const transaction = await sequelize.transaction();

    try {
        const order = await Order.create(orderData, { transaction });
        await Inventory.decrement('stock', {
            where: { productId: order.productId },
            transaction
        });
        await Payment.create(
            { orderId: order.id, amount: order.total },
            { transaction }
        );

        await transaction.commit();
    } catch (error) {
        await transaction.rollback();
        throw error;
    }
}

// BETTER - Managed transaction
async function createOrder(orderData) {
    return await sequelize.transaction(async (t) => {
        const order = await Order.create(orderData, { transaction: t });
        await Inventory.decrement('stock', {
            where: { productId: order.productId },
            transaction: t
        });
        await Payment.create(
            { orderId: order.id, amount: order.total },
            { transaction: t }
        );
    });
    // Auto commit/rollback
}
```

### Go - database/sql
```go
// BAD - No transaction
func createOrder(db *sql.DB, order Order) error {
    _, err := db.Exec("INSERT INTO orders (...) VALUES (...)", order.Data)
    if err != nil {
        return err
    }

    _, err = db.Exec("UPDATE inventory SET stock = stock - ? WHERE product_id = ?",
        order.Quantity, order.ProductID)
    if err != nil {
        return err  // Order already inserted!
    }

    _, err = db.Exec("INSERT INTO payments (...) VALUES (...)", order.Payment)
    return err  // If fails, order and inventory already changed!
}

// GOOD - With transaction
func createOrder(db *sql.DB, order Order) error {
    tx, err := db.Begin()
    if err != nil {
        return err
    }
    defer tx.Rollback()  // Rollback if not committed

    _, err = tx.Exec("INSERT INTO orders (...) VALUES (...)", order.Data)
    if err != nil {
        return err
    }

    _, err = tx.Exec("UPDATE inventory SET stock = stock - ? WHERE product_id = ?",
        order.Quantity, order.ProductID)
    if err != nil {
        return err
    }

    _, err = tx.Exec("INSERT INTO payments (...) VALUES (...)", order.Payment)
    if err != nil {
        return err
    }

    return tx.Commit()  // All or nothing
}
```

## Detection Heuristics

### Look for Multiple Writes
```regex
repository\.save.*repository\.save
\.save\(.*\.save\(
INSERT.*INSERT
UPDATE.*UPDATE
```

### Check for Transaction Annotation/Context
```
@Transactional
@transaction.atomic
sequelize.transaction
db.Begin()
```

### Common Patterns Requiring Transactions

1. **Transfer operations**
```java
// MUST be in transaction
account1.setBalance(account1.getBalance() - amount);
account2.setBalance(account2.getBalance() + amount);
accountRepo.save(account1);
accountRepo.save(account2);
```

2. **Parent-child creation**
```java
// MUST be in transaction
Order order = orderRepo.save(new Order());
for (Item item : items) {
    item.setOrder(order);
    itemRepo.save(item);  // Multiple saves
}
```

3. **Update with audit**
```java
// MUST be in transaction
user.setEmail(newEmail);
userRepo.save(user);
auditRepo.save(new Audit("Email changed"));
```

## Transaction Isolation Levels

### READ_UNCOMMITTED (Lowest)
- Dirty reads possible
- Use: Rare, only for non-critical reads

### READ_COMMITTED (Default)
- No dirty reads
- Non-repeatable reads possible
- Use: Most cases

### REPEATABLE_READ
- Consistent reads within transaction
- Phantom reads possible
- Use: Financial operations

### SERIALIZABLE (Highest)
- Full isolation
- Performance impact
- Use: Critical operations only

## Severity Guidelines

**CRITICAL:**
- Financial transactions (money transfer, payment)
- Inventory updates
- Account balance changes
- No transaction around multiple writes

**HIGH:**
- Multiple database writes
- Parent-child creation
- Data consistency critical
- Read-modify-write patterns

**MEDIUM:**
- Related updates
- Audit logging with data changes
- Cache invalidation with DB update

**LOW:**
- Independent writes
- Idempotent operations
- Read-only operations

## Common Mistakes

### 1. Transaction Too Large
```java
// BAD - Transaction too large
@Transactional
public void processOrders() {
    List<Order> orders = orderRepo.findAll();  // 10,000 orders
    for (Order order : orders) {
        // Process each order
        // Long-running transaction locks database
    }
}

// GOOD - Smaller transactions
public void processOrders() {
    List<Order> orders = orderRepo.findAll();
    for (Order order : orders) {
        processOrderInTransaction(order);  // Separate transaction per order
    }
}

@Transactional
private void processOrderInTransaction(Order order) {
    // Small, focused transaction
}
```

### 2. Transaction on Read-Only Method
```java
// UNNECESSARY - Read-only doesn't need write transaction
@Transactional
public List<User> getUsers() {
    return userRepo.findAll();
}

// BETTER - Mark as read-only
@Transactional(readOnly = true)
public List<User> getUsers() {
    return userRepo.findAll();
}
```

### 3. Missing Rollback Configuration
```java
// BAD - Checked exceptions don't rollback by default
@Transactional
public void createOrder(Order order) throws OrderException {
    orderRepo.save(order);
    if (invalidCondition) {
        throw new OrderException();  // Transaction NOT rolled back!
    }
}

// GOOD - Configure rollback for all exceptions
@Transactional(rollbackFor = Exception.class)
public void createOrder(Order order) throws OrderException {
    orderRepo.save(order);
    if (invalidCondition) {
        throw new OrderException();  // Transaction rolled back
    }
}
```

## Output Format
```json
{
  "severity": "CRITICAL",
  "category": "MISSING_TRANSACTION",
  "operations": ["orderRepo.save()", "inventoryRepo.update()", "paymentRepo.save()"],
  "evidence": "Multiple database writes without @Transactional",
  "impact": "Data inconsistency if any operation fails. Order saved but payment failed = lost revenue and customer complaint.",
  "recommendation": "Add @Transactional annotation to ensure atomicity"
}
```
