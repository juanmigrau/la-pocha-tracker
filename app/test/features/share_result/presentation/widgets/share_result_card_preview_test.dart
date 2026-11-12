@Tags(['preview'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/presentation/services/share_result_image_renderer_impl.dart';

const Object _defaultFinishedAt = Object();

/// Opt-in: excluded from default `flutter test` unless SHARE_PREVIEWS=true.
const bool _previewsEnabled = bool.fromEnvironment(
  'SHARE_PREVIEWS',
  defaultValue: false,
);

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
  Object? finishedAt = _defaultFinishedAt,
  int? playerCount,
  int roundCount = 3,
}) {
  final DateTime? resolvedFinishedAt = identical(finishedAt, _defaultFinishedAt)
      ? DateTime(2024, 11, 12)
      : finishedAt as DateTime?;
  return ShareResultPayload(
    ranking: ranking,
    finishedAt: resolvedFinishedAt,
    playerCount: playerCount ?? ranking.length,
    roundCount: roundCount,
  );
}

String _longName(int i) => 'NombreLargoJugador$i'.padRight(20).substring(0, 20);

Future<ByteData> _loadFontBytes(String absolutePath) async {
  final bytes = await File(absolutePath).readAsBytes();
  return ByteData.sublistView(Uint8List.fromList(bytes));
}

