import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/storage/auth_storage.dart';
import '../auth/auth_controller.dart';
import 'profile_controller.dart';

class ProfileView extends StatefulWidget {
  final int? userId;
  const ProfileView({super.key, this.userId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _ctrl = Get.put(ProfileController(), tag: 'profile');
  late int _id;

  @override
  void initState() {
    super.initState();
    _id = widget.userId ?? (Get.arguments as int? ?? AuthStorage.userId ?? 0);
    _ctrl.load(_id);
  }

  bool get _isMe => _id == AuthStorage.userId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_ctrl.isLoading.value && _ctrl.user.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      final u = _ctrl.user.value;
      if (u == null) return const Center(child: Text('User not found'));

      return RefreshIndicator(
        onRefresh: () => _ctrl.load(_id),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.seed.withValues(alpha: 0.2),
                  backgroundImage: u.avatarUrl != null ? CachedNetworkImageProvider(u.avatarUrl!) : null,
                  child: u.avatarUrl == null
                      ? Text(u.name.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 24))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (u.bio != null) Text(u.bio!, style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Dishes', u.postsCount ?? _ctrl.posts.length),
                _stat('Followers', u.followersCount ?? 0),
                _stat('Following', u.followingCount ?? 0),
              ],
            ),
            const SizedBox(height: 16),
            if (_isMe)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.toNamed(AppRoutes.editProfile),
                      child: const Text('Edit profile'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.find<AuthController>().logout(),
                      child: const Text('Log out'),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: u.isFollowing
                        ? OutlinedButton.icon(
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Following'),
                            onPressed: () => _ctrl.unfollow(_id),
                          )
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('Follow'),
                            onPressed: () => _ctrl.follow(_id),
                          ),
                  ),
                  if ((u.whatsappNumber ?? '').isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        onPressed: () => _ctrl.openWhatsapp(u),
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 24),
            const Text('Dishes shared', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              children: _ctrl.posts
                  .map((p) => GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.postDetail, arguments: p.id),
                        child: CachedNetworkImage(imageUrl: p.photoUrl, fit: BoxFit.cover),
                      ))
                  .toList(),
            ),
          ],
        ),
      );
    });
  }

  Widget _stat(String label, int value) => Column(
        children: [
          Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      );
}
