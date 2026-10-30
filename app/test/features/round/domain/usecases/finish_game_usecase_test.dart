import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/round/domain/usecases/finish_game_usecase.dart';
import 'package:la_pocha/features/sync/presentation/bloc/game_sync_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGameRepository extends Mock implements GameRepository {}

class MockGameSyncBloc extends MockBloc<GameSyncEvent, GameSyncState>
    implements GameSyncBloc {}

void main() {
  late MockGameRepository gameRepository;
  late MockGameSyncBloc gameSyncBloc;
  late FinishGameUseCase useCase;

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

  Game buildGame({GameStatus status = GameStatus.inProgress}) {
    return Game(
      id: 'game-1',
      status: status,
      playerCount: 2,
      totalCards: 40,
      maxCardsPerRound: 10,
      roundSequence: const [
        RoundDefinition(roundNumber: 1, cardsPerPlayer: 4),
        RoundDefinition(roundNumber: 2, cardsPerPlayer: 5),
      ],
      players: players,
      currentRoundNumber: 2,
      startedAt: DateTime(2026),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  Round buildRound({
    int roundNumber = 2,
    RoundStatus status = RoundStatus.closed,
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
      scoresDelta: const {'p1': 20, 'p2': 25},
      createdAt: DateTime(2026),
      closedAt: DateTime(2026),
    );
  }

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const GameUploadRequested(gameId: 'fallback'));
  });

  setUp(() {
    gameRepository = MockGameRepository();
    gameSyncBloc = MockGameSyncBloc();
    useCase = FinishGameUseCase(gameRepository, gameSyncBloc);
  });

  group('FinishGameUseCase', () {
    test('finishes the game and requests upload on the last closed round',
        () async {
      final game = buildGame();
      final finishedGame = game.copyWith(
        status: GameStatus.finished,
        finishedAt: DateTime(2026, 1, 2),
      );
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => game);
      when(
        () => gameRepository.finishGame(
          gameId: any(named: 'gameId'),
          finishedAt: any(named: 'finishedAt'),
        ),
      ).thenAnswer((_) async => finishedGame);

      final result = await useCase(
        gameId: 'game-1',
        closedRound: buildRound(),
      );

      expect(result, finishedGame);
      expect(result.status, GameStatus.finished);
      verify(
        () => gameRepository.finishGame(
          gameId: 'game-1',
          finishedAt: any(named: 'finishedAt'),
        ),
      ).called(1);

      // The sync event is dispatched asynchronously after returning.
      await Future<void>.delayed(Duration.zero);
      verify(
        () => gameSyncBloc.add(const GameUploadRequested(gameId: 'game-1')),
      ).called(1);
    });

    test('throws when the game is not in progress', () async {
      when(() => gameRepository.getGameById('game-1')).thenAnswer(
        (_) async => buildGame(status: GameStatus.finished),
      );

      await expectLater(
        useCase(gameId: 'game-1', closedRound: buildRound()),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Game must be in progress to finish',
          ),
        ),
      );

      verifyNever(
        () => gameRepository.finishGame(
          gameId: any(named: 'gameId'),
          finishedAt: any(named: 'finishedAt'),
        ),
      );
      verifyNever(() => gameSyncBloc.add(any()));
    });

    test('throws when the game is still in setup', () async {
      when(() => gameRepository.getGameById('game-1')).thenAnswer(
        (_) async => buildGame(status: GameStatus.setup),
      );

      await expectLater(
        useCase(gameId: 'game-1', closedRound: buildRound()),
        throwsStateError,
      );
    });

    test('throws when the game does not exist', () async {
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => null);

      await expectLater(
        useCase(gameId: 'game-1', closedRound: buildRound()),
        throwsStateError,
      );
    });

    test('throws when the round is not closed', () async {
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => buildGame());

      await expectLater(
        useCase(
          gameId: 'game-1',
          closedRound: buildRound(status: RoundStatus.playing),
        ),
        throwsStateError,
      );
      verifyNever(() => gameSyncBloc.add(any()));
    });

    test('throws when the closed round is not the last one', () async {
      when(() => gameRepository.getGameById('game-1'))
          .thenAnswer((_) async => buildGame());

      await expectLater(
        useCase(
          gameId: 'game-1',
          closedRound: buildRound(roundNumber: 1),
        ),
        throwsStateError,
      );
      verifyNever(
        () => gameRepository.finishGame(
          gameId: any(named: 'gameId'),
          finishedAt: any(named: 'finishedAt'),
        ),
      );
    });
  });
}
