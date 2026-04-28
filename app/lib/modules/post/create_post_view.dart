import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'create_post_controller.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});
  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _ctrl = Get.put(CreatePostController());
  final _caption = TextEditingController();
  final _dish = TextEditingController();
  final _cuisine = TextEditingController();
  final _minutes = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    _dish.dispose();
    _cuisine.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _submit() {
    _ctrl.submit(
      caption: _caption.text.trim(),
      dishName: _dish.text.trim(),
      cuisine: _cuisine.text.trim(),
      cookingMinutes: int.tryParse(_minutes.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share a dish')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() => GestureDetector(
                  onTap: _ctrl.pickFromGallery,
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      image: _ctrl.imageFile.value != null
                          ? DecorationImage(image: FileImage(_ctrl.imageFile.value!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: _ctrl.imageFile.value == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text('Tap to add a photo', style: TextStyle(color: Colors.grey.shade700)),
                            ],
                          )
                        : null,
                  ),
                )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: _ctrl.pickFromCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text('Gallery'),
                    onPressed: _ctrl.pickFromGallery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(controller: _dish, decoration: const InputDecoration(labelText: 'Dish name (e.g. Khichuri)')),
            const SizedBox(height: 12),
            TextField(controller: _cuisine, decoration: const InputDecoration(labelText: 'Cuisine (Bengali, Italian…)')),
            const SizedBox(height: 12),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cooking minutes'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _caption,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Caption — tell the story'),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final ll = _ctrl.lat.value != null
                  ? '${_ctrl.lat.value!.toStringAsFixed(4)}, ${_ctrl.lng.value!.toStringAsFixed(4)}'
                  : 'Detecting…';
              return Row(
                children: [
                  const Icon(Icons.location_on, size: 18),
                  const SizedBox(width: 8),
                  Text('Location: $ll', style: TextStyle(color: Colors.grey.shade700)),
                ],
              );
            }),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
                  onPressed: _ctrl.isUploading.value ? null : _submit,
                  child: _ctrl.isUploading.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Share to feed'),
                )),
          ],
        ),
      ),
    );
  }
}
