---
name: auth-bypass
type: skill
category: security
---

# Authentication Bypass Detection Skill

## Detection Patterns

### Missing Authentication

**Java/Spring:**
```java
// BAD - No authentication required
@RestController
public class UserController {
    @GetMapping("/users/{id}")
    public User getUser(@PathVariable Long id) {
        return userService.getUser(id);  // Anyone can access!
    }
}

// GOOD - Authentication required
@RestController
public class UserController {
    @GetMapping("/users/{id}")
    @PreAuthorize("isAuthenticated()")
    public User getUser(@PathVariable Long id) {
        return userService.getUser(id);
    }
}
```

**Python/Django:**
```python
# BAD - No authentication
def get_user(request, user_id):
    user = User.objects.get(id=user_id)
    return JsonResponse(user.to_dict())

# GOOD - Authentication required
from django.contrib.auth.decorators import login_required

@login_required
def get_user(request, user_id):
    user = User.objects.get(id=user_id)
    return JsonResponse(user.to_dict())
```

**Python/Flask:**
```python
# BAD - No authentication
@app.route('/users/<int:user_id>')
def get_user(user_id):
    user = User.query.get(user_id)
    return jsonify(user.to_dict())

# GOOD - Authentication required
from flask_login import login_required

@app.route('/users/<int:user_id>')
@login_required
def get_user(user_id):
    user = User.query.get(user_id)
    return jsonify(user.to_dict())
```

### Missing Authorization (IDOR)

```java
// BAD - No ownership check (Insecure Direct Object Reference)
@GetMapping("/orders/{id}")
@PreAuthorize("isAuthenticated()")
public Order getOrder(@PathVariable Long id, Principal principal) {
    return orderService.getOrder(id);
    // User can access ANY order, not just their own!
}

// GOOD - Check ownership
@GetMapping("/orders/{id}")
@PreAuthorize("isAuthenticated()")
public Order getOrder(@PathVariable Long id, Principal principal) {
    Order order = orderService.getOrder(id);
    if (!order.getUserId().equals(getCurrentUserId(principal))) {
        throw new AccessDeniedException("Not your order");
    }
    return order;
}

// BETTER - Query by user and ID
@GetMapping("/orders/{id}")
@PreAuthorize("isAuthenticated()")
public Order getOrder(@PathVariable Long id, Principal principal) {
    Long userId = getCurrentUserId(principal);
    return orderService.getOrderByIdAndUserId(id, userId);
    // Query ensures ownership
}
```

### Weak Password Requirements

```java
// BAD - No password validation
public void createUser(String username, String password) {
    User user = new User(username, password);
    userRepository.save(user);
}

// GOOD - Password validation
public void createUser(String username, String password) {
    if (password.length() < 12) {
        throw new IllegalArgumentException("Password must be at least 12 characters");
    }
    if (!password.matches(".*[A-Z].*")) {
        throw new IllegalArgumentException("Password must contain uppercase");
    }
    if (!password.matches(".*[a-z].*")) {
        throw new IllegalArgumentException("Password must contain lowercase");
    }
    if (!password.matches(".*[0-9].*")) {
        throw new IllegalArgumentException("Password must contain digit");
    }
    if (!password.matches(".*[!@#$%^&*].*")) {
        throw new IllegalArgumentException("Password must contain special character");
    }

    String hashedPassword = passwordEncoder.encode(password);
    User user = new User(username, hashedPassword);
    userRepository.save(user);
}
```

## Detection Rules

### Check for:
1. **Public endpoints** without @PreAuthorize/@Secured/@RolesAllowed
2. **State-changing operations** (POST/PUT/DELETE) without auth
3. **Direct object access** without ownership validation
4. **Admin operations** without role check

### Exclude:
- Login/register endpoints
- Public health checks
- Static resources
- Explicitly public APIs (documented)

## Severity Guidelines

**CRITICAL:**
- Admin endpoints without authentication
- Financial operations without authorization
- User data accessible without ownership check (IDOR)

**HIGH:**
- Protected endpoints without authentication
- State-changing operations without auth
- Missing role-based access control

**MEDIUM:**
- Read-only endpoints without auth
- Weak password requirements
- Missing rate limiting on auth endpoints

## Fix Templates

### Add Authentication
```java
// Spring Security
@PreAuthorize("isAuthenticated()")
@PreAuthorize("hasRole('ADMIN')")
@PreAuthorize("hasAnyRole('USER', 'ADMIN')")
```

### Add Authorization
```java
// Check ownership
@PreAuthorize("@securityService.canAccessOrder(#id)")
public Order getOrder(@PathVariable Long id) {
    return orderService.getOrder(id);
}

@Service
public class SecurityService {
    public boolean canAccessOrder(Long orderId) {
        Order order = orderService.getOrder(orderId);
        Long currentUserId = getCurrentUserId();
        return order.getUserId().equals(currentUserId);
    }
}
```
