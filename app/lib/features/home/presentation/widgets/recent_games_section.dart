import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/home/presentation/widgets/recent_game_tile.dart';

/// Recent local games on the home screen, plus the "Ver todas" entry point.
///
/// "Ver todas" is shown when there are local games **or** the user is
/// authenticated (cloud history may exist even with an empty local list).
class RecentGamesSection extends StatelessWidget {
  const RecentGamesSection({
    super.key,
    required this.games,
    required this.isAuthenticated,
    required this.onViewAll,
    required this.onGameTap,
  });

  final List<GameHistoryItem> games;
  final bool isAuthenticated;
  final VoidCallback onViewAll;
  final ValueChanged<GameHistoryItem> onGameTap;

  /// Visibility rule for the history list entry point.
  static bool shouldShowViewAll({
    required bool hasLocalGames,
    required bool isAuthenticated,
  }) =>
      hasLocalGames || isAuthenticated;

  bool get showViewAll => shouldShowViewAll(
        hasLocalGames: games.isNotEmpty,
        isAuthenticated: isAuthenticated,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (games.isEmpty)
          const _RecentGamesEmpty()
        else
          for (var index = 0; index < games.length; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            RecentGameTile(
              item: games[index],
              onTap: () => onGameTap(games[index]),
            ),
          ],
        if (showViewAll)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewAll,
              child: Text(
                'Ver todas →',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppTheme.primary),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentGamesEmpty extends StatelessWidget {
  const _RecentGamesEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(
            Icons.style,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primera partida para empezar',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
