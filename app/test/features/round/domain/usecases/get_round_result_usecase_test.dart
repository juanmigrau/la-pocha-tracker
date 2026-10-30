import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/round_repository.dart';
import 'package:la_pocha/features/round/domain/usecases/get_round_result_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockGameRepository extends Mock implements GameRepository {}

class MockRoundRepository extends Mock implements RoundRepository {}

void main() {
  late MockGameRepository gameRepository;
  late MockRoundRepository roundRepository;
  late GetRoundResultUseCase useCase;

  final players = [
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 30,
      joinedAt: DateTime(2026),
    ),
    PlayerEmbed(
      id: 'p2',
      displayName: 'Bob',
      isGuest: true,
      userId: null,
      seatOrder: 2,
      totalScore: 25,
      joinedAt: DateTime(2026),
    ),
  ];

  final game = Game(
    id: 'game-1',
    status: GameStatus.inProgress,
    playerCount: 2,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [
      RoundDefinition(roundNumber: 1, cardsPerPlayer: 4),
      RoundDefinition(roundNumber: 2, cardsPerPlayer: 5),
    ],
    players: players,
    currentRoundNumber: 1,
    startedAt: DateTime(2026),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Round buildRound({
    int roundNumber = 1,
    RoundStatus status = RoundStatus.closed,
    Map<String, int>? scoresDelta = const {'p1': 20, 'p2': 25},
  }) {
    return Round(
      id: 'round-$roundNumber',
      gameId: 'game-1',
      roundNumber: roundNumber,
      cardsInRound: 5,
      dealerPlayerId: 'p2',
      status: status,
      bids: const {'p1': 2, 'p2': 3},
      tricks: const {'p1': 2, 'p2': 3},
      scoresDelta: scoresDelta,
      createdAt: DateTime(2026),
      closedAt: DateTime(2026),
    );
  }

  setUp(() {
    gameRepository = MockGameRepository();
    roundRepository = MockRoundRepository();
    useCase = GetRoundResultUseCase(gameRepository, roundRepository);
  });

  group('GetRoundResultUseCase', () {
    test('returns the round result with ranking for a closed round',
        () async {
      final round = buildRound();
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => game);
      when(() => roundRepository.getRoundByGameAndNumber('game-1', 1))
          .thenAnswer((_) async => round);

      final result = await useCase(gameId: 'game-1', roundNumber: 1);

      expect(result.game, game);
      expect(result.round, round);
      expect(result.dealerDisplayName, 'Bob');
      expect(result.isLastRound, isFalse);
      expect(result.entries.map((e) => e.player.id), ['p1', 'p2']);
      expect(result.entries.map((e) => e.rank), [1, 2]);
      expect(result.entries.map((e) => e.roundScore), [20, 25]);
      // First round does not compute position deltas.
      expect(result.entries.every((e) => e.positionDelta == null), isTrue);
    });

    test('flags the last round and includes position deltas after round 1',
        () async {
      final round = buildRound(roundNumber: 2);
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => game);
      when(() => roundRepository.getRoundByGameAndNumber('game-1', 2))
          .thenAnswer((_) async => round);

      final result = await useCase(gameId: 'game-1', roundNumber: 2);

      expect(result.isLastRound, isTrue);
      expect(result.entries.every((e) => e.positionDelta != null), isTrue);
    });

    test('throws when the round is not closed yet', () async {
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => game);
      when(() => roundRepository.getRoundByGameAndNumber('game-1', 1))
          .thenAnswer(
        (_) async => buildRound(status: RoundStatus.playing, scoresDelta: null),
      );

      await expectLater(
        useCase(gameId: 'game-1', roundNumber: 1),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Round is not closed',
          ),
        ),
      );
    });

    test('throws when the closed round has no scores delta', () async {
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => game);
      when(() => roundRepository.getRoundByGameAndNumber('game-1', 1))
          .thenAnswer((_) async => buildRound(scoresDelta: null));

      await expectLater(
        useCase(gameId: 'game-1', roundNumber: 1),
        throwsStateError,
      );
    });

    test('throws when the game does not exist', () async {
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => null);

      await expectLater(
        useCase(gameId: 'game-1', roundNumber: 1),
        throwsStateError,
      );
      verifyNever(() => roundRepository.getRoundByGameAndNumber(any(), any()));
    });

    test('throws when the round does not exist', () async {
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => game);
      when(() => roundRepository.getRoundByGameAndNumber('game-1', 1))
          .thenAnswer((_) async => null);

      await expectLater(
        useCase(gameId: 'game-1', roundNumber: 1),
        throwsStateError,
      );
    });

    test('throws when the dealer is not a player of the game', () async {
      final round = buildRound().copyWith(dealerPlayerId: 'unknown');
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => game);
      when(() => roundRepository.getRoundByGameAndNumber('game-1', 1))
          .thenAnswer((_) async => round);

      await expectLater(
        useCase(gameId: 'game-1', roundNumber: 1),
        throwsStateError,
      );
    });
  });
}
