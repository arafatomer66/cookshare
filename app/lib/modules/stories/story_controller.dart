import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../core/location/location_service.dart';
import '../../data/models/story_model.dart';
import '../../data/repositories/story_repository.dart';

class StoryRingsController extends GetxController {
  final _repo = StoryRepository();
  final rings = <StoryRing>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshRings();
  }

  Future<void> refreshRings() async {
    isLoading.value = true;
    try {
      final pos = await LocationService.current();
      final list = await _repo.rings(
        lat: pos?.latitude,
        lng: pos?.longitude,
        radiusKm: 10,
      );
      rings.assignAll(list);
    } on DioException catch (_) {
      // soft-fail — rings are best-effort
    } finally {
      isLoading.value = false;
    }
  }

  void markRingViewed(int userId) {
    final i = rings.indexWhere((r) => r.userId == userId);
    if (i < 0) return;
    final r = rings[i];
    rings[i] = StoryRing(
      userId: r.userId,
      userName: r.userName,
      avatarUrl: r.avatarUrl,
      storyCount: r.storyCount,
      hasUnviewed: false,
      previewPhotoUrl: r.previewPhotoUrl,
      latestAt: r.latestAt,
    );
  }
}
