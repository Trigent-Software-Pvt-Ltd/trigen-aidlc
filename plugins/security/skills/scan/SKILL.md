---
name: scan
description: Comprehensive security scanning - SAST analysis, dependency vulnerabilities, and code security issues. Supports JavaScript/TypeScript, Python, Ruby, Go, Java, .NET. (Triggers - security scan, sec scan, security audit, vuln scan, sast scan)
allowed-tools: [Bash, Read, Grep, Glob, Task, Write, Edit, AskUserQuestion]
argument-hint: "[path or --focus <area>]"
---

# Security Scan Skill

Run comprehensive security analysis on your codebase to identify vulnerabilities, insecure code patterns, and dependency issues.

## Reference Documents

Before proceeding, read these reference documents to understand vulnerability classifications:
- OWASP Top 10: `{{SKILL_DIR}}/../../references/owasp-top10.md`
- CWE Top 25: `{{SKILL_DIR}}/../../references/cwe-top25.md`
- Secure Coding Standards: `{{SKILL_DIR}}/../../references/secure-coding-standards.md`

---

## Phase 1: Input Detection and Scope

### 1.1 Parse User Input

The user can provide:
- **No arguments** - Scan entire repository
- **Path** (e.g., `src/auth`, `app.py`) - Scan specific directory or file
- **Focus flag** (e.g., `--focus dependencies`) - Run only specific scan type

**Focus options:**
- `dependencies` - Only scan dependency vulnerabilities
- `sast` - Only run static analysis
- `config` - Only check security configurations
- `all` - Full scan (default)

**Pattern detection:**
```
Input: {USER_INPUT}

Parsing...
- Empty or "." → Full repository scan
- Path exists → Targeted scan
- Contains "--focus" → Specific scan type
```

### 1.2 Determine Scan Scope

If no input provided, ask user:

```
What would you like to scan for security issues?

(1) Full repository scan (Recommended)
(2) Specific directory or file
(3) Changed files only (git diff)
(4) Dependencies only (quick scan)

Select an option:
```

If user selects "Changed files only":
```bash
git diff --name-only HEAD
```

Store the list of files to scan.

---

## Phase 2: Environment Detection

### 2.1 Detect Project Languages and Frameworks

Scan the target scope to identify:

**Language detection:**
- Check for `package.json`, `*.js`, `*.ts` → JavaScript/TypeScript
- Check for `requirements.txt`, `Pipfile`, `*.py` → Python
- Check for `Gemfile`, `*.rb` → Ruby
- Check for `go.mod`, `*.go` → Go
- Check for `pom.xml`, `build.gradle`, `*.java` → Java
- Check for `*.csproj`, `*.cs` → .NET/C#

**Framework detection:**
- `express`, `koa` in package.json → Node.js web app
- `react`, `vue`, `angular` → Frontend framework
- `django`, `flask` in requirements → Python web framework
- `rails` in Gemfile → Ruby on Rails
- Check imports in code files for frameworks

**Output:**
```
Detected project stack:
- Languages: JavaScript (Node.js 18), Python 3.11
- Frameworks: Express.js, React
- Package managers: npm, pip
```

### 2.2 Check Available Security Tools

Check for security tools in this priority order:

#### JavaScript/TypeScript Tools
```bash
# Semgrep (preferred - multi-language SAST)
semgrep --version 2>/dev/null

# npm audit (dependency scanning)
npm --version 2>/dev/null

# ESLint with security plugin
npx eslint --version 2>/dev/null
```

#### Python Tools
```bash
# Semgrep (preferred)
semgrep --version 2>/dev/null

# pip-audit (dependency scanning)
pip-audit --version 2>/dev/null || python -m pip_audit --version 2>/dev/null

# Bandit (Python SAST)
bandit --version 2>/dev/null
```

#### Ruby Tools
```bash
# bundler-audit (dependency scanning)
bundle-audit --version 2>/dev/null

# Brakeman (Rails SAST)
brakeman --version 2>/dev/null
```

