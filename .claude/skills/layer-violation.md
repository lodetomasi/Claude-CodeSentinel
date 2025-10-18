---
name: layer-violation
type: skill
category: architecture
---

# Layer Violation Detection Skill

## Layered Architecture

### Standard Layers (Top to Bottom)
1. **Presentation** - Controllers, REST endpoints, UI
2. **Service/Business Logic** - Business rules, orchestration
3. **Data Access** - Repositories, DAOs, database access
4. **Domain** - Entities, DTOs, value objects

### Dependency Rule
**Higher layers can depend on lower layers, but NOT vice versa.**

```
Presentation → Service → Data Access → Domain
     ✓            ✓           ✓
     ✗ ←          ✗ ←         ✗ ←
```

## Common Violations

### 1. Controller → Repository (Skipping Service)

```java
// BAD - Layer violation
@RestController
public class UserController {
    @Autowired
    private UserRepository userRepository;  // WRONG! Skip service layer

    @GetMapping("/users/{id}")
    public User getUser(@PathVariable Long id) {
        return userRepository.findById(id).orElse(null);
        // No business logic, no validation, no transaction
    }
}

// GOOD - Proper layering
@RestController
public class UserController {
    @Autowired
    private UserService userService;  // Correct

    @GetMapping("/users/{id}")
    public UserDTO getUser(@PathVariable Long id) {
        return userService.getUser(id);
        // Service handles business logic, validation, transactions
    }
}

@Service
public class UserService {
    @Autowired
    private UserRepository userRepository;

    @Transactional(readOnly = true)
    public UserDTO getUser(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException(id));
        return userMapper.toDTO(user);
    }
}
```

### 2. SQL in Controller/Service

```java
// BAD - SQL in Controller
@RestController
public class OrderController {
    @Autowired
    private JdbcTemplate jdbcTemplate;  // Database access in controller!

    @GetMapping("/orders")
    public List<Order> getOrders() {
        return jdbcTemplate.query(
            "SELECT * FROM orders WHERE status = 'ACTIVE'",
            new OrderRowMapper()
        );
    }
}

// GOOD - SQL in Repository
@RestController
public class OrderController {
    @Autowired
    private OrderService orderService;

    @GetMapping("/orders")
    public List<OrderDTO> getOrders() {
        return orderService.getActiveOrders();
    }
}

@Service
public class OrderService {
    @Autowired
    private OrderRepository orderRepository;

    public List<OrderDTO> getActiveOrders() {
        return orderRepository.findByStatus("ACTIVE")
            .stream()
            .map(orderMapper::toDTO)
            .collect(Collectors.toList());
    }
}

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    List<Order> findByStatus(String status);
}
```

### 3. Business Logic in Repository

```java
// BAD - Business logic in Repository
@Repository
public class OrderRepository {
    public Order save(Order order) {
        // Business logic in Repository - WRONG!
        if (order.getTotal() > 10000) {
            order.setStatus("PENDING_APPROVAL");
        }

        if (order.getCustomer().isVIP()) {
            order.setDiscount(0.10);
        }

        return entityManager.persist(order);
    }
}

// GOOD - Business logic in Service
@Service
public class OrderService {
    @Autowired
    private OrderRepository orderRepository;

    @Transactional
    public Order createOrder(Order order) {
        // Business logic in Service layer
        if (order.getTotal() > 10000) {
            order.setStatus("PENDING_APPROVAL");
        }

        if (order.getCustomer().isVIP()) {
            applyVIPDiscount(order);
        }

        return orderRepository.save(order);
    }
}

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    // Pure data access, no business logic
}
```

### 4. Domain Entity Importing UI Classes

```java
// BAD - Domain depends on Presentation
@Entity
public class User {
    @Id
    private Long id;

    // WRONG! Domain entity importing UI dependency
    public UserDTO toDTO() {  // DTO is presentation concern
        return new UserDTO(this.id, this.name);
    }
}

// GOOD - Mapper in appropriate layer
@Entity
public class User {
    @Id
    private Long id;
    private String name;
    // Pure domain, no UI dependencies
}

@Component
public class UserMapper {  // In presentation or service layer
    public UserDTO toDTO(User user) {
        return new UserDTO(user.getId(), user.getName());
    }
}
```

