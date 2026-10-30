import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/set_first_dealer_usecase.dart';

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
  const useCase = SetFirstDealerUseCase();

  final players = [_player('p1', 1), _player('p2', 2), _player('p3', 3)];

  test('returns the player id when it exists in the roster', () {
    expect(useCase(players: players, playerId: 'p2'), 'p2');
  });

  test('accepts the first and the last player of the roster', () {
    expect(useCase(players: players, playerId: 'p1'), 'p1');
    expect(useCase(players: players, playerId: 'p3'), 'p3');
  });

  test('throws ArgumentError when playerId is not in the roster', () {
    expect(
      () => useCase(players: players, playerId: 'unknown'),
      throwsA(
        isA<ArgumentError>().having((e) => e.name, 'name', 'playerId'),
      ),
    );
  });

  test('throws ArgumentError when the roster is empty', () {
    expect(
      () => useCase(players: const [], playerId: 'p1'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
