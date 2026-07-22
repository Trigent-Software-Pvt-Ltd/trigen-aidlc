---
name: secrets
description: Detect exposed secrets, credentials, API keys, and tokens in code and git history. Provides remediation guidance and prevention strategies. (Triggers - find secrets, detect secrets, secret scan, credential leak, exposed keys, api key scan)
allowed-tools: [Bash, Read, Grep, Glob, Task, Write, Edit, AskUserQuestion]
argument-hint: "[path or --history]"
---

# Secrets Detection Skill

Scan for exposed secrets, credentials, API keys, tokens, and sensitive data in your codebase and git history. Get immediate remediation guidance to prevent security breaches.

## Reference Documents

Before proceeding, reference secure coding standards for secrets management:
- Secure Coding Standards: `{{SKILL_DIR}}/../../references/secure-coding-standards.md`
- Remediation Playbook: `{{SKILL_DIR}}/../../references/remediation-playbook.md`

---

## Phase 1: Input Detection and Scope

### 1.1 Parse User Input

The user can provide:
- **No arguments** - Scan current codebase (not git history)
- **Path** (e.g., `src/`, `config/`) - Scan specific directory
- **--history** flag - Scan git history for historical leaks
- **--all** flag - Scan codebase AND git history (comprehensive)

**Pattern detection:**
```
Input: {USER_INPUT}

Parsing...
- Empty → Current codebase only
- Path exists → Targeted scan
- Contains "--history" → Git history scan
- Contains "--all" → Comprehensive scan
```

### 1.2 Determine Scan Scope

If no input provided, ask user:

```
What would you like to scan for exposed secrets?

(1) Current codebase only (Recommended - fast)
(2) Git history (scan all commits)
(3) Both codebase and git history (comprehensive)
(4) Specific directory or file

Select an option:
```

**Warning for git history scans:**
```
⚠️ Git history scanning may take several minutes for large repositories.
This will scan all commits to find secrets that were committed and later removed.

Repository statistics:
- Total commits: {N}
- Estimated scan time: {X} minutes

Continue with git history scan? (Y/n)
```

---

## Phase 2: Environment Detection and Tool Check

### 2.1 Check for Secrets Detection Tools

Check for tools in this priority order:

**TruffleHog (Preferred - entropy analysis + pattern matching):**
```bash
trufflehog --version 2>/dev/null
```

**Gitleaks (Alternative - pattern-based with git history support):**
```bash
gitleaks version 2>/dev/null
```

**detect-secrets (Python-based, good for non-git workflows):**
```bash
detect-secrets --version 2>/dev/null
```

**git-secrets (AWS-focused, lightweight):**
```bash
git-secrets --version 2>/dev/null
```

**Tool availability status:**
```
Checking for secrets detection tools...

✓ TruffleHog v3.63.0 (Recommended)
✗ Gitleaks (not installed)
✗ detect-secrets (not installed)

Using: TruffleHog
```

**If NO tools available:**
```
No secrets detection tools found.

Recommended installations:
(1) TruffleHog (Recommended - entropy + patterns)
    macOS: brew install trufflehog
    Linux: wget https://github.com/trufflesecurity/trufflehog/releases/...
    Windows: Download from GitHub releases

(2) Gitleaks (Alternative - fast and lightweight)
    macOS: brew install gitleaks
    Linux: Download from GitHub releases

Would you like to:
(1) Continue with basic pattern-based scanning (Grep - less accurate)
(2) Exit and install tools first
(3) View installation instructions

Select an option:
```

If user selects basic scanning, proceed with Grep-based pattern detection (Phase 3B).

### 2.2 Check Git Repository Status

If git history scan is requested:

```bash
# Check if directory is a git repository
git rev-parse --is-inside-work-tree 2>/dev/null

# Get repository statistics
COMMIT_COUNT=$(git rev-list --count HEAD)
REPO_SIZE=$(du -sh .git | cut -f1)

echo "Repository info:"
echo "- Commits: $COMMIT_COUNT"
echo "- .git size: $REPO_SIZE"
```

If not a git repository:
```
This directory is not a git repository.

Git history scanning requires:
- Initialized git repository (git init)
- At least one commit

Would you like to:
(1) Scan current files only (no history)
(2) Exit
```

---

