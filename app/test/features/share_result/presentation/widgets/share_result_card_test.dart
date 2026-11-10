import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/presentation/widgets/share_result_card.dart';

PlayerEmbed _player(String id, String name, int score) {
  return PlayerEmbed(
    id: id,
    displayName: name,
    isGuest: true,
    userId: null,
    seatOrder: int.tryParse(id) ?? 0,
    totalScore: score,
    joinedAt: DateTime(2026, 1, 1),
  );
}

RankingEntry _entry({
  required String id,
  required String name,
  required int rank,
  required int score,
}) {
  return RankingEntry(
    player: _player(id, name, score),
    rank: rank,
    roundScore: 0,
    totalScore: score,
  );
}

ShareResultPayload _payload({
  required List<RankingEntry> ranking,
  DateTime? finishedAt,
  int? playerCount,
  int roundCount = 19,
}) {
  return ShareResultPayload(
    ranking: ranking,
    finishedAt: finishedAt,
    playerCount: playerCount ?? ranking.length,
    roundCount: roundCount,
  );
}

void main() {
  final sampleRanking = [
    _entry(id: '1', name: 'María', rank: 1, score: 245),
    _entry(id: '2', name: 'Juan', rank: 1, score: 245),
    _entry(id: '3', name: 'Ana', rank: 3, score: 180),
  ];

  testWidgets('omits date when finishedAt is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ShareResultCard(payload: _payload(ranking: sampleRanking)),
        ),
      ),
    );

    expect(find.byKey(const Key('share_result_date')), findsNothing);
    expect(find.textContaining('jugadores'), findsOneWidget);
  });

  testWidgets('shows formatted date when finishedAt is set', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ShareResultCard(
            payload: _payload(
              ranking: sampleRanking,
              finishedAt: DateTime(2026, 7, 4),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('share_result_date')), findsOneWidget);
    expect(find.text('4 jul 2026'), findsOneWidget);
  });

  testWidgets('paints RankingEntry.rank with ties 1º, 1º, 3º', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ShareResultCard(payload: _payload(ranking: sampleRanking)),
        ),
      ),
    );

    expect(find.text('1º'), findsNWidgets(2));
    expect(find.text('3º'), findsOneWidget);
    expect(find.text('2º'), findsNothing);
  });

  testWidgets('textScaler 3.0 and 1.0 produce the same card layout size', (
    tester,
  ) async {
    Future<Size> pumpWithScaler(double scale) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            home: Center(
              child: ShareResultCard(payload: _payload(ranking: sampleRanking)),
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getSize(find.byType(ShareResultCard));
    }

    final sizeAt1 = await pumpWithScaler(1.0);
    final sizeAt3 = await pumpWithScaler(3.0);

    expect(sizeAt1, ShareResultCard.logicalSize);
    expect(sizeAt3, sizeAt1);
  });

  testWidgets('fits 8 players with max-length names without overflow', (
    tester,
  ) async {
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') || message.contains('RenderFlex')) {
        fail(message);
      }
      FlutterError.presentError(details);
    };

    // App allows player names up to 20 characters.
    final ranking = [
      for (var i = 0; i < 8; i++)
        _entry(
          id: '$i',
          name: 'NombreLargoJugador$i'.padRight(20).substring(0, 20),
          rank: i < 2 ? 1 : i + 1,
          score: 300 - (i * 10),
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: ShareResultCard(
            payload: _payload(ranking: ranking, playerCount: 8),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('NombreLargoJugador'), findsWidgets);
  });
}
