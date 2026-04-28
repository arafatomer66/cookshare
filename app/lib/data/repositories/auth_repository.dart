import 'package:get/get.dart' hide Response;

import '../../core/api/api_client.dart';
import '../../core/storage/auth_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _api = Get.find<ApiClient>();

  Future<UserModel> register({required String name, required String email, required String password}) async {
    final res = await _api.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final user = UserModel.fromJson(Map<String, dynamic>.from(res.data['user']));
    await AuthStorage.save(res.data['token'] as String, user.id);
    return user;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final user = UserModel.fromJson(Map<String, dynamic>.from(res.data['user']));
    await AuthStorage.save(res.data['token'] as String, user.id);
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } finally {
      await AuthStorage.clear();
    }
  }

  Future<UserModel> me() async {
    final res = await _api.dio.get('/auth/me');
    return UserModel.fromJson(Map<String, dynamic>.from(res.data['data']));
  }
}
