import 'dart:convert';
import 'package:flutter/material.dart';

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.green;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  static TaskPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
      default:
        return TaskPriority.low;
    }
  }
}

class SubtaskModel {
  final String id;
  final String title;
  final bool isCompleted;

  const SubtaskModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubtaskModel.fromMap(Map<String, dynamic> map) {
    return SubtaskModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  SubtaskModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubtaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String? startTime; // e.g. "09:00"
  final String? dueTime; // e.g. "17:00"
  final TaskPriority priority;
  final String categoryId;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? recurrenceRule; // e.g. "DAILY", "WEEKDAYS", "WEEKLY", "MONTHLY", "CUSTOM:1,3,5"
  final String? reminderTime; // e.g. "10_MIN_BEFORE", "30_MIN_BEFORE", "EXACT"
  final String? notes;
  final bool isInbox;
  final List<SubtaskModel> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.startTime,
    this.dueTime,
    this.priority = TaskPriority.medium,
    required this.categoryId,
    this.isCompleted = false,
    this.completedAt,
    this.recurrenceRule,
    this.reminderTime,
    this.notes,
    this.isInbox = false,
    this.subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    return taskDay.isBefore(today);
  }

  double get subtasksCompletionRatio {
    if (subtasks.isEmpty) return 0.0;
    final done = subtasks.where((s) => s.isCompleted).length;
    return done / subtasks.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'dueTime': dueTime,
      'priority': priority.name,
      'categoryId': categoryId,
      'isCompleted': isCompleted ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
      'recurrenceRule': recurrenceRule,
      'reminderTime': reminderTime,
      'notes': notes,
      'isInbox': isInbox ? 1 : 0,
      'subtasks_json': jsonEncode(subtasks.map((s) => s.toMap()).toList()),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    List<SubtaskModel> parsedSubtasks = const [];
    if (map['subtasks_json'] != null && (map['subtasks_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['subtasks_json'] as String) as List;
        parsedSubtasks = decoded.map((e) => SubtaskModel.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
      startTime: map['startTime'] as String?,
      dueTime: map['dueTime'] as String?,
      priority: TaskPriority.fromString(map['priority'] as String?),
      categoryId: (map['categoryId'] as String?) ?? 'other',
      isCompleted: (map['isCompleted'] as int? ?? 0) == 1,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt'] as String) : null,
      recurrenceRule: map['recurrenceRule'] as String?,
      reminderTime: map['reminderTime'] as String?,
      notes: map['notes'] as String?,
      isInbox: (map['isInbox'] as int? ?? 0) == 1,
      subtasks: parsedSubtasks,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? startTime,
    String? dueTime,
    TaskPriority? priority,
    String? categoryId,
    bool? isCompleted,
    DateTime? completedAt,
    String? recurrenceRule,
    String? reminderTime,
    String? notes,
    bool? isInbox,
    List<SubtaskModel>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminderTime: reminderTime ?? this.reminderTime,
      notes: notes ?? this.notes,
      isInbox: isInbox ?? this.isInbox,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
