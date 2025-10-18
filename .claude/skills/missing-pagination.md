---
name: missing-pagination
type: skill
category: api_design
progressive_disclosure: true
---

# Missing Pagination Detection Skill

## Activation
Triggered when @api-design-agent encounters list endpoints returning collections.

## Problem
Returning all records in a single response:
- **Memory**: OutOfMemoryError with large datasets
- **Performance**: Slow queries (SELECT * FROM users → 1M rows)
- **Network**: Huge response payloads (MBs of JSON)
- **User Experience**: Long wait times, browser hangs

## Detection Patterns

### Java/Spring Boot
```java
// BAD - Returns all records
@GetMapping("/users")
public List<User> getUsers() {
    return userRepository.findAll();  // Could be 100,000+ users!
}

// BAD - List with no size limit
@GetMapping("/orders")
public List<Order> getOrders() {
    return orderRepository.findAll();
}

// GOOD - With pagination (Pageable)
@GetMapping("/users")
public Page<User> getUsers(Pageable pageable) {
    return userRepository.findAll(pageable);
}

// GOOD - Explicit page parameters
@GetMapping("/users")
public Page<User> getUsers(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "20") int size,
    @RequestParam(defaultValue = "id") String sortBy
) {
    PageRequest pageRequest = PageRequest.of(page, size, Sort.by(sortBy));
    return userRepository.findAll(pageRequest);
}

// RESPONSE includes metadata
{
  "content": [...],
  "page": {
    "size": 20,
    "number": 0,
    "totalElements": 1000,
    "totalPages": 50
  }
}
```

### Python/Django REST Framework
```python
# BAD - Returns all records
@api_view(['GET'])
def get_users(request):
    users = User.objects.all()  # Could be 100,000+ users!
    serializer = UserSerializer(users, many=True)
    return Response(serializer.data)

# GOOD - With pagination
from rest_framework.pagination import PageNumberPagination

class UserPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    pagination_class = UserPagination

# Or in settings.py
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20
}
```

### Python/Flask
```python
# BAD - Returns all records
@app.route('/users')
def get_users():
    users = User.query.all()  # All users!
    return jsonify([user.to_dict() for user in users])

# GOOD - With pagination
@app.route('/users')
def get_users():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)

    pagination = User.query.paginate(
        page=page,
        per_page=per_page,
        error_out=False
    )

    return jsonify({
        'items': [user.to_dict() for user in pagination.items],
        'total': pagination.total,
        'pages': pagination.pages,
        'page': page,
        'per_page': per_page
    })
```

### JavaScript/Express + Sequelize
```javascript
// BAD - Returns all records
app.get('/users', async (req, res) => {
    const users = await User.findAll();  // All users!
    res.json(users);
});

// GOOD - With pagination
app.get('/users', async (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const { count, rows } = await User.findAndCountAll({
        limit,
        offset,
        order: [['createdAt', 'DESC']]
    });

    res.json({
        data: rows,
        pagination: {
            total: count,
            page,
            limit,
            totalPages: Math.ceil(count / limit)
        }
    });
});
```

### JavaScript/Express + Mongoose
```javascript
// BAD - Returns all records
app.get('/users', async (req, res) => {
    const users = await User.find();  // All users!
    res.json(users);
});

// GOOD - With pagination
app.get('/users', async (req, res) => {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
        User.find()
            .limit(limit)
            .skip(skip)
            .sort({ createdAt: -1 }),
        User.countDocuments()
    ]);

    res.json({
        data: users,
        pagination: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit)
        }
    });
});
```

### Go - Gin + GORM
```go
// BAD - Returns all records
func GetUsers(c *gin.Context) {
    var users []User
    db.Find(&users)  // All users!
    c.JSON(http.StatusOK, users)
}

// GOOD - With pagination
type PaginationParams struct {
    Page  int `form:"page,default=1"`
    Limit int `form:"limit,default=20"`
}

type PaginatedResponse struct {
    Data       interface{} `json:"data"`
    Total      int64       `json:"total"`
    Page       int         `json:"page"`
    Limit      int         `json:"limit"`
    TotalPages int         `json:"totalPages"`
}

func GetUsers(c *gin.Context) {
    var params PaginationParams
    if err := c.ShouldBindQuery(&params); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    var users []User
    var total int64

    offset := (params.Page - 1) * params.Limit

    db.Model(&User{}).Count(&total)
    db.Offset(offset).Limit(params.Limit).Find(&users)

    c.JSON(http.StatusOK, PaginatedResponse{
        Data:       users,
        Total:      total,
        Page:       params.Page,
        Limit:      params.Limit,
        TotalPages: int(math.Ceil(float64(total) / float64(params.Limit))),
    })
}
```

