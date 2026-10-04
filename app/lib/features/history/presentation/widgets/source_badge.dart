import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';

class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source, this.syncStatus});

  final GameHistorySource source;
  final SyncStatus? syncStatus;

  @override
  Widget build(BuildContext context) {
    final appearance = _resolveAppearance(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: appearance.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(appearance.icon, size: 16, color: appearance.foreground),
          const SizedBox(width: 4),
          Text(
            appearance.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: appearance.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeAppearance _resolveAppearance(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (source == GameHistorySource.cloud ||
        syncStatus == SyncStatus.synced) {
      return _BadgeAppearance(
        label: 'Nube',
        icon: Icons.cloud,
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      );
    }

    if (syncStatus == SyncStatus.pending) {
      return const _BadgeAppearance(
        label: 'Pendiente',
        icon: Icons.cloud_upload_outlined,
        background: Color(0xFFFFF3E0),
        foreground: Color(0xFFE65100),
      );
    }

    if (syncStatus == SyncStatus.failed) {
      return const _BadgeAppearance(
        label: 'Error sync',
        icon: Icons.cloud_off_outlined,
        background: Color(0xFFFFEBEE),
        foreground: Color(0xFFC62828),
      );
    }

    return const _BadgeAppearance(
      label: 'Local',
      icon: Icons.smartphone,
      background: Color(0xFFD7ECE0),
      foreground: AppTheme.primary,
    );
  }
}

class _BadgeAppearance {
  const _BadgeAppearance({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
}