#### Go Tools
```bash
# gosec (Go SAST)
gosec --version 2>/dev/null
```

#### Multi-language Tools
```bash
# Semgrep (supports 30+ languages)
semgrep --version 2>/dev/null

# Trivy (dependencies + containers)
trivy --version 2>/dev/null
```

**Tool availability matrix:**

Create a matrix of available tools:
```
Available Security Tools:
✓ Semgrep (SAST)
✓ npm audit (JS dependencies)
✗ pip-audit (not installed)
✓ ESLint + security plugin
```

**If NO tools are available:**
```
No security scanning tools detected.

Recommended installations:
(1) Semgrep (Recommended - multi-language)
    Install: pip install semgrep
    Or: brew install semgrep

(2) Language-specific tools:
    - JavaScript: npm install -g eslint eslint-plugin-security
    - Python: pip install bandit pip-audit
    - Ruby: gem install bundler-audit brakeman

Would you like to:
(1) Continue with manual code review (limited scanning)
(2) Exit and install tools first
```

If user selects manual review, proceed with basic pattern-based scanning using Grep (less effective but better than nothing).

---

## Phase 3: Parallel Security Scanning

Run available scans in parallel using Task tool with sub-agents for maximum speed.

### 3.1 SAST Scanning (Static Application Security Testing)

**If Semgrep is available (PREFERRED):**

Create Semgrep configuration for scan:

```bash
# Run Semgrep with OWASP Top 10 rules
semgrep --config=auto \
  --config=p/owasp-top-ten \
  --config=p/cwe-top-25 \
  --json \
  --output=semgrep-results.json \
  {SCAN_PATH}
```

**Semgrep rule categories to include:**
- `security` - General security rules
- `owasp-top-ten` - OWASP Top 10 vulnerabilities
- `cwe-top-25` - CWE most dangerous weaknesses
- `secrets` - Hardcoded credentials (also covered by secrets skill)

**If Semgrep NOT available, use language-specific tools:**

**JavaScript/TypeScript (ESLint):**
```bash
npx eslint \
  --plugin security \
  --plugin node \
  --format json \
  --output-file eslint-results.json \
  {SCAN_PATH}
```

**Python (Bandit):**
```bash
bandit -r {SCAN_PATH} \
  -f json \
  -o bandit-results.json \
  --severity-level medium
```

**Ruby (Brakeman for Rails):**
```bash
brakeman {SCAN_PATH} \
  --format json \
  --output brakeman-results.json \
  --confidence-level 2
```

**Go (gosec):**
```bash
gosec -fmt=json -out=gosec-results.json {SCAN_PATH}
```

**If NO SAST tools available:**

Use Grep-based pattern detection for common vulnerabilities:

**SQL Injection patterns:**
```bash
# Look for string concatenation in SQL queries
grep -rn "execute.*+\|query.*+" {SCAN_PATH}
```

**XSS patterns:**
```bash
# innerHTML assignments
grep -rn "innerHTML.*=" {SCAN_PATH}
```

**Command Injection patterns:**
```bash
# Unsafe exec/eval usage
grep -rn "exec(.*)\|eval(.*)" {SCAN_PATH}
```

Note: Grep-based detection has high false positives. Recommend tool installation.

### 3.2 Dependency Scanning

**JavaScript/TypeScript (npm audit):**
```bash
# Run npm audit
npm audit --json > npm-audit-results.json

# Also check for outdated packages with known vulns
npm outdated --json > npm-outdated.json
```

**If using Yarn:**
```bash
yarn audit --json > yarn-audit-results.json
```

**Python (pip-audit):**
```bash
# Scan installed packages
pip-audit --format json --output pip-audit-results.json

# Or use safety as fallback
safety check --json --output safety-results.json
```

**Ruby (bundler-audit):**
```bash
bundle-audit check --format json --output bundler-audit-results.json
```

**Go (go list + vulnerabilities):**
```bash
# Go 1.18+ has built-in vuln scanning
go list -json -m all | govulncheck -json > go-vulns.json
```

