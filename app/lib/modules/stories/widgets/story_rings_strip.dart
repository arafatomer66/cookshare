import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/story_model.dart';
import '../story_controller.dart';

class StoryRingsStrip extends StatelessWidget {
  const StoryRingsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(StoryRingsController(), permanent: true);
    return Obx(() {
      final rings = ctrl.rings;
      // Always show the "Your story" tile, even when there are no rings yet.
      final tileCount = rings.length + 1;
      return SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tileCount,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _AddYourStoryTile(
                onTap: () async {
                  await Get.toNamed(AppRoutes.createStory);
                  await ctrl.refreshRings();
                },
              );
            }
            final r = rings[i - 1];
            return _RingTile(
              ring: r,
              onTap: () async {
                final result = await Get.toNamed(
                  AppRoutes.storyViewer,
                  arguments: {'userId': r.userId, 'userName': r.userName},
                );
                if (result == 'viewed') ctrl.markRingViewed(r.userId);
              },
            );
          },
        ),
      );
    });
  }
}

class _AddYourStoryTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddYourStoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.hairline, width: 1.5),
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.seed, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              'Your story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppTheme.inkSoft, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingTile extends StatelessWidget {
  final StoryRing ring;
  final VoidCallback onTap;
  const _RingTile({required this.ring, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnviewed = ring.hasUnviewed;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasUnviewed
                    ? const LinearGradient(
                        colors: [AppTheme.seed, Color(0xFFC44318)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasUnviewed ? null : AppTheme.hairline,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.surface),
                child: ClipOval(
                  child: ring.previewPhotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: ring.previewPhotoUrl!,
                          fit: BoxFit.cover,
                          width: 54,
                          height: 54,
                          placeholder: (_, __) => Container(color: AppTheme.surfaceElevated),
                          errorWidget: (_, __, ___) => _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ring.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppTheme.ink, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    final initials = ring.userName.isEmpty
        ? '?'
        : ring.userName.trim().split(' ').map((s) => s.isEmpty ? '' : s[0]).take(2).join().toUpperCase();
    return Container(
      width: 54,
      height: 54,
      color: AppTheme.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}
