class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? bio;
  final String? avatarUrl;
  final String? whatsappNumber;
  final double? defaultLat;
  final double? defaultLng;
  final int? postsCount;
  final int? followersCount;
  final int? followingCount;
  final bool isFollowing;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.bio,
    this.avatarUrl,
    this.whatsappNumber,
    this.defaultLat,
    this.defaultLng,
    this.postsCount,
    this.followersCount,
    this.followingCount,
    this.isFollowing = false,
  });

  UserModel copyWith({bool? isFollowing}) => UserModel(
        id: id,
        name: name,
        email: email,
        bio: bio,
        avatarUrl: avatarUrl,
        whatsappNumber: whatsappNumber,
        defaultLat: defaultLat,
        defaultLng: defaultLng,
        postsCount: postsCount,
        followersCount: followersCount,
        followingCount: followingCount,
        isFollowing: isFollowing ?? this.isFollowing,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        whatsappNumber: json['whatsapp_number'] as String?,
        defaultLat: (json['default_lat'] as num?)?.toDouble(),
        defaultLng: (json['default_lng'] as num?)?.toDouble(),
        postsCount: json['posts_count'] as int?,
        followersCount: json['followers_count'] as int?,
        followingCount: json['following_count'] as int?,
        isFollowing: (json['is_following'] as bool?) ?? false,
      );
}
