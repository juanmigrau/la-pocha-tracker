import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/favorites/domain/entities/favorite_player.dart';

class FavoriteListTile extends StatelessWidget {
  const FavoriteListTile({
    super.key,
    required this.favorite,
    this.trailing,
    this.onDelete,
  });

  final FavoritePlayer favorite;
  final Widget? trailing;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      tileColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: PlayerInitialAvatar(
        name: favorite.displayName,
        colorIndex: 0,
      ),
      title: Text(favorite.displayName),
      subtitle: Text(
        favorite.isRegistered ? 'Usuario registrado' : 'Invitado',
      ),
      trailing: trailing ??
          (onDelete != null
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                )
              : Icon(
                  favorite.isRegistered
                      ? Icons.verified
                      : Icons.person_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                )),
    );
  }
}
