import 'package:flutter/material.dart';
import '../today/today_screen.dart';
import '../tasks/tasks_screen.dart';
import '../calendar/calendar_screen.dart';
import '../focus/focus_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/add_edit_task_sheet.dart';
import '../../core/services/update_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/streak_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TodayScreen(),
    TasksScreen(),
    CalendarScreen(),
    FocusScreen(),
    AnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.instance.checkForUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final streakState = ref.watch(streakProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(
              title: Text(_getAppBarTitle(_currentIndex)),
        actions: [
          // Flame Streak Badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: streakState.currentStreak > 0
                  ? const Color(0xFFFF9100).withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: streakState.currentStreak > 0
                    ? const Color(0xFFFF9100).withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${streakState.currentStreak}d',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: streakState.currentStreak > 0
                        ? const Color(0xFFFF9100)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_currentIndex == 4)
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const AddEditTaskSheet(),
          );
        },
        tooltip: 'Add Task (<5s)',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          height: 68,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.today_outlined,
                selectedIcon: Icons.today_rounded,
                label: 'Today',
                theme: theme,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.task_alt_outlined,
                selectedIcon: Icons.task_alt_rounded,
                label: 'Tasks',
                theme: theme,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.calendar_month_outlined,
                selectedIcon: Icons.calendar_month_rounded,
                label: 'Calendar',
                theme: theme,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.timer_outlined,
                selectedIcon: Icons.timer_rounded,
                label: 'Focus',
                theme: theme,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights_rounded,
                label: 'Analytics',
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Daily Dashboard';
      case 1:
        return 'All Tasks';
      case 2:
        return 'Calendar Schedule';
      case 3:
        return 'Focus Mode';
      case 4:
        return 'Analytics & Streaks';
      default:
        return 'Focus Flow';
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;
    final primaryColor = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? Border.all(
                        color: primaryColor.withValues(alpha: 0.35),
                        width: 1,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.15 : 1.0,
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: 22,
                  color: isSelected
                      ? primaryColor
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: -0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
