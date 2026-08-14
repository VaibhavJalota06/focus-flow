import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/streak_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(analyticsProvider);
    final streakState = ref.watch(streakProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'This Week'),
                Tab(text: 'This Month'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayTab(theme, stats, streakState),
                  _buildWeekTab(theme, stats, streakState),
                  _buildMonthTab(theme, stats, streakState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab(ThemeData theme, ProductivityStats stats, StreakState streakState) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Productivity Score Card (0-100)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Productivity Score',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.productivityScore}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stats.productivityScore >= 80
                          ? '🔥 On Fire'
                          : stats.productivityScore >= 50
                              ? '⚡ Good Pace'
                              : '🌱 Getting Started',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.productivityScore / 100.0,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quick Stats Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Completed',
                '${stats.todayCompleted}',
                'of ${stats.todayTotal} tasks',
                Icons.check_circle_outline_rounded,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Focus Time',
                '${stats.todayFocusMinutes}m',
                'Pomodoro session',
                Icons.timer_outlined,
                Colors.indigo,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Streaks Card & Heatmap
        _buildStreakHeatmapCard(theme, stats, streakState),
      ],
    );
  }

  Widget _buildWeekTab(ThemeData theme, ProductivityStats stats, StreakState streakState) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Weekly Tasks',
                '${stats.weekCompleted}',
                'of ${stats.weekTotal} completed',
                Icons.task_alt_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Best Day',
                stats.bestDayOfWeek,
                'Most productive day',
                Icons.star_rounded,
                Colors.amber,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Completion Rate Chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Completion Rate',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: stats.weekTotal > 0
                              ? [
                                  PieChartSectionData(
                                    color: theme.colorScheme.primary,
                                    value: stats.weekCompleted.toDouble(),
                                    title: '${stats.weekCompleted}',
                                    radius: 40,
                                    titleStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  PieChartSectionData(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.15),
                                    value: (stats.weekTotal - stats.weekCompleted)
                                        .toDouble()
                                        .clamp(0.1, 999),
                                    title: '',
                                    radius: 35,
                                  ),
                                ]
                              : [
                                  PieChartSectionData(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.15),
                                    value: 1,
                                    title: '',
                                    radius: 40,
                                  ),
                                ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stats.weekTotal > 0
                                ? '${((stats.weekCompleted / stats.weekTotal) * 100).round()}%'
                                : '0%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
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
      ],
    );
  }

  Widget _buildMonthTab(ThemeData theme, ProductivityStats stats, StreakState streakState) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                'Monthly Tasks',
                '${stats.monthCompleted}',
                'Total completed',
                Icons.calendar_month_rounded,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                theme,
                'Total Focus',
                '${stats.monthFocusMinutes}m',
                'Total deep work',
                Icons.bolt_rounded,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _buildStreakHeatmapCard(theme, stats, streakState),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakHeatmapCard(ThemeData theme, ProductivityStats stats, StreakState streakState) {
    final currentStreak = streakState.currentStreak > 0 ? streakState.currentStreak : stats.currentStreak;
    final highestStreak = streakState.highestStreak > 0 ? streakState.highestStreak : stats.longestStreak;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '$currentStreak Day Streak',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '🏆 Best: $highestStreak Days',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Past 30 Days Activity Heatmap',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // Heatmap Grid (30 squares)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stats.heatmapData.entries.map((entry) {
                final count = entry.value;
                Color squareColor;
                if (count == 0) {
                  squareColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
                } else if (count <= 2) {
                  squareColor = Colors.green.shade200;
                } else if (count <= 5) {
                  squareColor = Colors.green.shade400;
                } else {
                  squareColor = Colors.green.shade700;
                }

                return Tooltip(
                  message: '${entry.key.month}/${entry.key.day}: $count completed',
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: squareColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