**Multi-language alternative (Trivy):**
```bash
trivy fs --format json --output trivy-results.json {SCAN_PATH}
```

### 3.3 Configuration Security Checks

Use Grep and Read tools to check for insecure configurations:

**Check for hardcoded credentials (overlap with secrets skill):**
```bash
grep -rn "password\s*=\|api_key\s*=\|secret\s*=" {SCAN_PATH}
```

**Check for debug mode in production:**
```bash
grep -rn "DEBUG\s*=\s*[Tt]rue" {SCAN_PATH}
```

**Check for insecure CORS configuration:**
```bash
# Allow all origins
grep -rn "Access-Control-Allow-Origin.*\*" {SCAN_PATH}
```

**Check for missing security headers:**

For web frameworks, check if security headers are configured:
- `Strict-Transport-Security` (HSTS)
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Content-Security-Policy`

Read framework configuration files and check for header middleware.

**Check for insecure cryptography:**
```bash
# Weak hashing algorithms
grep -rn "MD5\|SHA1" {SCAN_PATH}

# Insecure random number generation
grep -rn "Math.random()" {SCAN_PATH}  # JavaScript
grep -rn "random.random()" {SCAN_PATH}  # Python
```

### 3.4 Parallel Execution Strategy

Launch sub-agents in parallel for different scan types:

**Sub-agent 1: SAST Scan**
- Runs Semgrep or language-specific SAST tools
- Returns findings with severity, CWE, OWASP mapping

**Sub-agent 2: Dependency Scan**
- Runs npm audit, pip-audit, etc.
- Returns CVEs with CVSS scores

**Sub-agent 3: Config Security Check**
- Grep-based configuration scanning
- Returns insecure config findings

**Progress indicator:**
```
Running security scans...
[✓] SAST scan complete (3 findings)
[✓] Dependency scan complete (12 vulnerabilities)
[✓] Configuration check complete (2 issues)

Aggregating results...
```

---

## Phase 4: Results Aggregation and Severity Scoring

### 4.1 Parse Tool Outputs

Parse JSON output from each tool and normalize to a common format:

**Common finding format:**
```json
{
  "id": "semgrep-001",
  "tool": "Semgrep",
  "type": "SQL Injection",
  "severity": "HIGH",
  "cvss_score": 8.5,
  "cwe": "CWE-89",
  "owasp": "A03:2021 - Injection",
  "file": "src/auth/login.js",
  "line": 42,
  "code_snippet": "const query = 'SELECT * FROM users WHERE id=' + userId",
  "description": "User input concatenated into SQL query without sanitization",
  "recommendation": "Use parameterized queries or an ORM to prevent SQL injection"
}
```

### 4.2 Severity Classification

Map tool-specific severities to unified scale:

**CVSS Score to Severity:**
- **Critical**: CVSS 9.0-10.0 (immediate action required)
- **High**: CVSS 7.0-8.9 (fix before release)
- **Medium**: CVSS 4.0-6.9 (fix in sprint)
- **Low**: CVSS 0.1-3.9 (backlog)
- **Info**: CVSS 0.0 (best practice recommendation)

**Tool severity mappings:**
- Semgrep: ERROR → High, WARNING → Medium, INFO → Low
- npm audit: Critical → Critical, High → High, Moderate → Medium, Low → Low
- Bandit: HIGH → High, MEDIUM → Medium, LOW → Low

### 4.3 Deduplication

Remove duplicate findings across tools:

**Deduplication logic:**
- Same file + line + CWE → Deduplicate (keep highest severity)
- Same CVE across tools → Merge (combine tool references)

### 4.4 OWASP and CWE Mapping

For each finding, map to OWASP Top 10 and CWE:

**Common mappings:**
- SQL Injection → OWASP A03:2021 (Injection), CWE-89
- XSS → OWASP A03:2021 (Injection), CWE-79
- Broken Authentication → OWASP A07:2021 (Auth Failures), CWE-287
- Sensitive Data Exposure → OWASP A02:2021 (Crypto Failures), CWE-311
- XXE → OWASP A05:2021 (Security Misconfiguration), CWE-611
- Insecure Deserialization → OWASP A08:2021 (Software Integrity), CWE-502
- Using Components with Known Vulns → OWASP A06:2021, various CVEs

Reference `owasp-top10.md` and `cwe-top25.md` for full mappings.

---

## Phase 5: Results Presentation

### 5.1 Executive Summary

Display high-level statistics:

```
## Security Scan Results

