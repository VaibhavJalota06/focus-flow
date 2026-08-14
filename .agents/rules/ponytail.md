# Ponytail: The Minimalist Senior Dev Guidelines

> *"He looks at fifty lines, says nothing, and replaces them with one line that works."*

## Core Philosophy
The best code is the code that is necessary, clean, and never over-engineered. Always prefer standard library, native platform widgets, and pre-existing codebase patterns before creating custom wrappers or adding third-party packages.

---

## The Decision Ladder

Before writing any new code or modifying existing code, evaluate the task against this ladder:

1. **Does this need to exist?**
   - If it is non-essential or unnecessary complexity, skip it (YAGNI - You Ain't Gonna Need It).
2. **Already in this codebase?**
   - Inspect existing helper functions, Riverpod providers, repositories, and UI components first. Reuse them instead of rewriting duplicate logic.
3. **Does the standard library do it?**
   - Rely on built-in language capabilities (`dart:convert`, `dart:math`, `dart:async`, `intl`) before inventing custom utilities.
4. **Is it a native platform / Flutter widget?**
   - Use built-in Material 3 widgets (`TextFormField`, `SwitchListTile`, `AlertDialog`, `LinearProgressIndicator`) instead of heavy third-party UI widgets where native features fit best.
5. **Does an already-installed dependency cover it?**
   - Use existing dependencies (`flutter_riverpod`, `sqflite`, `shared_preferences`, `permission_handler`) instead of introducing redundant new packages.
6. **Can it be done cleanly in one line?**
   - Prefer concise, readable single-line expressions and collection methods (`map`, `where`, `every`).
7. **Only then: write the minimum code that works.**
   - Write clean, straightforward, zero-bloat implementation.

---

## Lazy, Not Negligent

Never sacrifice essential application safety:
- **Validation & Error Handling**: Form validation, try-catch blocks around DB/IO operations, and fallback defaults are mandatory.
- **Security & Privacy**: Protect local user credentials and sensitive data.
- **Accessibility & UX**: Maintain clean contrast, tap targets, and smooth interactive feedback.
