# Workspace Security Rules (Vibe-Security Standard)

1. **No Hardcoded Secrets**: Never commit API keys, tokens, passwords, or production credentials in client source code.
2. **Parameterized Database Queries**: All SQLite / database calls must use `whereArgs` to guarantee SQL injection safety.
3. **Safe Serialization**: All deserialization of local JSON strings (`subtasks_json`, `backup_json`) must be guarded with robust `try-catch` blocks and fallback values.
4. **Least Privilege**: Only request and declare necessary OS permissions (`RECORD_AUDIO`, `POST_NOTIFICATIONS`).
5. **Form & Input Validation**: Sanitize and validate user inputs (Emails, Passwords, Task titles) before state mutations.
