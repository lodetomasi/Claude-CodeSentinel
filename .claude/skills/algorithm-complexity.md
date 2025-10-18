---
name: algorithm-complexity
type: skill
category: performance
---

# Algorithm Complexity Detection Skill

## Big-O Complexity

### Common Complexities (Best to Worst)
- **O(1)**: Constant - Hash map lookup, array access
- **O(log n)**: Logarithmic - Binary search
- **O(n)**: Linear - Single loop, sequential search
- **O(n log n)**: Linearithmic - Efficient sorting (merge sort, quicksort)
- **O(n²)**: Quadratic - Nested loops
- **O(n³)**: Cubic - Triple nested loops
- **O(2^n)**: Exponential - Recursive fibonacci
- **O(n!)**: Factorial - Traveling salesman brute force

## Detection Patterns

### O(n²) - Nested Loops

```java
// BAD - O(n²)
public List<String> findDuplicates(List<String> items) {
    List<String> duplicates = new ArrayList<>();
    for (int i = 0; i < items.size(); i++) {          // O(n)
        for (int j = i + 1; j < items.size(); j++) {  // O(n)
            if (items.get(i).equals(items.get(j))) {
                duplicates.add(items.get(i));
            }
        }
    }
    return duplicates;
}
// Time: n × n = O(n²)
// For 1000 items: 1,000,000 comparisons

// GOOD - O(n) with HashSet
public List<String> findDuplicates(List<String> items) {
    Set<String> seen = new HashSet<>();
    List<String> duplicates = new ArrayList<>();
    for (String item : items) {  // O(n)
        if (!seen.add(item)) {   // O(1) hash lookup
            duplicates.add(item);
        }
    }
    return duplicates;
}
// Time: n × 1 = O(n)
// For 1000 items: 1,000 operations (1000x faster)
```

### O(n³) - Triple Nested Loops

```java
// BAD - O(n³)
public int countTriplets(int[] arr, int sum) {
    int count = 0;
    for (int i = 0; i < arr.length; i++) {          // O(n)
        for (int j = i + 1; j < arr.length; j++) {  // O(n)
            for (int k = j + 1; k < arr.length; k++) {  // O(n)
                if (arr[i] + arr[j] + arr[k] == sum) {
                    count++;
                }
            }
        }
    }
    return count;
}
// Time: O(n³)
// For 100 items: 1,000,000 operations

// GOOD - O(n²) with two pointers
public int countTriplets(int[] arr, int sum) {
    Arrays.sort(arr);  // O(n log n)
    int count = 0;
    for (int i = 0; i < arr.length - 2; i++) {  // O(n)
        int left = i + 1;
        int right = arr.length - 1;
        while (left < right) {  // O(n)
            int currentSum = arr[i] + arr[left] + arr[right];
            if (currentSum == sum) {
                count++;
                left++;
                right--;
            } else if (currentSum < sum) {
                left++;
            } else {
                right--;
            }
        }
    }
    return count;
}
// Time: O(n² + n log n) = O(n²)
// For 100 items: ~10,000 operations (100x faster)
```

### Linear Search vs Binary Search

```java
// BAD - O(n) linear search on sorted array
public boolean contains(int[] sortedArray, int target) {
    for (int num : sortedArray) {  // O(n)
        if (num == target) {
            return true;
        }
    }
    return false;
}
// For 1,000,000 items: up to 1,000,000 comparisons

// GOOD - O(log n) binary search
public boolean contains(int[] sortedArray, int target) {
    return Arrays.binarySearch(sortedArray, target) >= 0;
}
// For 1,000,000 items: ~20 comparisons (50,000x faster)
```

### Inefficient String Concatenation

```java
// BAD - O(n²) due to String immutability
public String concatenate(List<String> words) {
    String result = "";
    for (String word : words) {  // O(n)
        result += word;  // O(n) creates new string each time
    }
    return result;
}
// Time: O(n²)
// For 1000 words: creates 1000 intermediate strings

// GOOD - O(n) with StringBuilder
public String concatenate(List<String> words) {
    StringBuilder result = new StringBuilder();
    for (String word : words) {  // O(n)
        result.append(word);  // O(1) amortized
    }
    return result.toString();
}
// Time: O(n)
// For 1000 words: single buffer, much faster
```

