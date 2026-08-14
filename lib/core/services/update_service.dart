import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// Current app version
  static const String currentVersion = '1.0.0';

  /// GitHub repo endpoint for checking releases
  static const String githubRepo = 'VaibhavJalota06/focus-flow';

  /// Check GitHub Releases API for new updates
  Future<AppUpdateInfo?> checkForUpdates() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      
      final uri = Uri.parse('https://api.github.com/repos/$githubRepo/releases/latest');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'FocusFlow-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) {
        debugPrint('[UpdateService] Release check returned HTTP ${response.statusCode}');
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      final rawTag = data['tag_name'] as String? ?? '';
      final latestVersion = rawTag.replaceAll(RegExp(r'[^0-9.]'), '');
      final releaseNotes = data['body'] as String? ?? 'Exciting new improvements and bug fixes!';
      final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$githubRepo/releases';

      // Find direct asset link if available
      String downloadUrl = htmlUrl;
      final assets = data['assets'] as List<dynamic>? ?? [];
      if (defaultTargetPlatform == TargetPlatform.android) {
        final apkAsset = assets.firstWhere(
          (a) => (a['name'] as String? ?? '').endsWith('.apk'),
          orElse: () => null,
        );
        if (apkAsset != null && apkAsset['browser_download_url'] != null) {
          downloadUrl = apkAsset['browser_download_url'] as String;
        }
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ipaAsset = assets.firstWhere(
          (a) => (a['name'] as String? ?? '').endsWith('.ipa'),
          orElse: () => null,
        );
        if (ipaAsset != null && ipaAsset['browser_download_url'] != null) {
          downloadUrl = ipaAsset['browser_download_url'] as String;
        }
      }

      if (isVersionNewer(currentVersion, latestVersion)) {
        debugPrint('[UpdateService] Update available: v$currentVersion -> v$latestVersion');
        return AppUpdateInfo(
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          isMandatory: false,
        );
      } else {
        debugPrint('[UpdateService] App is up to date (v$currentVersion).');
        return null;
      }
    } catch (e) {
      debugPrint('[UpdateService] Error checking for updates: $e');
      return null;
    }
  }

  /// SemVer comparator: returns true if remote > current
  bool isVersionNewer(String current, String remote) {
    if (remote.isEmpty) return false;
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

  /// Show standard modern update dialog
  void showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: !info.isMandatory,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Color(0xFF007AFF), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Update Available',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'v$currentVersion → v${info.latestVersion}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version of Focus Flow is ready to download.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                "What's New:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  info.releaseNotes,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                      SnackBar(content: Text('Download link: ${info.downloadUrl}')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Update Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
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
