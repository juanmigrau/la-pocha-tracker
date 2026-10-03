import '../entities/game_history_item.dart';
import '../entities/game_history_load_result.dart';
import '../repositories/history_repository.dart';

class GetGameHistoryUseCase {
  const GetGameHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<GameHistoryLoadResult> call() => _repository.getGameHistory();

  /// Local-only watch (no Firestore). Prefer this for local-first UI.
  Stream<List<GameHistoryItem>> watchLocal() =>
      _repository.watchLocalFinishedGames();

  Future<List<GameHistoryItem>> getLocal() =>
      _repository.getLocalFinishedGames();

  Future<GameHistoryLoadResult> enrichWithCloud(
    List<GameHistoryItem> localItems,
  ) =>
      _repository.enrichGameHistoryWithCloud(localItems);

  Future<GameHistoryLoadResult> mergeLocalWithCloud({
    required List<GameHistoryItem> localItems,
    required List<GameHistoryItem> cloudItems,
    bool cloudError = false,
  }) =>
      _repository.mergeLocalWithCloud(
        localItems: localItems,
        cloudItems: cloudItems,
        cloudError: cloudError,
      );

  /// Deprecated for UI: local-only stream wrapped as [GameHistoryLoadResult].
  Stream<GameHistoryLoadResult> watch() => _repository.watchGameHistory();
}
