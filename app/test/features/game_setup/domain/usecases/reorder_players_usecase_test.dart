import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/game_setup/domain/usecases/reorder_players_usecase.dart';

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
  const useCase = ReorderPlayersUseCase();

  late List<PlayerEmbed> players;

  setUp(() {
    players = [
      _player('a', 1),
      _player('b', 2),
      _player('c', 3),
      _player('d', 4),
    ];
  });

  group('happy path', () {
    test('moves a player forward and renumbers seatOrder from 1', () {
      final result = useCase(players: players, oldIndex: 0, newIndex: 2);

      expect(result.map((p) => p.id), ['b', 'c', 'a', 'd']);
      expect(result.map((p) => p.seatOrder), [1, 2, 3, 4]);
    });

    test('moves a player backward and renumbers seatOrder from 1', () {
      final result = useCase(players: players, oldIndex: 3, newIndex: 1);

      expect(result.map((p) => p.id), ['a', 'd', 'b', 'c']);
      expect(result.map((p) => p.seatOrder), [1, 2, 3, 4]);
    });

    test('keeps the order when oldIndex equals newIndex', () {
      final result = useCase(players: players, oldIndex: 1, newIndex: 1);

      expect(result.map((p) => p.id), ['a', 'b', 'c', 'd']);
      expect(result.map((p) => p.seatOrder), [1, 2, 3, 4]);
    });

    test('does not mutate the input list', () {
      useCase(players: players, oldIndex: 0, newIndex: 3);

      expect(players.map((p) => p.id), ['a', 'b', 'c', 'd']);
      expect(players.map((p) => p.seatOrder), [1, 2, 3, 4]);
    });
  });

  group('edge cases', () {
    test('single player list with index 0 -> 0 is a valid no-op', () {
      final result = useCase(
        players: [_player('solo', 5)],
        oldIndex: 0,
        newIndex: 0,
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'solo');
      expect(result.first.seatOrder, 1);
    });

    test('throws RangeError when oldIndex is negative', () {
      expect(
        () => useCase(players: players, oldIndex: -1, newIndex: 1),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError when oldIndex is out of range', () {
      expect(
        () => useCase(players: players, oldIndex: 4, newIndex: 1),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError when newIndex is negative', () {
      expect(
        () => useCase(players: players, oldIndex: 1, newIndex: -1),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError when newIndex is out of range', () {
      expect(
        () => useCase(players: players, oldIndex: 1, newIndex: 4),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError for a single player with index 1', () {
      expect(
        () => useCase(
          players: [_player('solo', 1)],
          oldIndex: 0,
          newIndex: 1,
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('throws RangeError for an empty list', () {
      expect(
        () => useCase(players: const [], oldIndex: 0, newIndex: 0),
        throwsA(isA<RangeError>()),
      );
    });
  });
}
