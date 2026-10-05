import 'package:flutter/material.dart';
import 'package:la_pocha/features/round/domain/entities/game_curiosities.dart';

class GameCuriositiesSection extends StatelessWidget {
  const GameCuriositiesSection({super.key, required this.curiosities});

  final GameCuriosities curiosities;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <({String title, String value})>[
      (
        title: 'Jugador más arriesgado',
        value: curiosities.riskiestPlayerName ?? '—',
      ),
      (
        title: 'Jugador más conservador',
        value: curiosities.mostConservativePlayerName ?? '—',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Datos curiosos',
                style: theme.textTheme.titleSmall?.copyWith(
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
                onPressed: () => _showCuriositiesHelp(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(item.title),
                trailing: Text(
                  item.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCuriositiesHelp(BuildContext context) {
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
                  'Datos curiosos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _HelpLine(
                  title: 'Jugador más arriesgado',
                  body:
                      'el que más bazas apostó en proporción al total de cartas repartidas. Mide audacia, no acierto.',
                ),
                _HelpLine(
                  title: 'Jugador más conservador',
                  body:
                      'el que menos bazas apostó en esa misma proporción.',
                ),
              ],
            ),
          ),
        );
      },
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
