import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/models/category_model.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/task_provider.dart';
import '../tasks/task_action_sheet.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(taskProvider);
    final categories = ref.watch(categoryProvider);

    final selectedDayTasks = tasks.where((t) {
      return !t.isInbox &&
          t.date.year == _selectedDay.year &&
          t.date.month == _selectedDay.month &&
          t.date.day == _selectedDay.day;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Compact Collapsible Calendar Header
            TableCalendar<TaskModel>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              rowHeight: 38,
              daysOfWeekHeight: 22,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return tasks.where((t) {
                  return !t.isInbox &&
                      t.date.year == day.year &&
                      t.date.month == day.month &&
                      t.date.day == day.day;
                }).toList();
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                formatButtonTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // Selected Day Tasks Header Pill Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks for ${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${selectedDayTasks.length} Scheduled',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded Tasks List
            Expanded(
              child: selectedDayTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tasks scheduled for this day.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: selectedDayTasks.length,
                      itemBuilder: (context, index) {
                        final task = selectedDayTasks[index];
                        final effectiveCatId = (task.categoryId == 'other')
                            ? TaskNotifier.detectCategory(task.title, task.description)
                            : task.categoryId;
                        final category = categories.firstWhere(
                          (c) => c.id == effectiveCatId,
                          orElse: () => categories.isNotEmpty
                              ? categories.first
                              : CategoryModel.defaultCategories.first,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: task.isCompleted
                                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                                  : theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: task.isCompleted
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                                width: 1,
                              ),
                              boxShadow: [
                                if (!task.isCompleted)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => TaskActionSheet.show(context, task),
                                onLongPress: () => TaskActionSheet.show(context, task),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Custom Check Button
                                      GestureDetector(
                                        onTap: () {
                                          ref
                                              .read(taskProvider.notifier)
                                              .toggleTaskCompletion(task.id);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 14),
                                          child: AnimatedScale(
                                            duration: const Duration(milliseconds: 200),
                                            scale: task.isCompleted ? 1.1 : 1.0,
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: task.isCompleted
                                                    ? const Color(0xFF10B981)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: task.isCompleted
                                                      ? const Color(0xFF10B981)
                                                      : task.priority.color,
                                                  width: 2,
                                                ),
                                                boxShadow: task.isCompleted
                                                    ? [
                                                        BoxShadow(
                                                          color: const Color(0xFF10B981)
                                                              .withValues(alpha: 0.35),
                                                          blurRadius: 6,
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: task.isCompleted
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      size: 16,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Task Text & Meta Row
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AnimatedDefaultTextStyle(
                                              duration: const Duration(milliseconds: 200),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                decoration: task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: task.isCompleted
                                                    ? theme.colorScheme.onSurfaceVariant
                                                        .withValues(alpha: 0.6)
                                                    : theme.colorScheme.onSurface,
                                              ),
                                              child: Text(task.title),
                                            ),
                                            if (task.description.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                task.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 6,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                // Category Pill Badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: category.color
                                                        .withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: category.color
                                                          .withValues(alpha: 0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(category.icon,
                                                          size: 12, color: category.color),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        category.name,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: category.color,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Priority Pill Tag
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: task.priority.color
                                                        .withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          color: task.priority.color,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        task.priority.label,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: task.priority.color,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                if (task.dueTime != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme.surfaceContainerHighest
                                                          .withValues(alpha: 0.5),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.schedule_rounded,
                                                          size: 12,
                                                          color: theme
                                                              .colorScheme.onSurfaceVariant,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          task.dueTime!,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w500,
                                                            color: theme
                                                                .colorScheme.onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