## Phase 3A: Tool-Based Secrets Scanning (Preferred)

### 3.1 TruffleHog Scanning

**For current codebase:**
```bash
trufflehog filesystem {SCAN_PATH} \
  --json \
  --no-update \
  --output trufflehog-results.json
```

**For git history:**
```bash
trufflehog git file://. \
  --json \
  --no-update \
  --output trufflehog-git-results.json
```

**TruffleHog detection methods:**
- **Entropy analysis**: Detects high-entropy strings (random-looking keys)
- **Pattern matching**: Regex patterns for 700+ secret types
- **Verification**: Attempts to verify if credentials are valid (optional)

**Secret types detected:**
- AWS Access Keys, Secret Keys
- Azure Connection Strings, Client Secrets
- GCP API Keys, Service Account JSON
- GitHub Personal Access Tokens, OAuth Tokens
- Slack Tokens, Webhooks
- Stripe API Keys
- Database connection strings (PostgreSQL, MySQL, MongoDB)
- Private keys (RSA, SSH, PGP)
- JWT secrets
- API keys from 700+ services

### 3.2 Gitleaks Scanning

**For current codebase:**
```bash
gitleaks detect \
  --source {SCAN_PATH} \
  --report-format json \
  --report-path gitleaks-results.json \
  --no-git
```

**For git history:**
```bash
gitleaks detect \
  --source . \
  --report-format json \
  --report-path gitleaks-git-results.json
```

**Gitleaks features:**
- 140+ built-in secret patterns
- Custom rule support
- Git history scanning
- Allowlisting for false positives

### 3.3 Parse Tool Results

Parse JSON output and normalize to common format:

**Common finding format:**
```json
{
  "id": "trufflehog-001",
  "tool": "TruffleHog",
  "secret_type": "AWS Access Key",
  "severity": "CRITICAL",
  "file": "config/aws.js",
  "line": 15,
  "commit": "a1b2c3d4" (if git history scan),
  "commit_date": "2024-01-15" (if git history scan),
  "secret_preview": "AKIA****************XYZAB",
  "match": "AKIAIOSFODNN7EXAMPLE",
  "verified": true,
  "description": "AWS Access Key detected and verified as valid",
  "remediation": "Rotate this AWS key immediately and use environment variables or AWS Secrets Manager"
}
```

**Severity classification:**
- **CRITICAL**: Verified active credentials (AWS, Azure, database passwords)
- **HIGH**: Likely valid but unverified (API keys, tokens with known patterns)
- **MEDIUM**: High-entropy strings, possible secrets
- **LOW**: Pattern match but low confidence (test keys, examples)

---

## Phase 3B: Fallback Pattern-Based Scanning (Grep)

If no tools available, use Grep-based pattern detection.

**Warning to user:**
```
Using basic pattern-based scanning. This method has limitations:
- Higher false positive rate
- Cannot verify if credentials are valid
- No entropy analysis
- Recommended: Install TruffleHog for better accuracy
```

### 3.4 Grep Patterns for Common Secrets

**AWS Credentials:**
```bash
# AWS Access Key ID
grep -rn "AKIA[0-9A-Z]{16}" {SCAN_PATH}

# AWS Secret Access Key pattern
grep -rn "aws_secret_access_key\s*=\s*['\"][A-Za-z0-9/+=]{40}['\"]" {SCAN_PATH}
```

**API Keys (Generic):**
```bash
# Common API key patterns
grep -rn "api[_-]?key\s*[:=]\s*['\"][A-Za-z0-9_-]{20,}['\"]" {SCAN_PATH}

# Bearer tokens
grep -rn "Bearer\s+[A-Za-z0-9_-]{20,}" {SCAN_PATH}
```

**Database Connection Strings:**
```bash
# PostgreSQL
grep -rn "postgresql://[^:]+:[^@]+@" {SCAN_PATH}

# MySQL
grep -rn "mysql://[^:]+:[^@]+@" {SCAN_PATH}

# MongoDB
grep -rn "mongodb://[^:]+:[^@]+@" {SCAN_PATH}
grep -rn "mongodb\+srv://[^:]+:[^@]+@" {SCAN_PATH}
```

