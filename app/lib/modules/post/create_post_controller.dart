import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';

import '../../app/routes/app_routes.dart';
import '../../core/location/location_service.dart';
import '../../data/repositories/post_repository.dart';

class CreatePostController extends GetxController {
  final _repo = PostRepository();
  final imageFile = Rx<File?>(null);
  final isUploading = false.obs;
  final lat = RxnDouble();
  final lng = RxnDouble();

  Future<void> pickFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) imageFile.value = File(picked.path);
    await _ensureLocation();
  }

  Future<void> pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) imageFile.value = File(picked.path);
    await _ensureLocation();
  }

  Future<void> _ensureLocation() async {
    if (lat.value != null) return;
    final pos = await LocationService.current();
    if (pos != null) {
      lat.value = pos.latitude;
      lng.value = pos.longitude;
    }
  }

  Future<void> submit({String? caption, String? dishName, String? cuisine, int? cookingMinutes}) async {
    if (imageFile.value == null) {
      Get.snackbar('Photo required', 'Pick or take a photo first', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (lat.value == null || lng.value == null) {
      await _ensureLocation();
      if (lat.value == null) {
        Get.snackbar('Location required', 'Enable location to share your dish', snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    isUploading.value = true;
    try {
      final photoKey = await _repo.uploadPhoto(imageFile.value!);
      await _repo.create(
        photoKey: photoKey,
        lat: lat.value!,
        lng: lng.value!,
        caption: caption,
        dishName: dishName,
        cuisine: cuisine,
        cookingMinutes: cookingMinutes,
      );
      Get.offAllNamed(AppRoutes.home);
      Get.snackbar('Posted!', 'Your dish is now live nearby.', snackPosition: SnackPosition.BOTTOM);
    } on DioException catch (e) {
      Get.snackbar('Post failed', e.message ?? 'Try again', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUploading.value = false;
    }
  }
}
