import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:la_pocha/core/errors/user_facing_error_mapper.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_load_result.dart';
import 'package:la_pocha/features/history/domain/usecases/get_game_history_usecase.dart';
import 'package:la_pocha/features/sync/domain/usecases/retry_pending_uploads_usecase.dart';

part 'history_list_event.dart';
part 'history_list_state.dart';

class HistoryListBloc extends Bloc<HistoryListEvent, HistoryListState> {
  HistoryListBloc({
    required this._getGameHistory,
    required this._retryPendingUploads,
  }) : super(const HistoryListInitial()) {
    on<HistoryListStarted>(_onStarted);
    on<HistoryListRefreshed>(_onRefreshed);
    on<HistoryListGameDeleted>(_onGameDeleted);
    on<SyncRetryRequested>(_onSyncRetryRequested);
    on<SyncAllPendingRequested>(_onSyncAllPendingRequested);
    on<_HistoryListLocalData>(_onLocalData);
    on<_HistoryListCloudEnriched>(_onCloudEnriched);
    on<_HistoryListWatchFailed>(_onWatchFailed);
  }

  final GetGameHistoryUseCase _getGameHistory;
  final RetryPendingUploadsUseCase _retryPendingUploads;
  StreamSubscription<List<GameHistoryItem>>? _subscription;

  List<GameHistoryItem> _lastLocalItems = const [];
  List<GameHistoryItem> _lastCloudItems = const [];
  bool _cloudError = false;
  bool _isCloudLoading = false;
  bool _enrichRequested = false;

  Future<void> _onStarted(
    HistoryListStarted event,
    Emitter<HistoryListState> emit,
  ) async {
    if (state is! HistoryListLoaded) {
      emit(const HistoryListLoading());
    }
    unawaited(_retryPendingUploads());
    _lastCloudItems = const [];
    _cloudError = false;
    _isCloudLoading = true;
    _enrichRequested = false;
    await _listenToLocalWatch();
  }

  Future<void> _onRefreshed(
    HistoryListRefreshed event,
    Emitter<HistoryListState> emit,
  ) async {
    unawaited(_retryPendingUploads());
    _lastCloudItems = const [];
    _cloudError = false;
    _isCloudLoading = true;
    _enrichRequested = false;

    try {
      final localItems = await _getGameHistory.getLocal();
      _lastLocalItems = localItems;
      _emitFromCache(emit, isCloudLoading: true);
      await _runCloudEnrich(localItems);
    } catch (error) {
      emit(HistoryListFailure(message: mapExceptionToUserMessage(error)));
    }
  }

  void _onGameDeleted(
    HistoryListGameDeleted event,
    Emitter<HistoryListState> emit,
  ) {
    final current = state;
    if (current is! HistoryListLoaded) {
      return;
    }

    final updatedItems = current.items
        .where(
          (item) =>
              item.id != event.gameId && item.cloudGameId != event.gameId,
        )
        .toList();

    _lastLocalItems = _lastLocalItems
        .where(
          (item) =>
              item.id != event.gameId && item.cloudGameId != event.gameId,
        )
        .toList();
    _lastCloudItems = _lastCloudItems
        .where((item) => item.id != event.gameId)
        .toList();

    if (updatedItems.isEmpty && !current.isCloudLoading) {
      emit(const HistoryListEmpty());
      return;
    }

    emit(
      current.copyWith(
        items: updatedItems,
        clearSyncRetryFeedback: true,
      ),
    );
  }

  Future<void> _onSyncRetryRequested(
    SyncRetryRequested event,
    Emitter<HistoryListState> emit,
  ) async {
    final current = state;
    if (current is! HistoryListLoaded) {
      return;
    }

    emit(
      current.copyWith(
        syncingGameIds: {...current.syncingGameIds, event.gameId},
        clearSyncRetryFeedback: true,
      ),
    );

    final syncedCount = await _retryPendingUploads(gameId: event.gameId);
    final after = state;
    if (after is! HistoryListLoaded) {
      return;
    }

    final updatedSyncing = Set<String>.from(after.syncingGameIds)
      ..remove(event.gameId);

    emit(
      after.copyWith(
        syncingGameIds: updatedSyncing,
        syncRetryFeedback: syncedCount == 1
            ? HistorySyncRetryFeedback.success
            : HistorySyncRetryFeedback.failure,
      ),
    );
  }

