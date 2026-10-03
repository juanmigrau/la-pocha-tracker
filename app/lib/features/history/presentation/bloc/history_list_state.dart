part of 'history_list_bloc.dart';

enum HistorySyncRetryFeedback { success, failure }

sealed class HistoryListState extends Equatable {
  const HistoryListState();

  @override
  List<Object?> get props => [];
}

class HistoryListInitial extends HistoryListState {
  const HistoryListInitial();
}

class HistoryListLoading extends HistoryListState {
  const HistoryListLoading();
}

class HistoryListLoaded extends HistoryListState {
  const HistoryListLoaded({
    required this.items,
    this.cloudError = false,
    this.isCloudLoading = false,
    this.syncingGameIds = const {},
    this.syncRetryFeedback,
  });

  final List<GameHistoryItem> items;
  final bool cloudError;
  final bool isCloudLoading;
  final Set<String> syncingGameIds;
  final HistorySyncRetryFeedback? syncRetryFeedback;

  HistoryListLoaded copyWith({
    List<GameHistoryItem>? items,
    bool? cloudError,
    bool? isCloudLoading,
    Set<String>? syncingGameIds,
    HistorySyncRetryFeedback? syncRetryFeedback,
    bool clearSyncRetryFeedback = false,
  }) {
    return HistoryListLoaded(
      items: items ?? this.items,
      cloudError: cloudError ?? this.cloudError,
      isCloudLoading: isCloudLoading ?? this.isCloudLoading,
      syncingGameIds: syncingGameIds ?? this.syncingGameIds,
      syncRetryFeedback: clearSyncRetryFeedback
          ? null
          : (syncRetryFeedback ?? this.syncRetryFeedback),
    );
  }

  @override
  List<Object?> get props => [
        items,
        cloudError,
        isCloudLoading,
        syncingGameIds,
        syncRetryFeedback,
      ];
}

class HistoryListEmpty extends HistoryListState {
  const HistoryListEmpty();
}

class HistoryListFailure extends HistoryListState {
  const HistoryListFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
