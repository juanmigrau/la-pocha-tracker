import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';

class BuildShareResultCaptionUseCase {
  const BuildShareResultCaptionUseCase();

  /// Builds the share caption for [payload].
  ///
  /// Throws [ArgumentError] when [ShareResultPayload.ranking] is empty.
  String call(ShareResultPayload payload) {
    final ranking = payload.ranking;
    if (ranking.isEmpty) {
      throw ArgumentError.value(
        ranking,
        'payload.ranking',
        'Ranking must not be empty',
      );
    }

    final winners = ranking.where((entry) => entry.rank == 1).toList();
    final score = winners.first.totalScore;

    if (winners.length == ranking.length) {
      return 'La Pocha: empate a $score pts';
    }

    if (winners.length == 1) {
      return 'La Pocha: gana ${winners.first.player.displayName} con $score pts';
    }

    return 'La Pocha: empatan ${_joinNames(winners)} con $score pts';
  }

  String _joinNames(List<RankingEntry> winners) {
    final names = winners.map((entry) => entry.player.displayName).toList();
    if (names.length == 2) {
      return '${names[0]} y ${names[1]}';
    }

    final leading = names.sublist(0, names.length - 1).join(', ');
    return '$leading y ${names.last}';
  }
}
