import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:la_pocha/core/utils/player_colors.dart';
import 'package:la_pocha/features/round/domain/entities/game_stats.dart';

class GameProgressChart extends StatelessWidget {
  const GameProgressChart({
    super.key,
    required this.stats,
    required this.cardsByRoundNumber,
  });

  final GameStats stats;

  /// Maps roundNumber → cardsInRound for X-axis labels.
  final Map<int, int> cardsByRoundNumber;

  static const String emptyMessage =
      'Juega más rondas para ver la evolución';

  @override
  Widget build(BuildContext context) {
    if (stats.closedRoundCount < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final series = stats.progressSeries;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 1,
                maxX: stats.closedRoundCount.toDouble(),
                minY: _minScore(series).toDouble() - 5,
                maxY: _maxScore(series).toDouble() + 5,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value != value.roundToDouble()) {
                          return const SizedBox.shrink();
                        }
                        final roundNumber = value.toInt();
                        final cards = cardsByRoundNumber[roundNumber];
                        return Text(
                          cards?.toString() ?? '$roundNumber',
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: true),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final s = series[spot.barIndex];
                        final point = s.points[spot.spotIndex];
                        final cards =
                            cardsByRoundNumber[point.roundNumber];
                        return LineTooltipItem(
                          '${s.displayName}\n'
                          'Ronda ${point.roundNumber}'
                          '${cards != null ? ' · $cards cartas' : ''}\n'
                          'Puntos: ${point.cumulativeScore}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  for (var i = 0; i < series.length; i++)
                    LineChartBarData(
                      spots: [
                        for (final point in series[i].points)
                          FlSpot(
                            point.roundNumber.toDouble(),
                            point.cumulativeScore.toDouble(),
                          ),
                      ],
                      isCurved: false,
                      color: playerAvatarColorForIndex(series[i].seatOrder),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _Legend(series: series),
        ],
      ),
    );
  }

  int _minScore(List<PlayerProgressSeries> series) {
    var min = series.first.points.first.cumulativeScore;
    for (final s in series) {
      for (final p in s.points) {
        if (p.cumulativeScore < min) min = p.cumulativeScore;
      }
    }
    return min;
  }

  int _maxScore(List<PlayerProgressSeries> series) {
    var max = series.first.points.first.cumulativeScore;
    for (final s in series) {
      for (final p in s.points) {
        if (p.cumulativeScore > max) max = p.cumulativeScore;
      }
    }
    return max;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.series});

  final List<PlayerProgressSeries> series;

  @override
  Widget build(BuildContext context) {
    final useInitialOnly = series.length >= 6;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (final s in series)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: playerAvatarColorForIndex(s.seatOrder),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                useInitialOnly
                    ? _initial(s.displayName)
                    : s.displayName,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
      ],
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}
