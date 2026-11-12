import 'package:flutter/material.dart';
import 'package:la_pocha/core/utils/player_colors.dart';
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

  /// Vertical centered single-winner hero when total players is at most this.
  static const int verticalHeroMaxPlayers = 5;

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
    final totalPlayers = payload.ranking.length;
    final isTie = winners.length > 1;
    final useVerticalSingle = !isTie && totalPlayers <= verticalHeroMaxPlayers;

    final int heroFlex;
    if (rest.isEmpty) {
      heroFlex = 8;
    } else if (isTie) {
      heroFlex = 5;
    } else if (useVerticalSingle) {
      heroFlex = 5;
    } else {
      heroFlex = 3;
    }

    final listFlex = rest.length >= 5 ? 5 : 3;

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
                          flex: heroFlex,
                          child: winners.isEmpty
                              ? const SizedBox.shrink()
                              : _WinnerHero(
                                  winners: winners,
                                  useVerticalSingle: useVerticalSingle,
                                ),
                        ),
                        if (rest.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Expanded(
                            flex: listFlex,
                            child: _StandingsList(entries: rest),
                          ),
                        ],
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
  const _WinnerHero({required this.winners, required this.useVerticalSingle});

  final List<RankingEntry> winners;
  final bool useVerticalSingle;

  @override
  Widget build(BuildContext context) {
    final isTie = winners.length > 1;
    final score = winners.first.totalScore;

    return Container(
      decoration: BoxDecoration(
        color: ShareResultCard.brandGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: isTie
          ? _TieHeroContent(winners: winners, score: score)
          : _SingleWinnerContent(
              entry: winners.first,
              vertical: useVerticalSingle,
            ),
    );
  }
}

class _SingleWinnerContent extends StatelessWidget {
  const _SingleWinnerContent({required this.entry, required this.vertical});

  final RankingEntry entry;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return vertical
        ? _SingleWinnerVertical(entry: entry)
        : _SingleWinnerRow(entry: entry);
  }
}

class _SingleWinnerVertical extends StatelessWidget {
  const _SingleWinnerVertical({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.player.displayName;

    return KeyedSubtree(
      key: const Key('share_result_hero_vertical'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: ShareResultCard.trophyGold,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  _ShareInitialAvatar(
                    name: name,
                    colorIndex: entry.player.seatOrder,
                    radius: 32,
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 6),
                  Text(
                    name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(
                      fontFamily: ShareResultCard.brandFontFamily,
                      fontSize: 28,
                      color: Colors.white,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.totalScore} pts',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: ShareResultCard.brandFontFamily,
                      fontSize: 20,
                      color: ShareResultCard.trophyGold,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SingleWinnerRow extends StatelessWidget {
  const _SingleWinnerRow({required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.player.displayName;

    return KeyedSubtree(
      key: const Key('share_result_hero_row'),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_events,
            color: ShareResultCard.trophyGold,
            size: 36,
          ),
          const SizedBox(width: 12),
          _ShareInitialAvatar(
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
      ),
    );
  }
}

class _TieHeroContent extends StatelessWidget {
  const _TieHeroContent({required this.winners, required this.score});

  final List<RankingEntry> winners;
  final int score;

  @override
  Widget build(BuildContext context) {
    final compact = winners.length >= 4;
    // Compact chips sized to fit up to 4 per row in the 360-wide card.
    final avatarRadius = compact ? 14.0 : 22.0;
    final chipWidth = compact ? 62.0 : 96.0;
    final nameSize = compact ? 11.0 : 15.0;

    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: compact ? 6 : 12,
                        runSpacing: compact ? 8 : 10,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final entry in winners)
                            _TiedWinnerChip(
                              entry: entry,
                              avatarRadius: avatarRadius,
                              width: chipWidth,
                              nameSize: nameSize,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TiedWinnerChip extends StatelessWidget {
  const _TiedWinnerChip({
    required this.entry,
    required this.avatarRadius,
    required this.width,
    required this.nameSize,
  });

  final RankingEntry entry;
  final double avatarRadius;
  final double width;
  final double nameSize;

  @override
  Widget build(BuildContext context) {
    final name = entry.player.displayName;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ShareInitialAvatar(
            name: name,
            colorIndex: entry.player.seatOrder,
            radius: avatarRadius,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: ShareResultCard.brandFontFamily,
              fontSize: nameSize,
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
              _ShareInitialAvatar(
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

/// Initials avatar for the share capture tree.
///
/// Same color/initial rules as [PlayerInitialAvatar] via
/// [playerAvatarColorForIndex], with font size ~0.5× diameter so compact
/// rows keep the letter inside the circle.
class _ShareInitialAvatar extends StatelessWidget {
  const _ShareInitialAvatar({
    required this.name,
    required this.colorIndex,
    required this.radius,
  });

  final String name;
  final int colorIndex;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    final diameter = radius * 2;
    final inset = diameter * 0.18;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: playerAvatarColorForIndex(colorIndex),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              initial,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.0,
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
          ),
        ),
      ),
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
