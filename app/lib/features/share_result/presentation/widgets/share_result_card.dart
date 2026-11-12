import 'package:flutter/material.dart';
import 'package:la_pocha/core/widgets/player_initial_avatar.dart';
import 'package:la_pocha/core/widgets/pocha_logo.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';

/// Brand-fixed share card at logical size 360×450.
///
/// Ignores app [ThemeMode] and system text scaling. Palette constants mirror
/// the dark final-result screen (no [Theme.of] / [AppTheme] at runtime).
class ShareResultCard extends StatelessWidget {
  const ShareResultCard({super.key, required this.payload});

  static const Size logicalSize = Size(360, 450);

  /// Winner-card / brand green (dark [ColorScheme.primaryContainer] look).
  static const Color brandGreen = Color(0xFF2E5040);

  /// Dark scaffold surface from [AppTheme.dark].
  static const Color background = Color(0xFF1A2420);

  /// Dark accent primary (mint) from [AppTheme.dark].
  static const Color accentMint = Color(0xFF4CAF82);

  static const Color trophyGold = Color(0xFFC8A84B);
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
    final winners = payload.ranking.where((e) => e.rank == 1).toList();
    final rest = payload.ranking.where((e) => e.rank >= 2).toList();

    return MediaQuery(
      data: MediaQueryData(size: logicalSize, textScaler: TextScaler.noScaling),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(
            // Explicit family so isolated capture (no MaterialApp) matches app body text.
            fontFamily: 'Roboto',
            color: Colors.white,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
          child: SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _CardBackground(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _BrandHeader(),
                        const SizedBox(height: 16),
                        Expanded(
                          flex: rest.isEmpty ? 7 : 3,
                          child: winners.isEmpty
                              ? const SizedBox.shrink()
                              : _WinnerHero(winners: winners),
                        ),
                        if (rest.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Expanded(
                            flex: rest.length >= 5 ? 5 : 4,
                            child: _StandingsList(entries: rest),
                          ),
                        ] else
                          const Spacer(flex: 1),
                        const SizedBox(height: 12),
                        _FooterMeta(
                          finishedAt: payload.finishedAt,
                          playerCount: payload.playerCount,
                          roundCount: payload.roundCount,
                        ),
                      ],
                    ),
                  ),
                ],
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

class _CardBackground extends StatelessWidget {
  const _CardBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF24362E), ShareResultCard.background],
              stops: [0.0, 0.45],
            ),
          ),
        ),
        Positioned(
          right: -48,
          bottom: -56,
          child: Opacity(
            opacity: 0.07,
            child: Image.asset(
              PochaLogo.fanAssetPath,
              width: 220,
              height: 220,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              PochaLogo(height: 40),
              SizedBox(width: 10),
              Text(
                'La Pocha',
                style: TextStyle(
                  fontFamily: ShareResultCard.brandFontFamily,
                  fontSize: 32,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Resultado final',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ShareResultCard.accentMint,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _WinnerHero extends StatelessWidget {
  const _WinnerHero({required this.winners});

  final List<RankingEntry> winners;

  @override
  Widget build(BuildContext context) {
    final isTie = winners.length > 1;
    final score = winners.first.totalScore;

    return Container(
      decoration: BoxDecoration(
        color: ShareResultCard.brandGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: isTie
          ? _TieHeroContent(winners: winners, score: score)
          : _SingleWinnerContent(entry: winners.first),
    );
  }
}

class _SingleWinnerContent extends StatelessWidget {
  const _SingleWinnerContent({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.player.displayName;

    return Row(
      children: [
        const Icon(
          Icons.emoji_events,
          color: ShareResultCard.trophyGold,
          size: 36,
        ),
        const SizedBox(width: 12),
        PlayerInitialAvatar(
          name: name,
          colorIndex: entry.player.seatOrder,
          radius: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GANADOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: ShareResultCard.accentMint,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  name,
                  maxLines: 2,
                  softWrap: true,
                  style: const TextStyle(
                    fontFamily: ShareResultCard.brandFontFamily,
                    fontSize: 28,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.totalScore} pts',
                style: const TextStyle(
                  fontFamily: ShareResultCard.brandFontFamily,
                  fontSize: 18,
                  color: ShareResultCard.trophyGold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TieHeroContent extends StatelessWidget {
  const _TieHeroContent({required this.winners, required this.score});

  final List<RankingEntry> winners;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: ShareResultCard.trophyGold,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'EMPATE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: ShareResultCard.accentMint,
                height: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final entry in winners) _TiedWinnerChip(entry: entry),
              ],
            ),
          ),
        ),
        Text(
          '$score pts',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: ShareResultCard.brandFontFamily,
            fontSize: 20,
            color: ShareResultCard.trophyGold,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _TiedWinnerChip extends StatelessWidget {
  const _TiedWinnerChip({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.player.displayName;
    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerInitialAvatar(
            name: name,
            colorIndex: entry.player.seatOrder,
            radius: 22,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: ShareResultCard.brandFontFamily,
              fontSize: 16,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingsList extends StatelessWidget {
  const _StandingsList({required this.entries});

  final List<RankingEntry> entries;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('share_result_standings'),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 48),
                  child: _StandingRow(entry: entries[i]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.entry});

  final RankingEntry entry;

  Color get _rankColor {
    switch (entry.rank) {
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return ShareResultCard.accentMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = entry.player.displayName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowH = constraints.maxHeight.clamp(26.0, 48.0);
        final avatarRadius = (rowH * 0.32).clamp(10.0, 14.0);
        final nameSize = (rowH * 0.38).clamp(11.0, 14.0);
        final scoreSize = (rowH * 0.42).clamp(12.0, 16.0);
        final rankSize = (rowH * 0.4).clamp(12.0, 15.0);

        return SizedBox(
          height: rowH,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${entry.rank}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: rankSize,
                    fontWeight: FontWeight.w700,
                    color: _rankColor,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Initials only (no photoURL): same seatOrder color as the app.
              PlayerInitialAvatar(
                name: name,
                colorIndex: entry.player.seatOrder,
                radius: avatarRadius,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: nameSize,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.totalScore}',
                style: TextStyle(
                  fontFamily: ShareResultCard.brandFontFamily,
                  fontSize: scoreSize,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ],
          ),
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
    final parts = <String>[
      if (finishedAt != null) ShareResultCard.formatFinishedAt(finishedAt!),
      '$playerCount jugadores',
      '$roundCount rondas',
    ];

    return Text(
      parts.join(' · '),
      key: finishedAt != null
          ? const Key('share_result_date')
          : const Key('share_result_footer'),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.78),
        height: 1.2,
      ),
    );
  }
}
