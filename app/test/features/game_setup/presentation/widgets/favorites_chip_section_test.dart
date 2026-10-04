import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/favorites/domain/entities/favorite_player.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/favorites_chip_section.dart';

void main() {
  final currentUser = UserProfile(
    uid: 'uid-1',
    displayName: 'Juan',
    email: 'juan@test.com',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  final favoriteAna = FavoritePlayer(
    id: 'fav-ana',
    displayName: 'Ana',
    userId: null,
    createdAt: DateTime(2026),
  );

  final favoriteRegistered = FavoritePlayer(
    id: 'fav-registered',
    displayName: 'Luis',
    userId: 'uid-luis',
    photoURL: 'https://example.com/luis.jpg',
    createdAt: DateTime(2026),
  );

  Future<void> pumpSection(
    WidgetTester tester, {
    List<FavoritePlayer> visibleFavorites = const [],
    UserProfile? currentUser,
    FavoritePlayer? localSelf,
    ValueChanged<FavoritePlayer>? onFavoriteTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavoritesChipSection(
            visibleFavorites: visibleFavorites,
            currentUser: currentUser,
            localSelf: localSelf,
            onFavoriteTap: onFavoriteTap,
          ),
        ),
      ),
    );
  }

  testWidgets('shows current user as first chip when provided', (tester) async {
    await pumpSection(
      tester,
      visibleFavorites: [favoriteAna],
      currentUser: currentUser,
    );

    final chips = tester
        .widgetList<FilterChip>(find.byType(FilterChip))
        .toList();
    expect(chips, hasLength(2));
    expect(chips.first.key, const Key('currentUserFavoriteChip'));
    expect(find.text('Juan'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsNothing);
  });

  testWidgets('does not show current user chip when session is missing', (
    tester,
  ) async {
    await pumpSection(tester, visibleFavorites: [favoriteAna]);

    expect(find.byKey(const Key('currentUserFavoriteChip')), findsNothing);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.byIcon(Icons.account_circle), findsNothing);
  });

  testWidgets('shows empty hint when there is no session and no favorites', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.text('Añade jugadores frecuentes con ⭐'), findsOneWidget);
    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets('shows only current user chip when favorites are empty', (
    tester,
  ) async {
    await pumpSection(tester, currentUser: currentUser);

    expect(find.text('Añade jugadores frecuentes con ⭐'), findsNothing);
    expect(find.byKey(const Key('currentUserFavoriteChip')), findsOneWidget);
    expect(find.byType(FilterChip), findsOneWidget);
  });

  testWidgets('tapping current user chip emits registered favorite payload', (
    tester,
  ) async {
    FavoritePlayer? tapped;

    await pumpSection(
      tester,
      currentUser: currentUser,
      onFavoriteTap: (favorite) => tapped = favorite,
    );

    await tester.tap(find.byKey(const Key('currentUserFavoriteChip')));
    await tester.pump();

    expect(tapped, isNotNull);
    expect(tapped!.id, 'uid-1');
    expect(tapped!.displayName, 'Juan');
    expect(tapped!.userId, 'uid-1');
  });

  testWidgets('registered favorite chip passes photoURL to avatar', (
    tester,
  ) async {
    await pumpSection(tester, visibleFavorites: [favoriteRegistered]);

    final avatar = tester.widget<PlayerInitialAvatar>(
      find.byType(PlayerInitialAvatar).first,
    );
    expect(avatar.photoURL, 'https://example.com/luis.jpg');
    expect(avatar.name, 'Luis');
  });

  testWidgets('guest favorite chip does not show avatar', (tester) async {
    await pumpSection(tester, visibleFavorites: [favoriteAna]);

    expect(find.text('Ana'), findsOneWidget);
    expect(find.byType(PlayerInitialAvatar), findsNothing);
  });

  testWidgets('shows local self chip without avatar when provided', (
    tester,
  ) async {
    final localSelf = FavoritePlayer(
      id: 'local-1',
      displayName: 'Juan',
      userId: null,
      createdAt: DateTime(2026),
    );

    await pumpSection(tester, localSelf: localSelf);

    expect(find.byKey(const Key('localSelfFavoriteChip')), findsOneWidget);
    expect(find.text('Juan'), findsOneWidget);
    expect(find.byType(PlayerInitialAvatar), findsNothing);
    expect(find.byIcon(Icons.account_circle), findsNothing);
  });

  testWidgets('prefers current user chip over local self', (tester) async {
    final localSelf = FavoritePlayer(
      id: 'local-1',
      displayName: 'Local Juan',
      userId: null,
      createdAt: DateTime(2026),
    );

    await pumpSection(
      tester,
      currentUser: currentUser,
      localSelf: localSelf,
    );

    expect(find.byKey(const Key('currentUserFavoriteChip')), findsOneWidget);
    expect(find.byKey(const Key('localSelfFavoriteChip')), findsNothing);
    expect(find.text('Juan'), findsOneWidget);
    expect(find.text('Local Juan'), findsNothing);
  });
}
