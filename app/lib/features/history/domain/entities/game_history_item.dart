import 'package:equatable/equatable.dart';
import 'package:la_pocha/features/sync/domain/entities/sync_status.dart';

import 'game_history_source.dart';

/// Lightweight player identity used only for presentation-time name resolution.
class GameHistoryPlayerRef extends Equatable {
  const GameHistoryPlayerRef({
    required this.displayName,
    this.userId,
  });

  final String displayName;
  final String? userId;

  @override
  List<Object?> get props => [displayName, userId];
}

class GameHistoryItem extends Equatable {
  const GameHistoryItem({
    required this.id,
    required this.source,
    required this.finishedAt,
    required this.playerCount,
    required this.displayLabel,
    this.players = const [],
    this.winnerName,
    this.winnerUserId,
    this.winnerScore,
    this.cloudGameId,
    this.syncStatus,
  });

  final String id;
  final GameHistorySource source;
  final DateTime finishedAt;
  final int playerCount;
  final String displayLabel;
  final List<GameHistoryPlayerRef> players;
  final String? winnerName;
  final String? winnerUserId;
  final int? winnerScore;
  final String? cloudGameId;
  final SyncStatus? syncStatus;

  bool get needsSyncRetry =>
      syncStatus == SyncStatus.pending || syncStatus == SyncStatus.failed;

  @override
  List<Object?> get props => [
        id,
        source,
        finishedAt,
        playerCount,
        displayLabel,
        players,
        winnerName,
        winnerUserId,
        winnerScore,
        cloudGameId,
        syncStatus,
      ];
}
