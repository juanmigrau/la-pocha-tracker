import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_load_result.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/repositories/history_repository.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_history_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockHistoryRepository repository;
  late GetGameHistoryUseCase useCase;

  final localItem = GameHistoryItem(
    id: 'local-1',
    source: GameHistorySource.local,
    finishedAt: DateTime(2026, 8, 12, 21, 30),
    playerCount: 4,
    displayLabel: '12 ago 2026, 21:30 — Ana, Luis',
    winnerName: 'Ana',
    winnerScore: 40,
  );

  final cloudItem = GameHistoryItem(
    id: 'cloud-1',
    source: GameHistorySource.cloud,
    finishedAt: DateTime(2026, 8, 10, 20),
    playerCount: 3,
    displayLabel: '10 ago 2026, 20:00 — Marta, Pedro',
    winnerName: 'Marta',
    winnerScore: 35,
    cloudGameId: 'cloud-1',
  );

  setUp(() {
    repository = MockHistoryRepository();
    useCase = GetGameHistoryUseCase(repository);
  });

  group('call', () {
    test('returns the full history from the repository', () async {
      final expected = GameHistoryLoadResult(
        items: [localItem, cloudItem],
        cloudItems: [cloudItem],
      );
      when(() => repository.getGameHistory()).thenAnswer((_) async => expected);

      final result = await useCase();

      expect(result, expected);
      verify(() => repository.getGameHistory()).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('returns an empty result when the user has no games', () async {
      const expected = GameHistoryLoadResult(items: []);
      when(() => repository.getGameHistory()).thenAnswer((_) async => expected);

      final result = await useCase();

      expect(result.items, isEmpty);
      expect(result.cloudError, isFalse);
      expect(result.cloudItems, isEmpty);
    });

    test('propagates repository errors', () async {
      when(() => repository.getGameHistory()).thenThrow(StateError('boom'));

      expect(() => useCase(), throwsA(isA<StateError>()));
    });
  });

  group('local access', () {
    test('getLocal returns local finished games', () async {
      when(
        () => repository.getLocalFinishedGames(),
      ).thenAnswer((_) async => [localItem]);

      final result = await useCase.getLocal();

      expect(result, [localItem]);
      verify(() => repository.getLocalFinishedGames()).called(1);
    });

    test('getLocal returns an empty list when there are no games', () async {
      when(
        () => repository.getLocalFinishedGames(),
      ).thenAnswer((_) async => <GameHistoryItem>[]);

      expect(await useCase.getLocal(), isEmpty);
    });

    test('watchLocal emits the local stream from the repository', () async {
      when(
        () => repository.watchLocalFinishedGames(),
      ).thenAnswer((_) => Stream.value([localItem]));

      final result = await useCase.watchLocal().first;

      expect(result, [localItem]);
      verify(() => repository.watchLocalFinishedGames()).called(1);
    });

    test('watch emits the legacy load result stream', () async {
      final expected = GameHistoryLoadResult(items: [localItem]);
      when(
        () => repository.watchGameHistory(),
      ).thenAnswer((_) => Stream.value(expected));

      final result = await useCase.watch().first;

      expect(result, expected);
      verify(() => repository.watchGameHistory()).called(1);
    });
  });

  group('cloud orchestration', () {
    test('enrichWithCloud delegates local items to the repository', () async {
      final expected = GameHistoryLoadResult(
        items: [localItem, cloudItem],
        cloudItems: [cloudItem],
      );
      when(
        () => repository.enrichGameHistoryWithCloud([localItem]),
      ).thenAnswer((_) async => expected);

      final result = await useCase.enrichWithCloud([localItem]);

      expect(result, expected);
      verify(() => repository.enrichGameHistoryWithCloud([localItem])).called(1);
    });

    test('enrichWithCloud reports cloudError when cloud is unavailable', () async {
      final expected = GameHistoryLoadResult(
        items: [localItem],
        cloudError: true,
      );
      when(
        () => repository.enrichGameHistoryWithCloud([localItem]),
      ).thenAnswer((_) async => expected);

      final result = await useCase.enrichWithCloud([localItem]);

      expect(result.items, [localItem]);
      expect(result.cloudError, isTrue);
    });

    test('mergeLocalWithCloud merges local and cloud items', () async {
      final expected = GameHistoryLoadResult(
        items: [localItem, cloudItem],
        cloudItems: [cloudItem],
      );
      when(
        () => repository.mergeLocalWithCloud(
          localItems: [localItem],
          cloudItems: [cloudItem],
          cloudError: false,
        ),
      ).thenAnswer((_) async => expected);

      final result = await useCase.mergeLocalWithCloud(
        localItems: [localItem],
        cloudItems: [cloudItem],
      );

      expect(result, expected);
      expect(result.items, containsAll([localItem, cloudItem]));
      verify(
        () => repository.mergeLocalWithCloud(
          localItems: [localItem],
          cloudItems: [cloudItem],
          cloudError: false,
        ),
      ).called(1);
    });

    test('mergeLocalWithCloud forwards the cloudError flag', () async {
      final expected = GameHistoryLoadResult(
        items: [localItem],
        cloudError: true,
      );
      when(
        () => repository.mergeLocalWithCloud(
          localItems: [localItem],
          cloudItems: const [],
          cloudError: true,
        ),
      ).thenAnswer((_) async => expected);

      final result = await useCase.mergeLocalWithCloud(
        localItems: [localItem],
        cloudItems: const [],
        cloudError: true,
      );

      expect(result.cloudError, isTrue);
      expect(result.items, [localItem]);
    });

    test('mergeLocalWithCloud returns empty when both sources are empty', () async {
      const expected = GameHistoryLoadResult(items: []);
      when(
        () => repository.mergeLocalWithCloud(
          localItems: const [],
          cloudItems: const [],
          cloudError: false,
        ),
      ).thenAnswer((_) async => expected);

      final result = await useCase.mergeLocalWithCloud(
        localItems: const [],
        cloudItems: const [],
      );

      expect(result.items, isEmpty);
    });
  });
}
