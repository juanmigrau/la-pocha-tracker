import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';

class PlayerCountSelector extends StatelessWidget {
  const PlayerCountSelector({
    super.key,
    required this.selectedCount,
    required this.onCountSelected,
  });

  static const List<int> options = [3, 4, 5, 6, 7, 8];

  final int selectedCount;
  final ValueChanged<int> onCountSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NÚMERO DE JUGADORES',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
          children: [
            for (final count in options)
              Semantics(
                label: '$count jugadores',
                selected: selectedCount == count,
                button: true,
                child: _PlayerCountButton(
                  count: count,
                  selected: selectedCount == count,
                  onTap: () => onCountSelected(count),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlayerCountButton extends StatelessWidget {
  const _PlayerCountButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppTheme.primary
        : AppTheme.onSurfaceVariant.withValues(alpha: 0.3);

    return Material(
      color: selected ? AppTheme.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: selected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
