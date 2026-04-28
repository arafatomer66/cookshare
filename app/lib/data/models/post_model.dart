import 'user_model.dart';

class PostModel {
  final int id;
  final String? caption;
  final String photoUrl;
  final String? dishName;
  final String? cuisine;
  final int? cookingMinutes;
  final bool isForSale;
  final String? price;
  final int? portionsAvailable;
  final double lat;
  final double lng;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final UserModel? user;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.photoUrl,
    required this.lat,
    required this.lng,
    this.caption,
    this.dishName,
    this.cuisine,
    this.cookingMinutes,
    this.isForSale = false,
    this.price,
    this.portionsAvailable,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
    this.user,
    this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
        id: json['id'] as int,
        caption: json['caption'] as String?,
        photoUrl: json['photo_url'] as String,
        dishName: json['dish_name'] as String?,
        cuisine: json['cuisine'] as String?,
        cookingMinutes: json['cooking_minutes'] as int?,
        isForSale: (json['is_for_sale'] as bool?) ?? false,
        price: json['price']?.toString(),
        portionsAvailable: json['portions_available'] as int?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        likesCount: (json['likes_count'] as int?) ?? 0,
        commentsCount: (json['comments_count'] as int?) ?? 0,
        likedByMe: (json['liked_by_me'] as bool?) ?? false,
        user: json['user'] != null && (json['user'] as Map).isNotEmpty
            ? UserModel.fromJson(Map<String, dynamic>.from(json['user']))
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  PostModel copyWith({int? likesCount, bool? likedByMe, int? commentsCount}) => PostModel(
        id: id,
        photoUrl: photoUrl,
        lat: lat,
        lng: lng,
        caption: caption,
        dishName: dishName,
        cuisine: cuisine,
        cookingMinutes: cookingMinutes,
        isForSale: isForSale,
        price: price,
        portionsAvailable: portionsAvailable,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        likedByMe: likedByMe ?? this.likedByMe,
        user: user,
        createdAt: createdAt,
      );
}
