part of 'favorites_bloc.dart';

sealed class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class FavoritesStarted extends FavoritesEvent {
  const FavoritesStarted();
}

class FavoriteAdded extends FavoritesEvent {
  const FavoriteAdded({
    required this.displayName,
    this.userId,
    this.photoURL,
  });

  final String displayName;
  final String? userId;
  final String? photoURL;

  @override
  List<Object?> get props => [displayName, userId, photoURL];
}

class FavoriteRemoved extends FavoritesEvent {
  const FavoriteRemoved(this.favoriteId);

  final String favoriteId;

  @override
  List<Object?> get props => [favoriteId];
}

class FavoritesRefreshed extends FavoritesEvent {
  const FavoritesRefreshed();
}
