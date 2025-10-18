---
name: missing-cache
type: skill
category: performance
---

# Missing Cache Detection Skill

## When to Cache

### Good Caching Candidates
- Expensive computations (complex calculations)
- Slow database queries (reports, aggregations)
- External API calls (third-party services)
- Static/rarely changing data (categories, countries)
- Frequently accessed data (user profiles)

### Don't Cache
- Fast queries (< 10ms)
- Frequently changing data (real-time prices)
- Large datasets (memory issue)
- User-specific sensitive data (privacy)

## Detection Patterns

### Java/Spring

```java
// BAD - Repeated expensive query
@Service
public class ProductService {
    public List<Category> getCategories() {
        return categoryRepository.findAll();  // DB query every time
        // Called 100 times per page = 100 DB queries!
    }
}

// GOOD - With cache
@Service
public class ProductService {
    @Cacheable("categories")
    public List<Category> getCategories() {
        return categoryRepository.findAll();  // DB query only first time
        // Subsequent calls return cached result
    }
}

// Configuration
@Configuration
@EnableCaching
public class CacheConfig {
    @Bean
    public CacheManager cacheManager() {
        return new ConcurrentMapCacheManager("categories", "products");
    }
}
```

### Cache with Key

```java
// Cache per user
@Cacheable(value = "userOrders", key = "#userId")
public List<Order> getUserOrders(Long userId) {
    return orderRepository.findByUserId(userId);
}

// Cache with complex key
@Cacheable(value = "products", key = "#category + '-' + #brand")
public List<Product> getProducts(String category, String brand) {
    return productRepository.findByCategoryAndBrand(category, brand);
}
```

### Cache Eviction

```java
// Evict cache on update
@CacheEvict(value = "userOrders", key = "#order.userId")
public Order createOrder(Order order) {
    return orderRepository.save(order);
}

// Evict all entries
@CacheEvict(value = "categories", allEntries = true)
public void updateCategories() {
    // Update logic
}

// Update cache
@CachePut(value = "users", key = "#user.id")
public User updateUser(User user) {
    return userRepository.save(user);
}
```

### Python/Django

```python
# BAD - Repeated query
def get_categories(request):
    categories = Category.objects.all()  # DB query every request
    return render(request, 'page.html', {'categories': categories})

# GOOD - With cache
from django.core.cache import cache

def get_categories(request):
    categories = cache.get('categories')
    if categories is None:
        categories = list(Category.objects.all())
        cache.set('categories', categories, timeout=3600)  # 1 hour
    return render(request, 'page.html', {'categories': categories})

# Or with decorator
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # 15 minutes
def category_list(request):
    categories = Category.objects.all()
    return render(request, 'categories.html', {'categories': categories})
```

### JavaScript/Node.js

```javascript
// BAD - Repeated API call
async function getExchangeRate(currency) {
    const response = await axios.get(`https://api.exchange/rate/${currency}`);
    return response.data.rate;
    // Called 1000 times = 1000 API calls!
}

// GOOD - With cache (node-cache)
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 3600 });  // 1 hour TTL

