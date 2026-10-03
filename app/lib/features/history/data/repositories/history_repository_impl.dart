import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:la_pocha/features/game_setup/domain/repositories/game_repository.dart';
import 'package:la_pocha/features/history/data/datasources/hidden_games_local_datasource.dart';
import 'package:la_pocha/features/history/data/datasources/history_firestore_datasource.dart';
import 'package:la_pocha/features/history/data/datasources/history_local_datasource.dart';
import 'package:la_pocha/features/history/domain/entities/game_detail.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_item.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_load_result.dart';
import 'package:la_pocha/features/history/domain/entities/game_history_source.dart';
import 'package:la_pocha/features/history/domain/repositories/history_repository.dart';
import 'package:la_pocha/features/history/domain/services/game_detail_mapper.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(
    this._localDatasource,
    this._firestoreDatasource,
    this._hiddenGamesDatasource,
    this._gameRepository, {
    GameDetailMapper? gameDetailMapper,
    Connectivity? connectivity,
  }) : _gameDetailMapper = gameDetailMapper ?? const GameDetailMapper(),
       _connectivity = connectivity ?? Connectivity();

  static const _cloudTimeout = Duration(seconds: 5);

  final HistoryLocalDatasource _localDatasource;
  final HistoryFirestoreDatasource _firestoreDatasource;
  final HiddenGamesLocalDatasource _hiddenGamesDatasource;
  final GameRepository _gameRepository;
  final GameDetailMapper _gameDetailMapper;
  final Connectivity _connectivity;

  @override
  Future<List<GameHistoryItem>> getRecentFinishedGames({int limit = 3}) {
    return _localDatasource.getFinishedGames(limit: limit);
  }

  @override
  Stream<List<GameHistoryItem>> watchRecentFinishedGames({int limit = 3}) {
    return _localDatasource.watchFinishedGames(limit: limit);
  }

  @override
  Future<List<GameHistoryItem>> getLocalFinishedGames() async {
    final localItems = await _localDatasource.getFinishedGames();
    final hiddenIds = await _hiddenGamesDatasource.getHiddenGameIds();
    return _filterHiddenItems(localItems, hiddenIds);
  }

  @override
  Stream<List<GameHistoryItem>> watchLocalFinishedGames() {
    return _localDatasource.watchFinishedGames().asyncMap((localItems) async {
      final hiddenIds = await _hiddenGamesDatasource.getHiddenGameIds();
      return _filterHiddenItems(localItems, hiddenIds);
    });
  }

  @override
  Future<GameHistoryLoadResult> enrichGameHistoryWithCloud(
    List<GameHistoryItem> localItems,
  ) async {
    if (!await _hasConnectivity()) {
      return mergeLocalWithCloud(
        localItems: localItems,
        cloudItems: const [],
        cloudError: true,
      );
    }

    try {
      final cloudItems = await _firestoreDatasource
          .getFinishedCloudGames()
          .timeout(_cloudTimeout);
      return mergeLocalWithCloud(
        localItems: localItems,
        cloudItems: cloudItems,
      );
    } catch (_) {
      return mergeLocalWithCloud(
        localItems: localItems,
        cloudItems: const [],
        cloudError: true,
      );
    }
  }

  @override
  Future<GameHistoryLoadResult> mergeLocalWithCloud({
    required List<GameHistoryItem> localItems,
    required List<GameHistoryItem> cloudItems,
    bool cloudError = false,
  }) async {
    final hiddenIds = await _hiddenGamesDatasource.getHiddenGameIds();
    final merged = _mergeAndDeduplicate(localItems, cloudItems);
    final filtered = _filterHiddenItems(merged, hiddenIds);
    return GameHistoryLoadResult(
      items: filtered,
      cloudError: cloudError,
      cloudItems: cloudItems,
    );
  }

  @override
  Future<GameHistoryLoadResult> getGameHistory() async {
    final localItems = await getLocalFinishedGames();
    return enrichGameHistoryWithCloud(localItems);
  }

  @override
  Stream<GameHistoryLoadResult> watchGameHistory() {
    return watchLocalFinishedGames().map(
      (items) => GameHistoryLoadResult(items: items),
    );
  }

  @override
  Future<GameDetail> getGameDetail({
    required String gameId,
    required GameHistorySource source,
  }) async {
    final data = switch (source) {
      GameHistorySource.local => await _localDatasource.loadFinishedGameDetail(
        gameId,
      ),
      GameHistorySource.cloud =>
        await _firestoreDatasource.loadFinishedGameDetail(gameId),
    };

    return _gameDetailMapper.buildGameDetail(
      game: data.game,
      rounds: data.rounds,
      source: source,
    );
  }

  @override
  Future<void> deleteLocalGame(String gameId) async {
    await _gameRepository.deleteGame(gameId);
  }

  @override
  Future<void> hideCloudGame(String gameId) async {
    await _hiddenGamesDatasource.hideGame(gameId);
  }

  @override
  Future<void> clearHiddenGames() => _hiddenGamesDatasource.clearAll();

  Future<bool> _hasConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }

  List<GameHistoryItem> _filterHiddenItems(
    List<GameHistoryItem> items,
    Set<String> hiddenIds,
  ) {
    if (hiddenIds.isEmpty) {
      return items;
    }

    return items.where((item) {
      if (hiddenIds.contains(item.id)) {
        return false;
      }
      final cloudGameId = item.cloudGameId;
      if (cloudGameId != null && hiddenIds.contains(cloudGameId)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<GameHistoryItem> _mergeAndDeduplicate(
    List<GameHistoryItem> localItems,
    List<GameHistoryItem> cloudItems,
  ) {
    final cloudIds = cloudItems.map((item) => item.id).toSet();

    final filteredLocal = localItems.where((item) {
      final cloudGameId = item.cloudGameId;
      if (cloudGameId == null) {
        return true;
      }
      return !cloudIds.contains(cloudGameId);
    }).toList();

    final merged = [...filteredLocal, ...cloudItems]
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));

    return merged;
  }
}
