import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/presentation/widgets/share_result_card.dart';

PlayerEmbed _player(String id, String name, int score, {int? seatOrder}) {
  return PlayerEmbed(
    id: id,
    displayName: name,
    isGuest: true,
    userId: null,
    seatOrder: seatOrder ?? (int.tryParse(id) ?? 0),
    totalScore: score,
    joinedAt: DateTime(2026, 1, 1),
  );
}

RankingEntry _entry({
  required String id,
  required String name,
  required int rank,
  required int score,
  int? seatOrder,
}) {
  return RankingEntry(
    player: _player(id, name, score, seatOrder: seatOrder),
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

Future<void> _pumpCard(WidgetTester tester, ShareResultPayload payload) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(child: ShareResultCard(payload: payload)),
    ),
  );
  await tester.pump();
}

void _failOnOverflow() {
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('overflowed') || message.contains('RenderFlex')) {
      fail(message);
    }
    FlutterError.presentError(details);
  };
}

void main() {
  final sampleRanking = [
    _entry(id: '1', name: 'María', rank: 1, score: 245),
    _entry(id: '2', name: 'Juan', rank: 1, score: 245),
    _entry(id: '3', name: 'Ana', rank: 3, score: 180),
  ];

  testWidgets('omits date when finishedAt is null', (tester) async {
    await _pumpCard(tester, _payload(ranking: sampleRanking));

    expect(find.byKey(const Key('share_result_date')), findsNothing);
    expect(find.textContaining('jugadores'), findsOneWidget);
  });

  testWidgets('shows formatted date when finishedAt is set', (tester) async {
    await _pumpCard(
      tester,
      _payload(ranking: sampleRanking, finishedAt: DateTime(2026, 7, 4)),
    );

    expect(find.byKey(const Key('share_result_date')), findsOneWidget);
    expect(find.textContaining('4 jul 2026'), findsOneWidget);
  });

  testWidgets('first-place tie shows EMPATE hero and rest of ranking only', (
    tester,
  ) async {
    await _pumpCard(tester, _payload(ranking: sampleRanking));

    expect(find.text('EMPATE'), findsOneWidget);
    expect(find.text('GANADOR'), findsNothing);
    expect(find.text('María'), findsOneWidget);
    expect(find.text('Juan'), findsOneWidget);
    expect(find.text('1'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('three-way first-place tie shows all winners and rest list', (
    tester,
  ) async {
    _failOnOverflow();
    final ranking = [
      _entry(id: '0', name: 'María', rank: 1, score: 100),
      _entry(id: '1', name: 'Juan', rank: 1, score: 100),
      _entry(id: '2', name: 'Ana', rank: 1, score: 100),
      _entry(id: '3', name: 'Luis', rank: 4, score: 40),
      _entry(id: '4', name: 'Eva', rank: 5, score: 20),
    ];

    await _pumpCard(tester, _payload(ranking: ranking));

    expect(find.text('EMPATE'), findsOneWidget);
    expect(find.text('María'), findsOneWidget);
    expect(find.text('Juan'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.textContaining('100 pts'), findsOneWidget);
    expect(find.byKey(const Key('share_result_standings')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single winner shows GANADOR and excludes them from list', (
    tester,
  ) async {
    final ranking = [
      _entry(id: '1', name: 'tt', rank: 1, score: 35),
      _entry(id: '2', name: 'Juanmi', rank: 2, score: 20),
      _entry(id: '3', name: 'pp', rank: 3, score: 15),
      _entry(id: '4', name: 'kk', rank: 3, score: 15),
    ];

    await _pumpCard(tester, _payload(ranking: ranking, roundCount: 3));

    expect(find.text('GANADOR'), findsOneWidget);
    expect(find.text('EMPATE'), findsNothing);
    expect(find.text('tt'), findsOneWidget);
    expect(find.textContaining('35 pts'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets('five players use vertical single-winner hero without overflow', (
    tester,
  ) async {
    _failOnOverflow();
    final ranking = [
      for (var i = 0; i < 5; i++)
        _entry(id: '$i', name: 'Jugador$i', rank: i + 1, score: 50 - i * 5),
    ];

    await _pumpCard(tester, _payload(ranking: ranking));

    expect(find.byKey(const Key('share_result_hero_vertical')), findsOneWidget);
    expect(find.byKey(const Key('share_result_hero_row')), findsNothing);
    expect(find.text('GANADOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('six players use row single-winner hero without overflow', (
    tester,
  ) async {
    _failOnOverflow();
    final ranking = [
      for (var i = 0; i < 6; i++)
        _entry(id: '$i', name: 'Jugador$i', rank: i + 1, score: 60 - i * 5),
    ];

    await _pumpCard(tester, _payload(ranking: ranking));

    expect(find.byKey(const Key('share_result_hero_row')), findsOneWidget);
    expect(find.byKey(const Key('share_result_hero_vertical')), findsNothing);
    expect(find.text('GANADOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('third-place tie paints two rows with rank 3', (tester) async {
    final ranking = [
      _entry(id: '1', name: 'tt', rank: 1, score: 35),
      _entry(id: '2', name: 'Juanmi', rank: 2, score: 20),
      _entry(id: '3', name: 'pp', rank: 3, score: 15),
      _entry(id: '4', name: 'kk', rank: 3, score: 15),
    ];

    await _pumpCard(tester, _payload(ranking: ranking));

    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets('all tied for first omits standings list', (tester) async {
    final ranking = [
      _entry(id: '1', name: 'Alex', rank: 1, score: 10),
      _entry(id: '2', name: 'Bea', rank: 1, score: 10),
      _entry(id: '3', name: 'Cris', rank: 1, score: 10),
    ];

    await _pumpCard(tester, _payload(ranking: ranking));

    expect(find.text('EMPATE'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Bea'), findsOneWidget);
    expect(find.text('Cris'), findsOneWidget);
    expect(find.byKey(const Key('share_result_standings')), findsNothing);
  });

  testWidgets('all eight tied omits standings without overflow', (
    tester,
  ) async {
    _failOnOverflow();
    final ranking = [
      for (var i = 0; i < 8; i++)
        _entry(id: '$i', name: 'Empate$i', rank: 1, score: 12),
    ];

    await _pumpCard(tester, _payload(ranking: ranking));

    expect(find.text('EMPATE'), findsOneWidget);
    expect(find.byKey(const Key('share_result_standings')), findsNothing);
    expect(find.textContaining('12 pts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows negative scores as-is', (tester) async {
    final ranking = [
      _entry(id: '1', name: 'Top', rank: 1, score: 5),
      _entry(id: '2', name: 'Low', rank: 2, score: -12),
    ];

    await _pumpCard(tester, _payload(ranking: ranking));

    expect(find.textContaining('5 pts'), findsOneWidget);
    expect(find.text('-12'), findsOneWidget);
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
    _failOnOverflow();

    final ranking = [
      for (var i = 0; i < 8; i++)
        _entry(
          id: '$i',
          name: 'NombreLargoJugador$i'.padRight(20).substring(0, 20),
          rank: i + 1,
          score: 300 - (i * 10),
        ),
    ];

    await _pumpCard(tester, _payload(ranking: ranking, playerCount: 8));

    expect(tester.takeException(), isNull);
    expect(find.text('GANADOR'), findsOneWidget);
    expect(find.byKey(const Key('share_result_hero_row')), findsOneWidget);
    expect(find.byKey(const Key('share_result_standings')), findsOneWidget);
    expect(find.textContaining('NombreLargoJugador'), findsWidgets);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });
}