async function getExchangeRate(currency) {
    const cached = cache.get(currency);
    if (cached) {
        return cached;
    }

    const response = await axios.get(`https://api.exchange/rate/${currency}`);
    const rate = response.data.rate;
    cache.set(currency, rate);
    return rate;
}
```

### Redis Cache

```java
// Spring Boot with Redis
@Configuration
@EnableCaching
public class RedisCacheConfig {
    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(60))
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));

        return RedisCacheManager.builder(connectionFactory)
            .cacheDefaults(config)
            .build();
    }
}
```

## Cache Strategies

### 1. Cache-Aside (Lazy Loading)
```java
// Application checks cache first
public Product getProduct(Long id) {
    Product product = cache.get("product:" + id);
    if (product == null) {
        product = database.findById(id);
        cache.set("product:" + id, product);
    }
    return product;
}
```

### 2. Write-Through
```java
// Write to cache and database together
public void updateProduct(Product product) {
    database.save(product);
    cache.set("product:" + product.getId(), product);
}
```

### 3. Write-Behind (Write-Back)
```java
// Write to cache, async write to database
public void updateProduct(Product product) {
    cache.set("product:" + product.getId(), product);
    asyncQueue.add(() -> database.save(product));
}
```

## TTL (Time To Live) Guidelines

### By Data Type
- **Static data**: 24 hours (countries, categories)
- **Semi-static**: 1-6 hours (product catalogs)
- **Dynamic**: 5-15 minutes (prices, inventory)
- **Very dynamic**: 30-60 seconds (stock quotes)
- **Session data**: Session duration

### Example Configuration
```java
@Cacheable(value = "categories", key = "#root.methodName")  // 24h
@Cacheable(value = "products", key = "#id")  // 1h
@Cacheable(value = "prices", key = "#productId")  // 5m
```

## Cache Invalidation Strategies

### 1. Time-Based (TTL)
```java
cache.set("key", value, Duration.ofHours(1));
```

### 2. Event-Based
```java
@CacheEvict(value = "products", key = "#product.id")
public Product updateProduct(Product product) {
    return productRepository.save(product);
}
```

### 3. Manual Invalidation
```java
@CacheEvict(value = "products", allEntries = true)
public void clearProductCache() {
    // Cache cleared
}
```

## Common Cache Issues

### 1. Cache Stampede
```java
// Problem: When cache expires, 100 concurrent requests hit DB
// Solution: Lock or use single-flight pattern

private final Map<String, CompletableFuture<Product>> loading = new ConcurrentHashMap<>();

public Product getProduct(Long id) {
    Product cached = cache.get(id);
    if (cached != null) return cached;

    return loading.computeIfAbsent(id.toString(), key ->
        CompletableFuture.supplyAsync(() -> {
            Product product = database.findById(id);
            cache.set(id, product);
            return product;
        })
    ).join();
}
```

### 2. Stale Data
```java
// Ensure cache is invalidated on updates
@CacheEvict(value = "users", key = "#user.id")
public User updateUser(User user) {
    return userRepository.save(user);
}
```

### 3. Memory Overflow
```java
// Limit cache size
CacheBuilder.newBuilder()
    .maximumSize(10000)
    .expireAfterWrite(1, TimeUnit.HOURS)
    .build();
```

## Detection Rules

### Look for:
1. **Repeated database queries** in loops
2. **External API calls** without caching
3. **Expensive computations** called multiple times
4. **Static data queries** (categories, countries)
5. **High read-to-write ratio** (read 100x more than write)

### Check for:
- @Cacheable annotation
- cache.get() / cache.set()
- Redis/Memcached usage
- Cache configuration

## Severity Guidelines

**HIGH:**
- Expensive query called 100+ times per request
- External API called repeatedly
- Static data queried every time
- Performance bottleneck identified

**MEDIUM:**
- Expensive query called 10-100 times
- Moderate performance impact
- Semi-static data without cache

**LOW:**
- Fast query (< 10ms)
- Infrequent access
- Small optimization opportunity

## Performance Impact

### Example: Product Categories

**Without Cache:**
```
Requests: 1000/sec
DB queries: 1000/sec
DB time: 50ms per query
Total: 50,000ms CPU time
```

**With Cache:**
```
Requests: 1000/sec
Cache hits: 999/sec (0.1ms each)
Cache misses: 1/sec (50ms)
Total: 150ms CPU time
Improvement: 333x faster
```

## Fix Template

```java
// Add caching
@Configuration
@EnableCaching
public class CacheConfig {
    @Bean
    public CacheManager cacheManager() {
        return new ConcurrentMapCacheManager("products", "categories");
    }
}

@Service
public class ProductService {
    @Cacheable("products")
    public Product getProduct(Long id) {
        return productRepository.findById(id);
    }

    @CacheEvict(value = "products", key = "#product.id")
    public Product updateProduct(Product product) {
        return productRepository.save(product);
    }
}
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "MISSING_CACHE",
  "evidence": "categoryRepository.findAll() called in loop",
  "frequency": "Called 100 times per request",
  "query_time": "50ms per call",
  "impact": "5000ms total query time. With cache: 50ms (100x improvement)",
  "recommendation": "Add @Cacheable('categories') with 1 hour TTL"
}
```
