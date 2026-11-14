part of 'share_result_cubit.dart';

sealed class ShareResultState {
  const ShareResultState();
}

final class ShareResultInitial extends ShareResultState {
  const ShareResultInitial();
}

final class ShareResultInProgress extends ShareResultState {
  const ShareResultInProgress();
}

final class ShareResultSuccess extends ShareResultState {
  const ShareResultSuccess();
}

final class ShareResultFailure extends ShareResultState {
  const ShareResultFailure({required this.message});

  final String message;
}
