import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});
  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _repo = UserRepository();
  final _input = TextEditingController();
  Timer? _debounce;
  List<UserModel> _results = [];
  bool _loading = false;

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q.trim()));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      _results = await _repo.search(q);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _input,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search cooks…', border: InputBorder.none),
          onChanged: _onChanged,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final u = _results[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.seed.withValues(alpha: 0.2),
                    backgroundImage: u.avatarUrl != null ? CachedNetworkImageProvider(u.avatarUrl!) : null,
                    child: u.avatarUrl == null ? Text(u.name.substring(0, 1).toUpperCase()) : null,
                  ),
                  title: Text(u.name),
                  subtitle: u.bio != null ? Text(u.bio!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                  onTap: () => Get.toNamed(AppRoutes.profile, arguments: u.id),
                );
              },
            ),
    );
  }
}
