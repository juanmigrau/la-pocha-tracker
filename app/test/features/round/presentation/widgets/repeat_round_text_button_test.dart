import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/round/domain/usecases/repeat_round_usecase.dart';
import 'package:la_pocha/features/round/presentation/bloc/repeat_round_cubit.dart';
import 'package:la_pocha/features/round/presentation/widgets/repeat_round_text_button.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'repeat_round_text_button_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<RepeatRoundUseCase>(),
])
void main() {
  late MockRepeatRoundUseCase repeatRound;
  final getIt = GetIt.instance;

  final resetRound = Round(
    id: 'round-1',
    gameId: 'game-1',
    roundNumber: 1,
    cardsInRound: 4,
    dealerPlayerId: 'p1',
    status: RoundStatus.bidding,
    bids: const {},
    createdAt: DateTime(2026),
  );

  setUp(() async {
    repeatRound = MockRepeatRoundUseCase();
    when(
      repeatRound(
        gameId: anyNamed('gameId'),
        roundNumber: anyNamed('roundNumber'),
      ),
    ).thenAnswer((_) async => resetRound);

    await getIt.reset();
    getIt.registerFactory<RepeatRoundUseCase>(() => repeatRound);
    getIt.registerFactory<RepeatRoundCubit>(
      () => RepeatRoundCubit(repeatRound: getIt()),
    );
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/result',
      routes: [
        GoRoute(
          path: '/result',
          builder: (context, state) => Scaffold(
            body: SafeArea(
              child: RepeatRoundTextButton(
                gameId: 'game-1',
                roundNumber: 1,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/games/:gameId/rounds/:roundNumber/bids',
          builder: (context, state) => const Scaffold(
            body: Text('BIDDING SCREEN'),
          ),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  Future<void> tapRepeatButton(WidgetTester tester) async {
    await tester.tap(find.text('Repetir esta ronda'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows repeat round confirmation dialog', (tester) async {
    await tester.pumpWidget(buildApp());
    await tapRepeatButton(tester);

    expect(find.text('Volver'), findsOneWidget);
    expect(
      find.textContaining('Se perderan las apuestas'),
      findsOneWidget,
    );
  });

  testWidgets('does not repeat round when confirmation is dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tapRepeatButton(tester);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    verifyNever(
      repeatRound(
        gameId: anyNamed('gameId'),
        roundNumber: anyNamed('roundNumber'),
      ),
    );
    expect(find.text('BIDDING SCREEN'), findsNothing);
  });

  testWidgets('repeats round and navigates to bidding when confirmed', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tapRepeatButton(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Repetir ronda'));
    await tester.pumpAndSettle();

    verify(repeatRound(gameId: 'game-1', roundNumber: 1)).called(1);
    expect(find.text('BIDDING SCREEN'), findsOneWidget);
  });
}
