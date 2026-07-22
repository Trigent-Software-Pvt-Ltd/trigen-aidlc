# CWE Top 25 Most Dangerous Software Weaknesses (2023)

This document provides a reference for the CWE Top 25 - the most common and impactful software weaknesses that lead to serious vulnerabilities.

Reference: https://cwe.mitre.org/top25/

---

## Understanding CWE

**Common Weakness Enumeration (CWE)** is a community-developed list of software and hardware weakness types. It serves as a common language for describing security weaknesses in architecture, design, or code.

**Ranking Methodology:**
The Top 25 is calculated from real-world vulnerability data from the National Vulnerability Database (NVD), weighted by:
- Prevalence (how often it occurs)
- Severity (CVSS scores)

---

## Top 25 Dangerous Software Weaknesses

### [1] CWE-787: Out-of-bounds Write

**Rank:** #1 | **Score:** 65.93

**Description:**
The product writes data past the end or before the beginning of the intended buffer.

**Languages Affected:** C, C++, Assembly

**Example:**
```c
char buffer[10];
strcpy(buffer, "This string is way too long");  // Buffer overflow!
```

**Impact:**
- Memory corruption
- Code execution
- Crashes/DoS
- Information disclosure

**Prevention:**
- Use safe string functions (strncpy, snprintf)
- Bounds checking before writes
- Use memory-safe languages (Rust, Go)
- Enable stack canaries and ASLR

**OWASP Mapping:** Related to A01 (Broken Access Control), A04 (Insecure Design)

---

### [2] CWE-79: Cross-site Scripting (XSS)

**Rank:** #2 | **Score:** 46.84

**Description:**
The product does not neutralize or incorrectly neutralizes user-controllable input before it is placed in output that is used as a web page that is served to other users.

**Types:**
- **Stored XSS:** Malicious script stored in database
- **Reflected XSS:** Script in URL parameter reflected back
- **DOM-based XSS:** Client-side script manipulation

**Example:**
```javascript
// Vulnerable code
const username = req.query.name
res.send(`<h1>Welcome ${username}</h1>`)  // XSS!

// Attack: ?name=<script>alert(document.cookie)</script>
```

**Impact:**
- Session hijacking
- Credential theft
- Phishing
- Malware distribution

**Prevention:**
```javascript
// Secure: Output encoding
const username = escapeHTML(req.query.name)
res.send(`<h1>Welcome ${username}</h1>`)

// Or use templating engines with auto-escaping
res.render('welcome', { username })  // Automatically escapes
```

- Content Security Policy (CSP) headers
- HTTPOnly cookies
- Input validation
- Output encoding/escaping

**OWASP Mapping:** A03:2021 - Injection

---

### [3] CWE-89: SQL Injection

**Rank:** #3 | **Score:** 46.17

**Description:**
The product constructs SQL commands from user input without proper neutralization, allowing attackers to modify SQL queries.

**Example:**
```javascript
// Vulnerable
const query = `SELECT * FROM users WHERE id = ${userId}`
db.query(query)

// Secure: Parameterized query
const query = 'SELECT * FROM users WHERE id = ?'
db.query(query, [userId])
```

**Common Attacks:**
- Authentication bypass: `' OR '1'='1`
- Data extraction: `' UNION SELECT * FROM credit_cards --`
- Database modification: `'; DROP TABLE users; --`

**Impact:**
- Data theft
- Data modification/deletion
- Authentication bypass
- Remote code execution (via xp_cmdshell, etc.)

**Prevention:**
- Parameterized queries (prepared statements)
- ORM frameworks
- Stored procedures (with parameters)
- Input validation (allowlists)
- Least privilege database accounts

**OWASP Mapping:** A03:2021 - Injection

---

### [4] CWE-416: Use After Free

**Rank:** #4 | **Score:** 16.71

**Description:**
The product reuses or references memory after it has been freed, leading to memory corruption.

**Languages Affected:** C, C++

**Example:**
```c
char* ptr = malloc(100);
free(ptr);
strcpy(ptr, "data");  // Use after free!
```

**Impact:**
- Code execution
- Memory corruption
- Crashes

**Prevention:**
- Set pointers to NULL after free
- Use smart pointers (C++)
- Memory-safe languages
- Static analysis tools

**OWASP Mapping:** A04:2021 - Insecure Design

---

### [5] CWE-78: OS Command Injection

**Rank:** #5 | **Score:** 15.65

**Description:**
The product constructs OS commands using user input without proper neutralization.

**Example:**
```javascript
// Vulnerable
const filename = req.query.file
exec(`cat ${filename}`)  // Command injection!

// Attack: ?file=file.txt; rm -rf /
```

