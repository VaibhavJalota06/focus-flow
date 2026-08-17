import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final categories = ref.watch(categoryProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final selectedPriority = ref.watch(selectedPriorityFilterProvider);

    // Group tasks by date string key: "UPCOMING", "TODAY", "YESTERDAY", or "YYYY-MM-DD"
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<TaskModel>> groupedTasks = {};

    for (final task in filteredTasks) {
      final taskDay = DateTime(task.date.year, task.date.month, task.date.day);
      String groupKey;

      if (taskDay.isAfter(today)) {
        groupKey = 'UPCOMING';
      } else if (taskDay.isAtSameMomentAs(today)) {
        groupKey = 'TODAY';
      } else if (taskDay.isAtSameMomentAs(yesterday)) {
        groupKey = 'YESTERDAY';
      } else {
        groupKey = DateFormat('yyyy-MM-dd').format(taskDay);
      }

      groupedTasks.putIfAbsent(groupKey, () => []).add(task);
    }

    // Sort group keys: TODAY first, UPCOMING second, YESTERDAY third, then past dates descending
    final groupKeys = groupedTasks.keys.toList()..sort((a, b) {
      if (a == 'TODAY') return -1;
      if (b == 'TODAY') return 1;
      if (a == 'UPCOMING') return -1;
      if (b == 'UPCOMING') return 1;
      if (a == 'YESTERDAY') return -1;
      if (b == 'YESTERDAY') return 1;
      return b.compareTo(a); // Past dates descending
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar with Toggleable Search
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) {
                    ref.read(searchQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tasks, notes, categories...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        setState(() => _isSearching = false);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Tasks Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'Search Tasks',
                      onPressed: () => setState(() => _isSearching = true),
                    ),
                  ],
                ),
              ),

            // Filter Chips (Categories & Priorities)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
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

            const SizedBox(height: 8),

            // Date Grouped Task Timeline List
            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📋', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              'No tasks found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + below to create a new task',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: groupKeys.length,
                      itemBuilder: (context, groupIndex) {
                        final key = groupKeys[groupIndex];
                        final tasksInGroup = groupedTasks[key]!;

                        String headerTitle;
                        if (key == 'TODAY') {
                          headerTitle = '📅 Today (${DateFormat('E, MMM d').format(today)})';
                        } else if (key == 'UPCOMING') {
                          headerTitle = '🔮 Upcoming Tasks';
                        } else if (key == 'YESTERDAY') {
                          headerTitle = '🗓️ Yesterday (${DateFormat('E, MMM d').format(yesterday)})';
                        } else {
                          final parsedDate = DateTime.parse(key);
                          headerTitle = '🗓️ ${DateFormat('EEEE, MMM d, yyyy').format(parsedDate)}';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Section Header Pill
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Text(
                                      headerTitle,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${tasksInGroup.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Task items in this date group
                            ...tasksInGroup.map((task) {
                              final effectiveCatId = (task.categoryId == 'other')
                                  ? TaskNotifier.detectCategory(
                                      task.title, task.description)
                                  : task.categoryId;
                              final category = categories.firstWhere(
                                (c) => c.id == effectiveCatId,
                                orElse: () => categories.isNotEmpty
                                    ? categories.first
                                    : CategoryModel.defaultCategories.first,
                              );

                              return _buildTaskCard(context, ref, task, category);
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    CategoryModel category,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
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
                  // Checkbox
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

                  // Task details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
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
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            task.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Category Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(category.icon,
                                      size: 11, color: category.color),
                                  const SizedBox(width: 4),
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

                            // Priority Tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: task.priority.color
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                task.priority.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: task.priority.color,
                                ),
                              ),
                            ),

                            if (task.dueTime != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  task.dueTime!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),

                            if (task.recurrenceRule != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '🔁 ${task.recurrenceRule}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
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
  }
}
