import 'dart:io';
import 'package:flutter/material.dart';

/// Renders either a Google / Cloud Network Avatar Photo, a Local File Photo, or an Emoji Avatar cleanly
class UserAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String? fallbackName;
  final double size;
  final double fontSize;
  final BoxDecoration? decoration;

  const UserAvatarWidget({
    super.key,
    required this.avatarUrl,
    this.fallbackName,
    this.size = 40,
    this.fontSize = 20,
    this.decoration,
  });

  bool get _isNetworkImage =>
      avatarUrl != null &&
      (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://'));

  bool get _isLocalFile =>
      avatarUrl != null &&
      !_isNetworkImage &&
      (avatarUrl!.startsWith('/') ||
          avatarUrl!.contains(':\\') ||
          avatarUrl!.contains('cache') ||
          avatarUrl!.contains('app_flutter') ||
          avatarUrl!.contains('.jpg') ||
          avatarUrl!.contains('.png') ||
          avatarUrl!.contains('.jpeg'));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isNetworkImage) {
      return Container(
        width: size,
        height: size,
        decoration: decoration ??
            BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(theme),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: size * 0.4,
                  height: size * 0.4,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    if (_isLocalFile) {
      return Container(
        width: size,
        height: size,
        decoration: decoration ??
            BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
        child: ClipOval(
          child: Image.file(
            File(avatarUrl!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(theme),
          ),
        ),
      );
    }

    // Emoji or Initial Fallback
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        avatarUrl?.isNotEmpty == true ? avatarUrl! : '🚀',
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }

  Widget _buildFallback(ThemeData theme) {
    final initial = fallbackName?.isNotEmpty == true
        ? fallbackName!.substring(0, 1).toUpperCase()
        : '👤';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fontSize * 0.9,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
