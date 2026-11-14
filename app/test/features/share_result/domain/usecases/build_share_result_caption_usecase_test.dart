import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/ranking_entry.dart';
import 'package:la_pocha/features/share_result/domain/entities/share_result_payload.dart';
import 'package:la_pocha/features/share_result/domain/usecases/build_share_result_caption_usecase.dart';

PlayerEmbed _player(String id, String name, int score) {
  return PlayerEmbed(
    id: id,
    displayName: name,
    isGuest: true,
    userId: null,
    seatOrder: 0,
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

ShareResultPayload _payload(List<RankingEntry> ranking) {
  return ShareResultPayload(
    ranking: ranking,
    finishedAt: DateTime(2026, 7, 4),
    playerCount: ranking.length,
    roundCount: 19,
  );
}

void main() {
  const useCase = BuildShareResultCaptionUseCase();

  test('single winner caption', () {
    final caption = useCase(
      _payload([
        _entry(id: '1', name: 'María', rank: 1, score: 245),
        _entry(id: '2', name: 'Juan', rank: 2, score: 200),
      ]),
    );

    expect(caption, 'La Pocha: gana María con 245 pts');
  });

  test('two or more tied for first caption', () {
    final caption = useCase(
      _payload([
        _entry(id: '1', name: 'María', rank: 1, score: 245),
        _entry(id: '2', name: 'Juan', rank: 1, score: 245),
        _entry(id: '3', name: 'Ana', rank: 3, score: 180),
      ]),
    );

    expect(caption, 'La Pocha: empatan María y Juan con 245 pts');
  });

  test('three tied for first joins names with commas and y', () {
    final caption = useCase(
      _payload([
        _entry(id: '1', name: 'María', rank: 1, score: 245),
        _entry(id: '2', name: 'Juan', rank: 1, score: 245),
        _entry(id: '3', name: 'Ana', rank: 1, score: 245),
        _entry(id: '4', name: 'Luis', rank: 4, score: 100),
      ]),
    );

    expect(caption, 'La Pocha: empatan María, Juan y Ana con 245 pts');
  });

  test('all players tied caption', () {
    final caption = useCase(
      _payload([
        _entry(id: '1', name: 'María', rank: 1, score: 245),
        _entry(id: '2', name: 'Juan', rank: 1, score: 245),
        _entry(id: '3', name: 'Ana', rank: 1, score: 245),
      ]),
    );

    expect(caption, 'La Pocha: empate a 245 pts');
  });

  test('empty ranking is rejected', () {
    expect(() => useCase(_payload(const [])), throwsA(isA<ArgumentError>()));
  });

  test('negative scores appear as-is', () {
    final caption = useCase(
      _payload([
        _entry(id: '1', name: 'María', rank: 1, score: -10),
        _entry(id: '2', name: 'Juan', rank: 2, score: -20),
      ]),
    );

    expect(caption, 'La Pocha: gana María con -10 pts');
  });
}
