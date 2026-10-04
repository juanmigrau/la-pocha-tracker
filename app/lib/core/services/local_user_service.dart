import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalUserService {
  static const _keyLocalId = 'local_user_id';
  static const _keyLocalName = 'local_user_name';

  final SharedPreferences _prefs;

  LocalUserService(this._prefs);

  bool hasLocalId() => _prefs.containsKey(_keyLocalId);

  Future<String> getOrCreateLocalId() async {
    final existing = _prefs.getString(_keyLocalId);
    if (existing != null) {
      return existing;
    }
    final newId = const Uuid().v4();
    await _prefs.setString(_keyLocalId, newId);
    return newId;
  }

  String? getLocalName() => _prefs.getString(_keyLocalName);

  Future<void> setLocalName(String name) =>
      _prefs.setString(_keyLocalName, name);

  Future<void> clearAll() async {
    await _prefs.remove(_keyLocalId);
    await _prefs.remove(_keyLocalName);
  }
}