  Future<void> _onSyncAllPendingRequested(
    SyncAllPendingRequested event,
    Emitter<HistoryListState> emit,
  ) async {
    final current = state;
    if (current is! HistoryListLoaded) {
      return;
    }

    final retryIds = current.items
        .where((item) => item.needsSyncRetry)
        .map((item) => item.id)
        .toSet();
    if (retryIds.isEmpty) {
      return;
    }

    emit(
      current.copyWith(
        syncingGameIds: {...current.syncingGameIds, ...retryIds},
        clearSyncRetryFeedback: true,
      ),
    );

    final syncedCount = await _retryPendingUploads();
    final after = state;
    if (after is! HistoryListLoaded) {
      return;
    }

    final updatedSyncing = Set<String>.from(after.syncingGameIds)
      ..removeAll(retryIds);

    emit(
      after.copyWith(
        syncingGameIds: updatedSyncing,
        syncRetryFeedback: syncedCount == retryIds.length && syncedCount > 0
            ? HistorySyncRetryFeedback.success
            : HistorySyncRetryFeedback.failure,
      ),
    );
  }

  Future<void> _onLocalData(
    _HistoryListLocalData event,
    Emitter<HistoryListState> emit,
  ) async {
    _lastLocalItems = event.items;

    if (!_enrichRequested) {
      _enrichRequested = true;
      _isCloudLoading = true;
      _emitFromCache(emit, isCloudLoading: true);
      // Enrich in background; result arrives via _HistoryListCloudEnriched.
      unawaited(_runCloudEnrich(event.items));
      return;
    }

    if (_lastCloudItems.isEmpty && !_isCloudLoading) {
      _emitFromCache(emit, isCloudLoading: false);
      return;
    }

    if (_lastCloudItems.isEmpty) {
      _emitFromCache(emit, isCloudLoading: _isCloudLoading);
      return;
    }

    final merged = await _getGameHistory.mergeLocalWithCloud(
      localItems: _lastLocalItems,
      cloudItems: _lastCloudItems,
      cloudError: _cloudError,
    );
    _emitResult(merged, emit, isCloudLoading: _isCloudLoading);
  }

  void _onCloudEnriched(
    _HistoryListCloudEnriched event,
    Emitter<HistoryListState> emit,
  ) {
    _isCloudLoading = false;
    _cloudError = event.result.cloudError;
    _lastCloudItems = event.result.cloudItems;
    _emitResult(event.result, emit, isCloudLoading: false);
  }

  void _onWatchFailed(
    _HistoryListWatchFailed event,
    Emitter<HistoryListState> emit,
  ) {
    emit(HistoryListFailure(message: mapExceptionToUserMessage(event.error)));
  }

  Future<void> _listenToLocalWatch() async {
    await _subscription?.cancel();
    _subscription = _getGameHistory.watchLocal().listen(
      (items) => add(_HistoryListLocalData(items)),
      onError: (Object error, StackTrace _) =>
          add(_HistoryListWatchFailed(error)),
    );
  }

  Future<void> _runCloudEnrich(List<GameHistoryItem> localItems) async {
    try {
      final result = await _getGameHistory.enrichWithCloud(localItems);
      add(_HistoryListCloudEnriched(result));
    } catch (error) {
      add(
        _HistoryListCloudEnriched(
          GameHistoryLoadResult(items: localItems, cloudError: true),
        ),
      );
    }
  }

  void _emitFromCache(
    Emitter<HistoryListState> emit, {
    required bool isCloudLoading,
  }) {
    _emitResult(
      GameHistoryLoadResult(
        items: _lastLocalItems,
        cloudError: _cloudError,
        cloudItems: _lastCloudItems,
      ),
      emit,
      isCloudLoading: isCloudLoading,
    );
  }

  void _emitResult(
    GameHistoryLoadResult result,
    Emitter<HistoryListState> emit, {
    required bool isCloudLoading,
  }) {
    if (result.items.isEmpty && !isCloudLoading) {
      emit(const HistoryListEmpty());
      return;
    }

    final current = state;
    final syncingGameIds = current is HistoryListLoaded
        ? current.syncingGameIds
        : const <String>{};
    final syncRetryFeedback = current is HistoryListLoaded
        ? current.syncRetryFeedback
        : null;

    emit(
      HistoryListLoaded(
        items: result.items,
        cloudError: result.cloudError,
        isCloudLoading: isCloudLoading,
        syncingGameIds: syncingGameIds,
        syncRetryFeedback: syncRetryFeedback,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