### List.contains() in Loop

```java
// BAD - O(n²)
public List<Integer> filterDuplicates(List<Integer> items) {
    List<Integer> unique = new ArrayList<>();
    for (Integer item : items) {  // O(n)
        if (!unique.contains(item)) {  // O(n) linear search
            unique.add(item);
        }
    }
    return unique;
}
// Time: O(n²)

// GOOD - O(n) with HashSet
public List<Integer> filterDuplicates(List<Integer> items) {
    return new ArrayList<>(new HashSet<>(items));
}
// Time: O(n)
```

### Sorting Inside Loop

```java
// BAD - O(n² log n)
public void processInOrder(List<Item> items) {
    for (Item item : items) {  // O(n)
        Collections.sort(items);  // O(n log n)
        // Process item...
    }
}
// Sorts list n times!

// GOOD - O(n log n)
public void processInOrder(List<Item> items) {
    Collections.sort(items);  // O(n log n) once
    for (Item item : items) {  // O(n)
        // Process item...
    }
}
```

## Detection Rules

### High Complexity Patterns
1. **Nested loops**: `for (...) { for (...) { } }`
2. **List.contains() in loop**: Linear search per iteration
3. **String concatenation in loop**: Creates new string each time
4. **Sorting in loop**: Re-sorting already sorted data
5. **Database query in loop**: N+1 query problem

### Optimization Opportunities
- Replace nested loops with hash maps/sets
- Use binary search on sorted data
- Cache computed values
- Use appropriate data structures
- Batch operations

## Performance Impact

### Example: Finding Duplicates in 10,000 Items

**O(n²) approach:**
```
10,000 × 10,000 = 100,000,000 operations
Time: ~10 seconds
```

**O(n) approach:**
```
10,000 × 1 = 10,000 operations
Time: ~10 milliseconds
Improvement: 1000x faster
```

## Data Structure Complexity

### ArrayList vs HashSet
```java
// ArrayList - O(n) for contains()
List<String> list = new ArrayList<>();
list.contains("item");  // O(n) - scans entire list

// HashSet - O(1) for contains()
Set<String> set = new HashSet<>();
set.contains("item");  // O(1) - hash lookup
```

### TreeMap vs HashMap
```java
// HashMap - O(1) average
map.get(key);  // O(1)

// TreeMap - O(log n)
map.get(key);  // O(log n) - binary search tree

// Use TreeMap only if you need sorted keys
```

## Severity Guidelines

**CRITICAL:**
- O(n³) or worse in production code
- O(n²) with large datasets (n > 1000)
- Exponential complexity
- Performance regression causing outages

**HIGH:**
- O(n²) in user-facing operations
- Linear search on sorted data
- Inefficient algorithm with better alternative
- Database query in loop

**MEDIUM:**
- O(n²) in background jobs
- Suboptimal but acceptable performance
- Small datasets (n < 100)

**LOW:**
- Premature optimization
- Theoretical inefficiency, no real impact
- One-time operations

## Fix Templates

### Replace Nested Loop with Hash Map
```java
// Before: O(n²)
for (int i = 0; i < list1.size(); i++) {
    for (int j = 0; j < list2.size(); j++) {
        if (list1.get(i).equals(list2.get(j))) {
            // Found match
        }
    }
}

// After: O(n)
Set<String> set2 = new HashSet<>(list2);
for (String item : list1) {
    if (set2.contains(item)) {
        // Found match
    }
}
```

### Use Appropriate Data Structure
```java
// Before: ArrayList with contains()
List<String> list = new ArrayList<>();
for (String item : items) {
    if (!list.contains(item)) {  // O(n)
        list.add(item);
    }
}

// After: HashSet
Set<String> set = new HashSet<>(items);  // O(n)
```

## Output Format
```json
{
  "severity": "HIGH",
  "category": "INEFFICIENT_ALGORITHM",
  "complexity": "O(n²)",
  "evidence": "Nested loops: for(items1) { for(items2) { ... } }",
  "estimated_size": "n = 1000",
  "impact": "1,000,000 operations instead of 1,000. Estimated time: 10s vs 10ms (1000x slower)",
  "recommendation": "Replace nested loops with HashSet for O(n) complexity"
}
```