### 5. Repository Calling External Services

```java
// BAD - Repository calling external service
@Repository
public class OrderRepository {
    @Autowired
    private PaymentService paymentService;  // WRONG!

    public Order save(Order order) {
        paymentService.processPayment(order);  // External call in repository
        return entityManager.persist(order);
    }
}

// GOOD - Service orchestrates
@Service
public class OrderService {
    @Autowired
    private OrderRepository orderRepository;
    @Autowired
    private PaymentService paymentService;

    @Transactional
    public Order createOrder(Order order) {
        paymentService.processPayment(order);  // Service orchestrates
        return orderRepository.save(order);
    }
}
```

## Detection Patterns

### Import Analysis

```java
// Controller importing Repository = violation
import com.example.repository.UserRepository;  // In Controller - BAD

// Controller importing Service = correct
import com.example.service.UserService;  // In Controller - GOOD

// Domain importing DTO = violation
import com.example.dto.UserDTO;  // In Entity - BAD

// Repository with business logic keywords
// In Repository: if (total > threshold), calculateDiscount(), applyRules() = BAD
```

### Check for:
1. **@Controller** class with **@Autowired Repository**
2. **@Repository** with business logic (if/switch on domain rules)
3. **@Entity** importing presentation packages (dto, controller)
4. **Database access** outside Repository layer (JdbcTemplate, EntityManager in Service/Controller)

## Proper Layer Responsibilities

### Presentation Layer
- HTTP handling
- Request/response mapping
- Input validation (format)
- Authentication/authorization
- DTO conversion

### Service Layer
- Business logic
- Transaction management
- Business validation
- Service orchestration
- External service calls

### Data Access Layer
- Database operations (CRUD)
- Query construction
- Transaction participation
- Data mapping (entity ↔ database)

### Domain Layer
- Business entities
- Value objects
- Domain logic (entity methods)
- No dependencies on other layers

## Severity Guidelines

**HIGH:**
- Controller directly using Repository
- SQL queries in Controller
- Business logic in Repository
- Domain entities importing UI classes

**MEDIUM:**
- Missing Service layer
- Business logic scattered across layers
- Unclear layer boundaries

**LOW:**
- Minor coupling
- DTO placement
- Utility class location

## Benefits of Proper Layering

1. **Testability**: Each layer can be tested independently
2. **Maintainability**: Changes isolated to one layer
3. **Reusability**: Service layer can be used by multiple controllers
4. **Flexibility**: Can swap implementations (REST → GraphQL)

## Fix Template

```java
// Proper 3-layer architecture

// 1. Controller (Presentation)
@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUser(@PathVariable Long id) {
        UserDTO user = userService.getUser(id);
        return ResponseEntity.ok(user);
    }
}

// 2. Service (Business Logic)
@Service
@Transactional
public class UserService {
    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public UserDTO getUser(Long id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new UserNotFoundException(id));

        // Business logic here
        if (user.isInactive()) {
            throw new UserInactiveException();
        }

        return userMapper.toDTO(user);
    }
}

// 3. Repository (Data Access)
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Pure data access, no business logic
    Optional<User> findByEmail(String email);
}

// 4. Domain
@Entity
public class User {
    @Id
    private Long id;
    private String name;
    private boolean active;

    // Domain methods
    public boolean isInactive() {
        return !active;
    }
}
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "LAYER_VIOLATION",
  "violation_type": "CONTROLLER_TO_REPOSITORY",
  "evidence": "@RestController UserController { @Autowired UserRepository userRepository; }",
  "impact": "Bypasses business logic layer. No transaction management, validation, or business rules applied. Difficult to test and maintain.",
  "recommendation": "Introduce UserService layer between Controller and Repository. Move business logic to Service."
}
```
