import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/update_service.dart';
import '../profile/profile_screen.dart';
import '../../core/widgets/user_avatar_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showExportDialog(BuildContext context, String jsonText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export JSON Data'),
          content: SingleChildScrollView(
            child: SelectableText(jsonText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Backup JSON'),
          content: TextField(
            controller: controller,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Paste backup JSON here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  final success = await ref
                      .read(settingsProvider.notifier)
                      .importBackupJson(text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Data imported successfully!'
                            : 'Failed to parse backup JSON.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // Section 0: User Profile & Account Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          UserAvatarWidget(
                            avatarUrl: user?.avatarUrl,
                            fallbackName: user?.name ?? settings.userName,
                            size: 56,
                            fontSize: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user?.name ?? settings.userName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (user?.isGuest ?? true)
                                            ? Colors.grey.withValues(alpha: 0.2)
                                            : theme.colorScheme.primary
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        (user?.isGuest ?? true) ? 'Guest' : 'Member',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: (user?.isGuest ?? true)
                                              ? Colors.grey
                                              : theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (user?.isGuest ?? true)
                                      ? 'Offline Mode • Local Storage'
                                      : (user?.email ?? ''),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Target: ${settings.dailyGoal} tasks',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Full Profile & Stats',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 24),

            // Section 1: Appearance
            _buildSectionTitle(theme, 'Appearance'),
            ListTile(
              leading: const Icon(Icons.palette_rounded),
              title: const Text('Theme Mode'),
              subtitle: Text(settings.themeMode.name.toUpperCase()),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (mode) {
                  if (mode != null) notifier.updateThemeMode(mode);
                },
              ),
            ),

            // Section 2: Notifications & Permissions
            _buildSectionTitle(theme, 'Notifications & Permissions'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_rounded),
              title: const Text('Enable Reminders'),
              subtitle: const Text('Receive push alerts for task deadlines'),
              value: settings.notificationsEnabled,
              onChanged: notifier.updateNotifications,
            ),
            ListTile(
              leading: const Icon(Icons.security_rounded),
              title: const Text('Manage App Permissions'),
              subtitle: const Text('Microphone, Notifications & Storage'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await openAppSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm_rounded),
              title: const Text('Default Reminder Timing'),
              trailing: DropdownButton<int>(
                value: settings.defaultReminderMinutes,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Exact time')),
                  DropdownMenuItem(value: 10, child: Text('10m before')),
                  DropdownMenuItem(value: 30, child: Text('30m before')),
                  DropdownMenuItem(value: 60, child: Text('1h before')),
                ],
                onChanged: (val) {
                  if (val != null) notifier.updateDefaultReminder(val);
                },
              ),
            ),

            // Section 3: Task Settings
            _buildSectionTitle(theme, 'Task & Productivity'),
            ListTile(
              leading: const Icon(Icons.calendar_view_week_rounded),
              title: const Text('Week Starts On'),
              trailing: DropdownButton<String>(
                value: settings.weekStartDay,
                items: const [
                  DropdownMenuItem(value: 'Monday', child: Text('Monday')),
                  DropdownMenuItem(value: 'Sunday', child: Text('Sunday')),
                ],
                onChanged: (val) {
                  if (val != null) notifier.updateWeekStart(val);
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_rounded),
              title: const Text('Daily Goal Target'),
              subtitle: Text('${settings.dailyGoal} tasks per day'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (settings.dailyGoal > 1) {
                        notifier.updateDailyGoal(settings.dailyGoal - 1);
                      }
                    },
                  ),
                  Text('${settings.dailyGoal}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      notifier.updateDailyGoal(settings.dailyGoal + 1);
                    },
                  ),
                ],
              ),
            ),

            // Section 4: Data Management
            _buildSectionTitle(theme, 'Data & Backup'),

            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Export Backup (JSON)'),
              subtitle: const Text('Save your tasks and settings to backup text'),
              onTap: () async {
                final jsonStr = await notifier.exportBackupJson();
                if (context.mounted) _showExportDialog(context, jsonStr);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_rounded),
              title: const Text('Import Backup (JSON)'),
              subtitle: const Text('Restore tasks from a backup'),
              onTap: () => _showImportDialog(context, ref),
            ),

            // Section 5: About & Updates
            _buildSectionTitle(theme, 'About & Updates'),
            ListTile(
              leading: const Icon(Icons.system_update_rounded),
              title: const Text('Check for Updates'),
              subtitle: const Text('Automatically check for latest release'),
              onTap: () async {
                final info = await UpdateService.instance.checkForUpdates();
                if (context.mounted) {
                  if (info != null) {
                    UpdateService.instance.showUpdateDialog(context, info);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your app is up to date! (v1.0.0)'),
                      ),
                    );
                  }
                }
              },
            ),
            const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('App Version'),
              subtitle: Text('1.0.0 (Build 1)'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Focus Flow',
                  applicationVersion: '1.0.0',
                  applicationIcon: ClipOval(
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  children: const [
                    Text('Your task data is stored securely. Supabase Cloud Auth keeps your profile in sync.'),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