**Private Keys:**
```bash
# RSA Private Key
grep -rn "BEGIN RSA PRIVATE KEY" {SCAN_PATH}

# SSH Private Key
grep -rn "BEGIN OPENSSH PRIVATE KEY" {SCAN_PATH}

# PGP Private Key
grep -rn "BEGIN PGP PRIVATE KEY" {SCAN_PATH}
```

**Cloud Provider Secrets:**
```bash
# Azure Connection String
grep -rn "DefaultEndpointsProtocol=https;AccountName=" {SCAN_PATH}

# GCP Service Account JSON
grep -rn "\"type\":\s*\"service_account\"" {SCAN_PATH}

# Heroku API Key
grep -rn "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}" {SCAN_PATH}
```

**Generic Passwords:**
```bash
# Password in configs
grep -rn "password\s*[:=]\s*['\"][^'\"]{8,}['\"]" {SCAN_PATH}

# DB_PASSWORD, API_PASSWORD, etc.
grep -rn "[A-Z_]*PASSWORD\s*[:=]" {SCAN_PATH}
```

**Hardcoded Secrets:**
```bash
# Common variable names with values
grep -rn "secret\s*[:=]\s*['\"][^'\"]{10,}['\"]" {SCAN_PATH}
grep -rn "token\s*[:=]\s*['\"][^'\"]{10,}['\"]" {SCAN_PATH}
grep -rn "client_secret\s*[:=]" {SCAN_PATH}
```

**JWT Secrets:**
```bash
# JWT secret keys
grep -rn "jwt[_-]?secret\s*[:=]" {SCAN_PATH}
```

**Slack Tokens:**
```bash
# Slack tokens (xoxb-, xoxp-, xoxa-)
grep -rn "xox[bpsa]-[0-9]{10,13}-[0-9]{10,13}-[A-Za-z0-9]{24,}" {SCAN_PATH}
```

**GitHub Tokens:**
```bash
# GitHub Personal Access Token
grep -rn "ghp_[A-Za-z0-9]{36}" {SCAN_PATH}

# GitHub OAuth Token
grep -rn "gho_[A-Za-z0-9]{36}" {SCAN_PATH}
```

**Stripe API Keys:**
```bash
# Stripe secret key
grep -rn "sk_live_[A-Za-z0-9]{24,}" {SCAN_PATH}

# Stripe restricted key
grep -rn "rk_live_[A-Za-z0-9]{24,}" {SCAN_PATH}
```

---

## Phase 4: Git History Deep Scan (If Requested)

### 4.1 Historical Commits Scan

If git history scan is requested and tools are available:

**Using TruffleHog:**
```bash
# Scan entire git history
trufflehog git file://. \
  --json \
  --no-update \
  --since-commit "" \
  --output trufflehog-history.json
```

**Using Gitleaks:**
```bash
# Scan all commits
gitleaks detect \
  --source . \
  --report-format json \
  --report-path gitleaks-history.json \
  --verbose
```

**Progress indicator:**
```
Scanning git history...
[################------------------] 55% (2,450 / 4,500 commits)
Estimated time remaining: 2 minutes
```

### 4.2 Analyze Historical Findings

For secrets found in git history:

**Check if secret still exists in current codebase:**
```bash
# For each historical finding, check if it's in current files
grep -r "{SECRET_PATTERN}" {CURRENT_FILES}
```

**Classify findings:**
- **Active leak**: Secret found in history AND current codebase (CRITICAL)
- **Removed leak**: Secret found in history but NOT in current codebase (HIGH - still in git history)
- **False positive**: Test data or example credentials (LOW)

**For removed leaks, find when it was removed:**
```bash
git log -S "{SECRET}" --all --pretty=format:"%h - %an, %ar : %s"
```

This shows:
- When the secret was added
- When the secret was removed
- Who committed it

---

## Phase 5: Results Presentation

### 5.1 Executive Summary

```
## Secrets Detection Results

Scanned: {N} files, {M} commits (if history scan)
Scan duration: {X} seconds

### Summary

| Severity | Current Code | Git History | Total |
|----------|--------------|-------------|-------|
| Critical | 3            | 5           | 8     |
| High     | 8            | 12          | 20    |
| Medium   | 15           | 8           | 23    |
| Low      | 20           | 15          | 35    |
| **Total**| **46**       | **40**      | **86**|

### Secret Types Found

| Type | Count | Status |
|------|-------|--------|
| AWS Access Keys | 3 | 2 Active, 1 Removed |
| API Keys (Generic) | 12 | 8 Active, 4 Removed |
| Database Passwords | 4 | 4 Active |
| Private Keys (RSA/SSH) | 2 | 2 Active |
| GitHub Tokens | 3 | 1 Active, 2 Removed |
| Slack Tokens | 2 | 2 Removed (still in history!) |
```

