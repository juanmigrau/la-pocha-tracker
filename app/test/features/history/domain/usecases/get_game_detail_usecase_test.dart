import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/entities/round_definition.dart';
import 'package:la_pocha/features/history/domain/entities/game_detail.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/repositories/history_repository.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_detail_usecase.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockHistoryRepository repository;
  late GetGameDetailUseCase useCase;

  final players = [
    PlayerEmbed(
      id: 'p1',
      displayName: 'Ana',
      isGuest: true,
      userId: null,
      seatOrder: 1,
      totalScore: 10,
      joinedAt: DateTime(2026),
    ),
  ];

  Game buildGame({required GameStatus status}) => Game(
        id: 'game-1',
        status: status,
        playerCount: 1,
        totalCards: 40,
        maxCardsPerRound: 10,
        roundSequence: const [
          RoundDefinition(roundNumber: 1, cardsPerPlayer: 4),
        ],
        players: players,
        finishedAt: DateTime(2026),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  GameDetail buildDetail({
    required GameStatus status,
    GameHistorySource source = GameHistorySource.local,
  }) =>
      GameDetail(
        game: buildGame(status: status),
        roundSummaries: const [],
        finalRanking: [
          RankingEntry(
            player: players.first,
            rank: 1,
            roundScore: 10,
            totalScore: 10,
            positionDelta: null,
          ),
        ],
        source: source,
      );

  setUp(() {
    repository = MockHistoryRepository();
    useCase = GetGameDetailUseCase(repository);
  });

  test('returns the detail of a finished local game', () async {
    final detail = buildDetail(status: GameStatus.finished);
    when(
      () => repository.getGameDetail(
        gameId: 'game-1',
        source: GameHistorySource.local,
      ),
    ).thenAnswer((_) async => detail);

    final result = await useCase(
      gameId: 'game-1',
      source: GameHistorySource.local,
    );

    expect(result, detail);
    verify(
      () => repository.getGameDetail(
        gameId: 'game-1',
        source: GameHistorySource.local,
      ),
    ).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('returns the detail of a finished cloud game', () async {
    final detail = buildDetail(
      status: GameStatus.finished,
      source: GameHistorySource.cloud,
    );
    when(
      () => repository.getGameDetail(
        gameId: 'game-1',
        source: GameHistorySource.cloud,
      ),
    ).thenAnswer((_) async => detail);

    final result = await useCase(
      gameId: 'game-1',
      source: GameHistorySource.cloud,
    );

    expect(result.source, GameHistorySource.cloud);
    expect(result, detail);
  });

  test('throws StateError when the game is not finished', () async {
    when(
      () => repository.getGameDetail(
        gameId: 'game-1',
        source: GameHistorySource.local,
      ),
    ).thenAnswer((_) async => buildDetail(status: GameStatus.inProgress));

    expect(
      () => useCase(gameId: 'game-1', source: GameHistorySource.local),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('game-1'),
        ),
      ),
    );
  });

  test('propagates the repository error when the gameId is not found', () async {
    when(
      () => repository.getGameDetail(
        gameId: 'missing',
        source: GameHistorySource.local,
      ),
    ).thenThrow(StateError('Game not found: missing'));

    expect(
      () => useCase(gameId: 'missing', source: GameHistorySource.local),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('missing'),
        ),
      ),
    );
    verify(
      () => repository.getGameDetail(
        gameId: 'missing',
        source: GameHistorySource.local,
      ),
    ).called(1);
  });
}
