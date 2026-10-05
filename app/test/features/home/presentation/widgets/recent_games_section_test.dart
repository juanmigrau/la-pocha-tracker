import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/features/auth/domain/entities/user_profile.dart';
import 'package:la_pocha/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/home/presentation/widgets/recent_games_section.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  final item = GameHistoryItem(
    id: 'game-1',
    source: GameHistorySource.local,
    finishedAt: DateTime(2026, 8, 13, 20, 14),
    playerCount: 4,
    displayLabel: '13 ago 2026, 20:14 — Ana, Luis, Marta, Pedro',
    winnerName: 'Ana',
    winnerScore: 40,
  );

  final authenticated = Authenticated(
    UserProfile(
      uid: 'uid-1',
      displayName: 'Ana',
      email: 'ana@example.com',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  );

  Widget wrapSection({
    required List<GameHistoryItem> games,
    required bool isAuthenticated,
    VoidCallback? onViewAll,
  }) {
    final authBloc = MockAuthBloc();
    final authState =
        isAuthenticated ? authenticated : const Unauthenticated();
    whenListen(
      authBloc,
      Stream.value(authState),
      initialState: authState,
    );

    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: RecentGamesSection(
            games: games,
            isAuthenticated: isAuthenticated,
            onViewAll: onViewAll ?? () {},
            onGameTap: (_) {},
          ),
        ),
      ),
    );
  }

  group('RecentGamesSection.shouldShowViewAll', () {
    test('is true when there are local games', () {
      expect(
        RecentGamesSection.shouldShowViewAll(
          hasLocalGames: true,
          isAuthenticated: false,
        ),
        isTrue,
      );
    });

    test('is true when authenticated with no local games', () {
      expect(
        RecentGamesSection.shouldShowViewAll(
          hasLocalGames: false,
          isAuthenticated: true,
        ),
        isTrue,
      );
    });

    test('is false when unauthenticated and no local games', () {
      expect(
        RecentGamesSection.shouldShowViewAll(
          hasLocalGames: false,
          isAuthenticated: false,
        ),
        isFalse,
      );
    });
  });

  testWidgets(
    'hides Ver todas when empty and unauthenticated',
    (tester) async {
      await tester.pumpWidget(
        wrapSection(games: const [], isAuthenticated: false),
      );

      expect(find.text('Crea tu primera partida para empezar'), findsOneWidget);
      expect(find.text('Ver todas →'), findsNothing);
    },
  );

  testWidgets(
    'shows Ver todas when empty but authenticated',
    (tester) async {
      await tester.pumpWidget(
        wrapSection(games: const [], isAuthenticated: true),
      );

      expect(find.text('Crea tu primera partida para empezar'), findsOneWidget);
      expect(find.text('Ver todas →'), findsOneWidget);
    },
  );

  testWidgets(
    'shows Ver todas when there are local games',
    (tester) async {
      await tester.pumpWidget(
        wrapSection(games: [item], isAuthenticated: false),
      );

      expect(find.text('Ver todas →'), findsOneWidget);
      expect(find.text('Crea tu primera partida para empezar'), findsNothing);
    },
  );

  testWidgets('calls onViewAll when Ver todas is pressed', (tester) async {
    var viewAllCount = 0;

    await tester.pumpWidget(
      wrapSection(
        games: const [],
        isAuthenticated: true,
        onViewAll: () => viewAllCount++,
      ),
    );

    // Invoke onPressed directly to avoid Material ink_sparkle shader issues
    // in the local Flutter test renderer.
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Ver todas →'),
    );
    button.onPressed!();
    await tester.pump();

    expect(viewAllCount, 1);
  });
}