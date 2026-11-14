import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/presentation/widgets/share_result_card.dart';

ShareResultPayload _minimalPayload() {
  return ShareResultPayload(
    ranking: [
      RankingEntry(
        player: PlayerEmbed(
          id: '1',
          displayName: 'María',
          isGuest: true,
          userId: null,
          seatOrder: 0,
          totalScore: 245,
          joinedAt: DateTime(2026, 1, 1),
        ),
        rank: 1,
        roundScore: 0,
        totalScore: 245,
      ),
    ],
    finishedAt: DateTime(2026, 7, 4),
    playerCount: 1,
    roundCount: 19,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'spike: card via RepaintBoundary yields non-empty 1080x1350 PNG',
    (tester) async {
      final key = GlobalKey();
      await tester.binding.setSurfaceSize(ShareResultCard.logicalSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: key,
              child: ShareResultCard(payload: _minimalPayload()),
            ),
          ),
        ),
      );
      // Avoid pumpAndSettle: Image.asset can keep scheduling frames.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

      late final ui.Image image;
      late final ByteData? byteData;
      await tester.runAsync(() async {
        image = await boundary.toImage(pixelRatio: 3.0);
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      });

      expect(byteData, isNotNull);
      expect(byteData!.lengthInBytes, greaterThan(0));
      expect(image.width, 1080);
      expect(image.height, 1350);
      image.dispose();
    },
  );
}
