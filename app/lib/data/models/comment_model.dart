import 'user_model.dart';

class CommentModel {
  final int id;
  final String body;
  final UserModel? user;
  final DateTime? createdAt;

  CommentModel({required this.id, required this.body, this.user, this.createdAt});

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as int,
        body: json['body'] as String,
        user: json['user'] != null && (json['user'] as Map).isNotEmpty
            ? UserModel.fromJson(Map<String, dynamic>.from(json['user']))
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}
