import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game.dart';
import 'package:la_pocha/features/game_setup/domain/entities/game_status.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/get_active_game_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockGameRepository extends Mock implements GameRepository {}

void main() {
  late _MockGameRepository repository;
  late GetActiveGameUseCase useCase;

  final activeGame = Game(
    id: 'game-1',
    status: GameStatus.inProgress,
    playerCount: 4,
    totalCards: 40,
    maxCardsPerRound: 10,
    roundSequence: const [],
    players: const [],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    repository = _MockGameRepository();
    useCase = GetActiveGameUseCase(repository);
  });

  test('returns the in-progress game from the repository', () async {
    when(() => repository.getInProgressGame())
        .thenAnswer((_) async => activeGame);

    final result = await useCase();

    expect(result, activeGame);
    verify(() => repository.getInProgressGame()).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('returns null when there is no active game', () async {
    when(() => repository.getInProgressGame()).thenAnswer((_) async => null);

    final result = await useCase();

    expect(result, isNull);
    verify(() => repository.getInProgressGame()).called(1);
  });

  test('propagates repository errors', () async {
    when(() => repository.getInProgressGame()).thenThrow(StateError('boom'));

    expect(() => useCase(), throwsA(isA<StateError>()));
  });
}
