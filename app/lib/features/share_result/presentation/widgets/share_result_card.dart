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
    final isTie = winners.length > 1;

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
                          child: _CardBody(
                            winners: winners,
                            rest: rest,
                            isTie: isTie,
                          ),
                        ),
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

/// Middle section: hero + optional standings with capped inter-block gaps.
///
/// Single-winner hero stays compact (row); leftover centers the list with
/// gaps ≤ [_maxBlockGap]. Tie heroes may expand to fill when the list is short.
class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.winners,
    required this.rest,
    required this.isTie,
  });

  static const double _maxBlockGap = 40;
  static const double _minBlockGap = 14;
  static const double _heroMinHeight = 88;

  /// Fixed single-winner hero band (matches previews 11/12).
  static const double _singleHeroHeight = 124;

  final List<RankingEntry> winners;
  final List<RankingEntry> rest;
  final bool isTie;

  @override
  Widget build(BuildContext context) {
    if (winners.isEmpty) {
      return const SizedBox.shrink();
    }

    final hero = _WinnerHero(
      winners: winners,
      // Fill height for all-tied and multi-ties with a short list.
      expandTieToFill: rest.isEmpty || isTie,
    );

    if (rest.isEmpty) {
      return hero;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final listAtMax = _StandingsList.intrinsicHeight(rest.length);
        final singleHeroBudget = isTie ? _heroMinHeight : _singleHeroHeight;
        final tight =
            listAtMax + _minBlockGap + singleHeroBudget > constraints.maxHeight;

        if (tight) {
          final heroFlex = isTie ? 5 : 3;
          final listFlex = rest.length >= 5 ? 5 : 3;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: heroFlex,
                child: isTie
                    ? hero
                    : LayoutBuilder(
                        builder: (context, heroConstraints) {
                          final h = _singleHeroHeight.clamp(
                            0.0,
                            heroConstraints.maxHeight,
                          );
                          return Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: h,
                              width: double.infinity,
                              child: hero,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: _minBlockGap),
              Expanded(
                flex: listFlex,
                child: _StandingsList(entries: rest, shrinkToFit: true),
              ),
            ],
          );
        }

        assert(_minBlockGap <= _maxBlockGap);

        // Fixed-height single-winner hero; center hero+list; gaps ≤ maxBlockGap.
        // Parent adds 12 dp before the footer — keep body bottom pad ≤ 28 so
        // the measured list→footer gap stays ≤ ~40.
        if (!isTie) {
          const heroH = _singleHeroHeight;
          const outerFooterGap = 12.0;
          final maxBottomPad = (_maxBlockGap - outerFooterGap).clamp(
            0.0,
            _maxBlockGap,
          );
          var midGap = _minBlockGap;
          var free = constraints.maxHeight - heroH - listAtMax - midGap;
          var topPad = 0.0;
          var bottomPad = 0.0;
          if (free > 0) {
            topPad = free / 2;
            bottomPad = free - topPad;
            if (topPad > _maxBlockGap || bottomPad > maxBottomPad) {
              topPad = topPad.clamp(0.0, _maxBlockGap);
              bottomPad = bottomPad.clamp(0.0, maxBottomPad);
              final consumed = topPad + bottomPad;
              final overflow = free - consumed;
              midGap = (_minBlockGap + overflow).clamp(
                _minBlockGap,
                _maxBlockGap,
              );
            }
            final used = topPad + heroH + midGap + listAtMax + bottomPad;
            final still = constraints.maxHeight - used;
            if (still > 0) {
              // Prefer extra space above the block over a tall bottom void.
              topPad += still;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: topPad),
              SizedBox(height: heroH, child: hero),
              SizedBox(height: midGap),
              SizedBox(
                height: listAtMax,
                child: _StandingsList(entries: rest),
              ),
              SizedBox(height: bottomPad),
            ],
          );
        }

        // Tie + short standings: hero absorbs leftover; fixed gap to list.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: hero),
            const SizedBox(height: _minBlockGap),
            SizedBox(
              height: listAtMax,
              child: _StandingsList(entries: rest),
            ),
          ],
        );
      },
    );
  }
}

class _WinnerHero extends StatelessWidget {
  const _WinnerHero({required this.winners, required this.expandTieToFill});

