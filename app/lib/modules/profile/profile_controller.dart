import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class ProfileController extends GetxController {
  final _repo = UserRepository();
  final user = Rxn<UserModel>();
  final posts = <PostModel>[].obs;
  final isLoading = false.obs;

  Future<void> load(int userId) async {
    isLoading.value = true;
    try {
      user.value = await _repo.show(userId);
      posts.assignAll(await _repo.userPosts(userId));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> follow(int userId) async {
    await _repo.follow(userId);
    await load(userId);
  }

  Future<void> unfollow(int userId) async {
    await _repo.unfollow(userId);
    await load(userId);
  }

  Future<void> openWhatsapp(UserModel u) async {
    final number = (u.whatsappNumber ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) return;
    final msg = Uri.encodeComponent('Hi ${u.name}! Saw your cooking on CookShare.');
    final uri = Uri.parse('https://wa.me/$number?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
