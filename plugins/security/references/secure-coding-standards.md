# Secure Coding Standards by Language

This document provides language-specific secure coding guidelines and best practices.

---

## Table of Contents

1. [JavaScript/TypeScript](#javascripttypescript)
2. [Python](#python)
3. [Ruby](#ruby)
4. [Go](#go)
5. [Java](#java)
6. [C#/.NET](#cnet)
7. [General Security Principles](#general-security-principles)

---

## JavaScript/TypeScript

### Input Validation

```javascript
// BAD: No validation
app.post('/api/users', (req, res) => {
  const user = req.body
  db.createUser(user)
})

// GOOD: Schema validation
const Joi = require('joi')

const userSchema = Joi.object({
  email: Joi.string().email().required(),
  age: Joi.number().integer().min(13).max(120).required(),
  username: Joi.string().alphanum().min(3).max(30).required()
})

app.post('/api/users', (req, res) => {
  const { error, value } = userSchema.validate(req.body)
  if (error) {
    return res.status(400).json({ error: error.details[0].message })
  }
  db.createUser(value)
})
```

### SQL Injection Prevention

```javascript
// BAD: String concatenation
const query = `SELECT * FROM users WHERE email = '${userEmail}'`
db.query(query)

// GOOD: Parameterized queries
const query = 'SELECT * FROM users WHERE email = ?'
db.query(query, [userEmail])

// GOOD: ORM (Sequelize example)
const user = await User.findOne({ where: { email: userEmail } })
```

### XSS Prevention

```javascript
// BAD: Unsafe HTML rendering
res.send(`<h1>Welcome ${username}</h1>`)

// GOOD: Use templating with auto-escaping
res.render('welcome', { username })  // EJS, Pug, Handlebars auto-escape

// GOOD: Manual escaping
const escapeHTML = (str) => {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
}
res.send(`<h1>Welcome ${escapeHTML(username)}</h1>`)

// GOOD: Content Security Policy
app.use((req, res, next) => {
  res.setHeader("Content-Security-Policy", "default-src 'self'")
  next()
})
```

### Authentication & Session Management

```javascript
// BAD: Weak session
app.use(session({
  secret: 'keyboard cat',  // Weak secret
  resave: true,
  saveUninitialized: true
}))

// GOOD: Secure session
const crypto = require('crypto')
app.use(session({
  secret: process.env.SESSION_SECRET,  // Strong, random secret from env
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,        // HTTPS only
    httpOnly: true,      // No JavaScript access
    sameSite: 'strict',  // CSRF protection
    maxAge: 3600000      // 1 hour
  }
}))

// Password hashing
const bcrypt = require('bcrypt')

// BAD: Plain text or weak hashing
const hashedPassword = md5(password)

// GOOD: bcrypt with salt
const saltRounds = 10
const hashedPassword = await bcrypt.hash(password, saltRounds)

// Verification
const match = await bcrypt.compare(inputPassword, storedHash)
```

### CSRF Protection

```javascript
const csrf = require('csurf')
const csrfProtection = csrf({ cookie: true })

app.get('/form', csrfProtection, (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() })
})

app.post('/process', csrfProtection, (req, res) => {
  res.send('Data is being processed')
})
```

### Secure Randomness

```javascript
// BAD: Predictable
const token = Math.random().toString(36).substring(7)

// GOOD: Cryptographically secure
const crypto = require('crypto')
const token = crypto.randomBytes(32).toString('hex')
```

### Environment Variables (Secrets)

```javascript
// BAD: Hardcoded
const API_KEY = 'sk_live_abc123xyz'
const DB_PASSWORD = 'MyPassword123'

// GOOD: Environment variables
require('dotenv').config()
const API_KEY = process.env.API_KEY
const DB_PASSWORD = process.env.DB_PASSWORD

// Validate critical env vars on startup
if (!API_KEY || !DB_PASSWORD) {
  throw new Error('Missing required environment variables')
}
```

### Rate Limiting

```javascript
const rateLimit = require('express-rate-limit')

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests, please try again later.'
})

app.use('/api/', limiter)

// Stricter limit for authentication
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true
})

app.post('/login', authLimiter, loginHandler)
```

### Security Headers

```javascript
const helmet = require('helmet')

app.use(helmet())  // Sets multiple security headers

// Or configure individually:
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    styleSrc: ["'self'", "'unsafe-inline'"],
    scriptSrc: ["'self'"],
    imgSrc: ["'self'", "data:", "https:"]
  }
}))

app.use(helmet.hsts({
  maxAge: 31536000,
  includeSubDomains: true,
  preload: true
}))
```

### File Upload Security

```javascript
const multer = require('multer')
const path = require('path')
const crypto = require('crypto')

const storage = multer.diskStorage({
  destination: './uploads/',  // Outside webroot!
  filename: (req, file, cb) => {
    // Generate safe filename
    const uniqueName = crypto.randomBytes(16).toString('hex')
    const ext = path.extname(file.originalname).toLowerCase()
    cb(null, `${uniqueName}${ext}`)
  }
})

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024  // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allowlist file types
    const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf']
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true)
    } else {
      cb(new Error('Invalid file type'))
    }
  }
})
```

---

## Python

### Input Validation

```python
# BAD: No validation
def create_user(data):
    user = User(**data)
    user.save()

# GOOD: Pydantic validation
from pydantic import BaseModel, EmailStr, validator

class UserCreate(BaseModel):
    email: EmailStr
    age: int
    username: str

    @validator('age')
    def age_must_be_valid(cls, v):
        if v < 13 or v > 120:
            raise ValueError('age must be between 13 and 120')
        return v

    @validator('username')
    def username_alphanumeric(cls, v):
        if not v.isalnum():
            raise ValueError('username must be alphanumeric')
        return v

def create_user(data: dict):
    validated_data = UserCreate(**data)
    user = User(**validated_data.dict())
    user.save()
```

### SQL Injection Prevention

```python
import psycopg2

# BAD: String formatting
email = request.form['email']
query = f"SELECT * FROM users WHERE email = '{email}'"
cursor.execute(query)

# GOOD: Parameterized queries
email = request.form['email']
query = "SELECT * FROM users WHERE email = %s"
cursor.execute(query, (email,))

# GOOD: ORM (SQLAlchemy)
from sqlalchemy import select
user = session.execute(select(User).filter_by(email=email)).scalar_one()
```

### Password Hashing

```python
# BAD: Weak hashing
import hashlib
hashed = hashlib.md5(password.encode()).hexdigest()

# GOOD: bcrypt
import bcrypt

# Hashing
salt = bcrypt.gensalt()
hashed = bcrypt.hashpw(password.encode('utf-8'), salt)

# Verification
if bcrypt.checkpw(input_password.encode('utf-8'), stored_hash):
    print("Password matches")
```

### Secrets Management

```python
# BAD: Hardcoded
API_KEY = "sk_live_abc123xyz"
DB_PASSWORD = "MyPassword123"

# GOOD: Environment variables
import os
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv('API_KEY')
DB_PASSWORD = os.getenv('DB_PASSWORD')

if not API_KEY:
    raise ValueError("API_KEY environment variable not set")
```

### Secure Randomness

```python
# BAD: Predictable
import random
token = ''.join(random.choices('abcdefghijklmnopqrstuvwxyz', k=20))

# GOOD: Cryptographically secure
import secrets
token = secrets.token_urlsafe(32)
```

### Path Traversal Prevention

```python
import os

# BAD: No validation
filename = request.args.get('file')
with open(f'/uploads/{filename}', 'r') as f:
    content = f.read()

# GOOD: Validate path
import os.path

filename = request.args.get('file')
filepath = os.path.normpath(os.path.join('/uploads', filename))

# Ensure path is within allowed directory
if not filepath.startswith('/uploads/'):
    raise ValueError("Invalid file path")

with open(filepath, 'r') as f:
    content = f.read()
```

### Command Injection Prevention

```python
import subprocess

# BAD: Shell=True with user input
filename = request.args.get('file')
subprocess.run(f'cat {filename}', shell=True)

# GOOD: Use list arguments, no shell
filename = request.args.get('file')
subprocess.run(['cat', filename], shell=False)

# BETTER: Use Python libraries instead of shell commands
with open(filename, 'r') as f:
    content = f.read()
```

### Django Security

```python
# settings.py
DEBUG = False  # Never True in production

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')

ALLOWED_HOSTS = ['yourdomain.com']

# Security middleware
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# Security settings
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'

# HSTS
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

---

## Ruby

### SQL Injection Prevention

```ruby
# BAD: String interpolation
email = params[:email]
User.where("email = '#{email}'")

# GOOD: Parameterized queries
email = params[:email]
User.where("email = ?", email)

# GOOD: Hash conditions (ActiveRecord)
User.where(email: email)
```

### Mass Assignment Protection

```ruby
# BAD: Unprotected attributes
User.create(params[:user])  # Attacker can set admin=true

# GOOD: Strong parameters (Rails)
def user_params
  params.require(:user).permit(:email, :username, :age)
end

User.create(user_params)
```

### CSRF Protection (Rails)

```ruby
# ApplicationController
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# In forms
<%= form_with model: @user do |f| %>
  <%= f.hidden_field :authenticity_token %>
  ...
<% end %>
```

### Secrets Management

```ruby
# BAD: Hardcoded
API_KEY = "sk_live_abc123xyz"

# GOOD: Environment variables
API_KEY = ENV['API_KEY']

# Rails encrypted credentials
# config/credentials.yml.enc (encrypted)
Rails.application.credentials.api_key
```

### Command Injection Prevention

```ruby
# BAD: Backticks with user input
filename = params[:file]
content = `cat #{filename}`

# GOOD: Use Ruby methods
filename = params[:file]
content = File.read(filename)

# If shell is necessary, use array syntax
system('cat', filename)  # Safer than system("cat #{filename}")
```

---

## Go

### SQL Injection Prevention

```go
// BAD: String concatenation
email := r.FormValue("email")
query := fmt.Sprintf("SELECT * FROM users WHERE email = '%s'", email)
db.Query(query)

// GOOD: Parameterized queries
email := r.FormValue("email")
query := "SELECT * FROM users WHERE email = $1"
db.Query(query, email)
```

### Input Validation

```go
import (
    "github.com/go-playground/validator/v10"
)

type User struct {
    Email    string `validate:"required,email"`
    Age      int    `validate:"required,gte=13,lte=120"`
    Username string `validate:"required,alphanum,min=3,max=30"`
}

func createUser(data User) error {
    validate := validator.New()
    if err := validate.Struct(data); err != nil {
        return err
    }
    // Proceed with validated data
    return nil
}
```

### Cryptographic Operations

```go
import (
    "crypto/rand"
    "crypto/subtle"
    "golang.org/x/crypto/bcrypt"
)

// Password hashing
func hashPassword(password string) (string, error) {
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(bytes), err
}

// Password verification
func checkPassword(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}

// Secure random token
func generateToken() (string, error) {
    b := make([]byte, 32)
    if _, err := rand.Read(b); err != nil {
        return "", err
    }
    return hex.EncodeToString(b), nil
}

// Constant-time comparison (prevent timing attacks)
func compareHMAC(mac1, mac2 []byte) bool {
    return subtle.ConstantTimeCompare(mac1, mac2) == 1
}
```

### Error Handling (Don't leak info)

```go
// BAD: Exposes internal errors
if err != nil {
    http.Error(w, err.Error(), http.StatusInternalServerError)
}

// GOOD: Generic error to client, log details server-side
if err != nil {
    log.Printf("Error processing request: %v", err)
    http.Error(w, "Internal server error", http.StatusInternalServerError)
}
```

---

## Java

### SQL Injection Prevention

```java
// BAD: String concatenation
String email = request.getParameter("email");
String query = "SELECT * FROM users WHERE email = '" + email + "'";
Statement stmt = connection.createStatement();
ResultSet rs = stmt.executeQuery(query);

// GOOD: PreparedStatement
String email = request.getParameter("email");
String query = "SELECT * FROM users WHERE email = ?";
PreparedStatement pstmt = connection.prepareStatement(query);
pstmt.setString(1, email);
ResultSet rs = pstmt.executeQuery();
```

### Input Validation

```java
import javax.validation.constraints.*;

public class User {
    @NotNull
    @Email
    private String email;

    @Min(13)
    @Max(120)
    private int age;

    @NotNull
    @Pattern(regexp = "^[a-zA-Z0-9]{3,30}$")
    private String username;
}

// In controller
@PostMapping("/users")
public ResponseEntity createUser(@Valid @RequestBody User user) {
    // user is validated
    return ResponseEntity.ok().build();
}
```

### Password Hashing

```java
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

public class PasswordService {
    private BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    public String hashPassword(String plaintext) {
        return encoder.encode(plaintext);
    }

    public boolean checkPassword(String plaintext, String hashed) {
        return encoder.matches(plaintext, hashed);
    }
}
```

### Secure Randomness

```java
// BAD: Predictable
Random random = new Random();
int token = random.nextInt();

// GOOD: Cryptographically secure
import java.security.SecureRandom;

SecureRandom secureRandom = new SecureRandom();
byte[] token = new byte[32];
secureRandom.nextBytes(token);
```

---

## C#/.NET

### SQL Injection Prevention

```csharp
// BAD: String concatenation
string email = Request.Form["email"];
string query = $"SELECT * FROM Users WHERE Email = '{email}'";
SqlCommand cmd = new SqlCommand(query, connection);

// GOOD: Parameterized queries
string email = Request.Form["email"];
string query = "SELECT * FROM Users WHERE Email = @Email";
SqlCommand cmd = new SqlCommand(query, connection);
cmd.Parameters.AddWithValue("@Email", email);
```

### Input Validation

```csharp
using System.ComponentModel.DataAnnotations;

public class User
{
    [Required]
    [EmailAddress]
    public string Email { get; set; }

    [Range(13, 120)]
    public int Age { get; set; }

    [Required]
    [RegularExpression(@"^[a-zA-Z0-9]{3,30}$")]
    public string Username { get; set; }
}
```

### Password Hashing

```csharp
using Microsoft.AspNetCore.Identity;

public class PasswordService
{
    private readonly PasswordHasher<string> _hasher = new PasswordHasher<string>();

    public string HashPassword(string password)
    {
        return _hasher.HashPassword(null, password);
    }

    public bool VerifyPassword(string hashedPassword, string providedPassword)
    {
        var result = _hasher.VerifyHashedPassword(null, hashedPassword, providedPassword);
        return result == PasswordVerificationResult.Success;
    }
}
```

---

## General Security Principles

### Principle of Least Privilege
- Grant minimum necessary permissions
- Use service accounts with limited access
- Avoid running as root/admin

### Defense in Depth
- Multiple layers of security
- Don't rely on single control
- Assume other controls may fail

### Fail Securely
- Default deny for access control
- Graceful error handling
- Don't expose sensitive info in errors

### Complete Mediation
- Check permissions on every access
- Don't cache authorization decisions
- Validate on server side, not client

### Keep Security Simple
- Complex security is hard to maintain
- Use established libraries/frameworks
- Avoid "rolling your own crypto"

### Separation of Duties
- Different people for different roles
- Require multiple approvals for critical operations
- Audit trails for accountability

---

## Security Checklist

### Authentication
- [ ] Multi-factor authentication implemented
- [ ] Strong password policy enforced
- [ ] Account lockout after failed attempts
- [ ] Password reset tokens expire
- [ ] Sessions invalidated on logout

### Authorization
- [ ] All endpoints require authentication
- [ ] Role-based access control implemented
- [ ] Users can only access their own data
- [ ] Admin functions properly protected

### Input Validation
- [ ] All user input validated
- [ ] Allowlist approach used
- [ ] Server-side validation (don't trust client)
- [ ] File upload restrictions in place

### Output Encoding
- [ ] HTML output encoded (XSS prevention)
- [ ] SQL queries parameterized
- [ ] Command injection prevented
- [ ] JSON properly encoded

### Cryptography
- [ ] HTTPS/TLS enforced
- [ ] Strong algorithms used (no MD5/SHA1)
- [ ] Passwords hashed with bcrypt/argon2
- [ ] Secrets in environment variables

### Error Handling
- [ ] Generic errors to users
- [ ] Detailed logs server-side
- [ ] No stack traces exposed
- [ ] Debug mode off in production

### Security Headers
- [ ] Content-Security-Policy set
- [ ] X-Frame-Options set
- [ ] X-Content-Type-Options set
- [ ] Strict-Transport-Security set

### Dependencies
- [ ] Dependencies regularly updated
- [ ] Vulnerability scanning automated
- [ ] No known vulnerable packages
- [ ] License compliance checked
