import 'dart:io';

import 'package:get/get.dart' hide Response;

import '../../core/api/api_client.dart';
import '../models/story_model.dart';
import 'post_repository.dart';

class StoryRepository {
  final _api = Get.find<ApiClient>();
  final _posts = PostRepository(); // reuse S3 presign + PUT flow for photos

  Future<List<StoryRing>> rings({double? lat, double? lng, double? radiusKm}) async {
    final res = await _api.dio.get('/stories/rings', queryParameters: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusKm != null) 'radius_km': radiusKm,
    });
    final list = (res.data['rings'] as List).cast<Map>();
    return list.map((e) => StoryRing.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<StoryModel>> forUser(int userId) async {
    final res = await _api.dio.get('/stories/users/$userId');
    final list = (res.data['stories'] as List).cast<Map>();
    return list.map((e) => StoryModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<String> uploadPhoto(File file) => _posts.uploadPhoto(file);

  Future<StoryModel> create({
    required String photoKey,
    required double lat,
    required double lng,
    String? dishName,
    String? caption,
    bool isAvailable = false,
    int? portionsTotal,
    String? price,
    String? pickupArea,
  }) async {
    final res = await _api.dio.post('/stories', data: {
      'photo_key': photoKey,
      'lat': lat,
      'lng': lng,
      if (dishName != null && dishName.isNotEmpty) 'dish_name': dishName,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'is_available': isAvailable,
      if (isAvailable && portionsTotal != null) 'portions_total': portionsTotal,
      if (isAvailable && price != null && price.isNotEmpty) 'price': price,
      if (pickupArea != null && pickupArea.isNotEmpty) 'pickup_area': pickupArea,
    });
    return StoryModel.fromJson(Map<String, dynamic>.from(res.data['story']));
  }

  Future<void> markViewed(int storyId) async {
    await _api.dio.post('/stories/$storyId/view');
  }

  Future<void> delete(int storyId) async {
    await _api.dio.delete('/stories/$storyId');
  }

  Future<List<Map<String, dynamic>>> viewers(int storyId) async {
    final res = await _api.dio.get('/stories/$storyId/viewers');
    final list = (res.data['viewers'] as List).cast<Map>();
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
