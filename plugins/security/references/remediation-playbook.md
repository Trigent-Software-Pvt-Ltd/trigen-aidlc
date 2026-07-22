# Security Remediation Playbook

This playbook provides step-by-step remediation guidance for common security vulnerabilities.

---

## Table of Contents

1. [SQL Injection](#sql-injection)
2. [Cross-Site Scripting (XSS)](#cross-site-scripting-xss)
3. [Cross-Site Request Forgery (CSRF)](#cross-site-request-forgery-csrf)
4. [Broken Authentication](#broken-authentication)
5. [Sensitive Data Exposure](#sensitive-data-exposure)
6. [Broken Access Control](#broken-access-control)
7. [Security Misconfiguration](#security-misconfiguration)
8. [Insecure Deserialization](#insecure-deserialization)
9. [Using Components with Known Vulnerabilities](#using-components-with-known-vulnerabilities)
10. [Server-Side Request Forgery (SSRF)](#server-side-request-forgery-ssrf)
11. [Command Injection](#command-injection)
12. [Path Traversal](#path-traversal)
13. [Unrestricted File Upload](#unrestricted-file-upload)
14. [Hardcoded Credentials](#hardcoded-credentials)
15. [Insecure Cryptography](#insecure-cryptography)

---

## SQL Injection

### Severity: CRITICAL

### Identification
- User input concatenated into SQL queries
- Dynamic SQL construction from user data
- Error messages revealing SQL syntax

### Remediation Steps

**Step 1: Identify all SQL queries**
```bash
# Search for common SQL injection patterns
grep -rn "execute.*+\|query.*+" --include="*.js" --include="*.py"
```

**Step 2: Replace with parameterized queries**

**JavaScript (Node.js):**
```javascript
// BEFORE (Vulnerable)
const query = `SELECT * FROM users WHERE email = '${userEmail}'`
db.query(query)

// AFTER (Secure)
const query = 'SELECT * FROM users WHERE email = ?'
db.query(query, [userEmail])
```

**Python:**
```python
# BEFORE (Vulnerable)
query = f"SELECT * FROM users WHERE email = '{user_email}'"
cursor.execute(query)

# AFTER (Secure)
query = "SELECT * FROM users WHERE email = %s"
cursor.execute(query, (user_email,))
```

**Step 3: Use ORM when possible**

**JavaScript (Sequelize):**
```javascript
const user = await User.findOne({ where: { email: userEmail } })
```

**Python (SQLAlchemy):**
```python
user = session.query(User).filter_by(email=user_email).first()
```

**Step 4: Test the fix**
```bash
# Test with malicious input
curl -X POST http://localhost:3000/login \
  -d "email=admin' OR '1'='1&password=anything"

# Should NOT bypass authentication
```

**Step 5: Add input validation (defense in depth)**
```javascript
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
if (!emailRegex.test(userEmail)) {
  return res.status(400).json({ error: 'Invalid email format' })
}
```

### Verification
- [ ] All dynamic SQL uses parameterized queries
- [ ] ORM used where possible
- [ ] Input validation in place
- [ ] Tested with SQL injection payloads
- [ ] No error messages reveal SQL details

---

## Cross-Site Scripting (XSS)

### Severity: HIGH

### Types
- **Stored XSS:** Malicious script stored in database
- **Reflected XSS:** Script in URL parameter reflected back
- **DOM-based XSS:** Client-side DOM manipulation

### Remediation Steps

**Step 1: Identify XSS vulnerabilities**
```bash
# Search for unsafe HTML rendering
grep -rn "innerHTML\|outerHTML\|document.write" --include="*.js"
grep -rn "render.*dangerouslySetInnerHTML" --include="*.jsx"
```

**Step 2: Implement output encoding**

**JavaScript (Express):**
```javascript
// BEFORE (Vulnerable)
res.send(`<h1>Welcome ${username}</h1>`)

// AFTER (Secure) - Use templating with auto-escaping
res.render('welcome', { username })  // EJS/Pug auto-escapes

// Or manual escaping
function escapeHTML(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
}
res.send(`<h1>Welcome ${escapeHTML(username)}</h1>`)
```

**React:**
```jsx
// BEFORE (Vulnerable)
<div dangerouslySetInnerHTML={{__html: userInput}} />

// AFTER (Secure) - React auto-escapes by default
<div>{userInput}</div>

// If HTML is necessary, sanitize first
import DOMPurify from 'dompurify'
<div dangerouslySetInnerHTML={{__html: DOMPurify.sanitize(userInput)}} />
```

**Step 3: Implement Content Security Policy**
```javascript
app.use((req, res, next) => {
  res.setHeader(
    "Content-Security-Policy",
    "default-src 'self'; " +
    "script-src 'self' 'nonce-{RANDOM}'; " +
    "style-src 'self' 'unsafe-inline'; " +
    "img-src 'self' data: https:; " +
    "font-src 'self'; " +
    "connect-src 'self'; " +
    "frame-ancestors 'none'"
  )
  next()
})
```

**Step 4: Set HTTPOnly cookies**
```javascript
res.cookie('session', sessionId, {
  httpOnly: true,  // Prevents JavaScript access
  secure: true,
  sameSite: 'strict'
})
```

**Step 5: Test for XSS**
```html
<!-- Test payloads -->
<script>alert('XSS')</script>
<img src=x onerror=alert('XSS')>
<svg/onload=alert('XSS')>
```

### Verification
- [ ] All user input is encoded before output
- [ ] CSP headers configured
- [ ] HTTPOnly flag on session cookies
- [ ] No inline scripts (or use nonces)
- [ ] Tested with XSS payloads

---

## Cross-Site Request Forgery (CSRF)

### Severity: MEDIUM

### Remediation Steps

**Step 1: Implement CSRF tokens**

**Express.js:**
```javascript
const csrf = require('csurf')
const csrfProtection = csrf({ cookie: true })

// Add to all state-changing routes
app.post('/transfer', csrfProtection, (req, res) => {
  // Process transfer
})

// Include token in forms
app.get('/form', csrfProtection, (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() })
})
```

**HTML Form:**
```html
<form method="POST" action="/transfer">
  <input type="hidden" name="_csrf" value="<%= csrfToken %>">
  <input type="text" name="amount">
  <button type="submit">Transfer</button>
</form>
```

**AJAX Requests:**
```javascript
// Include token in AJAX headers
fetch('/api/transfer', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'CSRF-Token': csrfToken
  },
  body: JSON.stringify({ amount: 100 })
})
```

**Step 2: Use SameSite cookies**
```javascript
app.use(session({
  secret: process.env.SESSION_SECRET,
  cookie: {
    sameSite: 'strict',  // or 'lax'
    secure: true,
    httpOnly: true
  }
}))
```

**Step 3: Verify Origin/Referer headers (defense in depth)**
```javascript
app.use((req, res, next) => {
  if (['POST', 'PUT', 'DELETE'].includes(req.method)) {
    const origin = req.get('origin')
    const referer = req.get('referer')
    const allowedOrigins = ['https://yourdomain.com']

    if (!origin && !referer) {
      return res.status(403).send('Missing origin/referer')
    }

    // Validate origin
    if (origin && !allowedOrigins.includes(origin)) {
      return res.status(403).send('Invalid origin')
    }
  }
  next()
})
```

### Verification
- [ ] CSRF tokens on all state-changing operations
- [ ] SameSite cookie attribute set
- [ ] Custom headers for AJAX requests
- [ ] Origin/Referer validation in place
- [ ] Tested CSRF attack scenarios

---

## Broken Authentication

### Severity: CRITICAL

### Common Issues
- Weak password requirements
- No account lockout
- Predictable session IDs
- Session fixation
- No multi-factor authentication

### Remediation Steps

**Step 1: Implement strong password policy**
```javascript
const passwordValidator = require('password-validator')

const schema = new passwordValidator()
schema
  .is().min(12)                                     // Minimum length 12
  .is().max(128)                                    // Maximum length 128
  .has().uppercase()                                // Must have uppercase
  .has().lowercase()                                // Must have lowercase
  .has().digits(1)                                  // Must have at least 1 digit
  .has().symbols(1)                                 // Must have at least 1 symbol
  .has().not().spaces()                             // No spaces
  .is().not().oneOf(['Password123', 'Welcome123'])  // Blacklist common passwords

function validatePassword(password) {
  return schema.validate(password)
}
```

**Step 2: Implement account lockout**
```javascript
const MAX_LOGIN_ATTEMPTS = 5
const LOCKOUT_DURATION = 15 * 60 * 1000  // 15 minutes

async function handleLogin(username, password) {
  const user = await getUserByUsername(username)

  // Check if account is locked
  if (user.lockedUntil && user.lockedUntil > Date.now()) {
    return { error: 'Account locked. Try again later.' }
  }

  // Verify password
  const isValid = await bcrypt.compare(password, user.passwordHash)

  if (!isValid) {
    // Increment failed attempts
    user.failedLoginAttempts += 1

    if (user.failedLoginAttempts >= MAX_LOGIN_ATTEMPTS) {
      user.lockedUntil = Date.now() + LOCKOUT_DURATION
    }

    await user.save()
    return { error: 'Invalid credentials' }
  }

  // Reset on successful login
  user.failedLoginAttempts = 0
  user.lockedUntil = null
  await user.save()

  return { success: true, user }
}
```

**Step 3: Secure session management**
```javascript
const session = require('express-session')
const crypto = require('crypto')

app.use(session({
  secret: process.env.SESSION_SECRET,  // Strong random secret
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,        // HTTPS only
    httpOnly: true,      // No JavaScript access
    sameSite: 'strict',
    maxAge: 30 * 60 * 1000  // 30 minutes
  },
  genid: () => crypto.randomBytes(32).toString('hex')  // Secure session ID
}))

// Regenerate session ID on login (prevent session fixation)
app.post('/login', async (req, res) => {
  const { username, password } = req.body
  const result = await handleLogin(username, password)

  if (result.success) {
    req.session.regenerate((err) => {
      if (err) return res.status(500).send('Error')
      req.session.userId = result.user.id
      res.json({ success: true })
    })
  } else {
    res.status(401).json(result)
  }
})

// Destroy session on logout
app.post('/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) return res.status(500).send('Error')
    res.clearCookie('connect.sid')
    res.json({ success: true })
  })
})
```

**Step 4: Implement multi-factor authentication**
```javascript
const speakeasy = require('speakeasy')

// Generate secret for user
function generate2FASecret(user) {
  const secret = speakeasy.generateSecret({
    name: `YourApp (${user.email})`
  })
  user.twoFactorSecret = secret.base32
  return secret.otpauth_url  // Show QR code to user
}

// Verify 2FA token
function verify2FAToken(user, token) {
  return speakeasy.totp.verify({
    secret: user.twoFactorSecret,
    encoding: 'base32',
    token: token,
    window: 1  // Allow 1 time step tolerance
  })
}
```

### Verification
- [ ] Strong password requirements enforced
- [ ] Account lockout after failed attempts
- [ ] Secure session management
- [ ] Session regeneration on login
- [ ] Multi-factor authentication available
- [ ] Password reset tokens expire
- [ ] Logout properly destroys session

---

## Sensitive Data Exposure

### Severity: HIGH

### Common Issues
- Storing passwords in plain text
- Transmitting data over HTTP
- Using weak encryption
- Exposing sensitive data in logs/errors

### Remediation Steps

**Step 1: Enforce HTTPS**
```javascript
// Redirect HTTP to HTTPS
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https' && process.env.NODE_ENV === 'production') {
    res.redirect(`https://${req.header('host')}${req.url}`)
  } else {
    next()
  }
})

// Strict-Transport-Security header
app.use((req, res, next) => {
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload')
  next()
})
```

**Step 2: Hash passwords properly**
```javascript
const bcrypt = require('bcrypt')
const SALT_ROUNDS = 12  // Adjust based on security/performance needs

async function hashPassword(plaintext) {
  return await bcrypt.hash(plaintext, SALT_ROUNDS)
}

async function verifyPassword(plaintext, hash) {
  return await bcrypt.compare(plaintext, hash)
}
```

**Step 3: Encrypt sensitive data at rest**
```javascript
const crypto = require('crypto')

const ALGORITHM = 'aes-256-gcm'
const KEY = Buffer.from(process.env.ENCRYPTION_KEY, 'hex')  // 32-byte key

function encrypt(plaintext) {
  const iv = crypto.randomBytes(16)
  const cipher = crypto.createCipheriv(ALGORITHM, KEY, iv)

  let encrypted = cipher.update(plaintext, 'utf8', 'hex')
  encrypted += cipher.final('hex')

  const authTag = cipher.getAuthTag()

  return {
    encrypted,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex')
  }
}

function decrypt(encrypted, iv, authTag) {
  const decipher = crypto.createDecipheriv(
    ALGORITHM,
    KEY,
    Buffer.from(iv, 'hex')
  )

  decipher.setAuthTag(Buffer.from(authTag, 'hex'))

  let decrypted = decipher.update(encrypted, 'hex', 'utf8')
  decrypted += decipher.final('utf8')

  return decrypted
}
```

**Step 4: Remove sensitive data from logs**
```javascript
const winston = require('winston')

// Create custom format to redact sensitive fields
const redactSensitiveData = winston.format((info) => {
  const sensitiveFields = ['password', 'ssn', 'creditCard', 'apiKey']

  sensitiveFields.forEach(field => {
    if (info[field]) {
      info[field] = '[REDACTED]'
    }
  })

  return info
})

const logger = winston.createLogger({
  format: winston.format.combine(
    redactSensitiveData(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'app.log' })
  ]
})
```

**Step 5: Minimize data collection**
```javascript
// Only collect necessary data
const userSchema = new mongoose.Schema({
  email: String,
  passwordHash: String,
  // Don't store: SSN, full credit card, unnecessary PII
})

// Delete data when no longer needed
async function deleteInactiveUsers() {
  const oneYearAgo = new Date()
  oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1)

  await User.deleteMany({
    lastLogin: { $lt: oneYearAgo }
  })
}
```

### Verification
- [ ] All traffic uses HTTPS/TLS
- [ ] HSTS header configured
- [ ] Passwords hashed with bcrypt/argon2
- [ ] Sensitive data encrypted at rest
- [ ] Logs don't contain passwords/keys
- [ ] Error messages don't expose sensitive info
- [ ] Minimal data collection

---

## Broken Access Control

### Severity: CRITICAL

### Common Issues
- Insecure Direct Object References (IDOR)
- Missing function-level access control
- Horizontal privilege escalation
- Vertical privilege escalation

### Remediation Steps

**Step 1: Implement proper authorization checks**

```javascript
// BAD: No authorization check
app.delete('/api/users/:id', async (req, res) => {
  await User.findByIdAndDelete(req.params.id)
  res.json({ success: true })
})

// GOOD: Check ownership
app.delete('/api/users/:id', requireAuth, async (req, res) => {
  // Users can only delete their own account
  if (req.user.id !== req.params.id) {
    return res.status(403).json({ error: 'Unauthorized' })
  }

  await User.findByIdAndDelete(req.params.id)
  res.json({ success: true })
})

// GOOD: Admin can delete any account
app.delete('/api/users/:id', requireAuth, async (req, res) => {
  if (req.user.id !== req.params.id && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Unauthorized' })
  }

  await User.findByIdAndDelete(req.params.id)
  res.json({ success: true })
})
```

**Step 2: Use indirect references**

```javascript
// BAD: Direct database ID in URL (IDOR vulnerability)
app.get('/api/invoices/:id', async (req, res) => {
  const invoice = await Invoice.findById(req.params.id)
  res.json(invoice)  // Any user can access any invoice!
})

// GOOD: Check ownership
app.get('/api/invoices/:id', requireAuth, async (req, res) => {
  const invoice = await Invoice.findOne({
    _id: req.params.id,
    userId: req.user.id  // Ensure invoice belongs to user
  })

  if (!invoice) {
    return res.status(404).json({ error: 'Invoice not found' })
  }

  res.json(invoice)
})

// ALTERNATIVE: Use indirect references (mapping)
const invoiceMap = new Map()  // sessionId -> invoice IDs

app.get('/api/invoices/:reference', requireAuth, async (req, res) => {
  const invoiceId = invoiceMap.get(req.session.id, req.params.reference)

  if (!invoiceId) {
    return res.status(404).json({ error: 'Invoice not found' })
  }

  const invoice = await Invoice.findById(invoiceId)
  res.json(invoice)
})
```

**Step 3: Implement role-based access control (RBAC)**

```javascript
// Middleware for role checking
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Not authenticated' })
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' })
    }

    next()
  }
}

// Usage
app.get('/api/admin/users', requireRole('admin'), async (req, res) => {
  const users = await User.find()
  res.json(users)
})

app.post('/api/posts', requireRole('user', 'admin', 'moderator'), async (req, res) => {
  // Only authenticated users with specified roles can create posts
})
```

**Step 4: Deny by default**

```javascript
// BAD: Allow by default
function checkPermission(user, resource) {
  if (resource.private && user.id !== resource.userId) {
    return false
  }
  return true  // Default allow
}

// GOOD: Deny by default
function checkPermission(user, resource) {
  // Explicitly allow
  if (user.role === 'admin') return true
  if (resource.userId === user.id) return true

  // Default deny
  return false
}
```

### Verification
- [ ] All endpoints check authorization
- [ ] Users can only access their own data
- [ ] Admin functions require admin role
- [ ] Deny by default approach used
- [ ] Tested IDOR vulnerabilities
- [ ] Tested privilege escalation

---

## Security Misconfiguration

### Severity: MEDIUM-HIGH

### Common Issues
- Default credentials
- Unnecessary features enabled
- Detailed error messages
- Missing security headers
- Outdated software

### Remediation Steps

**Step 1: Disable debug mode in production**

```javascript
// BAD
app.set('DEBUG', true)

// GOOD
if (process.env.NODE_ENV !== 'production') {
  app.set('DEBUG', true)
} else {
  app.set('DEBUG', false)
}
```

**Step 2: Configure security headers**

```javascript
const helmet = require('helmet')

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  frameguard: {
    action: 'deny'
  },
  noSniff: true,
  xssFilter: true
}))
```

**Step 3: Generic error messages**

```javascript
// BAD: Exposes stack trace
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.stack })
})

