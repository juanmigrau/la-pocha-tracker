import '../entities/game_detail.dart';
import '../entities/game_history_item.dart';
import '../entities/game_history_load_result.dart';
import '../entities/game_history_source.dart';

abstract class HistoryRepository {
  /// Full history (local + cloud). Prefer local-first APIs for UI lists.
  Future<GameHistoryLoadResult> getGameHistory();

  /// Local-only stream (no Firestore). Kept for compatibility.
  Stream<GameHistoryLoadResult> watchGameHistory();

  /// Finished games from Drift only (hidden filter applied).
  Future<List<GameHistoryItem>> getLocalFinishedGames();

  /// Watches finished games from Drift only (hidden filter applied).
  Stream<List<GameHistoryItem>> watchLocalFinishedGames();

  /// Merges [localItems] with Firestore (connectivity check + 5s timeout).
  Future<GameHistoryLoadResult> enrichGameHistoryWithCloud(
    List<GameHistoryItem> localItems,
  );

  /// Merges local + cached cloud without network I/O.
  Future<GameHistoryLoadResult> mergeLocalWithCloud({
    required List<GameHistoryItem> localItems,
    required List<GameHistoryItem> cloudItems,
    bool cloudError = false,
  });

  Future<List<GameHistoryItem>> getRecentFinishedGames({int limit = 3});

  Stream<List<GameHistoryItem>> watchRecentFinishedGames({int limit = 3});

  Future<GameDetail> getGameDetail({
    required String gameId,
    required GameHistorySource source,
  });

  Future<void> deleteLocalGame(String gameId);

  Future<void> hideCloudGame(String gameId);

  Future<void> clearHiddenGames();
}
