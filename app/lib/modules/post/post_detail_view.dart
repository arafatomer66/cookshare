import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../data/models/comment_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/post_repository.dart';

class PostDetailView extends StatefulWidget {
  const PostDetailView({super.key});
  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  final _repo = PostRepository();
  final _commentInput = TextEditingController();
  late int _postId;
  PostModel? _post;
  List<CommentModel> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _postId = Get.arguments as int;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _post = await _repo.show(_postId);
      _comments = await _repo.comments(_postId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _comment() async {
    final body = _commentInput.text.trim();
    if (body.isEmpty) return;
    _commentInput.clear();
    final c = await _repo.comment(_postId, body);
    setState(() => _comments.insert(0, c));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dish')),
      body: _loading || _post == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(imageUrl: _post!.photoUrl, fit: BoxFit.cover),
                      ),
                      ListTile(
                        title: Text(_post!.dishName ?? 'Untitled dish', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('by ${_post!.user?.name ?? 'Unknown'} • ${_post!.cuisine ?? ''}'),
                      ),
                      if (_post!.caption != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(_post!.caption!),
                        ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Comments (${_comments.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._comments.map((c) => ListTile(
                            leading: CircleAvatar(child: Text(c.user?.name.substring(0, 1).toUpperCase() ?? '?')),
                            title: Text(c.user?.name ?? 'Unknown'),
                            subtitle: Text(c.body),
                            trailing: c.createdAt != null
                                ? Text(DateFormat.Hm().format(c.createdAt!.toLocal()), style: const TextStyle(fontSize: 11))
                                : null,
                          )),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentInput,
                            decoration: const InputDecoration(hintText: 'Add a comment…'),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.send), onPressed: _comment),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