// GOOD: Generic error to client, detailed log server-side
app.use((err, req, res, next) => {
  // Log detailed error server-side
  console.error('Error:', err.stack)

  // Send generic message to client
  res.status(500).json({
    error: 'An error occurred. Please try again later.'
  })
})
```

**Step 4: Disable unnecessary features**

```javascript
// Disable X-Powered-By header
app.disable('x-powered-by')

// Disable directory listing
app.use(express.static('public', {
  dotfiles: 'deny',
  index: false  // Disable directory listing
}))
```

**Step 5: Remove default credentials**

```javascript
// BAD: Default admin account
await User.create({
  username: 'admin',
  password: 'admin123'
})

// GOOD: Force admin to set password on first run
if (await User.countDocuments() === 0) {
  console.log('No admin user found. Please create one:')
  // Prompt for admin creation with strong password
}
```

### Verification
- [ ] Debug mode off in production
- [ ] Security headers configured
- [ ] Generic error messages
- [ ] No default credentials
- [ ] Unnecessary features disabled
- [ ] Software up to date

---

## Hardcoded Credentials

### Severity: CRITICAL

### Remediation Steps

**Step 1: Identify hardcoded secrets**

```bash
# Use secrets detection tools
trufflehog filesystem . --json

# Or manual search
grep -rn "password\s*=\|api_key\s*=\|secret\s*=" .
```

**Step 2: Move to environment variables**

```javascript
// BAD
const DB_PASSWORD = "MyP@ssw0rd123"
const API_KEY = "sk_live_abc123xyz"

