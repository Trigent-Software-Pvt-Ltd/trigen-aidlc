# OWASP Top 10 Web Application Security Risks (2021)

This document provides a comprehensive reference for the OWASP Top 10 - the most critical security risks to web applications.

Reference: https://owasp.org/www-project-top-ten/

---

## A01:2021 - Broken Access Control

**Description:**
Access control enforces policy such that users cannot act outside of their intended permissions. Failures typically lead to unauthorized information disclosure, modification, or destruction of data, or performing business functions outside the user's limits.

**Common Vulnerabilities:**
- Bypassing access control checks by modifying URL, internal application state, or HTML page
- Permitting viewing or editing someone else's account (IDOR - Insecure Direct Object References)
- Missing access controls for POST, PUT, DELETE operations
- Elevation of privilege (acting as a user without being logged in, or as admin when logged in as user)
- Metadata manipulation (replaying or tampering JWT tokens, cookies, or hidden fields)
- CORS misconfiguration allowing unauthorized API access
- Force browsing to authenticated pages as an unauthenticated user

**Example Attack:**
```
# Attacker changes URL parameter to access another user's data
https://example.com/account?id=123  →  https://example.com/account?id=124
```

**Prevention:**
- Deny by default (except for public resources)
- Implement access control mechanisms once and re-use throughout application
- Enforce record ownership rather than allowing users to create, read, update, or delete any record
- Disable web server directory listing and ensure file metadata (e.g., .git) is not present
- Log access control failures and alert admins when appropriate
- Rate limit API and controller access to minimize harm from automated attacks
- JWT tokens should be invalidated on the server after logout

**CWE Mappings:** CWE-22, CWE-23, CWE-35, CWE-59, CWE-200, CWE-201, CWE-219, CWE-264, CWE-275, CWE-276, CWE-284, CWE-285, CWE-352, CWE-359, CWE-377, CWE-402, CWE-425, CWE-441, CWE-497, CWE-538, CWE-540, CWE-548, CWE-552, CWE-566, CWE-601, CWE-639, CWE-651, CWE-668, CWE-706, CWE-862, CWE-863, CWE-913, CWE-922, CWE-1275

---

## A02:2021 - Cryptographic Failures

**Description:**
Previously known as "Sensitive Data Exposure." Failures related to cryptography (or lack thereof) which often lead to exposure of sensitive data.

