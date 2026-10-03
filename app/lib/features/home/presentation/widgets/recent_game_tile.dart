import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/player_display_name.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/services/game_history_mapper.dart';

class RecentGameTile extends StatelessWidget {
  const RecentGameTile({
    super.key,
    required this.item,
    required this.onTap,
    this.now,
    this.mapper = const GameHistoryMapper(),
  });

  static const String labelSeparator = ' — ';

  final GameHistoryItem item;
  final VoidCallback onTap;
  final DateTime? now;
  final GameHistoryMapper mapper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final formattedDate = mapper.formatRelativeFinishedAt(
      item.finishedAt,
      now: now,
    );
    final playerNames = item.players.isNotEmpty
        ? item.players
            .map(
              (player) => resolveDisplayName(
                storedName: player.displayName,
                storedUserId: player.userId,
                currentUserId: currentUser?.uid,
                currentDisplayName: currentUser?.displayName,
              ),
            )
            .join(', ')
        : _playerNamesFromLabel(item.displayLabel);
    final winnerName = item.winnerName == null
        ? null
        : resolveDisplayName(
            storedName: item.winnerName!,
            storedUserId: item.winnerUserId,
            currentUserId: currentUser?.uid,
            currentDisplayName: currentUser?.displayName,
          );

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedDate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  playerNames,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  winnerName == null ? 'Sin ganador' : 'Ganó $winnerName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _playerNamesFromLabel(String displayLabel) {
    final parts = displayLabel.split(labelSeparator);
    if (parts.length < 2) {
      return '';
    }
    return parts.sublist(1).join(labelSeparator);
  }
}
