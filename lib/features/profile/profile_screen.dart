import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/category_provider.dart';
import '../../core/providers/focus_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/streak_provider.dart';
import '../../core/providers/task_provider.dart';
import '../auth/auth_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../../core/widgets/user_avatar_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const List<String> avatarList = [
    '🚀', '👨‍💻', '👩‍🎨', '⚡', '🌟', '🎯',
    '🦁', '🦊', '🐱', '🦉', '👑', '🔥'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user ?? UserModel.guest();
    final streakState = ref.watch(streakProvider);
    final allTasks = ref.watch(taskProvider);
    final focusSessionsAsync = ref.watch(focusSessionsProvider);
    final focusSessions = focusSessionsAsync.value ?? [];

    final completedTasks = allTasks.where((t) => t.isCompleted).length;
    final totalFocusMinutes = focusSessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );

    final totalXp = (completedTasks * 10) +
        (streakState.currentStreak * 25) +
        (totalFocusMinutes * 2);

    final currentLevel = (totalXp ~/ 100) + 1;
    final xpInCurrentLevel = totalXp % 100;
    final levelTitle = _getLevelTitle(currentLevel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Stats'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileBottomSheet(context, ref, user),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. HERO PROFILE CARD
            _buildHeroProfileCard(context, ref, theme, user, levelTitle),
            const SizedBox(height: 20),

            // 2. LEVEL & XP PROGRESSION
            _buildLevelProgressionCard(theme, currentLevel, levelTitle, totalXp, xpInCurrentLevel),
            const SizedBox(height: 20),

            // 3. PRODUCTIVITY METRICS (2x2 Grid)
            _buildProductivityGrid(
              theme,
              completedTasksCount: completedTasks,
              currentStreak: streakState.currentStreak,
              highestStreak: streakState.highestStreak,
              focusMinutes: totalFocusMinutes,
              completionRate: allTasks.isNotEmpty ? ((completedTasks / allTasks.length) * 100).round() : 0,
            ),
            const SizedBox(height: 24),

            // 4. ACHIEVEMENT BADGES
            _buildAchievementBadges(
              theme,
              completedTasks: completedTasks,
              streakDays: streakState.currentStreak,
              focusMinutes: totalFocusMinutes,
              categoryCount: ref.watch(categoryProvider).length,
            ),
            const SizedBox(height: 24),

            // 5. ACCOUNT ACTIONS
            _buildAccountActions(context, ref, theme, user),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // HERO PROFILE CARD
  // -------------------------------------------------------------
  Widget _buildHeroProfileCard(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    UserModel user,
    String levelTitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: UserAvatarWidget(
                  avatarUrl: user.avatarUrl,
                  fallbackName: user.name,
                  size: 84,
                  fontSize: 44,
                ),
              ),
              InkWell(
                onTap: () => _showEditProfileBottomSheet(context, ref, user),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.bio ?? 'Focus on progress, not perfection 🎯',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                avatar: Icon(
                  user.isGuest ? Icons.cloud_off_rounded : Icons.verified_user_rounded,
                  size: 16,
                  color: user.isGuest ? Colors.orange : Colors.green,
                ),
                label: Text(
                  user.isGuest ? 'Offline Guest' : user.email,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                backgroundColor: theme.colorScheme.surface,
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                avatar: const Icon(Icons.military_tech_rounded, size: 16, color: Colors.amber),
                label: Text(
                  levelTitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                backgroundColor: theme.colorScheme.surface,
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // LEVEL & XP PROGRESSION CARD
  // -------------------------------------------------------------
  Widget _buildLevelProgressionCard(
    ThemeData theme,
    int level,
    String levelTitle,
    int totalXP,
    int xpInCurrentLevel,
  ) {
    final progress = xpInCurrentLevel / 100.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level • $levelTitle',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Total XP: $totalXP pts',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$xpInCurrentLevel / 100 XP to Level ${level + 1}',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PRODUCTIVITY METRICS GRID (2x2)
  // -------------------------------------------------------------
  Widget _buildProductivityGrid(
    ThemeData theme, {
    required int completedTasksCount,
    required int currentStreak,
    required int highestStreak,
    required int focusMinutes,
    required int completionRate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productivity Overview',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                theme,
                title: 'Completed',
                value: '$completedTasksCount',
                subtitle: 'Tasks finished',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                theme,
                title: 'Streak',
                value: '$currentStreak d',
                subtitle: 'Record: $highestStreak d',
                icon: Icons.local_fire_department_rounded,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                theme,
                title: 'Deep Focus',
                value: '$focusMinutes m',
                subtitle: 'Time logged',
                icon: Icons.timer_outlined,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                theme,
                title: 'Success Rate',
                value: '$completionRate%',
                subtitle: 'Task efficiency',
                icon: Icons.pie_chart_outline_rounded,
                color: Colors.purpleAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    ThemeData theme, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // ACHIEVEMENT BADGES SHOWCASE
  // -------------------------------------------------------------
  Widget _buildAchievementBadges(
    ThemeData theme, {
    required int completedTasks,
    required int streakDays,
    required int focusMinutes,
    required int categoryCount,
  }) {
    final badges = [
      _BadgeItem(
        emoji: '🎯',
        title: 'Task Novice',
        description: 'Finish your 1st task',
        isUnlocked: completedTasks >= 1,
      ),
      _BadgeItem(
        emoji: '🔥',
        title: 'Streak Starter',
        description: 'Reach a 3-day streak',
        isUnlocked: streakDays >= 3,
      ),
      _BadgeItem(
        emoji: '⚡',
        title: 'Task Champion',
        description: 'Complete 10 tasks',
        isUnlocked: completedTasks >= 10,
      ),
      _BadgeItem(
        emoji: '⏱️',
        title: 'Focus Monk',
        description: 'Clock 25 focus mins',
        isUnlocked: focusMinutes >= 25,
      ),
      _BadgeItem(
        emoji: '👑',
        title: 'Architect',
        description: 'Create 4+ categories',
        isUnlocked: categoryCount >= 4,
      ),
      _BadgeItem(
        emoji: '🌟',
        title: 'Centurion',
        description: 'Complete 50 tasks',
        isUnlocked: completedTasks >= 50,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievement Badges',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${badges.where((b) => b.isUnlocked).length} of ${badges.length} Unlocked',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: badges.length,
          itemBuilder: (context, index) {
            final badge = badges[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: badge.isUnlocked
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: badge.isUnlocked
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                  width: badge.isUnlocked ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: badge.isUnlocked ? 1.0 : 0.35,
                    child: Text(
                      badge.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: badge.isUnlocked
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.isUnlocked ? 'Unlocked ✨' : 'Locked 🔒',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: badge.isUnlocked ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // ACCOUNT ACTIONS
  // -------------------------------------------------------------
  Widget _buildAccountActions(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    UserModel user,
  ) {
    return Column(
      children: [
        if (user.isGuest)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Upgrade Guest to Full Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _showLogoutDialog(context, ref, theme),
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          label: const Text(
            'Log Out / Switch Account',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Log Out?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your FocusFlow account? Your local tasks will be preserved.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authProvider.notifier).logout();
              await ref.read(settingsProvider.notifier).resetOnboarding();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // EDIT PROFILE BOTTOM SHEET
  // -------------------------------------------------------------
  void _showEditProfileBottomSheet(BuildContext context, WidgetRef ref, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final bioController = TextEditingController(text: user.bio ?? '');
    String currentAvatar = user.avatarUrl ?? '🚀';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Edit Profile',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Avatar Preview with Camera badge
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.primary, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: UserAvatarWidget(
                              avatarUrl: currentAvatar,
                              fallbackName: user.name,
                              size: 80,
                              fontSize: 40,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              try {
                                final picker = ImagePicker();
                                final image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                );
                                if (image != null) {
                                  setModalState(() => currentAvatar = image.path);
                                }
                              } catch (e) {
                                debugPrint('Error picking image: $e');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Gallery Pick Button
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (image != null) {
                              setModalState(() => currentAvatar = image.path);
                            }
                          } catch (e) {
                            debugPrint('Error picking image: $e');
                          }
                        },
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: const Text(
                          'Choose Photo from Gallery',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Avatar Grid
                    const Text('Or Select Emoji Avatar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: avatarList.map((av) {
                        final isSel = currentAvatar == av;
                        return InkWell(
                          onTap: () => setModalState(() => currentAvatar = av),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel ? theme.colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(av, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Display Name Field
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Status Bio Field
                    TextField(
                      controller: bioController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Status Quote / Bio',
                        prefixIcon: const Icon(Icons.format_quote_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        final newBio = bioController.text.trim();
                        if (newName.isNotEmpty) {
                          await ref.read(authProvider.notifier).updateProfile(
                                name: newName,
                                avatarUrl: currentAvatar,
                                bio: newBio,
                              );
                          await ref.read(settingsProvider.notifier).updateUserName(newName);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Changes ✨',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getLevelTitle(int level) {
    if (level <= 1) return 'Novice Striver';
    if (level == 2) return 'Consistent Doer';
    if (level == 3) return 'Focus Specialist';
    if (level == 4) return 'Task Champion';
    return 'Productivity Legend';
  }
}

class _BadgeItem {
  final String emoji;
  final String title;
  final String description;
  final bool isUnlocked;

  const _BadgeItem({
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
  });
}
