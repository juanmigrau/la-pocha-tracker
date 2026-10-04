import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';

void main() {
  final joinedAt = DateTime(2026, 3, 15, 12);

  group('PlayerEmbed serialization', () {
    test('toJson/fromJson round-trips including photoURL and localUserId', () {
      final player = PlayerEmbed(
        id: 'p1',
        displayName: 'Ana',
        isGuest: false,
        userId: 'uid-1',
        seatOrder: 0,
        totalScore: 12,
        joinedAt: joinedAt,
        photoURL: 'https://example.com/ana.jpg',
        localUserId: 'local-1',
      );

      final restored = PlayerEmbed.fromJson(player.toJson());

      expect(restored, player);
      expect(restored.photoURL, 'https://example.com/ana.jpg');
      expect(restored.localUserId, 'local-1');
    });

    test('fromJson treats missing photoURL and localUserId as null', () {
      final restored = PlayerEmbed.fromJson({
        'id': 'p1',
        'displayName': 'Ana',
        'isGuest': true,
        'userId': null,
        'seatOrder': 0,
        'totalScore': 0,
        'joinedAt': joinedAt.toIso8601String(),
      });

      expect(restored.photoURL, isNull);
      expect(restored.localUserId, isNull);
      expect(restored.displayName, 'Ana');
    });

    test('toJson includes null photoURL and localUserId', () {
      final player = PlayerEmbed(
        id: 'p1',
        displayName: 'Guest',
        isGuest: true,
        userId: null,
        seatOrder: 1,
        totalScore: 0,
        joinedAt: joinedAt,
      );

      expect(player.toJson()['photoURL'], isNull);
      expect(player.toJson()['localUserId'], isNull);
    });
  });
}