  final List<RankingEntry> winners;
  final bool expandTieToFill;

  @override
  Widget build(BuildContext context) {
    final isTie = winners.length > 1;
    final score = winners.first.totalScore;

    return Container(
      key: const Key('share_result_winner_card'),
      decoration: BoxDecoration(
        color: ShareResultCard.brandGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      // Matches [WinnerCard] padding; brand colors stay fixed (no Theme).
      padding: const EdgeInsets.all(16),
      child: isTie
          ? _TieHeroContent(
              winners: winners,
              score: score,
              expandToFill: expandTieToFill,
            )
          : _SingleWinnerRow(entry: winners.first),
    );
  }
}

/// Single-winner hero: Row like [WinnerCard], points pinned to the trailing edge.
class _SingleWinnerRow extends StatelessWidget {
  const _SingleWinnerRow({required this.entry});

  static const double _nameFontSize = 24;
  static const double _scoreFontSize = 22;
  static const double _minNameScale = 0.6;

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.player.displayName;

    return KeyedSubtree(
      key: const Key('share_result_hero_row'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final row = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events,
                color: ShareResultCard.trophyGold,
                size: 32,
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
                  mainAxisSize: MainAxisSize.min,
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
                    _WinnerDisplayName(
                      name: name,
                      fontSize: _nameFontSize,
                      minScale: _minNameScale,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.totalScore} pts',
                style: const TextStyle(
                  fontFamily: ShareResultCard.brandFontFamily,
                  fontSize: _scoreFontSize,
                  color: ShareResultCard.trophyGold,
                  height: 1.0,
                ),
              ),
            ],
          );

          // Scale the whole row when the hero band is shorter (long lists).
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(width: constraints.maxWidth, child: row),
          );
        },
      ),
    );
  }
}

/// Scales the winner name down to [minScale]; then up to 2 lines + ellipsis.
class _WinnerDisplayName extends StatelessWidget {
  const _WinnerDisplayName({
    required this.name,
    required this.fontSize,
    required this.minScale,
  });

  final String name;
  final double fontSize;
  final double minScale;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: ShareResultCard.brandFontFamily,
      fontSize: fontSize,
      color: Colors.white,
      height: 1.05,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final painter = TextPainter(
          text: TextSpan(text: name, style: baseStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
        )..layout();
        final natural = painter.width;

        if (natural <= maxW) {
          return Text(name, maxLines: 1, style: baseStyle);
        }

        final scale = (maxW / natural).clamp(0.0, 1.0);
        if (scale >= minScale) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(name, maxLines: 1, style: baseStyle),
          );
        }

        return Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: baseStyle.copyWith(fontSize: fontSize * minScale),
        );
      },
    );
  }
}

/// Layout metrics for multi-winner tie hero (sizes scale with available space).
class _TieLayoutMetrics {
  const _TieLayoutMetrics({
    required this.avatarDiameter,
    required this.chipWidth,
    required this.nameSize,
    required this.scoreSize,
    required this.labelSize,
    required this.trophySize,
    required this.gapAfterLabel,
    required this.gapBeforeScore,
    required this.spacing,
    required this.runSpacing,
    required this.maxPerRow,
  });

  final double avatarDiameter;
  final double chipWidth;
  final double nameSize;
  final double scoreSize;
  final double labelSize;
  final double trophySize;
  final double gapAfterLabel;
  final double gapBeforeScore;
  final double spacing;
  final double runSpacing;
  final int maxPerRow;

  double get avatarRadius => avatarDiameter / 2;

  /// Row lengths for multi-row ties: 5→3+2, 6→3+3, 7→4+3, 8→4+4.
  static List<int> rowCounts(int winnerCount) {
    assert(winnerCount >= 2);
    return switch (winnerCount) {
      5 => const [3, 2],
      6 => const [3, 3],
      7 => const [4, 3],
      8 => const [4, 4],
      _ => [winnerCount],
    };
  }

