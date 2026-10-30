import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/round/domain/services/score_calculator_service.dart';
import 'package:la_pocha/features/round/domain/services/tricks_sum_validator.dart';
import 'package:la_pocha/features/round/domain/usecases/submit_tricks_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockScoreCalculatorService extends Mock
    implements ScoreCalculatorService {}

class MockTricksSumValidator extends Mock implements TricksSumValidator {}

void main() {
  const playerIds = ['p1', 'p2'];

  final round = Round(
    id: 'round-1',
    gameId: 'game-1',
    roundNumber: 1,
    cardsInRound: 4,
    dealerPlayerId: 'p1',
    status: RoundStatus.playing,
    bids: const {'p1': 2, 'p2': 1},
    createdAt: DateTime(2026),
  );

  group('SubmitTricksUseCase (real collaborators)', () {
    late SubmitTricksUseCase useCase;

    setUp(() {
      useCase = SubmitTricksUseCase();
    });

    test('returns the score delta per player when tricks sum matches cards',
        () {
      final result = useCase(
        round: round,
        tricks: const {'p1': 2, 'p2': 2},
        playerIds: playerIds,
      );

      // p1: exact bid (2) => 10 + 5 * 2; p2: bid 1, won 2 => -5 * 1.
      expect(result, {'p1': 20, 'p2': -5});
    });

    test('throws when tricks sum does not match cards in round', () {
      expect(
        () => useCase(
          round: round,
          tricks: const {'p1': 2, 'p2': 1},
          playerIds: playerIds,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Tricks cannot be submitted yet',
          ),
        ),
      );
    });

    test('throws when a player has no tricks entered', () {
      expect(
        () => useCase(
          round: round,
          tricks: const {'p1': 4},
          playerIds: playerIds,
        ),
        throwsStateError,
      );
    });

    test('throws when a trick is out of range', () {
      expect(
        () => useCase(
          round: round,
          tricks: const {'p1': 5, 'p2': -1},
          playerIds: playerIds,
        ),
        throwsStateError,
      );
    });

    test('previewScoresDelta skips players without valid tricks or bid', () {
      final result = useCase.previewScoresDelta(
        round: round,
        tricks: const {'p1': 2, 'p2': 9},
        playerIds: playerIds,
      );

      expect(result, {'p1': 20});
    });
  });

  group('SubmitTricksUseCase (mocked collaborators)', () {
    late MockScoreCalculatorService scoreCalculator;
    late MockTricksSumValidator validator;
    late SubmitTricksUseCase useCase;

    setUp(() {
      scoreCalculator = MockScoreCalculatorService();
      validator = MockTricksSumValidator();
      useCase = SubmitTricksUseCase(scoreCalculator, validator);
    });

    test('delegates validation and score calculation', () {
      const tricks = {'p1': 2, 'p2': 2};
      when(
        () => validator.canClose(
          cardsInRound: any(named: 'cardsInRound'),
          tricks: any(named: 'tricks'),
          playerIds: any(named: 'playerIds'),
        ),
      ).thenReturn(true);
      when(
        () => scoreCalculator.calculateRoundScore(
          bid: any(named: 'bid'),
          tricks: any(named: 'tricks'),
        ),
      ).thenReturn(7);

      final result = useCase(
        round: round,
        tricks: tricks,
        playerIds: playerIds,
      );

      expect(result, {'p1': 7, 'p2': 7});
      verify(
        () => validator.canClose(
          cardsInRound: round.cardsInRound,
          tricks: tricks,
          playerIds: playerIds,
        ),
      ).called(1);
      verify(
        () => scoreCalculator.calculateRoundScore(bid: 2, tricks: 2),
      ).called(1);
      verify(
        () => scoreCalculator.calculateRoundScore(bid: 1, tricks: 2),
      ).called(1);
    });

    test('does not calculate scores when the validator rejects the tricks',
        () {
      when(
        () => validator.canClose(
          cardsInRound: any(named: 'cardsInRound'),
          tricks: any(named: 'tricks'),
          playerIds: any(named: 'playerIds'),
        ),
      ).thenReturn(false);

      expect(
        () => useCase(
          round: round,
          tricks: const {'p1': 2, 'p2': 1},
          playerIds: playerIds,
        ),
        throwsStateError,
      );
      verifyNever(
        () => scoreCalculator.calculateRoundScore(
          bid: any(named: 'bid'),
          tricks: any(named: 'tricks'),
        ),
      );
    });
  });
}