### 5.2 Critical Active Leaks (Immediate Action)

```
### CRITICAL: Active Secrets in Current Codebase

These secrets are currently exposed and need immediate remediation.

---

#### 1. AWS Access Key (VERIFIED ACTIVE)
**File:** config/aws-config.js:15
**Severity:** CRITICAL
**Status:** Active and verified

**Exposed Secret:**
\`\`\`javascript
15 | const AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
16 | const AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
\`\`\`

**Preview:** AKIA****************MPLE

**Verification:** ✅ This credential was verified as ACTIVE by attempting AWS STS GetCallerIdentity

**Impact:**
- Anyone with access to this repository can access your AWS account
- Potential unauthorized access to EC2, S3, RDS, and other AWS services
- Could result in data breaches or unexpected AWS charges

**IMMEDIATE ACTIONS:**
1. **Rotate this key NOW** (within 1 hour):
   - AWS Console → IAM → Users → {USER} → Security credentials → Make inactive
   - Create new access key

2. **Review AWS CloudTrail** for unauthorized access:
   \`\`\`bash
   aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue={USER}
   \`\`\`

3. **Fix the code** (use environment variables):
   \`\`\`javascript
   const AWS_ACCESS_KEY_ID = process.env.AWS_ACCESS_KEY_ID
   const AWS_SECRET_ACCESS_KEY = process.env.AWS_SECRET_ACCESS_KEY
   \`\`\`

4. **Add to .gitignore:**
   \`\`\`
   .env
   .env.local
   config/credentials.js
   \`\`\`

5. **Use AWS Secrets Manager** (recommended):
   \`\`\`javascript
   const AWS = require('aws-sdk')
   const secretsManager = new AWS.SecretsManager()
   const secret = await secretsManager.getSecretValue({SecretId: 'prod/aws/creds'}).promise()
   \`\`\`

**References:**
- AWS Secret Rotation: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
- AWS Secrets Manager: https://aws.amazon.com/secrets-manager/

**Git History Check:**
This secret also appears in git history:
- First commit: a1b2c3d (2023-05-12) - "Add AWS config"
- Commits containing secret: 45 commits over 8 months

⚠️ **After rotating, you must scrub git history** (see remediation guidance below)

---

#### 2. PostgreSQL Database Password
**File:** src/database/connection.js:8
**Severity:** CRITICAL
**Status:** Active

**Exposed Secret:**
\`\`\`javascript
8 | const DATABASE_URL = "postgresql://admin:SuperSecret123!@prod-db.example.com:5432/production"
\`\`\`

**Preview:** postgresql://admin:Super***********@prod-db.example.com:5432/production

**Impact:**
- Direct access to production database
- Ability to read, modify, or delete all application data
- Potential data breach affecting users

**IMMEDIATE ACTIONS:**
1. **Change database password** (within 1 hour):
   \`\`\`sql
   ALTER USER admin WITH PASSWORD 'new-secure-password-from-password-manager';
   \`\`\`

2. **Check database logs** for unauthorized access:
   \`\`\`sql
   SELECT * FROM pg_stat_activity WHERE usename = 'admin';
   \`\`\`

3. **Use environment variables:**
   \`\`\`javascript
   const DATABASE_URL = process.env.DATABASE_URL
   \`\`\`

4. **Consider connection string encryption** or use a secrets manager

---

#### 3. Stripe Secret API Key
**File:** src/payments/stripe.ts:12
**Severity:** CRITICAL
**Status:** Active (Live mode key)

**Exposed Secret:**
\`\`\`typescript
12 | const stripe = new Stripe('sk_live_51H7qK2L...[REDACTED]', {
\`\`\`

**Preview:** sk_live_51*********************

**Verification:** ⚠️ Could not verify (requires Stripe API call - not attempted)

**Impact:**
- Unauthorized charges to customer credit cards
- Access to customer payment information
- Ability to issue refunds
- Financial and reputational damage

**IMMEDIATE ACTIONS:**
1. **Roll this API key** in Stripe Dashboard:
   - Dashboard → Developers → API keys → Roll key

2. **Review recent charges** for suspicious activity:
   - Check Stripe Dashboard for unexpected transactions

3. **Use environment variables:**
   \`\`\`typescript
   const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
   \`\`\`

4. **Enable Stripe Radar** for fraud detection

---
```