  /// Computes sizes so ≤4 winners stay on one row and 5–8 use balanced rows.
  static _TieLayoutMetrics compute({
    required int winnerCount,
    required double maxWidth,
    required double maxHeight,
  }) {
    assert(winnerCount >= 2);

    final counts = rowCounts(winnerCount);
    final maxPerRow = counts.reduce((a, b) => a > b ? a : b);
    final rows = counts.length;

    // Target diameter (logical) by case.
    final double targetMax;
    if (winnerCount <= 3) {
      targetMax = 58;
    } else if (winnerCount == 4) {
      targetMax = 60;
    } else {
      targetMax = 54; // 5–8: ~50–56
    }
    const targetMin = 28.0;

    final spacing = winnerCount <= 3 ? 14.0 : (winnerCount == 4 ? 10.0 : 8.0);
    final runSpacing = winnerCount <= 4 ? 12.0 : 14.0;

    // Full column share so names get width beyond the avatar circle.
    final chipWidth = ((maxWidth - spacing * (maxPerRow - 1)) / maxPerRow)
        .clamp(1.0, maxWidth);

    final diameterFromHeight = _diameterFromHeight(
      maxHeight: maxHeight,
      rows: rows,
      runSpacing: runSpacing,
    );

    // Avatar fills most of the chip, capped by case target and height budget.
    var diameter = [
      targetMax,
      chipWidth * 0.92,
      diameterFromHeight,
    ].reduce((a, b) => a < b ? a : b);
    diameter = diameter.clamp(targetMin, targetMax);

    final nameSize = (diameter * 0.34).clamp(13.0, 22.0);
    final scoreSize = (diameter * 0.40).clamp(18.0, 28.0);
    final labelSize = (diameter * 0.28).clamp(13.0, 18.0);
    final trophySize = (diameter * 0.50).clamp(26.0, 34.0);
    final gapAfterLabel = (diameter * 0.20).clamp(10.0, 16.0);
    final gapBeforeScore = (diameter * 0.20).clamp(10.0, 16.0);

    return _TieLayoutMetrics(
      avatarDiameter: diameter,
      chipWidth: chipWidth,
      nameSize: nameSize,
      scoreSize: scoreSize,
      labelSize: labelSize,
      trophySize: trophySize,
      gapAfterLabel: gapAfterLabel,
      gapBeforeScore: gapBeforeScore,
      spacing: spacing,
      runSpacing: runSpacing,
      maxPerRow: maxPerRow,
    );
  }

  static double _diameterFromHeight({
    required double maxHeight,
    required int rows,
    required double runSpacing,
  }) {
    // Keep the coefficient modest so all-tied heroes grow toward targetMax.
    final fixed = 28.0 + runSpacing * (rows - 1);
    final coef = 0.75 + rows * 1.28;
    if (coef <= 0 || maxHeight <= fixed) {
      return 28;
    }
    return (maxHeight - fixed) / coef;
  }
}

class _TieHeroContent extends StatelessWidget {
  const _TieHeroContent({
    required this.winners,
    required this.score,
    required this.expandToFill,
  });

  final List<RankingEntry> winners;
  final int score;
  final bool expandToFill;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Leave a little slack so the row never forces FittedBox to shrink.
        final usableWidth = constraints.maxWidth * 0.98;
        final metrics = _TieLayoutMetrics.compute(
          winnerCount: winners.length,
          maxWidth: usableWidth,
          maxHeight: constraints.maxHeight,
        );

        final label = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: ShareResultCard.trophyGold,
              size: metrics.trophySize,
            ),
            const SizedBox(width: 8),
            Text(
              'EMPATE',
              style: TextStyle(
                fontSize: metrics.labelSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: ShareResultCard.accentMint,
                height: 1.0,
              ),
            ),
          ],
        );
        final grid = _TieAvatarGrid(winners: winners, metrics: metrics);
        final points = Text(
          '$score pts',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: ShareResultCard.brandFontFamily,
            fontSize: metrics.scoreSize,
            color: ShareResultCard.trophyGold,
            height: 1.1,
          ),
        );

        final block = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            label,
            SizedBox(height: metrics.gapAfterLabel),
            grid,
            SizedBox(height: metrics.gapBeforeScore),
            points,
          ],
        );

        // Fill hero height: center the cohesive block; scale down if tight.
        if (expandToFill) {
          return KeyedSubtree(
            key: const Key('share_result_tie_hero'),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Flexible(
                    flex: 8,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: usableWidth),
                        child: block,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          );
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: usableWidth),
            child: KeyedSubtree(
              key: const Key('share_result_tie_hero'),
              child: block,
            ),
          ),
        );
      },
    );
  }
}

