import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task_model.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/task_provider.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final focusState = ref.watch(focusProvider);
    final focusNotifier = ref.read(focusProvider.notifier);
    final todayTasks = ref.watch(todayTasksProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              // Non-scrollable Segmented Mode Selector Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPresetSegment(
                        label: '⚡ 25m Sprint',
                        isSelected: focusState.totalDurationSeconds == 25 * 60,
                        onTap: () => focusNotifier.setDuration(25),
                        theme: theme,
                      ),
                      const SizedBox(width: 4),
                      _buildPresetSegment(
                        label: '☕ 5m Rest',
                        isSelected: focusState.totalDurationSeconds == 5 * 60,
                        onTap: () => focusNotifier.setDuration(5),
                        theme: theme,
                      ),
                      const SizedBox(width: 4),
                      _buildPresetSegment(
                        label: '🚀 50m Flow',
                        isSelected: focusState.totalDurationSeconds == 50 * 60,
                        onTap: () => focusNotifier.setDuration(50),
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Circular Countdown Timer Display
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: focusState.progress,
                        strokeWidth: 12,
                        backgroundColor: theme.colorScheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(focusState.secondsRemaining),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          focusState.isRunning
                              ? (focusState.isPaused ? 'Paused' : 'Focusing...')
                              : 'Ready',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Selected Task Display / Picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.task_alt_rounded, color: Color(0xFF60A5FA)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Focus Task',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            Text(
                              focusState.selectedTask?.title ?? 'General Focus Session',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                        onPressed: () => _showTaskPicker(context, ref, todayTasks),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Controls: Start / Pause / Complete / Exit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    if (!focusState.isRunning || focusState.isPaused)
                      ElevatedButton.icon(
                        onPressed: focusNotifier.startTimer,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(focusState.isPaused ? 'Resume' : 'Start Focus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: focusNotifier.pauseTimer,
                        icon: const Icon(Icons.pause_rounded),
                        label: const Text('Pause'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                    ElevatedButton.icon(
                      onPressed: focusNotifier.completeSession,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    if (focusState.isRunning || focusState.isPaused)
                      OutlinedButton.icon(
                        onPressed: focusNotifier.resetTimer,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Exit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskPicker(
      BuildContext context, WidgetRef ref, List<TaskModel> tasks) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Task for Focus',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('General Focus (No specific task)'),
                onTap: () {
                  ref.read(focusProvider.notifier).selectTask(null);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...tasks.map(
                (task) => ListTile(
                  title: Text(task.title),
                  onTap: () {
                    ref.read(focusProvider.notifier).selectTask(task);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPresetSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