### 5.3 High Severity: Secrets in Git History

```
### HIGH: Secrets Removed from Code but Still in Git History

These secrets were removed from current code but still exist in git history.
Anyone who clones the repository can find them.

---

#### 4. GitHub Personal Access Token
**Commits:** 12 commits (2023-06-01 to 2023-08-15)
**Removed:** 2023-08-15 (commit: f4e5d6c)
**Files:** .github/scripts/auto-deploy.sh

**Exposed Secret Preview:** ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxx

**Impact:**
- Access to your GitHub repositories
- Ability to push code, create releases, modify issues
- Potential supply chain attack vector

**REMEDIATION:**
1. **Revoke this token** on GitHub:
   - GitHub → Settings → Developer settings → Personal access tokens → Revoke

2. **Scrub from git history:**
   \`\`\`bash
   # Use BFG Repo Cleaner or git filter-repo
   git filter-repo --path .github/scripts/auto-deploy.sh --invert-paths

   # Or use BFG
   bfg --delete-files auto-deploy.sh
   \`\`\`

3. **Force push** (COORDINATE WITH TEAM FIRST):
   \`\`\`bash
   git push --force --all
   git push --force --tags
   \`\`\`

4. **Notify team** to re-clone repository

⚠️ **Warning:** Rewriting git history is destructive. Ensure team is aware.

**Alternative:** If you cannot rewrite history (shared repo), at minimum:
- Revoke the exposed token
- Monitor for unauthorized access
- Document the incident

---

#### 5. Slack Webhook URL
**Commits:** 8 commits (2024-01-10 to 2024-02-01)
**Removed:** 2024-02-01 (commit: c7d8e9f)
**Files:** config/notifications.js

**Exposed Secret Preview:** https://hooks.slack.com/services/T00000000/B00000000/xxxx...

**Impact:**
- Unauthorized messages to Slack channels
- Potential phishing or social engineering attacks
- Spam or information leakage

**REMEDIATION:**
1. **Regenerate webhook** in Slack:
   - Workspace settings → Manage apps → Incoming Webhooks → Regenerate

2. **Use environment variables** for new webhook

3. **Consider scrubbing git history** (same process as above)

---
```

### 5.4 Medium and Low Findings

```
### Medium Severity Issues (23)

| ID | Type | File | Line | Status |
|----|------|------|------|--------|
| M-1 | Generic API Key | src/api/client.js | 28 | Active |
| M-2 | High Entropy String | config/tokens.js | 42 | Active |
| M-3 | JWT Secret | src/auth/jwt.js | 15 | Active |
...

### Low Severity Issues (35)

Likely false positives or test credentials. Review manually.

[Collapsed by default - click to expand]
```

### 5.5 File Hotspots

```
### Files with Most Secrets

| File | Secret Count | Types |
|------|--------------|-------|
| config/aws-config.js | 5 | AWS Keys, Tokens |
| .env.example | 12 | Examples (Low severity) |
| src/database/connection.js | 3 | DB Passwords |
| tests/fixtures/mock-data.js | 8 | Test data (Low severity) |

**Recommendation:** Review security practices for frequently affected files.
```

---

## Phase 6: Remediation Guidance

### 6.1 General Remediation Steps

