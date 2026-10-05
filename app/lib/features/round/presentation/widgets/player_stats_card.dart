import 'package:flutter/material.dart';
import 'package:la_pocha/core/utils/player_colors.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/player_game_stats.dart';

class PlayerStatsCard extends StatelessWidget {
  const PlayerStatsCard({
    super.key,
    required this.stats,
    required this.player,
    required this.closedRoundCount,
  });

  final PlayerGameStats stats;
  final PlayerEmbed player;
  final int closedRoundCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = stats.accuracyPercent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlayerInitialAvatar(
                  name: stats.displayName,
                  colorIndex: stats.seatOrder,
                  photoURL: player.userId != null ? player.photoURL : null,
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    stats.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  accuracy == null
                      ? '—'
                      : '${accuracy.toStringAsFixed(0)}% acierto',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: playerAvatarColorForIndex(stats.seatOrder),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _showStatsHelp(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Bazas',
              value: '${stats.totalBids} → ${stats.totalTricks}',
            ),
            _StatRow(
              label: 'Media pts',
              value: stats.averageScorePerRound == null
                  ? '—'
                  : '${stats.averageScorePerRound!.toStringAsFixed(1)} / ronda',
            ),
            _StatRow(
              label: 'Media bazas',
              value: closedRoundCount == 0
                  ? '—'
                  : '${(stats.totalBids / closedRoundCount).toStringAsFixed(1)} / ronda',
            ),
            _StatRow(
              label: 'Mejor / Peor',
              value: '${_deltaLabel(stats.bestRoundDelta)} · '
                  '${_deltaLabel(stats.worstRoundDelta)}',
            ),
          ],
        ),
      ),
    );
  }

  String _deltaLabel(int? value) {
    if (value == null) return '—';
    if (value > 0) return '+$value';
    return '$value';
  }

  void _showStatsHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cómo se calculan las estadísticas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _HelpLine(
                  title: '% acierto',
                  body:
                      'porcentaje de rondas en que tu apuesta coincidió exactamente con las bazas que ganaste.',
                ),
                _HelpLine(
                  title: 'Bazas',
                  body:
                      'total de bazas apostadas → total de bazas reales conseguidas.',
                ),
                _HelpLine(
                  title: 'Media pts',
                  body: 'media de puntos ganados o perdidos por ronda.',
                ),
                _HelpLine(
                  title: 'Media bazas',
                  body: 'media de bazas que apostaste por ronda.',
                ),
                _HelpLine(
                  title: 'Mejor / Peor ronda',
                  body:
                      'puntuación más alta y más baja que obtuviste en una sola ronda.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpLine extends StatelessWidget {
  const _HelpLine({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: body),
          ],
        ),
      ),
    );
  }
}
