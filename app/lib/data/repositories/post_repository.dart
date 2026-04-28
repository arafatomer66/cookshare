import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;

import '../../core/api/api_client.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

class PostRepository {
  final _api = Get.find<ApiClient>();

  Future<List<PostModel>> feed({double? lat, double? lng, double? radiusKm}) async {
    final res = await _api.dio.get('/feed', queryParameters: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (radiusKm != null) 'radius_km': radiusKm,
    });
    final list = (res.data['data'] as List).cast<Map>();
    return list.map((e) => PostModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<PostModel> create({
    required String photoKey,
    required double lat,
    required double lng,
    String? caption,
    String? dishName,
    String? cuisine,
    int? cookingMinutes,
  }) async {
    final res = await _api.dio.post('/posts', data: {
      'photo_key': photoKey,
      'lat': lat,
      'lng': lng,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      if (dishName != null && dishName.isNotEmpty) 'dish_name': dishName,
      if (cuisine != null && cuisine.isNotEmpty) 'cuisine': cuisine,
      if (cookingMinutes != null) 'cooking_minutes': cookingMinutes,
    });
    return PostModel.fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  Future<PostModel> show(int id) async {
    final res = await _api.dio.get('/posts/$id');
    return PostModel.fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  Future<int> like(int id) async {
    final res = await _api.dio.post('/posts/$id/like');
    return (res.data['likes_count'] as int?) ?? 0;
  }

  Future<int> unlike(int id) async {
    final res = await _api.dio.delete('/posts/$id/like');
    return (res.data['likes_count'] as int?) ?? 0;
  }

  Future<List<CommentModel>> comments(int postId) async {
    final res = await _api.dio.get('/posts/$postId/comments');
    final list = (res.data['data'] as List).cast<Map>();
    return list.map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<CommentModel> comment(int postId, String body) async {
    final res = await _api.dio.post('/posts/$postId/comments', data: {'body': body});
    return CommentModel.fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  /// Two-step S3 upload: presign → PUT file → return S3 key.
  /// The bucket stays private; backend issues presigned GETs at read time.
  Future<String> uploadPhoto(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final presign = await _api.dio.post('/uploads/presign', data: {
      'content_type': contentType,
      'extension': ext == 'jpeg' ? 'jpg' : ext,
    });

    final uploadUrl = presign.data['upload_url'] as String;
    final photoKey = presign.data['photo_key'] as String;

    final put = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: await file.readAsBytes(),
    );
    if (put.statusCode != 200) {
      throw DioException(
        requestOptions: RequestOptions(path: uploadUrl),
        message: 'S3 upload failed: ${put.statusCode}',
      );
    }
    return photoKey;
  }
}
