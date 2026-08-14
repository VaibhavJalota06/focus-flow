import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    this.isMandatory = false,
  });
}

class UpdateService {
  static final UpdateService instance = UpdateService._init();

  UpdateService._init();

  static const String currentVersion = '1.0.0';

  Future<AppUpdateInfo?> checkForUpdates() async {
    // Connects to remote release API manifest
    await Future.delayed(const Duration(milliseconds: 600));
    // Example: isVersionNewer(currentVersion, '1.0.0');
    return null; // App is up to date (v1.0.0)
  }

  bool isVersionNewer(String current, String remote) {
    final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      if (r > c) return true;
      if (c > r) return false;
    }
    return false;
  }

  void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: !info.isMandatory,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update_rounded, color: Colors.indigo, size: 28),
              const SizedBox(height: 8),
              Text(
                'Update Available (v${info.latestVersion})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version of FocusFlow is ready for download.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                "What's New:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(info.releaseNotes, style: const TextStyle(fontSize: 13)),
            ],
          ),
          actions: [
            if (!info.isMandatory)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final uri = Uri.parse(info.downloadUrl);
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Update link: ${info.downloadUrl}')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Update Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
