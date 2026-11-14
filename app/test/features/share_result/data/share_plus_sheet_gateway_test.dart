import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/share_result/data/share_plus_sheet_gateway.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_origin.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_outcome.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  test('maps success to ShareOutcome.shared', () async {
    late ShareParams captured;
    final gateway = SharePlusSheetGateway(
      share: (params) async {
        captured = params;
        return const ShareResult('ok', ShareResultStatus.success);
      },
    );

    final outcome = await gateway.shareImage(
      filePath: '/tmp/la_pocha_share_result.png',
      caption: 'La Pocha: gana María con 245 pts',
      origin: const ShareOrigin(x: 1, y: 2, width: 3, height: 4),
    );

    expect(outcome, ShareOutcome.shared);
    expect(captured.text, 'La Pocha: gana María con 245 pts');
    expect(captured.files, isNotNull);
    expect(captured.files!.single.path, '/tmp/la_pocha_share_result.png');
    expect(captured.sharePositionOrigin, const Rect.fromLTWH(1, 2, 3, 4));
  });

  test('maps dismissed to ShareOutcome.dismissed', () async {
    final gateway = SharePlusSheetGateway(
      share: (_) async => const ShareResult('', ShareResultStatus.dismissed),
    );

    final outcome = await gateway.shareImage(
      filePath: '/tmp/la_pocha_share_result.png',
      caption: 'caption',
    );

    expect(outcome, ShareOutcome.dismissed);
  });

  test('maps unavailable to ShareOutcome.unavailable', () async {
    final gateway = SharePlusSheetGateway(
      share: (_) async => const ShareResult('', ShareResultStatus.unavailable),
    );

    final outcome = await gateway.shareImage(
      filePath: '/tmp/la_pocha_share_result.png',
      caption: 'caption',
    );

    expect(outcome, ShareOutcome.unavailable);
  });

  test('omits sharePositionOrigin when origin is null', () async {
    late ShareParams captured;
    final gateway = SharePlusSheetGateway(
      share: (params) async {
        captured = params;
        return const ShareResult('', ShareResultStatus.unavailable);
      },
    );

    await gateway.shareImage(
      filePath: '/tmp/la_pocha_share_result.png',
      caption: 'caption',
    );

    expect(captured.sharePositionOrigin, isNull);
  });
}
