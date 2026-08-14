# Implementation Plan - Production-Ready Android Daily Task Tracker & Productivity App

Build a complete, standalone **Flutter + Dart Android Daily Task Tracker App** featuring modern Material 3 design, Riverpod state management, offline local database persistence (`sqflite`), scheduled Android notifications, Pomodoro Focus mode, day/week/month Calendar view, comprehensive Analytics & Streaks, Overdue task handling, natural language Quick Add, Settings, Onboarding, automated tests, and a release APK build.

## User Review Required

> [!IMPORTANT]
> The app is built as a pure native Flutter Android application using Clean Architecture and offline SQLite storage. Cloud synchronization can be connected later via the repository interfaces without altering UI components.

> [!NOTE]
> All core features including scheduled local notifications, recurring task generation, focus session logging, heatmaps, productivity score calculation (0–100), search, data import/export, dark mode, unit tests, widget tests, and integration tests will be fully implemented and verified.

## Proposed Changes

### Project Setup & Core Foundation

#### [NEW] [pubspec.yaml](file:///d:/ai%20models/daily%20task%20tracker/pubspec.yaml)
- Configure Flutter SDK, app metadata (`daily_task_tracker`), assets, and dependencies:
  - `flutter_riverpod` (State management)
  - `sqflite` + `path` + `path_provider` (Offline SQLite database)
  - `flutter_local_notifications` + `timezone` (Android reminders & notifications)
  - `intl` (Date/time formatting and parsing)
  - `table_calendar` (Day/Week/Month calendar views)
  - `fl_chart` (Analytics charts)
  - `uuid` (Unique ID generation)
  - `shared_preferences` (User settings and onboarding state)
  - `flutter_lints` (Code quality & analysis)

---

### Architecture & Data Layer

#### [NEW] [lib/main.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/main.dart)
- Root entry point initializing Flutter bindings, timezone data, local notification service, SQLite database, and loading Riverpod `ProviderScope`.
- Configures dynamic theme switching (Light, Dark, System) with Material 3 styling.

#### [NEW] [lib/core/models/task_model.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/models/task_model.dart)
- Task data model: `id`, `title`, `description`, `date`, `startTime`, `dueTime`, `priority` (Low, Medium, High, Urgent), `categoryId`, `isCompleted`, `completedAt`, `recurrenceRule`, `reminderTime`, `notes`, `inbox`, `createdAt`, `updatedAt`.
- Serialization methods (`toMap`, `fromMap`, `copyWith`).

#### [NEW] [lib/core/models/category_model.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/models/category_model.dart)
- Category model with default presets (Work, Personal, Study, Health, Fitness, Finance, Shopping, Other) + custom user categories with name, icon code point, and accent color.

#### [NEW] [lib/core/models/subtask_model.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/models/subtask_model.dart)
- Subtask model: `id`, `taskId`, `title`, `isCompleted`.

#### [NEW] [lib/core/models/focus_session_model.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/models/focus_session_model.dart)
- Focus Session model: `id`, `taskId`, `taskTitle`, `durationMinutes`, `completed`, `startedAt`, `endedAt`.

#### [NEW] [lib/core/models/user_settings_model.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/models/user_settings_model.dart)
- User settings model: `userName`, `themeMode`, `notificationsEnabled`, `defaultReminderMinutes`, `dailyGoal`, `weekStartDay`, `onboardingCompleted`.

#### [NEW] [lib/core/database/database_helper.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/database/database_helper.dart)
- SQLite database initialization and table schemas for `tasks`, `categories`, `subtasks`, `focus_sessions`, and `user_settings`. Includes CRUD helper methods.

#### [NEW] [lib/core/repositories/task_repository.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/repositories/task_repository.dart)
- Repository pattern interface and SQLite implementation for data operations: tasks CRUD, subtasks, recurring task evaluation, focus sessions, and statistics calculation.

#### [NEW] [lib/core/services/notification_service.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/services/notification_service.dart)
- Android notification channel setup, permission request handler, scheduled task reminder manager, and focus timer completion alerts using `flutter_local_notifications`.

---

### State Management & Logic Providers

#### [NEW] [lib/core/providers/task_provider.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/providers/task_provider.dart)
- Riverpod state notifier for tasks, filtered views (Today, Inbox, Overdue, Category, Priority, Search), task completion toggle, quick add smart parser, recurring task generator, and CRUD actions.

#### [NEW] [lib/core/providers/category_provider.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/providers/category_provider.dart)
- Riverpod provider for default and custom category management.

#### [NEW] [lib/core/providers/focus_provider.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/providers/focus_provider.dart)
- Riverpod state notifier for Pomodoro/Focus timer state (Running, Paused, Completed), time remaining, active task selection, and session logging.

#### [NEW] [lib/core/providers/analytics_provider.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/providers/analytics_provider.dart)
- Riverpod provider calculating daily, weekly, monthly stats, productivity score algorithm (0–100 based on completion rate, urgent task completion, consistency, and focus time), current streak, and longest streak heatmap.

#### [NEW] [lib/core/providers/settings_provider.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/providers/settings_provider.dart)
- Riverpod state notifier for theme selection, notification preferences, daily task goals, export/import JSON backup, and onboarding state.

