import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  const PostCard({super.key, required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final time = post.createdAt != null ? _relativeTime(post.createdAt!) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(post: post, time: time),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.postDetail, arguments: post.id),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 5,
                      child: CachedNetworkImage(
                        imageUrl: post.photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppTheme.surfaceElevated),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.surfaceElevated,
                          child: const Icon(Icons.restaurant_outlined, size: 48, color: AppTheme.inkSoft),
                        ),
                      ),
                    ),
                    if (post.isForSale)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.ink.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '৳${post.price ?? '—'}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 12, 4),
                child: Row(
                  children: [
                    _IconAction(
                      icon: post.likedByMe ? Icons.favorite : Icons.favorite_outline,
                      color: post.likedByMe ? AppTheme.seed : AppTheme.ink,
                      label: '${post.likesCount}',
                      onTap: onLike,
                    ),
                    const SizedBox(width: 18),
                    _IconAction(
                      icon: Icons.mode_comment_outlined,
                      color: AppTheme.ink,
                      label: '${post.commentsCount}',
                      onTap: () => Get.toNamed(AppRoutes.postDetail, arguments: post.id),
                    ),
                    const Spacer(),
                    if (post.cuisine != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppTheme.hairline),
                        ),
                        child: Text(
                          post.cuisine!,
                          style: const TextStyle(fontSize: 11, color: AppTheme.inkSoft, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              if (post.dishName != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Text(
                    post.dishName!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              if (post.caption != null && post.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                  child: Text(
                    post.caption!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (post.caption == null || post.caption!.isEmpty) const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(ts);
  }
}

class _Header extends StatelessWidget {
  final PostModel post;
  final String? time;
  const _Header({required this.post, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.seed, AppTheme.seed.withValues(alpha: 0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.surface,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.surfaceElevated,
                backgroundImage: post.user?.avatarUrl != null
                    ? CachedNetworkImageProvider(post.user!.avatarUrl!)
                    : null,
                child: post.user?.avatarUrl == null
                    ? Text(
                        (post.user?.name.substring(0, 1).toUpperCase() ?? '?'),
                        style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w600),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.user?.name ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (time != null)
                  Text(
                    time!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppTheme.inkSoft),
            onPressed: () => Get.toNamed(AppRoutes.postDetail, arguments: post.id),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: AppTheme.ink, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
