import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/randomize_first_dealer_usecase.dart';
import 'package:mocktail/mocktail.dart';

class _MockRandom extends Mock implements Random {}

PlayerEmbed _player(String id, int seatOrder) => PlayerEmbed(
      id: id,
      displayName: 'Player $id',
      isGuest: true,
      userId: null,
      seatOrder: seatOrder,
      totalScore: 0,
      joinedAt: DateTime(2026),
    );

void main() {
  late _MockRandom random;
  late RandomizeFirstDealerUseCase useCase;

  final players = [_player('p1', 1), _player('p2', 2), _player('p3', 3)];

  setUp(() {
    random = _MockRandom();
    useCase = RandomizeFirstDealerUseCase(random: random);
  });

  test('returns the id of the player at the random index', () {
    when(() => random.nextInt(3)).thenReturn(1);

    final dealerId = useCase(players: players);

    expect(dealerId, 'p2');
    verify(() => random.nextInt(3)).called(1);
  });

  test('returns the only player when the roster has one player', () {
    when(() => random.nextInt(1)).thenReturn(0);

    final dealerId = useCase(players: [_player('solo', 1)]);

    expect(dealerId, 'solo');
  });

  test('always returns an id that belongs to the roster (real Random)', () {
    final realUseCase = RandomizeFirstDealerUseCase(random: Random(42));
    final ids = players.map((p) => p.id).toSet();

    for (var i = 0; i < 50; i++) {
      expect(ids, contains(realUseCase(players: players)));
    }
  });

  test('throws ArgumentError when the players list is empty', () {
    expect(
      () => useCase(players: const []),
      throwsA(isA<ArgumentError>()),
    );
    verifyNever(() => random.nextInt(any()));
  });
}