**Common Vulnerabilities:**
- Transmitting data in clear text (HTTP, SMTP, FTP)
- Using old or weak cryptographic algorithms (MD5, SHA1, DES, RC4)
- Default, weak, or reused cryptographic keys
- Missing encryption in transit (no TLS/HTTPS)
- Missing encryption at rest for sensitive data
- Not enforcing encryption (e.g., missing HTTP security headers)
- Using deprecated cryptographic padding methods (PKCS#1 v1.5)
- Not validating server certificates (SSL/TLS certificate validation disabled)

**Example Attack:**
```javascript
// Insecure: Using weak MD5 hashing for passwords
const hashedPassword = md5(userPassword)

// Secure: Using strong bcrypt with salt
const hashedPassword = await bcrypt.hash(userPassword, 10)
```

**Prevention:**
- Classify data processed, stored, or transmitted by the application
- Don't store sensitive data unnecessarily (discard ASAP or use PCI DSS tokenization)
- Encrypt all sensitive data at rest
- Encrypt all data in transit with secure protocols (TLS 1.2+, HSTS)
- Use strong, up-to-date encryption algorithms and keys
- Disable caching for responses containing sensitive data
- Store passwords using strong adaptive salted hashing (Argon2, scrypt, bcrypt, PBKDF2)
- Use initialization vectors appropriate for the mode of operation
- Independently verify encryption configuration effectiveness

**CWE Mappings:** CWE-259, CWE-327, CWE-331

---

## A03:2021 - Injection

**Description:**
An application is vulnerable to attack when user-supplied data is not validated, filtered, or sanitized. Hostile data tricks the interpreter into executing unintended commands or accessing data without authorization.

**Common Types:**
- **SQL Injection:** Malicious SQL queries
- **NoSQL Injection:** Malicious NoSQL queries
- **OS Command Injection:** Executing system commands
- **LDAP Injection:** LDAP query manipulation
- **XML Injection (XXE):** Malicious XML content
- **XPath Injection:** XPath query manipulation
- **Expression Language (EL) Injection:** Template injection
- **OGNL Injection:** Object Graph Navigation Language

**Example Attack:**
```sql
-- SQL Injection via user input
SELECT * FROM users WHERE username = 'admin' -- ' AND password = 'anything'

-- This comments out the password check, bypassing authentication
```

**Prevention:**
- Use parameterized queries (prepared statements) instead of string concatenation
- Use positive server-side input validation
- Use LIMIT and other SQL controls to prevent mass disclosure in case of SQL injection
- Escape special characters using specific escape syntax for that interpreter
- Use ORM frameworks (but watch for vulnerabilities in generated queries)
- Use safe APIs that avoid interpreters or provide parameterized interfaces
- Server-side input validation with allowlists for characters/patterns

**Secure Code Example (Parameterized Queries):**
```javascript
// Insecure - String concatenation
const query = `SELECT * FROM users WHERE id = ${userId}`
db.execute(query)

// Secure - Parameterized query
const query = 'SELECT * FROM users WHERE id = ?'
db.execute(query, [userId])
```

**CWE Mappings:** CWE-20, CWE-74, CWE-75, CWE-77, CWE-78, CWE-79, CWE-80, CWE-83, CWE-87, CWE-88, CWE-89, CWE-90, CWE-91, CWE-93, CWE-94, CWE-95, CWE-96, CWE-97, CWE-98, CWE-99, CWE-100, CWE-113, CWE-116, CWE-138, CWE-184, CWE-470, CWE-471, CWE-564, CWE-610, CWE-643, CWE-644, CWE-652, CWE-917

---

## A04:2021 - Insecure Design

**Description:**
A new category for 2021 focusing on risks related to design and architectural flaws. Calls for more threat modeling, secure design patterns, and reference architectures.

**Common Issues:**
- Missing or ineffective control design
- Failure to perform threat modeling
- Not implementing security by design
- Lack of security requirements
- Insufficient separation of privileges
- Missing rate limiting or resource quotas
- Not accounting for security in the design phase

**Example Vulnerability:**
```
A cinema website allows group bookings with discount.
Attackers create a script to book all seats in advance,
causing massive financial loss.

Missing: Rate limiting, CAPTCHA, anomaly detection
```

**Prevention:**
- Establish secure development lifecycle with security professionals
- Use threat modeling for critical authentication, access control, business logic, and key flows
- Integrate security language and controls into user stories
- Build security into every tier (presentation, logic, data)
- Write unit and integration tests to validate all critical flows are resistant to threat model
- Segregate tier layers on system and network level depending on exposure and protection needs
- Limit resource consumption by user or service (rate limiting, quotas)

**CWE Mappings:** CWE-73, CWE-183, CWE-209, CWE-213, CWE-235, CWE-256, CWE-257, CWE-266, CWE-269, CWE-280, CWE-311, CWE-312, CWE-313, CWE-316, CWE-419, CWE-430, CWE-434, CWE-444, CWE-451, CWE-472, CWE-501, CWE-522, CWE-525, CWE-539, CWE-579, CWE-598, CWE-602, CWE-642, CWE-646, CWE-650, CWE-653, CWE-656, CWE-657, CWE-799, CWE-807, CWE-840, CWE-841, CWE-927, CWE-1021, CWE-1173

---

## A05:2021 - Security Misconfiguration

**Description:**
The application might be vulnerable if it has missing appropriate security hardening across any part of the application stack or improperly configured permissions.

**Common Issues:**
- Missing security hardening or improperly configured permissions
- Unnecessary features enabled (ports, services, pages, accounts, privileges)
- Default accounts with unchanged passwords
- Error messages revealing stack traces or sensitive information
- Latest security features disabled or not configured securely
- Missing security headers or directives
- Software out of date or vulnerable

**Example Vulnerability:**
```javascript
// Development mode left on in production
app.set('DEBUG', true)  // Exposes stack traces

// Missing security headers
// No X-Frame-Options, CSP, HSTS, etc.
```

**Prevention:**
- Repeatable hardening process for deploying locked-down environments
- Minimal platform without unnecessary features, components, documentation, samples
- Review and update configurations appropriate to all security notes, updates, patches
- Segmented application architecture with separation between components/tenants
- Send security directives to clients (e.g., Security Headers)
- Automated process to verify effectiveness of configurations in all environments
- Disable directory listings and ensure file metadata isn't exposed

**Security Headers:**
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Content-Security-Policy: default-src 'self'
Referrer-Policy: no-referrer
Permissions-Policy: geolocation=(), microphone=()
```

**CWE Mappings:** CWE-2, CWE-11, CWE-13, CWE-15, CWE-16, CWE-260, CWE-315, CWE-520, CWE-526, CWE-537, CWE-541, CWE-547, CWE-611, CWE-614, CWE-756, CWE-776, CWE-942, CWE-1004, CWE-1032, CWE-1174

---

## A06:2021 - Vulnerable and Outdated Components

**Description:**
Using components (libraries, frameworks, modules) with known vulnerabilities. This includes directly used components and nested dependencies.

**Common Issues:**
- Not knowing versions of all components (client and server-side)
- Software that is vulnerable, unsupported, or out of date (OS, web/app server, DBMS, APIs, runtime, libraries)
- Not scanning for vulnerabilities regularly
- Not fixing or upgrading the underlying platform, frameworks, and dependencies in a timely fashion
- Not testing compatibility of updated/patched libraries
- Not securing component configurations (see A05)

**Example Vulnerability:**
```json
// package.json with vulnerable dependencies
{
  "dependencies": {
    "express": "4.16.0",  // CVE-2022-24999 (CVSS 9.1)
    "lodash": "4.17.11",  // CVE-2021-23337 (CVSS 9.8)
    "axios": "0.18.0"     // CVE-2021-3749 (CVSS 7.5)
  }
}
```

**Prevention:**
- Remove unused dependencies, features, components, files, and documentation
- Continuously inventory versions of client and server-side components and dependencies
- Monitor sources like CVE and NVD for vulnerabilities in components
- Use software composition analysis tools (npm audit, OWASP Dependency-Check, Snyk)
- Subscribe to email alerts for security vulnerabilities related to components you use
- Only obtain components from official sources over secure links
- Prefer signed packages to reduce chance of modified malicious component
- Monitor for unmaintained libraries and components

**Tools:**
- `npm audit` / `yarn audit` (JavaScript)
- `pip-audit` / `safety` (Python)
- `bundler-audit` (Ruby)
- OWASP Dependency-Check (multi-language)
- Snyk, WhiteSource, JFrog Xray (commercial)

**CWE Mappings:** CWE-1035, CWE-1104

---

## A07:2021 - Identification and Authentication Failures

**Description:**
Previously "Broken Authentication." Confirmation of user identity, authentication, and session management is critical. The application may be vulnerable if it permits automated attacks, permits weak passwords, uses plain text or weakly hashed passwords, or has weak session management.

**Common Issues:**
- Permits automated attacks (credential stuffing, brute force)
- Permits default, weak, or well-known passwords
- Uses weak or ineffective credential recovery processes (e.g., "knowledge-based answers")
- Uses plain text, encrypted, or weakly hashed passwords
- Missing or ineffective multi-factor authentication
- Exposes session identifiers in URL
- Reuses session identifiers after successful login
- Does not correctly invalidate sessions during logout or inactivity

**Example Vulnerability:**
```javascript
// Insecure: Session ID in URL
https://example.com/dashboard?sessionid=abc123

// No rate limiting on login
app.post('/login', (req, res) => {
  if (checkPassword(req.body.username, req.body.password)) {
    // No brute force protection!
  }
})
```

**Prevention:**
- Implement multi-factor authentication
- Do not ship or deploy with default credentials
- Implement weak password checks (e.g., against top 10,000 worst passwords)
- Align password length, complexity, and rotation policies with NIST 800-63b guidelines
- Limit or delay failed login attempts, log failures, alert admins on credential stuffing/brute force
- Use server-side, secure session manager that generates random session IDs
- Session IDs should not be in URL, securely stored, and invalidated after logout/inactivity

**Secure Authentication Example:**
```javascript
// Rate limiting
const rateLimit = require('express-rate-limit')
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5 // limit each IP to 5 requests per windowMs
})

