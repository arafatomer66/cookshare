import 'package:get_storage/get_storage.dart';

class AuthStorage {
  static final _box = GetStorage();
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  static String? get token => _box.read<String>(_tokenKey);
  static int? get userId => _box.read<int>(_userIdKey);

  static Future<void> save(String token, int userId) async {
    await _box.write(_tokenKey, token);
    await _box.write(_userIdKey, userId);
  }

  static Future<void> clear() async {
    await _box.remove(_tokenKey);
    await _box.remove(_userIdKey);
  }
}
