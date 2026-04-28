import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_theme.dart';
import '../stories/widgets/story_rings_strip.dart';
import 'feed_controller.dart';
import 'home_view.dart';
import 'widgets/post_card.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(FeedController());
    return Column(
      children: [
        const StoryRingsStrip(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Obx(() => _PillTabs(
                value: ctrl.useNearby.value,
                onChanged: ctrl.toggleMode,
              )),
        ),
        Expanded(
          child: Obx(() {
            if (ctrl.isLoading.value && ctrl.posts.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.seed));
            }
            if (ctrl.posts.isEmpty) {
              return RefreshIndicator(
                onRefresh: ctrl.refreshFeed,
                color: AppTheme.seed,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  children: [
                    const SizedBox(height: 64),
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.hairline),
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded, size: 38, color: AppTheme.inkSoft),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        ctrl.useNearby.value
                            ? 'No nearby cooks yet —\nbe the first to share.'
                            : 'Your feed is empty.\nFollow some cooks to see their dishes here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.inkSoft),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!ctrl.useNearby.value)
                      Center(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.people_alt_rounded, size: 18),
                          label: const Text('Find cooks to follow'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(220, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                          ),
                          onPressed: () => HomeView.goToTab(3), // Discover tab
                        ),
                      )
                    else
                      Center(
                        child: TextButton(
                          onPressed: () => ctrl.toggleMode(false),
                          child: const Text('Switch to Following'),
                        ),
                      ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: ctrl.refreshFeed,
              color: AppTheme.seed,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: ctrl.posts.length,
                itemBuilder: (_, i) {
                  final post = ctrl.posts[i];
                  return PostCard(post: post, onLike: () => ctrl.toggleLike(post));
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PillTabs extends StatelessWidget {
  final bool value; // false = Following, true = Nearby
  final ValueChanged<bool> onChanged;
  const _PillTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.hairline),
      ),
      child: Row(
        children: [
          Expanded(child: _segment('Following', !value, () => onChanged(false))),
          Expanded(child: _segment('Nearby', value, () => onChanged(true))),
        ],
      ),
    );
  }

  Widget _segment(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppTheme.inkSoft,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