```
## How to Fix Exposed Secrets

### Step 1: Rotate Immediately
For each active secret:
1. Deactivate/revoke the exposed credential
2. Generate a new credential
3. Update production systems with new credential
4. Verify systems are working with new credential

### Step 2: Remove from Code
Replace hardcoded secrets with environment variables:

**Before (Insecure):**
\`\`\`javascript
const API_KEY = "sk_live_1234567890abcdef"
\`\`\`

**After (Secure):**
\`\`\`javascript
const API_KEY = process.env.API_KEY
\`\`\`

Create `.env` file (add to .gitignore):
\`\`\`
API_KEY=sk_live_1234567890abcdef
DATABASE_URL=postgresql://user:pass@host/db
\`\`\`

### Step 3: Update .gitignore
Add patterns to prevent future leaks:
\`\`\`
# Environment variables
.env
.env.local
.env.*.local

# Credentials
**/credentials.json
**/secrets.yml
**/*_rsa
**/*.pem

# Cloud provider configs
.aws/credentials
.azure/credentials
gcloud/credentials.json
\`\`\`

### Step 4: Scrub Git History (If Needed)

⚠️ **Warning:** This is a destructive operation. Coordinate with team.

**Option A: BFG Repo Cleaner (Recommended)**
\`\`\`bash
# Install BFG
brew install bfg  # macOS
# or download from https://rtyley.github.io/bfg-repo-cleaner/

# Backup repository
cp -r . ../repo-backup

# Remove secrets file
bfg --delete-files credentials.json

# Or remove text patterns
bfg --replace-text patterns.txt  # File with SECRET==> patterns

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (COORDINATE WITH TEAM)
git push --force --all
git push --force --tags
\`\`\`

**Option B: git-filter-repo**
\`\`\`bash
# Install
pip install git-filter-repo

# Remove file from history
git filter-repo --path config/secrets.js --invert-paths

# Force push
git push --force --all
\`\`\`

**After rewriting history:**
1. Team must re-clone repository: `git clone {URL} new-folder`
2. Old clones will be out of sync
3. Update CI/CD pipelines to re-clone

### Step 5: Implement Secrets Management

**For local development:**
- Use `.env` files with `dotenv` library
- Add `.env` to `.gitignore`
- Provide `.env.example` template (no real secrets)

**For production:**
- **AWS:** AWS Secrets Manager, AWS Systems Manager Parameter Store
- **Azure:** Azure Key Vault
- **GCP:** Google Secret Manager
- **Kubernetes:** Kubernetes Secrets, External Secrets Operator
- **HashiCorp Vault:** Enterprise secrets management

**Example (AWS Secrets Manager):**
\`\`\`javascript
const AWS = require('aws-sdk')
const secretsManager = new AWS.SecretsManager()

async function getSecret(secretName) {
  const data = await secretsManager.getSecretValue({SecretId: secretName}).promise()
  return JSON.parse(data.SecretString)
}

const dbCreds = await getSecret('prod/database/credentials')
\`\`\`

### Step 6: Prevent Future Leaks

**Pre-commit hooks:**

Install and configure git-secrets or Talisman:

\`\`\`bash
# AWS git-secrets
brew install git-secrets
git secrets --install
git secrets --register-aws

# Talisman
curl https://thoughtworks.github.io/talisman/install.sh > ~/install-talisman.sh
chmod +x ~/install-talisman.sh
~/install-talisman.sh
\`\`\`

**CI/CD scanning:**

Add secrets detection to your pipeline:

\`\`\`yaml
# GitHub Actions
- name: TruffleHog Scan
  uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
    head: HEAD
\`\`\`

**Regular audits:**

Run `/security:secrets` weekly or on every PR.
\`\`\`

### 6.2 Service-Specific Remediation Links

```
### Credential Rotation Guides

| Service | Rotation Guide |
|---------|----------------|
| AWS | https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html |
| Azure | https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal |
| GCP | https://cloud.google.com/iam/docs/creating-managing-service-account-keys |
| GitHub | https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token |
| GitLab | https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html |
| Stripe | https://stripe.com/docs/keys#roll-keys |
| Slack | https://api.slack.com/authentication/rotation |
| Database Passwords | Contact your DBA or see database documentation |
```

---

## Phase 7: Prevention and Next Steps

### 7.1 Ask User for Actions

```
What would you like to do next?

(1) Get detailed remediation steps for Critical findings
(2) Generate git history scrubbing script
(3) Create .gitignore rules to prevent future leaks
(4) Create Jira issues for each finding
(5) Export report (JSON/Markdown)
(6) Set up pre-commit hooks
(7) Exit

Select an option:
```

### 7.2 Generate .gitignore Rules

If user selects option 3, generate comprehensive .gitignore:

```bash
cat >> .gitignore <<'EOF'
# Secrets and Environment Variables
.env
.env.local
.env.*.local
.envrc

