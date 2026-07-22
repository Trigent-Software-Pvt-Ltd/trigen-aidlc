# Stacktrace File Path Extraction

## Purpose
This reference is loaded during Phase 1.5 of `/sentry-triage` to extract application-level file paths and line numbers from Sentry stacktraces. The extracted paths are checked against the local repository to provide code context for triage.

## Skip List (Vendor/Library Paths)
Skip frames whose paths contain any of these patterns — they are framework or dependency code, not application code:
- `vendor/`, `node_modules/`, `site-packages/`, `dist-packages/`
- `gems/`, `.rubies/`, `.rvm/`, `.rbenv/`
- `__pycache__/`, `.tox/`, `.venv/`, `venv/`
- `<frozen`, `<internal:`, `<anonymous>`
- Paths starting with `/usr/lib/`, `/usr/local/lib/`

## Platform-Specific Extraction

### Ruby
**Format:** `path/to/file.rb:LINE:in 'method_name'`
**Regex:** `([^\s]+\.rb):(\d+)`
**Example:**
```
app/models/user.rb:45:in `validate_email'
app/controllers/sessions_controller.rb:23:in `create'
```
**Notes:** Rails apps typically have paths starting with `app/`, `lib/`, `config/`. Skip frames with `gems/` in the path.

### Python
**Format:** `File "path/to/file.py", line LINE, in function_name`
**Regex:** `File "([^"]+\.py)", line (\d+)`
**Example:**
```
File "app/services/auth.py", line 23, in authenticate
File "app/models/user.py", line 112, in save
```
**Notes:** Django apps use paths like `app/`, `myproject/`. Flask uses `app/`. Skip `site-packages/`.

### JavaScript / TypeScript
**Format:** `at FunctionName (path/to/file.js:LINE:COL)` or `at path/to/file.js:LINE:COL`
**Regex:** `(?:at\s+(?:\S+\s+)?\(?)?([^\s()]+\.[jt]sx?):(\d+)(?::\d+)?\)?`
**Example:**
```
at UserService.validate (src/services/user.ts:45:12)
at processTicket (/app/src/handlers/ticket.js:89:3)
at src/utils/auth.ts:23:8
```
**Notes:** Node.js may show absolute paths (`/app/src/...`). Strip leading path segments that don't exist in the repo. Skip `node_modules/`.

### Java / Kotlin
**Format:** `at package.Class.method(File.java:LINE)`
**Regex:** `at\s+[\w.$]+\((\w+\.(?:java|kt)):(\d+)\)`
**Example:**
```
at com.example.service.UserService.validate(UserService.java:45)
at com.example.controller.AuthController.login(AuthController.kt:23)
```
**Notes:** Java stacktraces only show the filename, not the full path. Use Glob to search for the file: `Glob("**/{filename}")`. The package name can hint at the directory structure (e.g., `com.example.service` → `src/main/java/com/example/service/`).

### Go
**Format:** `path/to/file.go:LINE +0xOFFSET` or `path/to/file.go:LINE`
**Regex:** `([^\s]+\.go):(\d+)`
**Example:**
```
main.go:45
internal/handler/user.go:89 +0x1a4
```
**Notes:** Go paths are typically relative to the module root. Skip frames from the Go standard library (paths starting with `runtime/`, `net/`, `os/`).

### C# / .NET
**Format:** `at Namespace.Class.Method() in path/to/File.cs:line LINE`
**Regex:** `in\s+([^\s]+\.cs):line\s+(\d+)`
**Example:**
```
at MyApp.Services.UserService.Validate() in /app/src/Services/UserService.cs:line 45
```
**Notes:** .NET stacktraces include the full path after `in`. Skip frames without `in` (no source info available).

## General Extraction Algorithm

1. Split the stacktrace into individual frames (one per line)
2. For each frame, try the platform-specific regex based on the `platform` field from the Sentry issue
3. If platform is unknown, try all regexes in order: Ruby → Python → JS/TS → Java → Go → C#
4. Filter out frames matching the skip list
5. Return up to 10 application-level file paths with line numbers
6. Order: preserve the stacktrace order (most recent frame first)

## Path Resolution

Extracted paths may need adjustment to match the local repo:
- **Absolute paths** (e.g., `/app/src/...`): Strip the prefix that doesn't exist locally. Try progressively shorter prefixes until a match is found.
- **Relative paths** (e.g., `app/models/...`): Try relative to the repo root first.
- **Filename only** (e.g., Java): Use `Glob("**/{filename}")` to find the file. If multiple matches, prefer the one whose directory structure matches the package name.
