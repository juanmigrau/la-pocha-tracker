import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/core/utils/card_count_label.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/game_overflow_menu.dart';

class RoundHeader extends StatelessWidget {
  const RoundHeader({
    super.key,
    required this.gameId,
    required this.roundNumber,
    required this.cardsInRound,
    required this.phaseName,
    this.onBack,
  });

  final String gameId;
  final int roundNumber;
  final int? cardsInRound;
  final String phaseName;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onPrimary = colorScheme.onPrimary;
    final roundSubtitle = cardsInRound == null
        ? 'Ronda $roundNumber'
        : 'Ronda $roundNumber · ${cardCountLabel(cardsInRound!)}';

    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(8, 16 + statusBarHeight, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => context.pop(),
            icon: Icon(Icons.arrow_back, color: onPrimary),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  phaseName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  roundSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onPrimary.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ),
          GameOverflowMenu(gameId: gameId),
        ],
      ),
    );
  }
}
