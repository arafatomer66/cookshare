import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_theme.dart';
import '../../core/location/location_service.dart';
import '../../data/repositories/story_repository.dart';

class CreateStoryView extends StatefulWidget {
  const CreateStoryView({super.key});

  @override
  State<CreateStoryView> createState() => _CreateStoryViewState();
}

class _CreateStoryViewState extends State<CreateStoryView> {
  final _repo = StoryRepository();
  final _dish = TextEditingController();
  final _caption = TextEditingController();
  final _portions = TextEditingController();
  final _price = TextEditingController();
  final _area = TextEditingController();

  File? _image;
  bool _available = false;
  bool _uploading = false;
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _dish.dispose();
    _caption.dispose();
    _portions.dispose();
    _price.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() => _image = File(picked.path));
    await _ensureLocation();
  }

  Future<void> _ensureLocation() async {
    if (_lat != null) return;
    final pos = await LocationService.current();
    if (pos != null) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    }
  }

  Future<void> _submit() async {
    if (_image == null) {
      Get.snackbar('Photo required', 'Pick or take a photo first', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    await _ensureLocation();
    if (_lat == null) {
      Get.snackbar('Location required', 'Enable location to share your story', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_available) {
      final p = int.tryParse(_portions.text.trim());
      final pr = double.tryParse(_price.text.trim());
      if (p == null || p <= 0) {
        Get.snackbar('Portions needed', 'How many portions are available?', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      if (pr == null || pr < 0) {
        Get.snackbar('Price needed', 'Enter a price per portion', snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    setState(() => _uploading = true);
    try {
      final key = await _repo.uploadPhoto(_image!);
      await _repo.create(
        photoKey: key,
        lat: _lat!,
        lng: _lng!,
        dishName: _dish.text.trim(),
        caption: _caption.text.trim(),
        isAvailable: _available,
        portionsTotal: _available ? int.tryParse(_portions.text.trim()) : null,
        price: _available ? _price.text.trim() : null,
        pickupArea: _available ? _area.text.trim() : null,
      );
      Get.back();
      Get.snackbar('Story posted', 'Your story is live for the next 24 hours.',
          snackPosition: SnackPosition.BOTTOM);
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? (e.response!.data['message'] as String?) : null;
      Get.snackbar('Story failed', msg ?? e.message ?? 'Try again', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New story')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => _pick(ImageSource.gallery),
              child: AspectRatio(
                aspectRatio: 9 / 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.hairline),
                    image: _image != null
                        ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 44, color: AppTheme.inkSoft),
                            const SizedBox(height: 10),
                            Text('Tap to pick a dish photo',
                                style: TextStyle(color: AppTheme.inkSoft, fontSize: 13)),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Camera'),
                    onPressed: () => _pick(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                    onPressed: () => _pick(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _dish,
              decoration: const InputDecoration(labelText: 'Dish name (e.g. Khichuri)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Caption (optional)'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.hairline),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available to buy', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _available
                      ? 'Neighbors can WhatsApp to reserve a portion.'
                      : 'Just a "look at this" share — no sales.',
                  style: const TextStyle(color: AppTheme.inkSoft, fontSize: 12),
                ),
                value: _available,
                activeThumbColor: AppTheme.seed,
                onChanged: (v) => setState(() => _available = v),
              ),
            ),
            if (_available) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _portions,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Portions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price (৳)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _area,
                decoration: const InputDecoration(labelText: 'Pickup area (e.g. Gulshan-2)'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.hairline),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.inkSoft),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cash on pickup. Add a WhatsApp number on your profile so buyers can reach you.',
                        style: TextStyle(color: AppTheme.inkSoft, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _uploading ? null : _submit,
              child: _uploading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post story'),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Disappears in 24 hours',
                  style: TextStyle(color: AppTheme.inkSoft, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
