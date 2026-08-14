import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/category_model.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/task_provider.dart';
import '../profile/profile_screen.dart';
import '../tasks/add_edit_task_sheet.dart';
import '../tasks/task_action_sheet.dart';
import '../../core/widgets/user_avatar_widget.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late ConfettiController _confettiController;
  bool _hasCelebratedToday = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userSettings = ref.watch(settingsProvider);
    final todayTasks = ref.watch(todayTasksProvider);
    final analytics = ref.watch(analyticsProvider);
    final categories = ref.watch(categoryProvider);

    final completedTasks = todayTasks.where((t) => t.isCompleted).toList();
    final pendingTasks = todayTasks.where((t) => !t.isCompleted).toList();

    // Trigger celebration if all tasks are complete
    if (todayTasks.isNotEmpty && pendingTasks.isEmpty && completedTasks.isNotEmpty) {
      if (!_hasCelebratedToday) {
        _hasCelebratedToday = true;
        _confettiController.play();
      }
    } else if (pendingTasks.isNotEmpty) {
      _hasCelebratedToday = false;
    }

    // Grouping pending tasks into Morning, Afternoon, Evening
    final morningTasks = <TaskModel>[];
    final afternoonTasks = <TaskModel>[];
    final eveningTasks = <TaskModel>[];

    for (final task in pendingTasks) {
      if (task.dueTime != null) {
        final hour = int.tryParse(task.dueTime!.split(':')[0]) ?? 9;
        if (hour < 12) {
          morningTasks.add(task);
        } else if (hour < 17) {
          afternoonTasks.add(task);
        } else {
          eveningTasks.add(task);
        }
      } else {
        morningTasks.add(task);
      }
    }

    final totalCount = todayTasks.length;
    final completedCount = completedTasks.length;
    final progressPct = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(taskProvider.notifier).loadTasks();
              },
              child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Sliver
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting & Streak Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()}, ${userSettings.userName} 👋',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Streak Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(
                                  '${analytics.currentStreak} Day Streak',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B00),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Profile Avatar Button
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: UserAvatarWidget(
                                avatarUrl: ref.watch(authProvider).user?.avatarUrl,
                                fallbackName: ref.watch(authProvider).user?.name,
                                size: 38,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Progress Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Today's Progress",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(progressPct * 100).round()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$completedCount / $totalCount Tasks Completed',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progressPct,
                                minHeight: 8,
                                backgroundColor: Colors.white24,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty State
              if (todayTasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 54)),
                          const SizedBox(height: 16),
                          Text(
                            "You're all caught up!",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enjoy your free time or plan something new.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => const AddEditTaskSheet(),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                // Task Groups: Morning, Afternoon, Evening
                if (morningTasks.isNotEmpty) ...[
                  _buildSectionHeader(theme, '🌅 Morning'),
                  _buildTaskSliverList(morningTasks, categories),
                ],

                if (afternoonTasks.isNotEmpty) ...[
                  _buildSectionHeader(theme, '☀️ Afternoon'),
                  _buildTaskSliverList(afternoonTasks, categories),
                ],

                if (eveningTasks.isNotEmpty) ...[
                  _buildSectionHeader(theme, '🌙 Evening'),
                  _buildTaskSliverList(eveningTasks, categories),
                ],

                if (completedTasks.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  _buildSectionHeader(
                      theme, 'Completed (${completedTasks.length})'),
                                  _buildTaskSliverList(completedTasks, categories),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ],
          ),
        ),
      ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Color(0xFFFF3355),
            Color(0xFF00E676),
            Color(0xFFFF9100),
            Color(0xFF60A5FA),
            Color(0xFFC084FC),
          ],
          numberOfParticles: 25,
          gravity: 0.2,
        ),
      ],
    ),
  );
}

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSliverList(
      List<TaskModel> taskList, List<CategoryModel> categories) {
    final theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
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
                                          borderRadius:
                                              BorderRadius.circular(20),
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
          childCount: taskList.length,
        ),
      ),
    );
  }
}