Scanned: {N} files across {M} languages
Scan duration: {X} seconds

### Summary

| Severity | Count | Percentage |
|----------|-------|------------|
| Critical | 2     | 3%         |
| High     | 8     | 13%        |
| Medium   | 25    | 40%        |
| Low      | 27    | 44%        |
| **Total**| **62**| **100%**   |

### OWASP Top 10 Coverage

| Category | Findings |
|----------|----------|
| A03:2021 - Injection | 12 |
| A02:2021 - Cryptographic Failures | 5 |
| A06:2021 - Vulnerable Components | 18 |
| A07:2021 - Authentication Failures | 3 |
| A01:2021 - Broken Access Control | 2 |
```

### 5.2 Critical and High Findings Detail

Show detailed breakdown for Critical and High severity issues:

```
### Critical Issues (Immediate Action Required)

#### 1. SQL Injection in User Authentication
**File:** src/auth/login.js:42
**Severity:** CRITICAL (CVSS 9.8)
**OWASP:** A03:2021 - Injection
**CWE:** CWE-89

**Vulnerable Code:**
\`\`\`javascript
42 | const query = 'SELECT * FROM users WHERE id=' + userId
43 | const user = db.execute(query)
\`\`\`

**Description:**
User input `userId` is concatenated directly into SQL query without sanitization, allowing attackers to inject malicious SQL commands.

**Impact:**
Attackers can bypass authentication, access/modify/delete database records, or execute administrative operations.

**Recommendation:**
Use parameterized queries to prevent SQL injection:

\`\`\`javascript
const query = 'SELECT * FROM users WHERE id = ?'
const user = db.execute(query, [userId])
\`\`\`

Or use an ORM like Sequelize, TypeORM, or Prisma.

**References:**
- OWASP SQL Injection: https://owasp.org/www-community/attacks/SQL_Injection
- CWE-89: https://cwe.mitre.org/data/definitions/89.html

---

#### 2. Hardcoded Database Password
**File:** config/database.js:15
**Severity:** CRITICAL (CVSS 10.0)
**OWASP:** A02:2021 - Cryptographic Failures
**CWE:** CWE-798

**Vulnerable Code:**
\`\`\`javascript
15 | const DB_PASSWORD = "Prod123!Database"
16 | const connection = mysql.createConnection({
\`\`\`

**Description:**
Database password is hardcoded in source code and likely committed to version control.

**Impact:**
Anyone with access to the repository can access the production database.

**Recommendation:**
1. Immediately rotate database password
2. Use environment variables:
\`\`\`javascript
const DB_PASSWORD = process.env.DB_PASSWORD
\`\`\`
3. Add `.env` to `.gitignore`
4. Use secrets management (AWS Secrets Manager, HashiCorp Vault)

**References:**
- CWE-798: https://cwe.mitre.org/data/definitions/798.html

---
```

### 5.3 Dependency Vulnerabilities

```
### Dependency Vulnerabilities

#### Critical (2)

1. **express@4.16.0** - CVE-2022-24999 (CVSS 9.1)
   - Vulnerability: Regex DoS in qs module
   - Fix: Upgrade to express@4.17.3 or later
   - Command: `npm install express@latest`

2. **lodash@4.17.11** - CVE-2021-23337 (CVSS 9.8)
   - Vulnerability: Command injection via template
   - Fix: Upgrade to lodash@4.17.21 or later
   - Command: `npm install lodash@latest`

#### High (6)

[List high severity dependencies...]

**Quick Fix:**
Run `npm audit fix` to automatically update fixable vulnerabilities.
For breaking changes, review release notes before upgrading.
```

