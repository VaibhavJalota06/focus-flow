import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/task_model.dart';
import 'supabase_service.dart';

/// Tracks the last sync result for UI feedback (Issue #9)
enum SyncStatus { idle, syncing, success, failed }

class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._internal();

  CloudSyncService._internal();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Observable sync status for UI feedback (Issue #9)
  final ValueNotifier<SyncStatus> syncStatus =
      ValueNotifier<SyncStatus>(SyncStatus.idle);
  String? lastSyncError;

  /// Sync all local data with Supabase Cloud
  Future<void> syncAll({String? userId}) async {
    if (_isSyncing) return;
    if (!SupabaseService.instance.isLiveConfigured ||
        !SupabaseService.instance.isInitialized) {
      return;
    }

    final uid = userId ?? SupabaseService.instance.client.auth.currentUser?.id;
    if (uid == null) {
      debugPrint('[CloudSyncService] Skipping sync: No active user session.');
      return;
    }

    _isSyncing = true;
    syncStatus.value = SyncStatus.syncing;
    lastSyncError = null;

    try {
      debugPrint('[CloudSyncService] Starting full two-way cloud sync for user: $uid...');

      // 1. Sync User Profile
      await _syncProfile(uid);

      // 2. Sync Categories (Upload local custom categories)
      await _syncCategories(uid);

      // 3. Sync Tasks (Upload local tasks & pull remote tasks with conflict resolution)
      await _syncTasks(uid);

      // 4. Sync Focus Sessions (Issue #4)
      await _syncFocusSessions(uid);

      debugPrint('[CloudSyncService] Cloud sync completed successfully ✨');
      syncStatus.value = SyncStatus.success;
    } catch (e) {
      debugPrint('[CloudSyncService] Cloud sync error: $e');
      lastSyncError = e.toString();
      syncStatus.value = SyncStatus.failed;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync user profile to Supabase 'profiles' table
  Future<void> _syncProfile(String userId) async {
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      if (user == null) return;

      final metadata = user.userMetadata ?? {};
      final name = metadata['full_name'] as String? ??
          metadata['name'] as String? ??
          user.email?.split('@').first ??
          'User';
      final avatarUrl = metadata['avatar_url'] as String? ??
          metadata['picture'] as String? ??
          '🌟';

      await SupabaseService.instance.client.from('profiles').upsert({
        'id': userId,
        'name': name,
        'email': user.email,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[CloudSyncService] Profile sync warning: $e');
      rethrow; // Bubble up for syncAll to catch (Issue #9)
    }
  }

  /// Sync Categories
  Future<void> _syncCategories(String userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final localRows = await db.query('categories');

      for (final row in localRows) {
        await SupabaseService.instance.client.from('categories').upsert({
          'id': row['id'],
          'user_id': userId,
          'name': row['name'],
          'icon_code_point': row['iconCodePoint'],
          'color_value': row['colorValue'],
          'is_default': (row['isDefault'] as int? ?? 0) == 1,
        });
      }
    } catch (e) {
      debugPrint('[CloudSyncService] Category sync warning: $e');
      // Categories are non-critical, don't rethrow
    }
  }

  /// Sync Tasks with updatedAt-based conflict resolution (Issue #5)
  Future<void> _syncTasks(String userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final localTasks = await db.query('tasks');

      // 1. Upload local tasks to Supabase (with conflict check)
      for (final row in localTasks) {
        final task = TaskModel.fromMap(row);
        await uploadTask(task, userId: userId);
      }

      // 2. Download and merge remote tasks (Issue #5: conflict resolution)
      final remoteRows = await SupabaseService.instance.client
          .from('tasks')
          .select()
          .eq('user_id', userId);

      for (final r in remoteRows) {
        final remoteTask = _taskFromSupabaseRow(r);
        if (remoteTask == null) continue;

        final existing = await db.query(
          'tasks',
          where: 'id = ?',
          whereArgs: [remoteTask.id],
        );

        if (existing.isEmpty) {
          // New remote task — insert locally
          await db.insert('tasks', remoteTask.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          // Existing task — compare updatedAt timestamps (Issue #5)
          final localTask = TaskModel.fromMap(existing.first);
          if (remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
            // Remote is newer — update local
            await db.update('tasks', remoteTask.toMap(),
                where: 'id = ?', whereArgs: [remoteTask.id]);
          }
          // else: local is newer or equal — already uploaded above
        }
      }
    } catch (e) {
      debugPrint('[CloudSyncService] Tasks sync warning: $e');
      rethrow;
    }
  }

  /// Parse a Supabase row into TaskModel with defensive type handling (Issue #2 & #3)
  TaskModel? _taskFromSupabaseRow(Map<String, dynamic> r) {
    try {
      // Defensive subtasks_json parsing (Issue #3)
      List<SubtaskModel> subtasks = const [];
      final rawSubtasks = r['subtasks_json'];
      if (rawSubtasks != null) {
        if (rawSubtasks is List) {
          // jsonb column returns a Dart List directly
          subtasks = rawSubtasks
              .map((e) => SubtaskModel.fromMap(e as Map<String, dynamic>))
              .toList();
        } else if (rawSubtasks is String && rawSubtasks.isNotEmpty) {
          // text column returns a JSON string
          final decoded = jsonDecode(rawSubtasks) as List;
          subtasks = decoded
              .map((e) => SubtaskModel.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      }

      return TaskModel(
        id: r['id'] as String,
        title: r['title'] as String,
        description: (r['description'] as String?) ?? '',
        date: DateTime.parse(r['date'] as String),
        startTime: r['start_time'] as String?,
        dueTime: r['due_time'] as String?,
        priority: TaskPriority.fromString(r['priority'] as String?),
        categoryId: (r['category_id'] as String?) ?? 'other',
        // Issue #2: Supabase returns bool, handle both bool and int
        isCompleted: _parseBool(r['is_completed']),
        completedAt: r['completed_at'] != null
            ? DateTime.parse(r['completed_at'] as String)
            : null,
        recurrenceRule: r['recurrence_rule'] as String?,
        reminderTime: r['reminder_time'] as String?,
        notes: r['notes'] as String?,
        isInbox: _parseBool(r['is_inbox']),
        subtasks: subtasks,
        createdAt: DateTime.parse(r['created_at'] as String),
        updatedAt: DateTime.parse(r['updated_at'] as String),
      );
    } catch (e) {
      debugPrint('[CloudSyncService] Failed to parse remote task: $e');
      return null;
    }
  }

  /// Safely parse bool from Supabase (bool) or SQLite (int) (Issue #2)
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    return false;
  }

  /// Sync Focus Sessions to/from Supabase (Issue #4)
  Future<void> _syncFocusSessions(String userId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final localSessions = await db.query('focus_sessions');

      // Upload local focus sessions
      for (final row in localSessions) {
        await SupabaseService.instance.client.from('focus_sessions').upsert({
          'id': row['id'],
          'user_id': userId,
          'task_id': row['taskId'],
          'task_title': row['taskTitle'],
          'duration_minutes': row['durationMinutes'],
          'completed': (row['completed'] as int? ?? 0) == 1,
          'started_at': row['startedAt'],
          'ended_at': row['endedAt'],
        });
      }

      // Download remote focus sessions that don't exist locally
      final remoteSessions = await SupabaseService.instance.client
          .from('focus_sessions')
          .select()
          .eq('user_id', userId);

      for (final r in remoteSessions) {
        final existing = await db.query(
          'focus_sessions',
          where: 'id = ?',
          whereArgs: [r['id']],
        );

        if (existing.isEmpty) {
          await db.insert('focus_sessions', {
            'id': r['id'] as String,
            'taskId': r['task_id'] as String?,
            'taskTitle': r['task_title'] as String,
            'durationMinutes': r['duration_minutes'] as int,
            'completed': (r['completed'] as bool? ?? false) ? 1 : 0,
            'startedAt': r['started_at'] as String,
            'endedAt': r['ended_at'] as String,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    } catch (e) {
      debugPrint('[CloudSyncService] Focus sessions sync warning: $e');
      // Non-critical, don't rethrow
    }
  }

  /// Upload or update a single task to Supabase
  Future<void> uploadTask(TaskModel task, {String? userId}) async {
    try {
      if (!SupabaseService.instance.isLiveConfigured ||
          !SupabaseService.instance.isInitialized) {
        return;
      }

      final uid = userId ?? SupabaseService.instance.client.auth.currentUser?.id;
      if (uid == null) {
        debugPrint('[CloudSyncService] Skipping upload: No active user session.');
        return;
      }

      await SupabaseService.instance.client.from('tasks').upsert({
        'id': task.id,
        'user_id': uid,
        'title': task.title,
        'description': task.description,
        'date': task.date.toIso8601String().split('T').first,
        'start_time': task.startTime,
        'due_time': task.dueTime,
        'priority': task.priority.name,
        'category_id': task.categoryId,
        'is_completed': task.isCompleted,
        'completed_at': task.completedAt?.toUtc().toIso8601String(),
        'recurrence_rule': task.recurrenceRule,
        'reminder_time': task.reminderTime,
        'notes': task.notes,
        'is_inbox': task.isInbox,
        'subtasks_json': task.subtasks.map((s) => s.toMap()).toList(),
        'created_at': task.createdAt.toUtc().toIso8601String(),
        'updated_at': task.updatedAt.toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[CloudSyncService] Task upload warning: $e');
    }
  }

  /// Delete a task from Supabase
  Future<void> deleteTask(String taskId) async {
    try {
      if (!SupabaseService.instance.isLiveConfigured ||
          !SupabaseService.instance.isInitialized) {
        return;
      }

      final uid = SupabaseService.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      await SupabaseService.instance.client
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', uid);
    } catch (e) {
      debugPrint('[CloudSyncService] Task delete warning: $e');
    }
  }
}
