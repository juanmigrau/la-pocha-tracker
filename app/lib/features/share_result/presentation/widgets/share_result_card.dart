import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/pocha_logo.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';

/// Brand-fixed share card at logical size 360×450.
///
/// Ignores app [ThemeMode] and system text scaling.
class ShareResultCard extends StatelessWidget {
  const ShareResultCard({super.key, required this.payload});

  static const Size logicalSize = Size(360, 450);
  static const Color brandGreen = Color(0xFF2E5040);
  static const String brandFontFamily = 'LilitaOne';

  final ShareResultPayload payload;

  static const List<String> _monthNames = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData(size: logicalSize, textScaler: TextScaler.noScaling),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: ColoredBox(
              color: brandGreen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BrandHeader(),
                    const SizedBox(height: 14),
                    if (payload.ranking.isNotEmpty) ...[
                      _WinnerHighlight(entry: payload.ranking.first),
                      const SizedBox(height: 12),
                    ],
                    Expanded(child: _RankingList(ranking: payload.ranking)),
                    const SizedBox(height: 10),
                    _FooterMeta(
                      finishedAt: payload.finishedAt,
                      playerCount: payload.playerCount,
                      roundCount: payload.roundCount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String formatFinishedAt(DateTime finishedAt) {
    final day = finishedAt.day;
    final month = _monthNames[finishedAt.month - 1];
    final year = finishedAt.year;
    return '$day $month $year';
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        PochaLogo(height: 36),
        SizedBox(width: 10),
        Text(
          'La Pocha',
          style: TextStyle(
            fontFamily: ShareResultCard.brandFontFamily,
            fontSize: 28,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _WinnerHighlight extends StatelessWidget {
  const _WinnerHighlight({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.player.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: ShareResultCard.brandFontFamily,
            fontSize: 26,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        Text(
          '${entry.totalScore} pts',
          style: const TextStyle(
            fontFamily: ShareResultCard.brandFontFamily,
            fontSize: 22,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.ranking});

  final List<RankingEntry> ranking;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: ranking.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final entry = ranking[index];
        return Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${entry.rank}º',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Text(
                entry.player.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            Text(
              '${entry.totalScore}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FooterMeta extends StatelessWidget {
  const _FooterMeta({
    required this.finishedAt,
    required this.playerCount,
    required this.roundCount,
  });

  final DateTime? finishedAt;
  final int playerCount;
  final int roundCount;

  @override
  Widget build(BuildContext context) {
    final meta = '$playerCount jugadores · $roundCount rondas';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (finishedAt != null) ...[
          Text(
            ShareResultCard.formatFinishedAt(finishedAt!),
            key: const Key('share_result_date'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          meta,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