// GOOD
require('dotenv').config()
const DB_PASSWORD = process.env.DB_PASSWORD
const API_KEY = process.env.API_KEY

// Validate on startup
if (!DB_PASSWORD || !API_KEY) {
  throw new Error('Required environment variables not set')
}
```

**Step 3: Create .env file (add to .gitignore)**

Create `.env`:
```
DB_PASSWORD=actual_password_here
API_KEY=actual_api_key_here
```

Update `.gitignore`:
```
.env
.env.local
.env.*.local
```

**Step 4: Provide .env.example template**

Create `.env.example`:
```
DB_PASSWORD=your_database_password
API_KEY=your_api_key
```

**Step 5: Rotate exposed credentials**

If credentials were committed to git:
1. Immediately rotate/deactivate exposed credentials
2. Scrub git history (see secrets remediation)
3. Update with new credentials in environment variables

**Step 6: Use secrets management for production**

```javascript
// AWS Secrets Manager
const AWS = require('aws-sdk')
const secretsManager = new AWS.SecretsManager()

async function getSecret(secretName) {
  const data = await secretsManager.getSecretValue({
    SecretId: secretName
  }).promise()

  return JSON.parse(data.SecretString)
}

// Usage
const dbCreds = await getSecret('prod/database/credentials')
const connection = await mysql.createConnection({
  host: dbCreds.host,
  user: dbCreds.username,
  password: dbCreds.password
})
```

### Verification
- [ ] No hardcoded passwords/keys in code
- [ ] All secrets in environment variables
- [ ] .env in .gitignore
- [ ] .env.example provided
- [ ] Exposed secrets rotated
- [ ] Secrets manager used for production

---

## Using Components with Known Vulnerabilities

### Severity: HIGH

### Remediation Steps

**Step 1: Audit dependencies**

```bash
# JavaScript
npm audit
npm audit --json > audit-report.json

