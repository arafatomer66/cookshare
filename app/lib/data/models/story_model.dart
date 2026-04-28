import 'user_model.dart';

class StoryModel {
  final int id;
  final String? photoUrl;
  final String? dishName;
  final String? caption;
  final double lat;
  final double lng;
  final bool isAvailable;
  final int? portionsTotal;
  final String? price;
  final String? pickupArea;
  final String? whatsapp;
  final UserModel? user;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  StoryModel({
    required this.id,
    required this.lat,
    required this.lng,
    this.photoUrl,
    this.dishName,
    this.caption,
    this.isAvailable = false,
    this.portionsTotal,
    this.price,
    this.pickupArea,
    this.whatsapp,
    this.user,
    this.expiresAt,
    this.createdAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) => StoryModel(
        id: json['id'] as int,
        photoUrl: json['photo_url'] as String?,
        dishName: json['dish_name'] as String?,
        caption: json['caption'] as String?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        isAvailable: (json['is_available'] as bool?) ?? false,
        portionsTotal: json['portions_total'] as int?,
        price: json['price']?.toString(),
        pickupArea: json['pickup_area'] as String?,
        whatsapp: json['whatsapp'] as String?,
        user: json['user'] != null && (json['user'] as Map).isNotEmpty
            ? UserModel.fromJson(Map<String, dynamic>.from(json['user']))
            : null,
        expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'] as String) : null,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      );
}

class StoryRing {
  final int userId;
  final String userName;
  final String? avatarUrl;
  final int storyCount;
  final bool hasUnviewed;
  final String? previewPhotoUrl;
  final DateTime? latestAt;

  StoryRing({
    required this.userId,
    required this.userName,
    required this.storyCount,
    required this.hasUnviewed,
    this.avatarUrl,
    this.previewPhotoUrl,
    this.latestAt,
  });

  factory StoryRing.fromJson(Map<String, dynamic> json) {
    final u = Map<String, dynamic>.from(json['user'] as Map);
    return StoryRing(
      userId: u['id'] as int,
      userName: u['name'] as String,
      avatarUrl: u['avatar_url'] as String?,
      storyCount: (json['story_count'] as int?) ?? 0,
      hasUnviewed: (json['has_unviewed'] as bool?) ?? false,
      previewPhotoUrl: json['preview_photo_url'] as String?,
      latestAt: json['latest_at'] != null ? DateTime.tryParse(json['latest_at'] as String) : null,
    );
  }
}
