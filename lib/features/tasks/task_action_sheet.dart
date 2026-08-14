import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/task_provider.dart';
import 'add_edit_task_sheet.dart';

class TaskActionSheet extends ConsumerWidget {
  final TaskModel task;

  const TaskActionSheet({super.key, required this.task});

  static void show(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskActionSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(taskProvider.notifier);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Task Header Title
          Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Actions List
          ListTile(
            leading: Icon(
              task.isCompleted
                  ? Icons.check_box_outline_blank_rounded
                  : Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
            ),
            title: Text(task.isCompleted ? 'Mark as Incomplete' : 'Mark as Completed'),
            onTap: () async {
              Navigator.pop(context);
              await notifier.toggleTaskCompletion(task.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('Edit Task'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => AddEditTaskSheet(taskToEdit: task),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Duplicate Task'),
            onTap: () async {
              Navigator.pop(context);
              await notifier.addTask(
                title: '${task.title} (Copy)',
                description: task.description,
                date: task.date,
                startTime: task.startTime,
                dueTime: task.dueTime,
                priority: task.priority,
                categoryId: task.categoryId,
                recurrenceRule: task.recurrenceRule,
                reminderTime: task.reminderTime,
                notes: task.notes,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sunny_snowing),
            title: const Text('Move to Tomorrow'),
            onTap: () async {
              Navigator.pop(context);
              await notifier.moveToTomorrow(task.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.today_rounded),
            title: const Text('Move to Today'),
            onTap: () async {
              Navigator.pop(context);
              await notifier.moveToToday(task.id);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            title: const Text('Delete Task', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await notifier.deleteTask(task.id);
            },
          ),
        ],
      ),
    ),
  );
}
}
