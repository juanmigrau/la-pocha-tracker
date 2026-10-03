import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/utils/player_display_name.dart';

void main() {
  group('resolveDisplayName', () {
    test('returns current display name when stored user matches current user', () {
      expect(
        resolveDisplayName(
          storedName: 'OldName',
          storedUserId: 'uid-1',
          currentUserId: 'uid-1',
          currentDisplayName: 'NewName',
        ),
        'NewName',
      );
    });

    test('returns stored name when user ids do not match', () {
      expect(
        resolveDisplayName(
          storedName: 'Ana',
          storedUserId: 'uid-1',
          currentUserId: 'uid-2',
          currentDisplayName: 'NewName',
        ),
        'Ana',
      );
    });

    test('returns stored name when stored user id is null', () {
      expect(
        resolveDisplayName(
          storedName: 'Guest',
          storedUserId: null,
          currentUserId: 'uid-1',
          currentDisplayName: 'NewName',
        ),
        'Guest',
      );
    });

    test('returns stored name when current user id is null', () {
      expect(
        resolveDisplayName(
          storedName: 'Ana',
          storedUserId: 'uid-1',
          currentUserId: null,
          currentDisplayName: 'NewName',
        ),
        'Ana',
      );
    });

    test('returns stored name when current display name is null', () {
      expect(
        resolveDisplayName(
          storedName: 'Ana',
          storedUserId: 'uid-1',
          currentUserId: 'uid-1',
          currentDisplayName: null,
        ),
        'Ana',
      );
    });
  });
}