### 5.4 Medium and Low Findings Summary

For Medium and Low severity, provide condensed table:

```
### Medium Severity Issues (25)

| ID | Type | File | Line | Quick Fix |
|----|------|------|------|-----------|
| M-1 | Weak Crypto (MD5) | src/utils/hash.js | 28 | Use SHA-256 or bcrypt |
| M-2 | Missing CSRF Token | src/routes/api.js | 15 | Add csurf middleware |
| M-3 | Insecure Random | src/auth/token.js | 42 | Use crypto.randomBytes |
...

### Low Severity Issues (27)

[Collapsed by default - click to expand]
```

### 5.5 Statistics and Trends

If previous scans exist, show trends:

```
### Security Trend

Compared to previous scan (7 days ago):
- Critical: 2 → 2 (no change)
- High: 12 → 8 (⬇ 33% improvement)
- Medium: 30 → 25 (⬇ 17% improvement)
- Low: 25 → 27 (⬆ 8% increase)

Total vulnerabilities: 69 → 62 (⬇ 10% improvement)
```

### 5.6 Next Steps and Recommendations

```
## Recommended Actions

### Immediate (Today)
1. Fix 2 Critical issues (estimated time: 2-3 hours)
   - SQL Injection in login.js
   - Hardcoded password in database.js
2. Rotate compromised database credentials

### This Week
1. Upgrade 8 vulnerable dependencies (estimated time: 4-6 hours)
2. Fix High severity issues (8 findings)
3. Add security headers middleware

### This Sprint
1. Address Medium severity issues (25 findings)
2. Enable automated security scanning in CI/CD
3. Team training on secure coding practices

### Integration Options
- Create Jira issues for findings: `/issues:create-jira-issue`
- Get remediation help: `/security:remediate`
- Schedule regular scans: Add to CI/CD pipeline

### Tool Recommendations
Would you like help installing missing security tools?
- Semgrep (recommended): `pip install semgrep` or `brew install semgrep`
- pip-audit: `pip install pip-audit`
```

---

## Phase 6: Export and Tracking

### 6.1 Ask User for Next Actions

```
What would you like to do with these findings?

(1) Get remediation help for Critical/High issues
(2) Create Jira issues for all findings
(3) Export report (JSON/HTML/PDF)
(4) Save results and exit
(5) View detailed report for specific issue

Select an option:
```

### 6.2 Export Options

**JSON Export:**
```bash
# Save full results as JSON
cat > security-scan-results.json <<EOF
{FULL_RESULTS_JSON}
EOF

echo "Results saved to security-scan-results.json"
```

**HTML Export (if requested):**

Generate HTML report with:
- Executive summary
- Severity distribution charts
- Detailed findings with syntax highlighting
- OWASP/CWE references
- Remediation guidance

**Markdown Export:**
```bash
# Save as markdown for documentation
cat > SECURITY_REPORT.md <<EOF
{FORMATTED_MARKDOWN}
EOF
```

### 6.3 Create Jira Issues (Optional)

If user selects Jira integration:

For each Critical/High finding, use the `issues` plugin to create Jira issue:

```
Issue Title: [SECURITY] SQL Injection in User Authentication

Description:
**Severity:** Critical (CVSS 9.8)
**File:** src/auth/login.js:42
**OWASP:** A03:2021 - Injection

**Vulnerability:**
User input concatenated into SQL query without sanitization.

**Recommendation:**
Use parameterized queries or ORM.

**References:**
- OWASP: https://owasp.org/www-community/attacks/SQL_Injection
- CWE-89: https://cwe.mitre.org/data/definitions/89.html

Labels: security, critical, sql-injection
```

Use MCP Atlassian tools if available, or integrate with `/issues:create-jira-issue` skill.

### 6.4 Save Scan History

Store scan results for trend analysis:

