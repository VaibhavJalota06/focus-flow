import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import '../services/cloud_sync_service.dart';
import '../services/notification_service.dart';
import 'category_provider.dart';

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  final ITaskRepository _repository;
  final Ref ref;

  TaskNotifier(this._repository, this.ref) : super([]) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    final tasks = await _repository.getTasks();
    
    // Auto-categorize existing tasks that currently have categoryId == 'other'
    bool needsReload = false;
    for (final task in tasks) {
      if (task.categoryId == 'other') {
        final autoCat = detectCategory(task.title, task.description);
        if (autoCat != 'other') {
          final updated = task.copyWith(categoryId: autoCat);
          await _repository.updateTask(updated);
          needsReload = true;
        }
      }
    }

    final finalTasks = needsReload ? await _repository.getTasks() : tasks;
    state = finalTasks;
    _evaluateRecurringTasks(finalTasks);
  }

  Future<void> _evaluateRecurringTasks(List<TaskModel> currentTasks) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final recurringMasterTasks =
        currentTasks.where((t) => t.recurrenceRule != null && !t.isInbox).toList();

    for (final task in recurringMasterTasks) {
      bool shouldGenerateToday = false;
      final rule = task.recurrenceRule!.toUpperCase();

      if (rule == 'DAILY') {
        shouldGenerateToday = true;
      } else if (rule == 'WEEKDAYS') {
        shouldGenerateToday = today.weekday >= DateTime.monday &&
            today.weekday <= DateTime.friday;
      } else if (rule == 'WEEKLY') {
        shouldGenerateToday = today.weekday == task.date.weekday;
      } else if (rule == 'MONTHLY') {
        shouldGenerateToday = today.day == task.date.day;
      } else if (rule.startsWith('CUSTOM:')) {
        final daysStr = rule.replaceFirst('CUSTOM:', '').split(',');
        final customDays = daysStr.map((e) => int.tryParse(e.trim())).whereType<int>().toSet();
        shouldGenerateToday = customDays.contains(today.weekday);
      }

      if (shouldGenerateToday) {
        final hasInstanceToday = currentTasks.any((t) =>
            t.title == task.title &&
            t.date.year == today.year &&
            t.date.month == today.month &&
            t.date.day == today.day);

        if (!hasInstanceToday) {
          final newInstance = task.copyWith(
            id: const Uuid().v4(),
            date: today,
            isCompleted: false,
            completedAt: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _repository.insertTask(newInstance);
        }
      }
    }

    final updatedList = await _repository.getTasks();
    state = updatedList;
  }

  Future<TaskModel> addTask({
    required String title,
    String description = '',
    DateTime? date,
    String? startTime,
    String? dueTime,
    TaskPriority priority = TaskPriority.medium,
    String categoryId = 'other',
    String? recurrenceRule,
    String? reminderTime,
    String? notes,
    bool isInbox = false,
    List<SubtaskModel> subtasks = const [],
  }) async {
    final now = DateTime.now();
    final taskDate = date ?? DateTime(now.year, now.month, now.day);
    final finalCategoryId = categoryId == 'other' ? detectCategory(title, description) : categoryId;

    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      date: taskDate,
      startTime: startTime,
      dueTime: dueTime,
      priority: priority,
      categoryId: finalCategoryId,
      isCompleted: false,
      recurrenceRule: recurrenceRule,
      reminderTime: reminderTime,
      notes: notes,
      isInbox: isInbox,
      subtasks: subtasks,
      createdAt: now,
      updatedAt: now,
    );

    await _repository.insertTask(task);
    if (reminderTime != null) {
      await NotificationService.instance.scheduleTaskReminder(task);
    }
    CloudSyncService.instance.uploadTask(task);
    await loadTasks();
    return task;
  }

  Future<void> quickAddTask(String input) async {
    final parsed = parseQuickAdd(input);
    await addTask(
      title: parsed.title,
      date: parsed.date,
      dueTime: parsed.dueTime,
      categoryId: parsed.categoryId,
      isInbox: parsed.isInbox,
    );
  }

  static String detectCategory(String title, [String description = '']) {
    final text = '$title $description'.toLowerCase();

    // Fitness
    if (RegExp(r'\b(exercise|workout|gym|run|running|jog|jogging|walk|walking|cardio|yoga|cycling|bike|biking|swim|swimming|pushup|pushups|squat|squats|stretch|stretching|pilates|treadmill|hiit|marathon|legs|chest|abs|biceps|weights|lifting)\b', caseSensitive: false).hasMatch(text)) {
      return 'fitness';
    }
    // Health & Wellness
    if (RegExp(r'\b(doctor|medicine|medication|dentist|pill|pills|checkup|hospital|clinic|water|sleep|therapy|appointment|diet|vitamin|vitamins|blood|pharmacy|prescription|mental|meditate|meditation|dentistry|skin|skincare|eye|optician)\b', caseSensitive: false).hasMatch(text)) {
      return 'health';
    }
    // Work & Career
    if (RegExp(r'\b(meeting|email|mail|project|code|coding|commit|presentation|report|client|office|review|design|portfolio|bug|deploy|pr|standup|sprint|task|deadline|zoom|teams|slack|document|doc|sheet|slide|pitch|boss|manager|interview|hire|job|resume|cv)\b', caseSensitive: false).hasMatch(text)) {
      return 'work';
    }
    // Study & Education
    if (RegExp(r'\b(study|studying|read|reading|book|books|exam|test|homework|assignment|course|lecture|quiz|chapter|research|paper|thesis|learn|learning|math|science|history|english|class|school|college|university|tutor|revision)\b', caseSensitive: false).hasMatch(text)) {
      return 'study';
    }
    // Finance & Money
    if (RegExp(r'\b(pay|payment|bill|bills|rent|salary|bank|transfer|tax|taxes|subscription|invoice|budget|crypto|bitcoin|invest|investment|stock|stocks|loan|emi|credit|card|expense|expenses|insurance|save|savings)\b', caseSensitive: false).hasMatch(text)) {
      return 'finance';
    }
    // Shopping & Groceries
    if (RegExp(r'\b(buy|buying|purchase|groceries|grocery|shop|shopping|store|order|amazon|milk|bread|fruits|vegetables|veggies|supermarket|mall|clothes|shoes|cart|deliver|delivery|package)\b', caseSensitive: false).hasMatch(text)) {
      return 'shopping';
    }
    // Personal & Home
    if (RegExp(r'\b(clean|cleaning|cook|cooking|laundry|wash|washing|dishes|call|family|friend|friends|birthday|party|movie|game|gaming|relax|nap|vacation|trip|flight|hotel|car|drive|haircut|gift|dinner|lunch|breakfast)\b', caseSensitive: false).hasMatch(text)) {
      return 'personal';
    }

    return 'other';
  }

  static QuickAddParsed parseQuickAdd(String text) {
    String cleanTitle = text.trim();
    DateTime date = DateTime.now();
    String? dueTime;
    bool isInbox = false;

    final lower = cleanTitle.toLowerCase();

    if (lower.contains('tomorrow')) {
      date = DateTime.now().add(const Duration(days: 1));
      cleanTitle = cleanTitle.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '').trim();
    } else if (lower.contains('today')) {
      date = DateTime.now();
      cleanTitle = cleanTitle.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '').trim();
    }

    // Time parsing (e.g. at 6 PM or at 18:00)
    final timeMatch = RegExp(r'at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false).firstMatch(cleanTitle);
    if (timeMatch != null) {
      int hour = int.parse(timeMatch.group(1)!);
      int minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
      final ampm = timeMatch.group(3)?.toLowerCase();

      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;

      dueTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      cleanTitle = cleanTitle.replaceAll(timeMatch.group(0)!, '').trim();
    }

    if (cleanTitle.isEmpty) cleanTitle = text;

    final autoCategory = detectCategory(cleanTitle);

    return QuickAddParsed(
      title: cleanTitle,
      date: DateTime(date.year, date.month, date.day),
      dueTime: dueTime,
      categoryId: autoCategory,
      isInbox: isInbox,
    );
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final isCompleted = !task.isCompleted;

    // Celebratory Tactile Haptic Feedback
    if (isCompleted) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }

    final updated = task.copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    await _repository.updateTask(updated);
    CloudSyncService.instance.uploadTask(updated);
    if (isCompleted) {
      await NotificationService.instance.cancelNotification(taskId.hashCode.abs());
    } else if (updated.reminderTime != null) {
      await NotificationService.instance.scheduleTaskReminder(updated);
    }

    await loadTasks();
  }

  Future<void> toggleSubtaskCompletion(String taskId, String subtaskId) async {
    final taskIndex = state.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    final task = state[taskIndex];

    final updatedSubtasks = task.subtasks.map((s) {
      if (s.id == subtaskId) {
        final newDone = !s.isCompleted;
        if (newDone) {
          HapticFeedback.lightImpact();
        }
        return s.copyWith(isCompleted: newDone);
      }
      return s;
    }).toList();

    final allDone = updatedSubtasks.isNotEmpty && updatedSubtasks.every((s) => s.isCompleted);
    final updatedTask = task.copyWith(
      subtasks: updatedSubtasks,
      isCompleted: allDone ? true : task.isCompleted,
      completedAt: allDone ? DateTime.now() : task.completedAt,
    );

    if (allDone && !task.isCompleted) {
      HapticFeedback.mediumImpact();
    }

    await _repository.updateTask(updatedTask);
    CloudSyncService.instance.uploadTask(updatedTask);
    await loadTasks();
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    await _repository.updateTask(updatedTask);
    if (updatedTask.reminderTime != null) {
      await NotificationService.instance.scheduleTaskReminder(updatedTask);
    }
    CloudSyncService.instance.uploadTask(updatedTask);
    await loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    await _repository.deleteTask(taskId);
    CloudSyncService.instance.deleteTask(taskId);
    await loadTasks();
  }

  Future<void> moveToTomorrow(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final updated = task.copyWith(
      date: DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
      isInbox: false,
      updatedAt: DateTime.now(),
    );
    await _repository.updateTask(updated);
    await loadTasks();
  }

  Future<void> moveToToday(String taskId) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final now = DateTime.now();
    final updated = task.copyWith(
      date: DateTime(now.year, now.month, now.day),
      isInbox: false,
      updatedAt: DateTime.now(),
    );
    await _repository.updateTask(updated);
    await loadTasks();
  }

  Future<void> convertInboxToScheduled(String taskId, DateTime newDate) async {
    final task = state.firstWhere((t) => t.id == taskId);
    final updated = task.copyWith(
      date: DateTime(newDate.year, newDate.month, newDate.day),
      isInbox: false,
      updatedAt: DateTime.now(),
    );
    await _repository.updateTask(updated);
    await loadTasks();
  }
}

