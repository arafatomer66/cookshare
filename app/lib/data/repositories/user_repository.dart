import 'package:get/get.dart' hide Response;

import '../../core/api/api_client.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class UserRepository {
  final _api = Get.find<ApiClient>();

  Future<UserModel> show(int id) async {
    final res = await _api.dio.get('/users/$id');
    return UserModel.fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  Future<UserModel> updateMe({
    String? name,
    String? bio,
    String? avatarUrl,
    String? whatsappNumber,
    double? defaultLat,
    double? defaultLng,
  }) async {
    final res = await _api.dio.patch('/users/me', data: {
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
      if (defaultLat != null) 'default_lat': defaultLat,
      if (defaultLng != null) 'default_lng': defaultLng,
    });
    return UserModel.fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  Future<bool> follow(int id) async {
    final res = await _api.dio.post('/users/$id/follow');
    return (res.data['following'] as bool?) ?? false;
  }

  Future<bool> unfollow(int id) async {
    final res = await _api.dio.delete('/users/$id/follow');
    return (res.data['following'] as bool?) ?? false;
  }

  Future<List<PostModel>> userPosts(int id) async {
    final res = await _api.dio.get('/users/$id/posts');
    final list = (res.data['data'] as List).cast<Map>();
    return list.map((e) => PostModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<UserModel>> nearbyCooks({required double lat, required double lng, double radiusKm = 5}) async {
    final res = await _api.dio.get('/users/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    final list = (res.data['data'] as List).cast<Map>();
    return list.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<UserModel>> allCooks() async {
    final res = await _api.dio.get('/users/cooks');
    final list = (res.data['data'] as List).cast<Map>();
    return list.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<UserModel>> search(String q) async {
    final res = await _api.dio.get('/users/search', queryParameters: {'q': q});
    final list = (res.data['data'] as List).cast<Map>();
    return list.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
