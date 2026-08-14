---
name: vibe-security
description: Audits codebases for common security vulnerabilities that AI coding assistants introduce in vibe-coded applications. Checks for exposed API keys, broken access control, missing auth validation, client-side trust issues, insecure storage, and more.
---

# Vibe Security — AI Coding Security Guidelines

## The Core Principle
**Never trust the client.** Every sensitive value, user ID, role, feature flag, and cryptographic operation must be validated or protected securely. If it exists unencrypted in client storage or memory without guards, it is vulnerable.

## Security Checklist for Mobile & Flutter Applications

### 1. Secrets & Credentials Protection
- No hardcoded API keys, bearer tokens, or secrets in Dart source files or `AndroidManifest.xml`.
- Ensure `.env` and local keystore credentials are in `.gitignore`.

### 2. Database & Storage Security
- All SQLite queries must use parameterized SQL (`whereArgs: [...]`) to prevent SQL Injection.
- Sensitive credentials, auth tokens, or passwords must not be stored in plaintext in standard `SharedPreferences` without hashing/encryption.

### 3. Permissions & Privacy
- Adhere to the principle of least privilege: only declare runtime permissions that are actively used (`RECORD_AUDIO`, `POST_NOTIFICATIONS`).
- Request permissions with contextual explanation before OS prompt triggers.

### 4. Input Sanitization & Serialization Safety
- Validate all incoming user input (task titles, deadlines, email formats).
- Wrap JSON decoders and DB schema deserialization in `try-catch` blocks to prevent crash-based denial of service.
