import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/auth_storage.dart';
import '../../data/repositories/user_repository.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});
  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _repo = UserRepository();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _avatarUrl = TextEditingController();
  final _whatsapp = TextEditingController();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final id = AuthStorage.userId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final me = await _repo.show(id);
      _name.text = me.name;
      _bio.text = me.bio ?? '';
      _avatarUrl.text = me.avatarUrl ?? '';
      _whatsapp.text = me.whatsappNumber ?? '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _repo.updateMe(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        avatarUrl: _avatarUrl.text.trim().isEmpty ? null : _avatarUrl.text.trim(),
        whatsappNumber: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
      );
      Get.back();
      Get.snackbar('Saved', 'Profile updated', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 12),
                  TextField(controller: _bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
                  const SizedBox(height: 12),
                  TextField(controller: _avatarUrl, decoration: const InputDecoration(labelText: 'Avatar URL')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp number',
                      helperText: 'With country code, e.g. +8801XXXXXXXXX. Buyers tap your story to message you.',
                      helperMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
