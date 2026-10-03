import 'package:equatable/equatable.dart';

import 'game_history_item.dart';

/// Result of loading game history from local and optionally cloud sources.
class GameHistoryLoadResult extends Equatable {
  const GameHistoryLoadResult({
    required this.items,
    this.cloudError = false,
    this.cloudItems = const [],
  });

  final List<GameHistoryItem> items;
  final bool cloudError;

  /// Raw cloud items used for client-side re-merge on local Drift updates.
  final List<GameHistoryItem> cloudItems;

  @override
  List<Object?> get props => [items, cloudError, cloudItems];
}