## Pagination Strategies

### 1. Offset-Based (Page Number)
```
?page=2&size=20
```
**Pros:** Simple, direct page access
**Cons:** Performance degrades with deep pagination (OFFSET 10000)

### 2. Cursor-Based (Keyset)
```
?cursor=eyJpZCI6MTAwfQ==&limit=20
```
**Pros:** Consistent performance, handles real-time data
**Cons:** No direct page access, complex implementation

### 3. Seek Method
```
?since_id=100&limit=20
```
**Pros:** Fast, simple
**Cons:** Only forward pagination

## Default Page Sizes

### Recommendations
- **Default**: 20-50 items
- **Max**: 100-200 items
- **Mobile**: 10-20 items (smaller screens)
- **Admin**: 50-100 items (power users)

### By Use Case
- **Social feed**: 10-20 posts
- **Search results**: 10-25 results
- **Admin tables**: 25-100 rows
- **API**: 20-50 items
- **Autocomplete**: 5-10 suggestions

## Response Format Standards

### Standard Pagination Response
```json
{
  "data": [...],
  "pagination": {
    "total": 1000,
    "page": 1,
    "limit": 20,
    "totalPages": 50
  },
  "links": {
    "first": "/users?page=1",
    "prev": null,
    "next": "/users?page=2",
    "last": "/users?page=50"
  }
}
```

### Cursor-Based Response
```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MjB9",
    "prev_cursor": null,
    "has_more": true
  }
}
```

## Detection Rules

### Check for:
1. **List return type** without Page/Pageable
2. **findAll()** without pagination parameters
3. **GET endpoints** returning collections
4. **No limit** in query methods

### Exclude:
- Dropdown/select options (< 100 items)
- Admin-only endpoints (if documented)
- Lookup tables (countries, states)
- Internal APIs with size guarantees

## Severity Guidelines

**HIGH:**
- Public API returning unbounded lists
- User-facing endpoints
- Tables with 1000+ rows
- No pagination on collections

**MEDIUM:**
- Internal API without pagination
- Tables with 100-1000 rows
- Pagination exists but no max limit

**LOW:**
- Small tables (< 100 rows)
- Admin-only endpoints
- Lookup/reference data

## Performance Impact

### Without Pagination
```
Table: 100,000 users
Query: SELECT * FROM users
Time: 5 seconds
Memory: 500 MB
Response: 50 MB JSON
```

### With Pagination
```
Table: 100,000 users
Query: SELECT * FROM users LIMIT 20 OFFSET 0
Time: 50 ms
Memory: 1 MB
Response: 10 KB JSON
```

## Fix Template

### Java/Spring Boot
```java
// Add Pageable parameter
@GetMapping("/users")
public Page<UserDTO> getUsers(
    @PageableDefault(size = 20, sort = "id") Pageable pageable
) {
    Page<User> users = userRepository.findAll(pageable);
    return users.map(userMapper::toDTO);
}

// Repository automatically supports pagination
public interface UserRepository extends JpaRepository<User, Long> {
    // findAll(Pageable) inherited
    Page<User> findByStatus(String status, Pageable pageable);
}
```

### Python/Django
```python
# Use PageNumberPagination
from rest_framework.pagination import PageNumberPagination

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100

class UserViewSet(viewsets.ModelViewSet):
    pagination_class = StandardResultsSetPagination
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "MISSING_PAGINATION",
  "evidence": "@GetMapping(\"/users\") public List<User> getUsers()",
  "impact": "Memory exhaustion with 100,000+ users. Response size: 50+ MB. Query time: 5+ seconds. Poor user experience.",
  "recommendation": "Add Pageable parameter: public Page<User> getUsers(Pageable pageable)"
}
```
