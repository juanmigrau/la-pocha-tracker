import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';

class ShareResultPayload {
  const ShareResultPayload({
    required this.ranking,
    required this.finishedAt,
    required this.playerCount,
    required this.roundCount,
  });

  final List<RankingEntry> ranking;
  final DateTime? finishedAt;
  final int playerCount;
  final int roundCount;
}
