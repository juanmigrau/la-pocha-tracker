import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/favorites/domain/entities/favorite_player.dart';

class FavoritesChipSection extends StatelessWidget {
  const FavoritesChipSection({
    super.key,
    required this.visibleFavorites,
    this.currentUser,
    this.localSelf,
    this.onFavoriteTap,
  });

  final List<FavoritePlayer> visibleFavorites;
  final UserProfile? currentUser;

  /// Local organizer chip when there is no Firebase session.
  final FavoritePlayer? localSelf;
  final ValueChanged<FavoritePlayer>? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final user = currentUser;
    final local = user == null ? localSelf : null;
    final hasChips =
        user != null || local != null || visibleFavorites.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAVORITOS',
          style: textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        if (!hasChips)
          Text(
            'Añade jugadores frecuentes con ⭐',
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user != null)
                FilterChip(
                  key: const Key('currentUserFavoriteChip'),
                  avatar: _chipAvatar(
                    name: user.displayName,
                    colorIndex: 0,
                    photoURL: user.photoUrl,
                    fallbackIcon: Icon(
                      Icons.account_circle,
                      color: colors.primary,
                      size: 18,
                    ),
                  ),
                  label: Text(
                    user.displayName,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: colors.primaryContainer,
                  showCheckmark: false,
                  onSelected: (_) => onFavoriteTap?.call(
                    FavoritePlayer(
                      id: user.uid,
                      displayName: user.displayName,
                      userId: user.uid,
                      photoURL: user.photoUrl,
                      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                    ),
                  ),
                ),
              if (local != null)
                FilterChip(
                  key: const Key('localSelfFavoriteChip'),
                  label: Text(
                    local.displayName,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: colors.primaryContainer,
                  showCheckmark: false,
                  onSelected: (_) => onFavoriteTap?.call(local),
                ),
              ...visibleFavorites.asMap().entries.map((entry) {
                final index = entry.key;
                final favorite = entry.value;
                final showAvatar = favorite.userId != null;
                return FilterChip(
                  avatar: showAvatar
                      ? _chipAvatar(
                          name: favorite.displayName,
                          colorIndex: index + 1,
                          photoURL: favorite.photoURL,
                        )
                      : null,
                  label: Text(favorite.displayName),
                  showCheckmark: false,
                  onSelected: (_) => onFavoriteTap?.call(favorite),
                );
              }),
            ],
          ),
      ],
    );
  }

  Widget _chipAvatar({
    required String name,
    required int colorIndex,
    String? photoURL,
    Widget? fallbackIcon,
  }) {
    final url = photoURL;
    if (url != null && url.isNotEmpty) {
      return PlayerInitialAvatar(
        name: name,
        colorIndex: colorIndex,
        photoURL: url,
        radius: 12,
      );
    }
    if (fallbackIcon != null) {
      return fallbackIcon;
    }
    return PlayerInitialAvatar(
      name: name,
      colorIndex: colorIndex,
      radius: 12,
    );
  }
}
