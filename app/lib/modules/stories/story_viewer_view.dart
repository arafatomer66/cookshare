import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';
import '../../core/storage/auth_storage.dart';
import '../../data/models/story_model.dart';
import '../../data/repositories/story_repository.dart';

class StoryViewerView extends StatefulWidget {
  const StoryViewerView({super.key});

  @override
  State<StoryViewerView> createState() => _StoryViewerViewState();
}

class _StoryViewerViewState extends State<StoryViewerView> with SingleTickerProviderStateMixin {
  static const _perStorySeconds = 6;

  final _repo = StoryRepository();
  late final int _userId;
  late final String _userName;

  List<StoryModel> _stories = [];
  int _index = 0;
  bool _loading = true;
  bool _viewedAny = false;

  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    final args = Map<String, dynamic>.from(Get.arguments as Map);
    _userId = args['userId'] as int;
    _userName = args['userName'] as String? ?? '';

    _progress = AnimationController(vsync: this, duration: const Duration(seconds: _perStorySeconds));
    _progress.addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });

    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.forUser(_userId);
      if (!mounted) return;
      setState(() {
        _stories = list;
        _loading = false;
      });
      if (list.isNotEmpty) _start();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _start() {
    if (_stories.isEmpty) return;
    final story = _stories[_index];
    _viewedAny = true;
    _repo.markViewed(story.id);
    _progress.forward(from: 0);
  }

  void _next() {
    if (_index + 1 >= _stories.length) {
      Get.back(result: _viewedAny ? 'viewed' : null);
      return;
    }
    setState(() => _index += 1);
    _start();
  }

  void _prev() {
    if (_index == 0) {
      _progress.forward(from: 0);
      return;
    }
    setState(() => _index -= 1);
    _start();
  }

  void _setPaused(bool v) {
    if (v) {
      _progress.stop();
    } else {
      _progress.forward();
    }
  }

  Future<void> _openWhatsapp(StoryModel s) async {
    final number = (s.whatsapp ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) {
      Get.snackbar('No WhatsApp', 'This cook has not added a WhatsApp number',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final dish = s.dishName ?? 'your dish';
    final msg = Uri.encodeComponent('Hi! I saw your CookShare story and would love a portion of $dish.');
    final uri = Uri.parse('https://wa.me/$number?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _stories.isEmpty
                ? _emptyState()
                : _viewer(),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cake_outlined, color: Colors.white70, size: 56),
          const SizedBox(height: 12),
          const Text('No active stories', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Get.back(), child: const Text('Close', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _viewer() {
    final s = _stories[_index];
    final isOwn = s.user?.id == AuthStorage.userId;
    return GestureDetector(
      onTapUp: (details) {
        final w = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < w / 3) {
          _prev();
        } else {
          _next();
        }
      },
      onLongPressStart: (_) => _setPaused(true),
      onLongPressEnd: (_) => _setPaused(false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          if (s.photoUrl != null)
            Center(
              child: CachedNetworkImage(
                imageUrl: s.photoUrl!,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white54, size: 48),
              ),
            )
          else
            Container(color: Colors.black),

          // Top scrim for contrast
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
              ),
            ),
          ),

          // Bottom scrim where overlays live
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
            ),
          ),

          // Progress + header
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Row(
                  children: List.generate(_stories.length, (i) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == _stories.length - 1 ? 0 : 4),
                        child: AnimatedBuilder(
                          animation: _progress,
                          builder: (_, __) {
                            double v;
                            if (i < _index) {
                              v = 1;
                            } else if (i == _index) {
                              v = _progress.value;
                            } else {
                              v = 0;
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: v,
                                minHeight: 2.5,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _avatarCircle(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                          if (s.createdAt != null)
                            Text(_relative(s.createdAt!), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (isOwn)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white),
                        onPressed: _confirmDelete,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Get.back(result: _viewedAny ? 'viewed' : null),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom: dish + caption + (sale or message CTA)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _bottomBlock(s, isOwn),
          ),
        ],
      ),
    );
  }

  Widget _avatarCircle() {
    final initials = _userName.isEmpty
        ? '?'
        : _userName.trim().split(' ').map((s) => s.isEmpty ? '' : s[0]).take(2).join().toUpperCase();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _bottomBlock(StoryModel s, bool isOwn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.dishName != null && s.dishName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(s.dishName!,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
          ),
        if (s.caption != null && s.caption!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(s.caption!, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
          ),
        if (s.isAvailable) ...[
          _saleStrip(s),
          const SizedBox(height: 12),
        ],
        if (isOwn)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: const Text('See viewers'),
            onPressed: () => _showViewers(s),
          )
        else if (s.isAvailable)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF25D366), // WhatsApp green
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('Message cook on WhatsApp'),
            onPressed: () => _openWhatsapp(s),
          ),
      ],
    );
  }

  Widget _saleStrip(StoryModel s) {
    final price = s.price != null ? '৳${s.price}' : '';
    final portions = s.portionsTotal != null ? '${s.portionsTotal} portions' : '';
    final area = s.pickupArea ?? '';
    final parts = [
      if (price.isNotEmpty) price,
      if (portions.isNotEmpty) portions,
      if (area.isNotEmpty) 'Pickup: $area',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _relative(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  Future<void> _confirmDelete() async {
    _setPaused(true);
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this story?'),
        content: const Text('It will disappear immediately for everyone.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _repo.delete(_stories[_index].id);
      } catch (_) {}
      _stories.removeAt(_index);
      if (_stories.isEmpty) {
        Get.back(result: 'viewed');
        return;
      }
      if (_index >= _stories.length) _index = _stories.length - 1;
      setState(() {});
      _start();
    } else {
      _setPaused(false);
    }
  }

  Future<void> _showViewers(StoryModel s) async {
    _setPaused(true);
    try {
      final viewers = await _repo.viewers(s.id);
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        isScrollControlled: true,
        builder: (_) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: AppTheme.hairline, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                Text('${viewers.length} viewer${viewers.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (viewers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No viewers yet — share with friends!')),
                  )
                else
                  ...viewers.map((v) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surfaceElevated,
                          backgroundImage: v['avatar_url'] != null ? NetworkImage(v['avatar_url'] as String) : null,
                          child: v['avatar_url'] == null
                              ? Text((v['name'] as String? ?? '?').characters.first.toUpperCase())
                              : null,
                        ),
                        title: Text(v['name'] as String? ?? 'Unknown'),
                      )),
              ],
            ),
          ),
        ),
      );
    } catch (_) {} finally {
      _setPaused(false);
    }
  }
}
