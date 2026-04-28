import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../app/routes/app_routes.dart';
import '../../core/storage/auth_storage.dart';
import '../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final _repo = AuthRepository();
  final isLoading = false.obs;

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      await _repo.login(email: email, password: password);
      Get.offAllNamed(AppRoutes.home);
    } on DioException catch (e) {
      Get.snackbar('Login failed', _msg(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    isLoading.value = true;
    try {
      await _repo.register(name: name, email: email, password: password);
      Get.offAllNamed(AppRoutes.home);
    } on DioException catch (e) {
      Get.snackbar('Sign-up failed', _msg(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    await AuthStorage.clear();
    Get.offAllNamed(AppRoutes.login);
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return e.message ?? 'Network error';
  }
}
