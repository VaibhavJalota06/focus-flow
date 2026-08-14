import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category_model.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/task_provider.dart';
import 'task_action_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _quickAddController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quickAddController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onQuickAddSubmitted() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;
    await ref.read(taskProvider.notifier).quickAddTask(text);
    _quickAddController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added via Quick Add!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdueTasks = ref.watch(overdueTasksProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final inboxTasks = ref.watch(inboxTasksProvider);
    final categories = ref.watch(categoryProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final selectedPriority = ref.watch(selectedPriorityFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Quick Add & Search Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Search TextField
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search tasks, notes, categories...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Quick Add TextField ("Finish portfolio tomorrow at 6 PM")
                  TextField(
                    controller: _quickAddController,
                    onSubmitted: (_) => _onQuickAddSubmitted(),
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: '⚡ Quick Add: "Task tomorrow at 6 PM"',
                      prefixIcon: const Icon(Icons.flash_on_rounded, color: Colors.amber),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: _onQuickAddSubmitted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar: All Tasks, Inbox, Overdue
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                const Tab(text: 'All Tasks'),
                Tab(text: 'Inbox (${inboxTasks.length})'),
                Tab(text: 'Overdue (${overdueTasks.length})'),
              ],
            ),

            // Filter Chips (Categories & Priorities)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      showCheckmark: false,
                      selectedColor: theme.colorScheme.primary,
                      label: Text(
                        'All Categories',
                        style: TextStyle(
                          color: selectedCategory == null
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: selectedCategory == null
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      selected: selectedCategory == null,
                      onSelected: (_) => ref
                          .read(selectedCategoryFilterProvider.notifier)
                          .state = null,
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) {
                      final isSel = selectedCategory == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          showCheckmark: false,
                          selectedColor: theme.colorScheme.primary,
                          label: Text(cat.name),
                          labelStyle: TextStyle(
                            color: isSel
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.w600,
                          ),
                          avatar: Icon(
                            cat.icon,
                            size: 14,
                            color: isSel ? Colors.white : cat.color,
                          ),
                          selected: isSel,
                          onSelected: (val) {
                            ref
                                .read(selectedCategoryFilterProvider.notifier)
                                .state = val ? cat.id : null;
                          },
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    ...TaskPriority.values.map((p) {
                      final isSel = selectedPriority == p;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          showCheckmark: false,
                          selectedColor: theme.colorScheme.primary,
                          label: Text(p.label),
                          labelStyle: TextStyle(
                            color: isSel
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isSel ? FontWeight.bold : FontWeight.w600,
                          ),
                          selected: isSel,
                          onSelected: (val) {
                            ref
                                .read(selectedPriorityFilterProvider.notifier)
                                .state = val ? p : null;
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: All Tasks
                  _buildTaskList(context, ref, filteredTasks, categories),

                  // Tab 2: Inbox Tasks
                  _buildTaskList(context, ref, inboxTasks, categories, isInboxView: true),

                  // Tab 3: Overdue Tasks
                  _buildOverdueView(context, ref, overdueTasks, categories),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> taskList,
    List<CategoryModel> categories, {
    bool isInboxView = false,
  }) {
    if (taskList.isEmpty) {
      return Center(
        child: Text(
          isInboxView
              ? 'Inbox is empty! Quick capture ideas here.'
              : 'No tasks found.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: taskList.length,
      itemBuilder: (context, index) {
        final task = taskList[index];
        final effectiveCatId = (task.categoryId == 'other')
            ? TaskNotifier.detectCategory(task.title, task.description)
            : task.categoryId;
        final category = categories.firstWhere(
          (c) => c.id == effectiveCatId,
          orElse: () => categories.isNotEmpty
              ? categories.first
              : CategoryModel.defaultCategories.first,
        );

        final theme = Theme.of(context);

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
                      // Custom Interactive Check Button
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

                      // Task Details Column
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
                            if (task.subtasks.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: task.subtasksCompletionRatio,
                                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${task.subtasks.where((s) => s.isCompleted).length}/${task.subtasks.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Column(
                                children: task.subtasks.map((subtask) {
                                  return InkWell(
                                    onTap: () {
                                      ref.read(taskProvider.notifier).toggleSubtaskCompletion(task.id, subtask.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            subtask.isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                            size: 16,
                                            color: subtask.isCompleted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              subtask.title,
                                              style: TextStyle(
                                                fontSize: 12,
                                                decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                                                color: subtask.isCompleted ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
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

                      if (isInboxView)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            onPressed: () {
                              ref
                                  .read(taskProvider.notifier)
                                  .convertInboxToScheduled(
                                      task.id, DateTime.now());
                            },
                            child: const Text('Schedule'),
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
    );
  }

  Widget _buildOverdueView(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> overdueTasks,
    List<CategoryModel> categories,
  ) {
    if (overdueTasks.isEmpty) {
      return const Center(
        child: Text('🎉 No overdue tasks! Great job staying on schedule.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overdue Banner Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${overdueTasks.length} Overdue Tasks',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      'Reschedule or move them to today to keep your streak alive.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ...overdueTasks.map(
          (task) => Card(
            child: ListTile(
              onTap: () => TaskActionSheet.show(context, task),
              title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Was due on ${task.date.year}-${task.date.month}-${task.date.day}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.today_rounded, color: Colors.blue),
                    tooltip: 'Move to Today',
                    onPressed: () {
                      ref.read(taskProvider.notifier).moveToToday(task.id);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                    tooltip: 'Complete',
                    onPressed: () {
                      ref.read(taskProvider.notifier).toggleTaskCompletion(task.id);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