---

### Design System & Theme

#### [NEW] [lib/core/theme/app_theme.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/core/theme/app_theme.dart)
- Material 3 color palettes for Light and Dark modes. Custom typography (Inter/Roboto styled), rounded card themes, bottom sheet themes, FAB styling, dynamic dark mode contrast.

---

### Features & UI Screens

#### [NEW] [lib/features/navigation/main_navigation_screen.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/navigation/main_navigation_screen.dart)
- Bottom Navigation Bar with 5 core tabs: **Today**, **Tasks**, **Calendar**, **Focus**, **Analytics**. Smooth page transitions and prominent Floating Action Button (`+`).

#### [NEW] [lib/features/today/today_screen.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/today/today_screen.dart)
- Greeting header ("Good morning, [Name] 👋", Date).
- Progress Summary Card (Tasks Completed, %, visual progress bar, 🔥 Streak badge).
- Task groups: Morning (before 12 PM), Afternoon (12 PM - 5 PM), Evening (after 5 PM).
- Smooth animated task card completion into completed drawer.

#### [NEW] [lib/features/tasks/tasks_screen.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/tasks/tasks_screen.dart)
- Search bar with debounced filtering (Title, Description, Category, Priority).
- Filter chips (Today, Inbox, Overdue, Priority, Category).
- Overdue tasks banner (`⚠️ 3 Overdue Tasks` with quick actions: Complete, Reschedule, Move to Today, Delete).
- Quick Add input field (Instant parse: "Finish portfolio tomorrow at 6 PM").

#### [NEW] [lib/features/tasks/add_edit_task_sheet.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/tasks/add_edit_task_sheet.dart)
- Comprehensive modal bottom sheet / page for creating & editing tasks.
- Auto-focused title input, description, date picker, start & due time pickers, priority selector (Low, Medium, High, Urgent), category selector, reminder selector, repeat rule selector, subtasks builder, notes.
- Keyboard Done/Enter listener for instant creation (< 5 seconds flow).

#### [NEW] [lib/features/tasks/task_action_sheet.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/tasks/task_action_sheet.dart)
- Long-press bottom sheet with actions: Complete, Edit, Duplicate, Move to tomorrow, Reschedule, Change priority, Change category, Add reminder, Delete.

#### [NEW] [lib/features/calendar/calendar_screen.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/calendar/calendar_screen.dart)
- Day, Week, and Month calendar views (`table_calendar`).
- Date tap displays that day's scheduled, completed, overdue, and priority tasks.

#### [NEW] [lib/features/focus/focus_screen.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/focus/focus_screen.dart)
- Pomodoro timer: 25-min Pomodoro, 5-min short break, 50-min focus, custom duration.
- Circular animated timer countdown, active task selector, Start / Pause / Complete / Exit controls.
- Local notification on completion and automated analytics logging.

#### [NEW] [lib/features/analytics/analytics_screen.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/analytics/analytics_screen.dart)
- Today / Week / Month tabbed analytics dashboard.
- Productivity Score card (0-100) with detailed algorithm breakdown.
- Streak summary (🔥 Current, 🏆 Longest) with heat map calendar.
- Charts for task completion rate and focus time distributions (`fl_chart`).

#### [NEW] [lib/features/settings/settings_screen.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/settings/settings_screen.dart)
- Appearance (Light / Dark / System), Notifications, Task Settings (Default priority, default duration, week start), Productivity Goal, Data Backup/Export & Import, About app modal.

#### [NEW] [lib/features/onboarding/onboarding_screen.dart](file:///d:/ai%20models/daily%20task%20tracker/lib/features/onboarding/onboarding_screen.dart)
- Step-by-step user onboarding: Name, primary productivity goal, working hours, preferred categories, notification settings, daily task goal.

---

### Automated Tests & Verification Setup

#### [NEW] [test/unit/task_test.dart](file:///d:/ai%20models/daily%20task%20tracker/test/unit/task_test.dart)
- Unit tests for Task creation, task completion toggle, recurring task instance generator, streak calculation logic, and productivity score formula.

#### [NEW] [test/widget/today_screen_test.dart](file:///d:/ai%20models/daily%20task%20tracker/test/widget/today_screen_test.dart)
- Widget tests verifying Today screen rendering, task creation dialog trigger, task completion interaction, and filter chips.

#### [NEW] [test/integration/app_flow_test.dart](file:///d:/ai%20models/daily%20task%20tracker/test/integration/app_flow_test.dart)
- Integration test for full workflow: open app -> complete onboarding -> create task -> mark complete -> check progress update -> restart state -> verify database persistence.

---

## Verification Plan

### Automated Tests
- Run code analyzer:
  `flutter analyze`
- Run test suite:
  `flutter test`
- Build release Android APK:
  `flutter build apk --release`

### Manual Verification
- Verify database persistence and offline capability.
- Verify Material 3 Light and Dark mode UI contrast and animations.
- Verify Quick Add parsing, recurring tasks logic, Pomodoro timer, notifications setup, calendar views, analytics score calculation, and export/import functionality.