Future<void> _loadPreviewFonts() async {
  final lilita = FontLoader('LilitaOne')
    ..addFont(rootBundle.load('assets/fonts/LilitaOne-Regular.ttf'));
  await lilita.load();

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    fail('FLUTTER_ROOT is required to load preview fonts');
  }
  final fontsDir = [
    flutterRoot,
    'bin',
    'cache',
    'artifacts',
    'material_fonts',
  ].join(Platform.pathSeparator);

  final robotoData = await _loadFontBytes(
    '$fontsDir${Platform.pathSeparator}roboto-regular.ttf',
  );
  await (FontLoader('Roboto')..addFont(Future.value(robotoData))).load();
  await (FontLoader('Ahem')..addFont(Future.value(robotoData))).load();

  final iconsData = await _loadFontBytes(
    '$fontsDir${Platform.pathSeparator}materialicons-regular.otf',
  );
  await (FontLoader('MaterialIcons')..addFont(Future.value(iconsData))).load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory previewDir;

  setUpAll(() async {
    if (!_previewsEnabled) {
      return;
    }
    await _loadPreviewFonts();
    previewDir = Directory(
      [
        Directory.current.path,
        'build',
        'share_previews',
      ].join(Platform.pathSeparator),
    );
    if (previewDir.existsSync()) {
      previewDir.deleteSync(recursive: true);
    }
    previewDir.createSync(recursive: true);
  });

  Future<void> renderPreview({
    required String fileName,
    required ShareResultPayload payload,
  }) async {
    final renderer = ShareResultImageRendererImpl(
      getTemporaryDirectoryFn: () async => previewDir,
      fileName: fileName,
    );
    final path = await renderer.renderPngFile(payload);
    final file = File(path);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  }

  test(
    'generates share card PNG previews for visual review',
    () async {
      await renderPreview(
        fileName: '01_three_players.png',
        payload: _payload(
          ranking: [
            _entry(id: '0', name: 'María', rank: 1, score: 40),
            _entry(id: '1', name: 'Juan', rank: 2, score: 22),
            _entry(id: '2', name: 'Ana', rank: 3, score: 10),
          ],
        ),
      );

      await renderPreview(
        fileName: '02_four_players_capture.png',
        payload: _payload(
          ranking: [
            _entry(id: '0', name: 'tt', rank: 1, score: 35, seatOrder: 0),
            _entry(id: '1', name: 'Juanmi', rank: 2, score: 20, seatOrder: 1),
            _entry(id: '2', name: 'pp', rank: 3, score: 15, seatOrder: 2),
            _entry(id: '3', name: 'kk', rank: 3, score: 15, seatOrder: 3),
          ],
        ),
      );

      await renderPreview(
        fileName: '03_first_place_tie.png',
        payload: _payload(
          ranking: [
            _entry(id: '0', name: 'María', rank: 1, score: 245),
            _entry(id: '1', name: 'Juan', rank: 1, score: 245),
            _entry(id: '2', name: 'Ana', rank: 3, score: 180),
            _entry(id: '3', name: 'Luis', rank: 4, score: 90),
          ],
        ),
      );

      await renderPreview(
        fileName: '04_eight_long_names.png',
        payload: _payload(
          ranking: [
            for (var i = 0; i < 8; i++)
              _entry(
                id: '$i',
                name: _longName(i),
                rank: i + 1,
                score: 300 - (i * 10),
              ),
          ],
          playerCount: 8,
          roundCount: 19,
        ),
      );

      await renderPreview(
        fileName: '05_negative_scores.png',
        payload: _payload(
          ranking: [
            _entry(id: '0', name: 'Top', rank: 1, score: 8),
            _entry(id: '1', name: 'Mid', rank: 2, score: -3),
            _entry(id: '2', name: 'Low', rank: 3, score: -21),
          ],
        ),
      );

      await renderPreview(
        fileName: '06_no_date.png',
        payload: _payload(
          ranking: [
            _entry(id: '0', name: 'tt', rank: 1, score: 35),
            _entry(id: '1', name: 'Juanmi', rank: 2, score: 20),
            _entry(id: '2', name: 'pp', rank: 3, score: 15),
          ],
          finishedAt: null,
        ),
      );

      await renderPreview(
        fileName: '07_tie_two_long_names.png',
        payload: _payload(
          ranking: [
            _entry(id: '0', name: _longName(0), rank: 1, score: 200),
            _entry(id: '1', name: _longName(1), rank: 1, score: 200),
            _entry(id: '2', name: 'Ana', rank: 3, score: 90),
            _entry(id: '3', name: 'Luis', rank: 4, score: 40),
          ],
        ),
      );

      await renderPreview(
        fileName: '08_tie_three_of_five.png',
        payload: _payload(
          ranking: [
            _entry(id: '0', name: 'María', rank: 1, score: 100),
            _entry(id: '1', name: 'Juan', rank: 1, score: 100),
            _entry(id: '2', name: 'Ana', rank: 1, score: 100),
            _entry(id: '3', name: 'Luis', rank: 4, score: 40),
            _entry(id: '4', name: 'Eva', rank: 5, score: 20),
          ],
        ),
      );

      await renderPreview(
        fileName: '09_all_four_tied.png',
        payload: _payload(
          ranking: [
            for (var i = 0; i < 4; i++)
              _entry(id: '$i', name: 'Jugador$i', rank: 1, score: 15),
          ],
        ),
      );

      await renderPreview(
        fileName: '10_all_eight_tied.png',
        payload: _payload(
          ranking: [
            for (var i = 0; i < 8; i++)
              _entry(id: '$i', name: 'Empate$i', rank: 1, score: 12),
          ],
          roundCount: 19,
        ),
      );

      await renderPreview(
        fileName: '11_five_vertical_winner.png',
        payload: _payload(
          ranking: [
            for (var i = 0; i < 5; i++)
              _entry(
                id: '$i',
                name: 'Jugador$i',
                rank: i + 1,
                score: 50 - i * 5,
              ),
          ],
        ),
      );

      await renderPreview(
        fileName: '12_six_row_winner.png',
        payload: _payload(
          ranking: [
            for (var i = 0; i < 6; i++)
              _entry(
                id: '$i',
                name: 'Jugador$i',
                rank: i + 1,
                score: 60 - i * 5,
              ),
          ],
        ),
      );

      final files = previewDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList();
      expect(files, hasLength(12));
      // ignore: avoid_print
      print('Share previews written to: ${previewDir.path}');
    },
    skip: _previewsEnabled
        ? false
        : 'Opt-in previews: flutter test --dart-define=SHARE_PREVIEWS=true '
              '--tags preview '
              'test/features/share_result/presentation/widgets/'
              'share_result_card_preview_test.dart',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
