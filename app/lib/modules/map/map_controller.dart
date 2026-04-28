import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_service.dart';
import '../../data/repositories/map_repository.dart';

class MapPageController extends GetxController {
  final _repo = MapRepository();
  final pins = <MapPin>[].obs;
  final isLoading = false.obs;
  final followOnly = false.obs;
  final center = const LatLng(23.7806, 90.4193).obs; // Dhaka default
  final radiusKm = 50.0.obs;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    final pos = await LocationService.current();
    // Only snap to device location if it's near Dhaka — emulator defaults to
    // Mountain View, which is 13,000 km from the seeded pins.
    if (pos != null && (pos.latitude - 23.7806).abs() < 5 && (pos.longitude - 90.4193).abs() < 5) {
      center.value = LatLng(pos.latitude, pos.longitude);
    }
    await fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    try {
      final list = await _repo.nearby(
        lat: center.value.latitude,
        lng: center.value.longitude,
        radiusKm: radiusKm.value,
        followOnly: followOnly.value,
      );
      pins.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  void toggleFollowOnly() {
    followOnly.value = !followOnly.value;
    fetch();
  }
}
