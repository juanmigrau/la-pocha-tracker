import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/dealer_selector.dart';

class ReorderablePlayerList extends StatelessWidget {
  const ReorderablePlayerList({
    super.key,
    required this.players,
    required this.firstDealerPlayerId,
    required this.onReorder,
    required this.onDealerSelected,
  });

  final List<PlayerEmbed> players;
  final String firstDealerPlayerId;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(String playerId) onDealerSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        buildDefaultDragHandles: false,
        padding: EdgeInsets.zero,
        itemCount: players.length,
        onReorderItem: onReorder,
        itemBuilder: (context, index) {
          final player = players[index];
          final isDealer = player.id == firstDealerPlayerId;
          final isLast = index == players.length - 1;

          return Column(
            key: ValueKey(player.id),
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 52,
                child: _PlayerRow(
                  player: player,
                  index: index,
                  isDealer: isDealer,
                  onDealerSelected: () => onDealerSelected(player.id),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.index,
    required this.isDealer,
    required this.onDealerSelected,
  });

  final PlayerEmbed player;
  final int index;
  final bool isDealer;
  final VoidCallback onDealerSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.drag_handle,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${player.seatOrder}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          PlayerInitialAvatar(
            name: player.displayName,
            colorIndex: index,
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.displayName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DealerSelector(
            isSelected: isDealer,
            onTap: onDealerSelected,
          ),
        ],
      ),
    );
  }
}