**Prevention:**
```javascript
// Secure: Use libraries instead of shell commands
const fs = require('fs')
fs.readFile(filename, 'utf8', (err, data) => { ... })

// If shell is necessary: Validate and escape
const { execFile } = require('child_process')
execFile('cat', [filename])  // Array args are safer
```

**OWASP Mapping:** A03:2021 - Injection

---

### [6] CWE-20: Improper Input Validation

**Rank:** #6 | **Score:** 15.50

**Description:**
The product receives input but does not validate or incorrectly validates that the input has properties required for safe processing.

**Example:**
```javascript
// Vulnerable: No validation
app.post('/transfer', (req, res) => {
  const amount = req.body.amount  // Could be negative!
  transferMoney(req.user, amount)
})

// Secure: Validation
const amount = parseInt(req.body.amount)
if (isNaN(amount) || amount <= 0 || amount > 10000) {
  return res.status(400).send('Invalid amount')
}
```

**Prevention:**
- Allowlist validation (preferred over blocklist)
- Type checking
- Range checking
- Format validation (regex)
- Server-side validation (don't trust client)

**OWASP Mapping:** A03:2021 - Injection, A04:2021 - Insecure Design

---

### [7] CWE-125: Out-of-bounds Read

**Rank:** #7 | **Score:** 14.60

**Description:**
The product reads data past the end or before the beginning of the intended buffer.

**Languages Affected:** C, C++

**Example:**
```c
int arr[10];
int value = arr[15];  // Out-of-bounds read!
```

**Impact:**
- Information disclosure
- Crashes
- Potential code execution

**Prevention:**
- Bounds checking
- Safe array access functions
- Memory-safe languages

**OWASP Mapping:** A04:2021 - Insecure Design

---

### [8] CWE-352: Cross-Site Request Forgery (CSRF)

**Rank:** #8 | **Score:** 11.73

**Description:**
The web application does not verify that requests are intentionally provided by the authenticated user.

**Example Attack:**
```html
<!-- Attacker's malicious website -->
<img src="https://bank.com/transfer?to=attacker&amount=1000">
<!-- Executes if victim is logged into bank.com -->
```

**Prevention:**
```javascript
// Use CSRF tokens
const csrf = require('csurf')
app.use(csrf())

app.get('/form', (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() })
})

// Verify on POST
app.post('/transfer', (req, res) => {
  // CSRF middleware automatically verifies token
  transferMoney(...)
})
```

- CSRF tokens
- SameSite cookies
- Custom request headers (for AJAX)
- Verify Origin/Referer headers

**OWASP Mapping:** A01:2021 - Broken Access Control

---

### [9] CWE-434: Unrestricted Upload of File with Dangerous Type

**Rank:** #9 | **Score:** 10.41

**Description:**
The product allows upload of dangerous file types that can be processed or executed.

**Example:**
```javascript
// Vulnerable: No file type checking
app.post('/upload', upload.single('file'), (req, res) => {
  // Attacker uploads malicious.php to webroot
  fs.writeFileSync(`/var/www/${req.file.originalname}`, req.file.buffer)
})
```

**Prevention:**
```javascript
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'application/pdf']

app.post('/upload', upload.single('file'), (req, res) => {
  // Validate MIME type
  if (!ALLOWED_TYPES.includes(req.file.mimetype)) {
    return res.status(400).send('Invalid file type')
  }

  // Validate file extension
  const ext = path.extname(req.file.originalname).toLowerCase()
  if (!['.jpg', '.png', '.pdf'].includes(ext)) {
    return res.status(400).send('Invalid file extension')
  }

  // Use safe filename (don't trust user input)
  const safeFilename = `${uuid.v4()}${ext}`

  // Store outside webroot
  fs.writeFileSync(`/uploads/${safeFilename}`, req.file.buffer)
})
```

**OWASP Mapping:** A04:2021 - Insecure Design, A05:2021 - Security Misconfiguration

---

### [10] CWE-862: Missing Authorization

**Rank:** #10 | **Score:** 6.90

**Description:**
The product does not perform authorization checks when a user attempts to access a resource.

**Example:**
```javascript
// Vulnerable: No authorization check
app.delete('/users/:id', (req, res) => {
  deleteUser(req.params.id)  // Any user can delete any account!
})

// Secure: Authorization check
app.delete('/users/:id', (req, res) => {
  if (req.user.id !== req.params.id && !req.user.isAdmin) {
    return res.status(403).send('Unauthorized')
  }
  deleteUser(req.params.id)
})
```

**OWASP Mapping:** A01:2021 - Broken Access Control

---

### [11] CWE-476: NULL Pointer Dereference

**Rank:** #11 | **Score:** 6.59

**Languages Affected:** C, C++, Java

**Description:**
Dereferencing a null pointer causes crashes or unexpected behavior.

**Prevention:**
- Null checks before dereferencing
- Use Optional types
- Static analysis

**OWASP Mapping:** A04:2021 - Insecure Design

---

### [12] CWE-287: Improper Authentication

**Rank:** #12 | **Score:** 6.39

**Description:**
Product does not prove user identity or incorrectly verifies identity.

**Examples:**
- No password requirement
- Weak password policy
- Hardcoded credentials
- Bypassable authentication

**Prevention:**
- Multi-factor authentication
- Strong password policies
- Proper session management
- No default/hardcoded credentials

**OWASP Mapping:** A07:2021 - Identification and Authentication Failures

---

### [13] CWE-190: Integer Overflow or Wraparound

**Rank:** #13 | **Score:** 5.56

**Description:**
Integer calculations can wrap around, leading to unexpected values.

**Example:**
```c
unsigned int x = UINT_MAX;
x = x + 1;  // Wraps to 0!
```

**Prevention:**
- Range checking
- Use larger integer types
- Safe math libraries

**OWASP Mapping:** A04:2021 - Insecure Design

---

### [14] CWE-502: Deserialization of Untrusted Data

**Rank:** #14 | **Score:** 5.50

**Description:**
Deserializing untrusted data without validation can lead to code execution.

**Example:**
```javascript
// Vulnerable
const userData = deserialize(req.body.data)

// Secure: Use JSON (safer than native serialization)
const userData = JSON.parse(req.body.data)
// And validate schema
```

**Prevention:**
- Avoid native serialization for untrusted data
- Use JSON/XML instead
- Validate deserialized data
- Implement integrity checks (HMAC)

**OWASP Mapping:** A08:2021 - Software and Data Integrity Failures

---

### [15] CWE-77: Command Injection

**Rank:** #15 | **Score:** 4.95

**Description:**
Similar to CWE-78, but broader scope including non-OS commands.

**Prevention:**
- Avoid constructing commands from user input
- Use parameterized APIs
- Input validation

**OWASP Mapping:** A03:2021 - Injection

---

### [16] CWE-119: Buffer Errors

**Rank:** #16 | **Score:** 4.75

**Description:**
Improper buffer operations (generic category including overflows/underflows).

**Prevention:**
- Bounds checking
- Safe functions
- Memory-safe languages

**OWASP Mapping:** A04:2021 - Insecure Design

---

### [17] CWE-798: Use of Hard-coded Credentials

**Rank:** #17 | **Score:** 4.57

**Description:**
Product contains hard-coded credentials (passwords, API keys, cryptographic keys).

**Example:**
```javascript
// Vulnerable
const DB_PASSWORD = "MyP@ssw0rd123"
const API_KEY = "sk_live_abc123xyz"

// Secure
const DB_PASSWORD = process.env.DB_PASSWORD
const API_KEY = process.env.API_KEY
```

**Prevention:**
- Environment variables
- Secrets management systems
- Configuration files (not in version control)
- Never commit secrets to git

**OWASP Mapping:** A02:2021 - Cryptographic Failures, A07:2021 - Auth Failures

---

### [18] CWE-918: Server-Side Request Forgery (SSRF)

**Rank:** #18 | **Score:** 4.56

**Description:**
Product fetches remote resource without validating user-supplied URL.

**Example:**
```javascript
// Vulnerable
app.get('/fetch', (req, res) => {
  fetch(req.query.url).then(data => res.send(data))
})

// Attack: ?url=http://169.254.169.254/latest/meta-data/
```

**Prevention:**
- URL allowlists
- Disable redirects
- Network segmentation
- Validate protocols and domains

**OWASP Mapping:** A10:2021 - Server-Side Request Forgery

---

### [19] CWE-306: Missing Authentication for Critical Function

**Rank:** #19 | **Score:** 4.33

**Description:**
Critical functionality lacks authentication requirements.

**Example:**
```javascript
// Vulnerable: No auth check
app.post('/admin/delete-all-users', (req, res) => {
  deleteAllUsers()  // No authentication!
})

// Secure
app.post('/admin/delete-all-users', requireAdmin, (req, res) => {
  deleteAllUsers()
})
```

**OWASP Mapping:** A07:2021 - Authentication Failures

---

### [20] CWE-362: Concurrent Execution (Race Condition)

**Rank:** #20 | **Score:** 4.16

**Description:**
Product's concurrent execution leads to unexpected state.

**Example:**
```javascript
// Vulnerable: Race condition
if (balance >= amount) {
  // Another thread could modify balance here!
  balance -= amount
}

// Secure: Use transactions or locks
db.transaction(() => {
  const row = db.query('SELECT balance FROM accounts WHERE id = ? FOR UPDATE', [id])
  if (row.balance >= amount) {
    db.query('UPDATE accounts SET balance = balance - ? WHERE id = ?', [amount, id])
  }
})
```

**Prevention:**
- Database transactions
- Locks/mutexes
- Atomic operations

**OWASP Mapping:** A04:2021 - Insecure Design

---

### [21] CWE-269: Improper Privilege Management

**Rank:** #21 | **Score:** 3.31

**Description:**
Product does not properly assign, modify, track, or check privileges.

**Prevention:**
- Principle of least privilege
- Role-based access control (RBAC)
- Regular privilege audits

**OWASP Mapping:** A01:2021 - Broken Access Control

---

### [22] CWE-94: Code Injection

**Rank:** #22 | **Score:** 3.30

**Description:**
Product allows arbitrary code from untrusted source to be executed.

**Example:**
```javascript
// Vulnerable
eval(req.body.code)  // Extremely dangerous!

// Avoid eval() entirely
```

**Prevention:**
- Never use eval() with user input
- Use safe alternatives (JSON.parse, etc.)
- Sandboxing if dynamic code is required

**OWASP Mapping:** A03:2021 - Injection

---

### [23] CWE-863: Incorrect Authorization

**Rank:** #23 | **Score:** 3.16

**Description:**
Product performs authorization check incorrectly.

**Example:**
```javascript
// Vulnerable: Incorrect check
if (req.user.role === 'admin' || req.user.role === 'user') {
  // Should be && not ||
  deleteUser(id)
}
```

**OWASP Mapping:** A01:2021 - Broken Access Control

---

### [24] CWE-276: Incorrect Default Permissions

**Rank:** #24 | **Score:** 3.16

**Description:**
Product sets overly permissive default permissions.

**Example:**
```javascript
// Vulnerable: World-readable
fs.writeFileSync('secrets.txt', data, { mode: 0o777 })

// Secure: Restrictive permissions
fs.writeFileSync('secrets.txt', data, { mode: 0o600 })
```

**OWASP Mapping:** A05:2021 - Security Misconfiguration

---

### [25] CWE-200: Exposure of Sensitive Information

**Rank:** #25 | **Score:** 2.90

**Description:**
Product exposes sensitive information to unauthorized actors.

**Examples:**
- Stack traces in error messages
- Detailed error messages revealing system info
- Debug logs in production
- Directory listings

**Prevention:**
- Generic error messages to users
- Detailed logs only server-side
- Disable directory listings
- Review what data is exposed in APIs

**OWASP Mapping:** A02:2021 - Cryptographic Failures, A05:2021 - Security Misconfiguration

---

## CWE Categories by Impact

### Code Execution
- CWE-787 (Out-of-bounds Write)
- CWE-416 (Use After Free)
- CWE-78 (OS Command Injection)
- CWE-502 (Deserialization)
- CWE-94 (Code Injection)

### Data Theft
- CWE-79 (XSS)
- CWE-89 (SQL Injection)
- CWE-918 (SSRF)
- CWE-200 (Info Exposure)

### Access Control
- CWE-862 (Missing Authorization)
- CWE-287 (Improper Authentication)
- CWE-306 (Missing Authentication)
- CWE-863 (Incorrect Authorization)
- CWE-269 (Privilege Management)

### Input Validation
- CWE-20 (Improper Input Validation)
- CWE-434 (Unrestricted Upload)
- CWE-352 (CSRF)

---

## Quick Reference Table

| Rank | CWE | Name | CVSS Avg | Prevention |
|------|-----|------|----------|------------|
| 1 | 787 | Out-of-bounds Write | 9.3 | Bounds checking, safe functions |
| 2 | 79 | XSS | 6.1 | Output encoding, CSP |
| 3 | 89 | SQL Injection | 8.5 | Parameterized queries |
| 4 | 416 | Use After Free | 9.3 | Memory-safe languages |
| 5 | 78 | Command Injection | 9.8 | Avoid shell, use libraries |
| 6 | 20 | Improper Input Validation | 6.5 | Allowlist validation |
| 7 | 125 | Out-of-bounds Read | 7.1 | Bounds checking |
| 8 | 352 | CSRF | 6.5 | CSRF tokens, SameSite |
| 9 | 434 | Unrestricted Upload | 8.5 | File type validation |
| 10 | 862 | Missing Authorization | 6.5 | Authorization checks |

---

## Additional Resources

- **CWE Top 25:** https://cwe.mitre.org/top25/
- **CWE Database:** https://cwe.mitre.org/
- **MITRE ATT&CK:** https://attack.mitre.org/
- **CAPEC (Attack Patterns):** https://capec.mitre.org/
