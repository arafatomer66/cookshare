import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../core/location/location_service.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

class FeedController extends GetxController {
  final _repo = PostRepository();
  final posts = <PostModel>[].obs;
  final isLoading = false.obs;
  final useNearby = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshFeed();
  }

  Future<void> refreshFeed() async {
    isLoading.value = true;
    try {
      double? lat;
      double? lng;
      if (useNearby.value) {
        final pos = await LocationService.current();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }
      final list = await _repo.feed(lat: lat, lng: lng);
      posts.assignAll(list);
    } on DioException catch (e) {
      Get.snackbar('Feed error', e.message ?? 'Could not load feed', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleMode(bool nearby) {
    useNearby.value = nearby;
    refreshFeed();
  }

  Future<void> toggleLike(PostModel post) async {
    final i = posts.indexWhere((p) => p.id == post.id);
    if (i < 0) return;
    final wasLiked = post.likedByMe;
    posts[i] = post.copyWith(
      likedByMe: !wasLiked,
      likesCount: post.likesCount + (wasLiked ? -1 : 1),
    );
    try {
      final count = wasLiked ? await _repo.unlike(post.id) : await _repo.like(post.id);
      posts[i] = posts[i].copyWith(likesCount: count);
    } catch (_) {
      posts[i] = post; // revert
    }
  }
}