# Python
pip-audit
safety check

# Ruby
bundle audit
```

**Step 2: Update vulnerable dependencies**

```bash
# JavaScript - Automatic fixes
npm audit fix

# For breaking changes, update manually
npm install package-name@latest

# Python
pip install --upgrade package-name

# Ruby
bundle update package-name
```

**Step 3: Review breaking changes**

Before updating:
1. Read release notes/changelog
2. Check for breaking changes
3. Update code if necessary
4. Run tests
5. Test in staging environment

**Step 4: Remove unused dependencies**

```bash
# JavaScript
npm uninstall unused-package

# Find unused packages
npx depcheck
```

**Step 5: Automate dependency scanning**

**GitHub Actions (.github/workflows/security.yml):**
```yaml
name: Dependency Scan
on:
  schedule:
    - cron: '0 0 * * *'  # Daily
  push:
    branches: [main]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm audit --audit-level=moderate
```

**Step 6: Use Dependabot/Renovate**

**GitHub Dependabot (.github/dependabot.yml):**
```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

### Verification
- [ ] npm audit shows no high/critical issues
- [ ] Unused dependencies removed
- [ ] Automated scanning in CI/CD
- [ ] Dependabot/Renovate enabled
- [ ] Process for reviewing/applying updates

---

## Quick Reference: Remediation Priority

| Severity | Response Time | Examples |
|----------|--------------|----------|
| Critical | Within 24 hours | SQL Injection, Hardcoded credentials, RCE |
| High | Within 1 week | XSS, Broken authentication, SSRF |
| Medium | Within 1 month | CSRF, Security misconfiguration |
| Low | Within 3 months | Information disclosure, Best practices |

---

## Post-Remediation Checklist

After fixing any vulnerability:

- [ ] Code fixed and tested
- [ ] Tests added to prevent regression
- [ ] Code reviewed by peer
- [ ] Deployed to staging
- [ ] Verified fix in staging
- [ ] Deployed to production
- [ ] Monitoring/alerting in place
- [ ] Documentation updated
- [ ] Team notified of changes
- [ ] Post-mortem completed (for critical issues)

---

## Additional Resources

- **OWASP Cheat Sheets:** https://cheatsheetseries.owasp.org/
- **CWE Mitigation:** https://cwe.mitre.org/
- **NIST Vulnerability Database:** https://nvd.nist.gov/
- **Security Tool Guides:** See secure-coding-standards.md
