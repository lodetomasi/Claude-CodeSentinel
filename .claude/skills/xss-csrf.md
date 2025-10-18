---
name: xss-csrf
type: skill
category: security
---

# XSS and CSRF Detection Skill

## Cross-Site Scripting (XSS)

### Detection Patterns

**Java:**
```java
// BAD - XSS vulnerability
response.getWriter().write("<div>" + userInput + "</div>");
model.addAttribute("message", userInput);  // If rendered unescaped

// GOOD - Escaped output
response.getWriter().write(StringEscapeUtils.escapeHtml4(userInput));
```

**JavaScript:**
```javascript
// BAD - XSS vulnerability
element.innerHTML = userInput;
div.outerHTML = `<div>${userInput}</div>`;

// React BAD
<div dangerouslySetInnerHTML={{__html: userInput}} />

// GOOD - Text content (auto-escaped)
element.textContent = userInput;

// React GOOD - Auto-escaped
<div>{userInput}</div>
```

**Python:**
```python
# BAD - XSS in template
return f"<div>{user_input}</div>"

# GOOD - Use template engine with auto-escape
return render_template('page.html', message=user_input)
```

### Severity
- **CRITICAL**: User input directly rendered as HTML
- **HIGH**: innerHTML usage without sanitization

## Cross-Site Request Forgery (CSRF)

### Detection Patterns

**Java/Spring:**
```java
// BAD - CSRF disabled
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable();  // DANGEROUS
    }
}

// GOOD - CSRF enabled (default)
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf();  // Enabled
    }
}
```

**JavaScript:**
```javascript
// GOOD - Include CSRF token
fetch('/api/transfer', {
    method: 'POST',
    headers: {
        'X-CSRF-Token': getCsrfToken()
    },
    body: JSON.stringify(data)
});
```

### Severity
- **CRITICAL**: State-changing operations without CSRF protection
- **HIGH**: CSRF disabled globally

## Fix Templates

### Sanitize HTML Output
```java
// Use OWASP Java Encoder
String safe = Encode.forHtml(userInput);

// Or Spring's HtmlUtils
String safe = HtmlUtils.htmlEscape(userInput);
```

### Enable CSRF Protection
```java
// Ensure CSRF is enabled
http.csrf();
```
