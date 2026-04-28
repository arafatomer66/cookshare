import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../core/location/location_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});
  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final _repo = UserRepository();
  List<UserModel> _cooks = [];
  bool _loading = true;
  bool _useNearby = true;
  String? _emptyHint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _emptyHint = null;
    });
    try {
      if (_useNearby) {
        final pos = await LocationService.current();
        if (pos == null) {
          // Graceful fallback so the user always sees cooks they can follow.
          _cooks = await _repo.allCooks();
          _emptyHint = 'Showing all cooks (location unavailable).';
        } else {
          final nearby = await _repo.nearbyCooks(lat: pos.latitude, lng: pos.longitude, radiusKm: 50);
          if (nearby.isEmpty) {
            _cooks = await _repo.allCooks();
            _emptyHint = 'Nobody nearby yet — showing all cooks.';
          } else {
            _cooks = nearby;
          }
        }
      } else {
        _cooks = await _repo.allCooks();
      }
    } catch (e) {
      _emptyHint = 'Could not load cooks. Pull to retry.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(int index) async {
    final u = _cooks[index];
    setState(() => _cooks[index] = u.copyWith(isFollowing: !u.isFollowing));
    try {
      if (u.isFollowing) {
        await _repo.unfollow(u.id);
      } else {
        await _repo.follow(u.id);
      }
      Get.snackbar(
        u.isFollowing ? 'Unfollowed ${u.name}' : 'Following ${u.name}',
        u.isFollowing ? '' : 'Their stories and posts will show in your feed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      // revert on failure
      if (mounted) setState(() => _cooks[index] = u);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: _PillTabs(
            useNearby: _useNearby,
            onChanged: (v) {
              setState(() => _useNearby = v);
              _load();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.search),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search by name'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: AppTheme.hairline),
                foregroundColor: AppTheme.inkSoft,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_emptyHint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(_emptyHint!,
                style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.seed))
              : _cooks.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppTheme.seed,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: _cooks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.hairline),
                        itemBuilder: (_, i) => _CookRow(
                          user: _cooks[i],
                          onFollowToggle: () => _toggleFollow(i),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _emptyView() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.seed,
      child: ListView(
        children: [
          const SizedBox(height: 80),
          const Center(child: Icon(Icons.people_outline, size: 56, color: AppTheme.inkSoft)),
          const SizedBox(height: 14),
          const Center(
            child: Text('No cooks yet — be the first.',
                style: TextStyle(color: AppTheme.inkSoft, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _PillTabs extends StatelessWidget {
  final bool useNearby;
  final ValueChanged<bool> onChanged;
  const _PillTabs({required this.useNearby, required this.onChanged});

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
          Expanded(child: _segment('Nearby', useNearby, () => onChanged(true))),
          Expanded(child: _segment('All cooks', !useNearby, () => onChanged(false))),
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

class _CookRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback onFollowToggle;
  const _CookRow({required this.user, required this.onFollowToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.profile, arguments: user.id),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.surfaceElevated,
              backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.ink))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.ink)),
                  const SizedBox(height: 2),
                  Text(
                    user.bio?.isNotEmpty == true
                        ? user.bio!
                        : '${user.postsCount ?? 0} dish${(user.postsCount ?? 0) == 1 ? '' : 'es'} shared',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _FollowButton(isFollowing: user.isFollowing, onTap: onFollowToggle),
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;
  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : AppTheme.seed,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: isFollowing ? AppTheme.hairline : AppTheme.seed),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowing ? AppTheme.ink : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
