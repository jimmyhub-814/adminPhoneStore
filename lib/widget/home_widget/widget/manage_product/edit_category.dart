import 'dart:io';
import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/storages.dart';
import 'package:admin/models/category.dart';
import 'package:admin/provider/category.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:image_cropper/image_cropper.dart';

class EditCategoryScreen extends StatefulWidget {
  static const route = '/edit-category';
  const EditCategoryScreen({super.key});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final TextEditingController categoryController = TextEditingController();
  String? _pickedImage;
  String? categoryImageUrl;
  final ImagePicker picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImageCamera({
    required CropAspectRatio aspectRatio,
  }) async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: aspectRatio,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Cut image',
              toolbarColor: Colors.blueAccent,
              toolbarWidgetColor: AppColors.surface,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Cut image'),
          ],
        );
        if (croppedFile != null) {
          setState(() => _pickedImage = croppedFile.path);
        }
      } catch (e, stack) {
        debugPrint('❌ Lỗi khi crop ảnh: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  Future<void> _pickImageGallery({
    required CropAspectRatio aspectRatio,
  }) async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cut image',
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: AppColors.surface,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Cut image'),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _pickedImage = croppedFile.path;
        });
      }
    }
  }

  void uploadImage() async {
    await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                _pickImageCamera(
                    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageGallery(
                    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1));
              },
              child: const Text('Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteImage(String imagePath) async {
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(imagePath);
      await storageRef.delete();
      print('Xóa ảnh thành công');
    } catch (e) {
      print('Lỗi khi xóa ảnh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var categoriesProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    final data = ModalRoute.of(context)!.settings.arguments as Category;
    categoryController.text = data.categoryName;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa danh mục',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.iconDisabled,
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: AppColors.dark.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _pickedImage == null
                          ? Image.network(
                              data.categoryImage,
                              height: 130,
                              width: 130,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_pickedImage!),
                              height: 130,
                              width: 130,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: uploadImage,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Đổi ảnh'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Label
            const Text(
              "Tên danh mục",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: categoryController,
              decoration: InputDecoration(
                hintText: 'Nhập tên danh mục…',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isUploading
              ? null
              : () async {
                  if (categoryController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập tên danh mục!'),
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _isUploading = true;
                  });

                  try {
                    if (_pickedImage != null) {
                      await deleteImage(data.categoryImage);
                      final ref = Storages.category(data.id);
                      await ref.putFile(File(_pickedImage!));
                      categoryImageUrl = await ref.getDownloadURL();
                    }

                    final category = Category(
                      id: data.id,
                      categoryImage: _pickedImage != null
                          ? categoryImageUrl!
                          : data.categoryImage,
                      categoryName: categoryController.text.trim(),
                    );

                    categoriesProvider.editItem(category);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cập nhật thành công!')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  } finally {
                    setState(() {
                      _isUploading = false;
                    });
                  }
                },
          child: _isUploading
              ? LoadingAnimationWidget.waveDots(
                  color: AppColors.primary,
                  size: 60,
                )
              : const Text(
                  "Cập nhật",
                  style: TextStyle(fontSize: 16, color: AppColors.surface),
                ),
        ),
      ),
    );
  }
}