app.post('/login', loginLimiter, async (req, res) => {
  // Strong password hashing
  const match = await bcrypt.compare(req.body.password, user.hashedPassword)

  if (match) {
    // Secure session
    req.session.userId = user.id
    req.session.regenerate() // Prevent session fixation
  }
})
```

**CWE Mappings:** CWE-255, CWE-259, CWE-287, CWE-288, CWE-290, CWE-294, CWE-295, CWE-297, CWE-300, CWE-302, CWE-304, CWE-306, CWE-307, CWE-346, CWE-384, CWE-521, CWE-613, CWE-620, CWE-640, CWE-798, CWE-940, CWE-1216

---

## A08:2021 - Software and Data Integrity Failures

**Description:**
New category for 2021 focusing on making assumptions related to software updates, critical data, and CI/CD pipelines without verifying integrity. Examples include insecure deserialization and dependency confusion attacks.

**Common Issues:**
- Applications that rely on plugins, libraries, or modules from untrusted sources/repositories/CDNs
- Insecure CI/CD pipeline that allows unauthorized access
- Auto-update functionality that downloads updates without integrity verification
- Insecure deserialization (objects or data structures from untrusted sources)
- Unsigned or unencrypted serialized data sent to untrusted clients

**Example Vulnerability:**
```javascript
// Insecure deserialization
app.post('/profile', (req, res) => {
  const userData = deserialize(req.body.data)  // Dangerous!
  // Attacker can inject malicious objects
})

