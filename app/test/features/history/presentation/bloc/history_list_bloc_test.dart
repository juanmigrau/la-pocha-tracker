import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_load_result.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_history_usecase.dart';
import 'package:la_pocha/features/history/presentation/bloc/history_list_bloc.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';
import 'package:la_pocha/features/sync/domain/usecases/retry_pending_uploads_usecase.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'history_list_bloc_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetGameHistoryUseCase>(),
  MockSpec<RetryPendingUploadsUseCase>(),
])
void main() {
  late MockGetGameHistoryUseCase getGameHistory;
  late MockRetryPendingUploadsUseCase retryPendingUploads;

  final items = [
    GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
    ),
  ];

  final cloudItem = GameHistoryItem(
    id: 'cloud-1',
    source: GameHistorySource.cloud,
    finishedAt: DateTime(2026, 7, 5),
    playerCount: 4,
    displayLabel: '5 jul 2026 — Nube',
    winnerName: 'Luis',
    winnerScore: 10,
  );

  final pendingItems = [
    GameHistoryItem(
      id: 'game-1',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 4),
      playerCount: 4,
      displayLabel: '4 jul 2026, 22:00 — Ana, Carlos',
      winnerName: 'Ana',
      winnerScore: 42,
      syncStatus: SyncStatus.pending,
    ),
    GameHistoryItem(
      id: 'game-2',
      source: GameHistorySource.local,
      finishedAt: DateTime(2026, 7, 5),
      playerCount: 3,
      displayLabel: '5 jul 2026 — Luis',
      winnerName: 'Luis',
      winnerScore: 10,
      syncStatus: SyncStatus.failed,
    ),
  ];

  void stubLocalFirst({
    required List<GameHistoryItem> local,
    required GameHistoryLoadResult enrichResult,
  }) {
    when(getGameHistory.watchLocal()).thenAnswer((_) => Stream.value(local));
    when(getGameHistory.enrichWithCloud(local)).thenAnswer(
      (_) async => enrichResult,
    );
    when(
      getGameHistory.mergeLocalWithCloud(
        localItems: anyNamed('localItems'),
        cloudItems: anyNamed('cloudItems'),
        cloudError: anyNamed('cloudError'),
      ),
    ).thenAnswer((invocation) async {
      final localItems =
          invocation.namedArguments[#localItems] as List<GameHistoryItem>;
      final cloudItems =
          invocation.namedArguments[#cloudItems] as List<GameHistoryItem>;
      final cloudError =
          invocation.namedArguments[#cloudError] as bool? ?? false;
      return GameHistoryLoadResult(
        items: [...localItems, ...cloudItems],
        cloudError: cloudError,
        cloudItems: cloudItems,
      );
    });
  }

  setUp(() {
    getGameHistory = MockGetGameHistoryUseCase();
    retryPendingUploads = MockRetryPendingUploadsUseCase();
    when(retryPendingUploads()).thenAnswer((_) async => 0);
  });

  HistoryListBloc buildBloc() => HistoryListBloc(
        getGameHistory: getGameHistory,
        retryPendingUploads: retryPendingUploads,
      );

  blocTest<HistoryListBloc, HistoryListState>(
    'emits local first then enriched result',
    build: buildBloc,
    setUp: () {
      stubLocalFirst(
        local: items,
        enrichResult: GameHistoryLoadResult(
          items: [...items, cloudItem],
          cloudItems: [cloudItem],
        ),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 30),
    expect: () => [
      const HistoryListLoading(),
      HistoryListLoaded(items: items, isCloudLoading: true),
      HistoryListLoaded(
        items: [...items, cloudItem],
        isCloudLoading: false,
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'emits loaded with cloudError when enrich fails offline',
    build: buildBloc,
    setUp: () {
      stubLocalFirst(
        local: items,
        enrichResult: GameHistoryLoadResult(
          items: items,
          cloudError: true,
        ),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 30),
    expect: () => [
      const HistoryListLoading(),
      HistoryListLoaded(items: items, isCloudLoading: true),
      HistoryListLoaded(
        items: items,
        cloudError: true,
        isCloudLoading: false,
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'emits empty when local and cloud have no items',
    build: buildBloc,
    setUp: () {
      stubLocalFirst(
        local: const [],
        enrichResult: const GameHistoryLoadResult(items: []),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 30),
    expect: () => [
      const HistoryListLoading(),
      const HistoryListLoaded(items: [], isCloudLoading: true),
      const HistoryListEmpty(),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'reloads local then enrich on refresh',
    build: buildBloc,
    setUp: () {
      when(getGameHistory.getLocal()).thenAnswer((_) async => items);
      when(getGameHistory.enrichWithCloud(items)).thenAnswer(
        (_) async => GameHistoryLoadResult(items: items),
      );
    },
    seed: () => HistoryListLoaded(items: items),
    act: (bloc) => bloc.add(const HistoryListRefreshed()),
    wait: const Duration(milliseconds: 30),
    expect: () => [
      HistoryListLoaded(items: items, isCloudLoading: true),
      HistoryListLoaded(items: items, isCloudLoading: false),
    ],
    verify: (_) {
      verify(getGameHistory.getLocal()).called(1);
      verify(getGameHistory.enrichWithCloud(items)).called(1);
    },
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'emits failure without DEBUG details when local watch errors',
    build: buildBloc,
    setUp: () {
      when(getGameHistory.watchLocal()).thenAnswer(
        (_) => Stream.error(Exception('network error')),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const HistoryListLoading(),
      isA<HistoryListFailure>().having(
        (state) => state.message,
        'message',
        isNot(contains('[DEBUG]')),
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'removes deleted game optimistically from loaded list',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: items),
    act: (bloc) => bloc.add(const HistoryListGameDeleted('game-1')),
    expect: () => [const HistoryListEmpty()],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'preserves cloudError when deleting one of several items',
    build: buildBloc,
    seed: () => HistoryListLoaded(
      items: [
        items.first,
        GameHistoryItem(
          id: 'game-2',
          source: GameHistorySource.local,
          finishedAt: DateTime(2026, 7, 5),
          playerCount: 3,
          displayLabel: '5 jul 2026 — Luis',
          winnerName: 'Luis',
          winnerScore: 10,
        ),
      ],
      cloudError: true,
    ),
    act: (bloc) => bloc.add(const HistoryListGameDeleted('game-1')),
    expect: () => [
      HistoryListLoaded(
        items: [
          GameHistoryItem(
            id: 'game-2',
            source: GameHistorySource.local,
            finishedAt: DateTime(2026, 7, 5),
            playerCount: 3,
            displayLabel: '5 jul 2026 — Luis',
            winnerName: 'Luis',
            winnerScore: 10,
          ),
        ],
        cloudError: true,
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'SyncRetryRequested shows syncing then success feedback',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: pendingItems),
    setUp: () {
      when(retryPendingUploads(gameId: 'game-1')).thenAnswer((_) async => 1);
    },
    act: (bloc) => bloc.add(const SyncRetryRequested(gameId: 'game-1')),
    expect: () => [
      HistoryListLoaded(
        items: pendingItems,
        syncingGameIds: const {'game-1'},
      ),
      HistoryListLoaded(
        items: pendingItems,
        syncRetryFeedback: HistorySyncRetryFeedback.success,
      ),
    ],
    verify: (_) {
      verify(retryPendingUploads(gameId: 'game-1')).called(1);
    },
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'SyncRetryRequested shows failure feedback when upload does not sync',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: pendingItems),
    setUp: () {
      when(retryPendingUploads(gameId: 'game-1')).thenAnswer((_) async => 0);
    },
    act: (bloc) => bloc.add(const SyncRetryRequested(gameId: 'game-1')),
    expect: () => [
      HistoryListLoaded(
        items: pendingItems,
        syncingGameIds: const {'game-1'},
      ),
      HistoryListLoaded(
        items: pendingItems,
        syncRetryFeedback: HistorySyncRetryFeedback.failure,
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'SyncAllPendingRequested retries all pending and failed games',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: pendingItems),
    setUp: () {
      when(retryPendingUploads()).thenAnswer((_) async => 2);
    },
    act: (bloc) => bloc.add(const SyncAllPendingRequested()),
    expect: () => [
      HistoryListLoaded(
        items: pendingItems,
        syncingGameIds: const {'game-1', 'game-2'},
      ),
      HistoryListLoaded(
        items: pendingItems,
        syncRetryFeedback: HistorySyncRetryFeedback.success,
      ),
    ],
    verify: (_) {
      verify(retryPendingUploads()).called(1);
    },
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'SyncAllPendingRequested emits failure when not all games sync',
    build: buildBloc,
    seed: () => HistoryListLoaded(items: pendingItems),
    setUp: () {
      when(retryPendingUploads()).thenAnswer((_) async => 1);
    },
    act: (bloc) => bloc.add(const SyncAllPendingRequested()),
    expect: () => [
      HistoryListLoaded(
        items: pendingItems,
        syncingGameIds: const {'game-1', 'game-2'},
      ),
      HistoryListLoaded(
        items: pendingItems,
        syncRetryFeedback: HistorySyncRetryFeedback.failure,
      ),
    ],
  );

  blocTest<HistoryListBloc, HistoryListState>(
    'does not await retry before emitting local history',
    build: buildBloc,
    setUp: () {
      when(retryPendingUploads()).thenAnswer(
        (_) => Future.delayed(
          const Duration(milliseconds: 200),
          () => 0,
        ),
      );
      stubLocalFirst(
        local: items,
        enrichResult: GameHistoryLoadResult(items: items),
      );
    },
    act: (bloc) => bloc.add(const HistoryListStarted()),
    wait: const Duration(milliseconds: 40),
    expect: () => [
      const HistoryListLoading(),
      HistoryListLoaded(items: items, isCloudLoading: true),
      HistoryListLoaded(items: items, isCloudLoading: false),
    ],
  );
}
