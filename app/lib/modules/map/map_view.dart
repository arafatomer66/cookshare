import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/api/api_config.dart';
import '../../data/repositories/map_repository.dart';
import 'map_controller.dart';

class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MapPageController());

    return Stack(
      children: [
        Obx(() => FlutterMap(
              options: MapOptions(
                initialCenter: ctrl.center.value,
                initialZoom: 15,
                minZoom: 3,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: '${ApiConfig.baseUrl}/map/osm/{z}/{x}/{y}',
                  userAgentPackageName: 'com.cookshare.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ctrl.center.value,
                      width: 22,
                      height: 22,
                      child: _MeDot(),
                    ),
                    ...ctrl.pins.map((pin) => Marker(
                          point: LatLng(pin.lat, pin.lng),
                          width: 64,
                          height: 64,
                          child: GestureDetector(
                            onTap: () => _showPin(context, pin),
                            child: _DishPin(photoUrl: pin.photoUrl),
                          ),
                        )),
                  ],
                ),
              ],
            )),
        // Top gradient scrim so the floating controls + status bar stay legible.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withValues(alpha: 0.92),
                    AppTheme.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _GlassChip(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppTheme.seed),
                      const SizedBox(width: 6),
                      Obx(() => Text(
                            '${ctrl.pins.length} dishes nearby',
                            style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w600, fontSize: 13),
                          )),
                    ],
                  ),
                ),
                const Spacer(),
                Obx(() => _GlassIconButton(
                      icon: Icons.people_alt_rounded,
                      active: ctrl.followOnly.value,
                      onTap: ctrl.toggleFollowOnly,
                    )),
                const SizedBox(width: 8),
                _GlassIconButton(
                  icon: Icons.refresh_rounded,
                  onTap: ctrl.fetch,
                ),
              ],
            ),
          ),
        ),
        Obx(() => ctrl.isLoading.value
            ? const Positioned(
                top: 80, left: 0, right: 0,
                child: Center(child: CircularProgressIndicator(color: AppTheme.seed)),
              )
            : const SizedBox()),
      ],
    );
  }

  void _showPin(BuildContext ctx, MapPin pin) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.hairline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: pin.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.surfaceElevated),
                  errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceElevated, child: const Icon(Icons.restaurant_outlined, color: AppTheme.inkSoft)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(pin.dishName ?? 'Dish', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('by ${pin.userName}', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppTheme.inkSoft)),
            if (pin.caption != null) ...[
              const SizedBox(height: 12),
              Text(pin.caption!, style: Theme.of(ctx).textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Get.back();
                Get.toNamed(AppRoutes.postDetail, arguments: pin.postId);
              },
              child: const Text('Open dish'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2F80ED),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80ED).withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _DishPin extends StatelessWidget {
  final String photoUrl;
  const _DishPin({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.seed, Color(0xFFC44318)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(2.5),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppTheme.surfaceElevated),
            errorWidget: (_, __, ___) => Container(color: AppTheme.surfaceElevated, child: const Icon(Icons.restaurant_outlined, size: 18)),
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final Widget child;
  const _GlassChip({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.hairline),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: active ? AppTheme.ink : AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: active ? AppTheme.ink : AppTheme.hairline),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: active ? Colors.white : AppTheme.ink, size: 20),
      ),
    );
  }
}