// Using unverified CDN
<script src="https://cdn.example.com/jquery.js"></script>
// No Subresource Integrity (SRI) check
```

**Prevention:**
- Use digital signatures or similar mechanisms to verify software or data is from expected source
- Ensure libraries and dependencies are from trusted repositories
- Use software supply chain security tools (OWASP Dependency-Check, Snyk)
- Ensure there is a review process for code and configuration changes
- Ensure CI/CD pipeline has proper segregation, configuration, and access control
- Do not send unsigned or unencrypted serialized data to untrusted clients without integrity check
- Use Subresource Integrity (SRI) for CDN content

**Secure Example:**
```html
<!-- Subresource Integrity for CDN -->
<script
  src="https://cdn.example.com/jquery-3.6.0.min.js"
  integrity="sha384-vtXRMe3mGCbOeY7l30aIg8H9p3GdeSe4IFlP6G8JMa7o7lXvnz3GFKzPxzJdPfGK"
  crossorigin="anonymous">
</script>
```

**CWE Mappings:** CWE-345, CWE-353, CWE-426, CWE-494, CWE-502, CWE-565, CWE-784, CWE-829, CWE-830, CWE-915

---

## A09:2021 - Security Logging and Monitoring Failures

**Description:**
Without logging and monitoring, breaches cannot be detected. Insufficient logging, detection, monitoring, and active response allows attackers to further attack systems, maintain persistence, pivot to more systems, and tamper/extract/destroy data.

**Common Issues:**
- Auditable events (logins, failed logins, high-value transactions) not logged
- Warnings and errors generate no, inadequate, or unclear log messages
- Logs of applications and APIs not monitored for suspicious activity
- Logs only stored locally
- Appropriate alerting thresholds and response escalation processes not in place
- Penetration testing and DAST scans do not trigger alerts
- Application cannot detect, escalate, or alert for active attacks in real-time or near real-time

**Example Vulnerability:**
```javascript
// No logging of authentication events
app.post('/login', (req, res) => {
  if (authenticate(req.body.username, req.body.password)) {
    // Success - but no log entry!
    return res.json({success: true})
  }
  // Failure - but no log entry!
  return res.status(401).json({error: 'Invalid credentials'})
})
```

**Prevention:**
- Ensure all login, access control, and server-side input validation failures are logged with context
- Ensure logs are in format suitable for log management solutions
- Ensure log data is encoded correctly to prevent injections or attacks on logging/monitoring systems
- Ensure high-value transactions have audit trail with integrity controls
- Establish effective monitoring and alerting (suspicious activities detected and responded to quickly)
- Establish or adopt incident response and recovery plan (NIST 800-61r2 or later)

**Secure Logging Example:**
```javascript
const winston = require('winston')

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'security.log' })
  ]
})

