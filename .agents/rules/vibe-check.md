# Security Rules (Vibe-Check)

These rules apply to all code generated in this project. They are non-negotiable.

## Secrets
- NEVER put secret keys, database master passwords, or service role tokens in frontend client code.
- NEVER hardcode sensitive private credentials in source files.
- The `.env` file MUST be in `.gitignore`.
- Use `.env.example` with placeholder values only.

## Database
- Enable Row Level Security (RLS) on all Supabase tables before public production deployment, scoped to `auth.uid() = user_id`.
- NEVER use unsafe deserialization on user-supplied data. Use JSON for all network data exchange.
- All SQLite queries MUST use parameterized queries (`whereArgs: [...]`).

## Authentication & Authorization
- Protected endpoints/tables must enforce authentication before modifying user data.
- Resource access MUST verify ownership: `current_user.id == resource.user_id`.

## Input and Output
- NEVER concatenate user input into SQL queries. ALWAYS use parameterized queries.
- ALL user input MUST be validated.
- File uploads / avatars must be sanitized and scoped to the user.
