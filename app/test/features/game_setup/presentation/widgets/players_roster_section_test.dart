import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/presentation/widgets/players_roster_section.dart';

void main() {
  PlayerEmbed player({
    required String id,
    required String displayName,
    String? userId,
    String? localUserId,
    int seatOrder = 0,
  }) {
    return PlayerEmbed(
      id: id,
      displayName: displayName,
      isGuest: userId == null,
      userId: userId,
      seatOrder: seatOrder,
      totalScore: 0,
      joinedAt: DateTime(2026),
      localUserId: localUserId,
    );
  }

  Future<void> pumpRoster(
    WidgetTester tester, {
    required List<PlayerEmbed> players,
    int playerCount = 3,
    String? currentUserId,
    String? localUserId,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayersRosterSection(
            playerCount: playerCount,
            players: players,
            activeEditIndex: null,
            isLoading: false,
            currentUserId: currentUserId,
            localUserId: localUserId,
            isFavoritePlayer: (_) => false,
          ),
        ),
      ),
    );
  }

  Finder starIcons() => find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.star || widget.icon == Icons.star_border),
      );

  testWidgets('hides favorite star for Firebase current user', (tester) async {
    await pumpRoster(
      tester,
      currentUserId: 'uid-1',
      players: [
        player(id: 'p1', displayName: 'Yo', userId: 'uid-1'),
        player(id: 'p2', displayName: 'Ana', userId: null),
      ],
    );

    // One star for Ana; none for the signed-in self.
    expect(starIcons(), findsOneWidget);
    expect(find.text('Yo'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('hides favorite star for local self player', (tester) async {
    await pumpRoster(
      tester,
      localUserId: 'local-1',
      players: [
        player(
          id: 'p1',
          displayName: 'Juan Local',
          userId: null,
          localUserId: 'local-1',
        ),
        player(id: 'p2', displayName: 'Ana', userId: null),
      ],
    );

    expect(starIcons(), findsOneWidget);
    expect(find.text('Juan Local'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('shows favorite star for other guests when localUserId differs', (
    tester,
  ) async {
    await pumpRoster(
      tester,
      localUserId: 'local-1',
      players: [
        player(
          id: 'p1',
          displayName: 'Otro',
          userId: null,
          localUserId: 'local-other',
        ),
      ],
      playerCount: 1,
    );

    expect(starIcons(), findsOneWidget);
  });

  testWidgets('shows favorite star when no self ids are provided', (
    tester,
  ) async {
    await pumpRoster(
      tester,
      players: [
        player(id: 'p1', displayName: 'Invitado', userId: null),
      ],
      playerCount: 1,
    );

    expect(starIcons(), findsOneWidget);
  });
}
