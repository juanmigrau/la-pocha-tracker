import 'package:flutter_test/flutter_test.dart';
import 'package:la_pocha/core/services/local_user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late LocalUserService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = LocalUserService(prefs);
  });

  group('LocalUserService', () {
    test('hasLocalId returns false when no id is stored', () {
      expect(service.hasLocalId(), isFalse);
    });

    test('hasLocalId returns true when id is stored', () async {
      await prefs.setString('local_user_id', 'existing-id');

      expect(service.hasLocalId(), isTrue);
    });

    test('getOrCreateLocalId creates a UUID v4 and persists it', () async {
      final id = await service.getOrCreateLocalId();

      expect(id, isNotEmpty);
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(prefs.getString('local_user_id'), id);
      expect(service.hasLocalId(), isTrue);
    });

    test('getOrCreateLocalId returns the same id on subsequent calls', () async {
      final first = await service.getOrCreateLocalId();
      final second = await service.getOrCreateLocalId();

      expect(second, first);
    });

    test('setLocalName and getLocalName persist the name', () async {
      expect(service.getLocalName(), isNull);

      await service.setLocalName('Juan');

      expect(service.getLocalName(), 'Juan');
    });

    test('clearAll removes id and name', () async {
      await service.getOrCreateLocalId();
      await service.setLocalName('Juan');

      await service.clearAll();

      expect(service.hasLocalId(), isFalse);
      expect(service.getLocalName(), isNull);
    });
  });
}