class _TieAvatarGrid extends StatelessWidget {
  const _TieAvatarGrid({required this.winners, required this.metrics});

  final List<RankingEntry> winners;
  final _TieLayoutMetrics metrics;

  List<Widget> _rowChildren(List<RankingEntry> entries) {
    return [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) SizedBox(width: metrics.spacing),
        _TiedWinnerChip(
          entry: entries[i],
          avatarRadius: metrics.avatarRadius,
          width: metrics.chipWidth,
          nameSize: metrics.nameSize,
          nameGap: metrics.avatarDiameter * 0.12,
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final counts = _TieLayoutMetrics.rowCounts(winners.length);

    // ≤4: one centered row (avoids Wrap turning 3 into 2+1).
    if (counts.length == 1) {
      return Row(
        key: const Key('share_result_tie_single_row'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: _rowChildren(winners),
      );
    }

    // 5–8: balanced rows (3+2, 3+3, 4+3, 4+4).
    final rows = <Widget>[];
    var offset = 0;
    for (var r = 0; r < counts.length; r++) {
      final n = counts[r];
      final slice = winners.sublist(offset, offset + n);
      offset += n;
      if (rows.isNotEmpty) {
        rows.add(SizedBox(height: metrics.runSpacing));
      }
      rows.add(
        Row(
          key: Key('share_result_tie_row_${r}_$n'),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: _rowChildren(slice),
        ),
      );
    }

    return Column(
      key: const Key('share_result_tie_wrap'),
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }
}

class _TiedWinnerChip extends StatelessWidget {
  const _TiedWinnerChip({
    required this.entry,
    required this.avatarRadius,
    required this.width,
    required this.nameSize,
    required this.nameGap,
  });

  final RankingEntry entry;
  final double avatarRadius;
  final double width;
  final double nameSize;
  final double nameGap;

  /// Scale names down to this factor before falling back to ellipsis.
  static const double _minNameScale = 0.6;

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
          SizedBox(height: nameGap),
          _ScaledEllipsisName(
            name: name,
            width: width,
            fontSize: nameSize,
            minScale: _minNameScale,
          ),
        ],
      ),
    );
  }
}

/// Scales [name] down with [FittedBox] semantics to [minScale], then ellipsis.
class _ScaledEllipsisName extends StatelessWidget {
  const _ScaledEllipsisName({
    required this.name,
    required this.width,
    required this.fontSize,
    required this.minScale,
  });

  final String name;
  final double width;
  final double fontSize;
  final double minScale;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontFamily: ShareResultCard.brandFontFamily,
      fontSize: fontSize,
      color: Colors.white,
      height: 1.1,
    );

    return SizedBox(
      width: width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final painter = TextPainter(
            text: TextSpan(text: name, style: baseStyle),
            maxLines: 1,
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.noScaling,
          )..layout();
          final natural = painter.width;

          if (natural <= maxW) {
            return Text(
              name,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: baseStyle,
            );
          }

          final scale = (maxW / natural).clamp(0.0, 1.0);
          if (scale >= minScale) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: baseStyle,
              ),
            );
          }

          return Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: baseStyle.copyWith(fontSize: fontSize * minScale),
          );
        },
      ),
    );
  }
}

class _StandingsList extends StatelessWidget {
  const _StandingsList({required this.entries, this.shrinkToFit = false});

  static const double rowMaxHeight = 48;
  static const double dividerHeight = 1;

  final List<RankingEntry> entries;
  final bool shrinkToFit;

  static double intrinsicHeight(int count) {
    if (count <= 0) {
      return 0;
    }
    return count * rowMaxHeight + (count - 1) * dividerHeight;
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('share_result_standings'),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(
                height: dividerHeight,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            if (shrinkToFit)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: rowMaxHeight),
                    child: _StandingRow(entry: entries[i]),
                  ),
                ),
              )
            else
              SizedBox(
                height: rowMaxHeight,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StandingRow(entry: entries[i]),
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