```bash
# Create security scan history directory
mkdir -p .security-scans

# Save with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp security-scan-results.json .security-scans/scan_${TIMESTAMP}.json

# Update latest symlink
ln -sf scan_${TIMESTAMP}.json .security-scans/latest.json
```

Add `.security-scans/` to `.gitignore` to avoid committing scan results.

---

## Error Handling

### Tool Execution Errors

If a security tool fails:
```
Warning: Semgrep scan failed with error:
{ERROR_MESSAGE}

Continuing with available tools...
```

Continue with other scans rather than failing entirely.

### No Vulnerabilities Found

If scan finds no issues:
```
## Security Scan Results

Great news! No security vulnerabilities detected.

Scanned: {N} files
Duration: {X} seconds

### What was checked:
✓ SAST analysis (Semgrep)
✓ Dependency vulnerabilities (npm audit)
✓ Configuration security
✓ Common vulnerability patterns

### Recommendations:
- Run scans regularly (weekly or on every PR)
- Keep dependencies up to date
- Review OWASP Top 10: {{SKILL_DIR}}/../../references/owasp-top10.md
- Enable `/security:scan` in CI/CD pipeline
```

### Large Scan Results

If more than 100 findings:
```
Found {N} security issues. This is a large result set.

Options:
(1) Show Critical and High only (Recommended)
(2) Show top 20 findings
(3) Export full results to file
(4) Filter by type (Injection, XSS, etc.)

Select an option:
```

### Permission Errors

If tool lacks permissions:
```
Error: Permission denied when scanning {PATH}

Try:
- Check file permissions: ls -la {PATH}
- Run with appropriate permissions
- Exclude the directory if not needed
```

---

## Tool Installation Guidance

If user wants to install missing tools:

### Semgrep (Recommended)

```
Installing Semgrep - Multi-language SAST tool

**macOS:**
brew install semgrep

**Linux:**
pip3 install semgrep

**Windows:**
pip install semgrep

**Verify installation:**
semgrep --version

**First scan:**
/security:scan
```

### Language-Specific Tools

**JavaScript/TypeScript:**
```
npm install -g eslint eslint-plugin-security
npm audit (built-in with npm)
```

**Python:**
```
pip install bandit pip-audit
```

**Ruby:**
```
gem install bundler-audit brakeman
```

---

## CI/CD Integration Guidance

If user wants to automate scans:

```
## Integrating Security Scans into CI/CD

### GitHub Actions

Create `.github/workflows/security-scan.yml`:

\`\`\`yaml
name: Security Scan
on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
      - name: Run npm audit
        run: npm audit --audit-level=moderate
\`\`\`

### GitLab CI

Add to `.gitlab-ci.yml`:

\`\`\`yaml
security_scan:
  stage: test
  script:
    - pip install semgrep
    - semgrep --config=auto --config=p/owasp-top-ten .
    - npm audit
\`\`\`

Would you like me to create these files for you?
```

---

## Performance Considerations

### Large Repositories

For repositories with 10,000+ files:

1. **Incremental scanning**: Scan only changed files
2. **Parallel execution**: Use sub-agents for different directories
3. **Caching**: Cache dependency scan results
4. **Exclusions**: Skip `node_modules`, `vendor`, `build` directories

### Scan Duration Estimates

- Small project (<100 files): 10-30 seconds
- Medium project (100-1000 files): 30 seconds - 2 minutes
- Large project (1000-10000 files): 2-5 minutes
- Very large project (10000+ files): 5-15 minutes

Show progress indicators for long-running scans.

---

## Success Criteria

A successful scan execution includes:

1. ✓ Environment detected (languages, frameworks)
2. ✓ Security tools checked and executed
3. ✓ SAST, dependency, and config scans completed
4. ✓ Results aggregated and deduplicated
5. ✓ Findings mapped to OWASP/CWE
6. ✓ Severity scoring applied (CVSS)
7. ✓ Clear, actionable report presented
8. ✓ Next steps and remediation guidance provided

The user should leave with:
- Clear understanding of security posture
- Prioritized action items
- Confidence in what was scanned and what wasn't
