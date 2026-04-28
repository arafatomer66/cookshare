import 'package:get/get.dart' hide Response;

import '../../core/api/api_client.dart';

class MapPin {
  final int postId;
  final double lat;
  final double lng;
  final String photoUrl;
  final String? dishName;
  final String? caption;
  final bool isForSale;
  final String? price;
  final int userId;
  final String userName;
  final String? userAvatar;
  final DateTime? createdAt;

  MapPin({
    required this.postId,
    required this.lat,
    required this.lng,
    required this.photoUrl,
    required this.userId,
    required this.userName,
    this.dishName,
    this.caption,
    this.isForSale = false,
    this.price,
    this.userAvatar,
    this.createdAt,
  });
}

class MapRepository {
  final _api = Get.find<ApiClient>();

  Future<List<MapPin>> nearby({
    required double lat,
    required double lng,
    double radiusKm = 5,
    bool followOnly = false,
  }) async {
    final res = await _api.dio.get('/map/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
      if (followOnly) 'follow_only': true,
    });

    final features = (res.data['features'] as List).cast<Map>();
    return features.map((f) {
      final coords = (f['geometry']['coordinates'] as List).cast<num>();
      final p = Map<String, dynamic>.from(f['properties'] as Map);
      final user = Map<String, dynamic>.from(p['user'] as Map);
      return MapPin(
        postId: p['id'] as int,
        lng: coords[0].toDouble(),
        lat: coords[1].toDouble(),
        photoUrl: p['photo_url'] as String,
        dishName: p['dish_name'] as String?,
        caption: p['caption'] as String?,
        isForSale: (p['is_for_sale'] as bool?) ?? false,
        price: p['price']?.toString(),
        userId: user['id'] as int,
        userName: user['name'] as String,
        userAvatar: user['avatar_url'] as String?,
        createdAt: p['created_at'] != null ? DateTime.tryParse(p['created_at'] as String) : null,
      );
    }).toList();
  }
}
