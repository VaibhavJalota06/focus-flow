import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/models/task_model.dart';
import 'package:focus_flow/core/providers/task_provider.dart';

void main() {
  group('TaskModel Unit Tests', () {
    test('TaskModel serializes and deserializes correctly', () {
      final now = DateTime.now();
      final task = TaskModel(
        id: 'test-123',
        title: 'Complete Flutter Build',
        description: 'Test description',
        date: DateTime(2026, 8, 14),
        dueTime: '18:00',
        priority: TaskPriority.urgent,
        categoryId: 'work',
        createdAt: now,
        updatedAt: now,
      );

      final map = task.toMap();
      final restored = TaskModel.fromMap(map);

      expect(restored.id, equals('test-123'));
      expect(restored.title, equals('Complete Flutter Build'));
      expect(restored.priority, equals(TaskPriority.urgent));
      expect(restored.dueTime, equals('18:00'));
    });

    test('Overdue logic calculates correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      final overdueTask = TaskModel(
        id: 'overdue-1',
        title: 'Past Task',
        date: pastDate,
        categoryId: 'work',
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(overdueTask.isOverdue, isTrue);

      final completedOverdueTask = overdueTask.copyWith(isCompleted: true);
      expect(completedOverdueTask.isOverdue, isFalse);
    });

    test('Quick Add NLP Parser extracts title, date, and due time', () {
      const input = 'Finish portfolio tomorrow at 6 PM';
      final parsed = TaskNotifier.parseQuickAdd(input);

      expect(parsed.title, equals('Finish portfolio'));
      expect(parsed.dueTime, equals('18:00'));
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(parsed.date.day, equals(tomorrow.day));
    });

    test('TaskModel copyWith clears recurrenceRule when clearRecurrenceRule is true', () {
      final now = DateTime.now();
      final recurringTask = TaskModel(
        id: 'rec-1',
        title: 'Daily Exercise',
        date: now,
        categoryId: 'fitness',
        recurrenceRule: 'DAILY',
        createdAt: now,
        updatedAt: now,
      );

      expect(recurringTask.recurrenceRule, equals('DAILY'));

      final nonRecurringTask = recurringTask.copyWith(
        clearRecurrenceRule: true,
      );

      expect(nonRecurringTask.recurrenceRule, isNull);
    });
  });
}