app.post('/login', (req, res) => {
  if (authenticate(req.body.username, req.body.password)) {
    logger.info('Successful login', {
      username: req.body.username,
      ip: req.ip,
      timestamp: new Date()
    })
  } else {
    logger.warn('Failed login attempt', {
      username: req.body.username,
      ip: req.ip,
      timestamp: new Date()
    })
  }
})
```

**CWE Mappings:** CWE-117, CWE-223, CWE-532, CWE-778

---

## A10:2021 - Server-Side Request Forgery (SSRF)

**Description:**
SSRF flaws occur when a web application fetches a remote resource without validating the user-supplied URL. It allows an attacker to coerce the application to send requests to an unexpected destination, even when protected by a firewall, VPN, or network ACL.

**Common Issues:**
- Fetching URLs provided by users without validation
- Accessing cloud metadata services (AWS, Azure, GCP)
- Accessing internal services or databases
- Port scanning internal networks
- Reading local files via file:// protocol

**Example Attack:**
```javascript
// Vulnerable code
app.get('/fetch', (req, res) => {
  const url = req.query.url  // User-controlled!
  fetch(url).then(data => res.send(data))
})

// Attack: Access cloud metadata
// /fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/
// Retrieves AWS credentials from metadata service!

// Attack: Scan internal network
// /fetch?url=http://192.168.1.1:22
// /fetch?url=http://192.168.1.1:3306
```

**Prevention:**
- Sanitize and validate all client-supplied input data
- Enforce URL schema, port, and destination with positive allowlist
- Disable HTTP redirections
- Don't send raw responses to clients
- Use network segmentation to isolate resource access
- Block by default network traffic to internal services
- Be aware of URL consistency to avoid attacks such as DNS rebinding and TOCTOU races

**Secure Example:**
```javascript
const ALLOWED_DOMAINS = ['api.example.com', 'cdn.example.com']

app.get('/fetch', (req, res) => {
  const url = new URL(req.query.url)

  // Validate protocol
  if (url.protocol !== 'https:') {
    return res.status(400).send('Only HTTPS allowed')
  }

  // Validate domain allowlist
  if (!ALLOWED_DOMAINS.includes(url.hostname)) {
    return res.status(400).send('Domain not allowed')
  }

  // Validate not internal IP
  if (url.hostname.match(/^(10\.|192\.168\.|127\.)/)) {
    return res.status(400).send('Internal IPs not allowed')
  }

  fetch(url).then(data => res.send(data))
})
```

**CWE Mappings:** CWE-918

---

## Quick Reference Table

| # | Risk | Key Threat | Primary Defense |
|---|------|------------|-----------------|
| A01 | Broken Access Control | Unauthorized data access | Deny by default, proper authorization checks |
| A02 | Cryptographic Failures | Sensitive data exposure | Encrypt data at rest and in transit |
| A03 | Injection | Code/command execution | Parameterized queries, input validation |
| A04 | Insecure Design | Flawed architecture | Threat modeling, secure design patterns |
| A05 | Security Misconfiguration | Exposed services/data | Hardening, minimal platform, security headers |
| A06 | Vulnerable Components | Known CVEs | Dependency scanning, regular updates |
| A07 | Auth Failures | Account takeover | MFA, strong passwords, session security |
| A08 | Integrity Failures | Supply chain attacks | Verify signatures, SRI, secure CI/CD |
| A09 | Logging Failures | Undetected breaches | Comprehensive logging, monitoring, alerting |
| A10 | SSRF | Internal network access | URL validation, allowlists, network segmentation |

---

## Additional Resources

- **OWASP Top 10 2021:** https://owasp.org/Top10/
- **OWASP Cheat Sheet Series:** https://cheatsheetseries.owasp.org/
- **OWASP Testing Guide:** https://owasp.org/www-project-web-security-testing-guide/
- **OWASP Code Review Guide:** https://owasp.org/www-project-code-review-guide/