class QuickAddParsed {
  final String title;
  final DateTime date;
  final String? dueTime;
  final String categoryId;
  final bool isInbox;

  QuickAddParsed({
    required this.title,
    required this.date,
    this.dueTime,
    this.categoryId = 'other',
    this.isInbox = false,
  });
}

final taskProvider =
    StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return TaskNotifier(repo, ref);
});

// Filtered Selectors
final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(taskProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return tasks
      .where((t) =>
          !t.isInbox &&
          t.date.year == today.year &&
          t.date.month == today.month &&
          t.date.day == today.day)
      .toList();
});

final inboxTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((t) => t.isInbox && !t.isCompleted).toList();
});

final overdueTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((t) => t.isOverdue && !t.isInbox).toList();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final selectedPriorityFilterProvider = StateProvider<TaskPriority?>((ref) => null);

final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(taskProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final catFilter = ref.watch(selectedCategoryFilterProvider);
  final priorityFilter = ref.watch(selectedPriorityFilterProvider);

  return tasks.where((task) {
    if (query.isNotEmpty) {
      final titleMatch = task.title.toLowerCase().contains(query);
      final descMatch = task.description.toLowerCase().contains(query);
      final notesMatch = (task.notes ?? '').toLowerCase().contains(query);
      if (!titleMatch && !descMatch && !notesMatch) return false;
    }

    if (catFilter != null && task.categoryId != catFilter) return false;
    if (priorityFilter != null && task.priority != priorityFilter) return false;

    return true;
  }).toList();
});