# Credentials
credentials.json
secrets.yml
secrets.yaml
**/credentials/
**/secrets/

# Private Keys
*.pem
*.key
*_rsa
*_dsa
*.p12
*.pfx

# Cloud Provider Configs
.aws/credentials
.aws/config
.azure/credentials
gcloud/credentials.json
gcloud/application_default_credentials.json

# Database
*.sql (if contains sensitive data)
database.yml (if contains passwords)

# API Keys and Tokens
.apikey
.token
*.license

# IDE and Tool-Specific
.idea/dataSources.xml
.vscode/settings.json (if contains secrets)
EOF

echo "Updated .gitignore with security patterns"
```

### 7.3 Generate Pre-Commit Hook Script

If user selects option 6:

```bash
# Create pre-commit hook
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash

# Run secrets detection before commit
echo "Running secrets detection..."

if command -v trufflehog &> /dev/null; then
    trufflehog filesystem . --json --fail
    if [ $? -ne 0 ]; then
        echo "❌ Secrets detected! Commit blocked."
        echo "Run '/security:secrets' to review findings."
        exit 1
    fi
else
    echo "⚠️  TruffleHog not installed. Install for pre-commit scanning."
fi

echo "✅ No secrets detected."
EOF

chmod +x .git/hooks/pre-commit

echo "Pre-commit hook installed. Commits with secrets will be blocked."
```

### 7.4 Export Report

**Markdown export:**
```bash
cat > SECRETS_REPORT.md <<EOF
# Secrets Detection Report

Generated: $(date)

{FULL_MARKDOWN_REPORT}
EOF

echo "Report saved to SECRETS_REPORT.md"
```

**JSON export:**
```bash
cat > secrets-scan-results.json <<EOF
{FULL_JSON_RESULTS}
EOF

echo "Results saved to secrets-scan-results.json"
```

---

## Error Handling

### Tool Not Found

```
TruffleHog not found. Install it for better secret detection.

Installation:
- macOS: brew install trufflehog
- Linux: wget https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_linux_amd64.tar.gz
- Windows: Download from GitHub releases

Or use Gitleaks as alternative:
- macOS: brew install gitleaks
```

### No Secrets Found

```
## Secrets Detection Results

✅ No secrets detected!

Scanned: {N} files
Duration: {X} seconds

### What was checked:
✓ AWS credentials
✓ API keys and tokens
✓ Database passwords
✓ Private keys
✓ Cloud provider secrets
✓ 700+ secret patterns

### Recommendations:
- Continue using environment variables for secrets
- Run `/security:secrets` before every release
- Enable pre-commit hooks to prevent accidental commits
- Consider secrets management (AWS Secrets Manager, Vault)
```

### Large Repository Warning

```
⚠️ Large repository detected ({SIZE} GB, {N} commits)

Git history scan may take 15+ minutes.

Options:
(1) Scan recent history only (last 100 commits)
(2) Scan full history (slow but thorough)
(3) Skip git history, scan current code only

Select an option:
```

---

## Tool Installation Guide

### Installing TruffleHog (Recommended)

**macOS:**
```bash
brew install trufflehog
```

**Linux:**
```bash
wget https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_linux_amd64.tar.gz
tar -xzf trufflehog_linux_amd64.tar.gz
sudo mv trufflehog /usr/local/bin/
```

**Windows:**
```powershell
# Download from GitHub releases
# https://github.com/trufflesecurity/trufflehog/releases
# Extract and add to PATH
```

**Verify:**
```bash
trufflehog --version
```

### Installing Gitleaks (Alternative)

**macOS:**
```bash
brew install gitleaks
```

**Linux:**
```bash
wget https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_linux_amd64.tar.gz
tar -xzf gitleaks_linux_amd64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

**Verify:**
```bash
gitleaks version
```

---

## Success Criteria

A successful secrets scan includes:

1. ✓ Environment and tools checked
2. ✓ Codebase scanned for exposed secrets
3. ✓ Git history scanned (if requested)
4. ✓ Results categorized by severity
5. ✓ Active vs. removed secrets identified
6. ✓ Specific remediation guidance provided
7. ✓ Prevention strategies recommended

The user should leave with:
- Clear list of exposed secrets and severity
- Actionable remediation steps
- Tools to prevent future leaks
- Confidence that secrets are secured
