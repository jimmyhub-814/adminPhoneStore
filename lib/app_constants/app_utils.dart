import 'dart:io';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/storages.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class AppUtils {
  const AppUtils._();
  static void showMessage(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  static String formatPhone(String input) {
    String digits = input.trim();

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '+84$digits';
  }

  static void hideLoading(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? suffix,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle:
          const TextStyle(color: AppColors.iconSecondary, fontSize: 13.5),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
      suffixIcon: suffix,
      prefixIcon: prefix,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.bg, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  static Future<String?> pickImage(
      ImageSource source, ImagePicker picker) async {
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Edit Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: AppColors.surface,
          ),
        ],
      );

      return cropped!.path;
    }
    return null;
  }

  static String mapErrorMessage(String code) {
    return switch (code) {
      'invalid-verification-code' => 'Mã OTP không đúng',
      'session-expired' => 'Mã OTP đã hết hạn, vui lòng gửi lại',
      'too-many-requests' => 'Thử lại sau vài phút',
      _ => 'Đã có lỗi xảy ra',
    };
  }

  static Future<String?> pickImageCamera(
      {required CropAspectRatio aspectRatio}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh',
            toolbarColor: const Color(0xFF1A1A2E),
            toolbarWidgetColor: AppColors.surface,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Cắt ảnh'),
        ],
      );
      return croppedFile?.path;
    }
    return null;
  }

  static Future<String?> pickImageGallery(
      {required CropAspectRatio aspectRatio}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh',
            toolbarColor: const Color(0xFF1A1A2E),
            toolbarWidgetColor: AppColors.surface,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Cắt ảnh'),
        ],
      );
      return croppedFile?.path;
    }
    return null;
  }

  static void showImageSourcePicker(BuildContext context, Widget child) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn ảnh từ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: child,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  static Future<String> uploadImage(String id, String filePath) async {
    final ref = Storages.category(id);
    await ref.putFile(File(filePath));
    String? imageUrl = await ref.getDownloadURL();
    return imageUrl;
  }

  static Future<String?> chooseImage(
      BuildContext context, ImagePicker picker) async {
    return await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            20,
          ),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take a photo"),
              onTap: () async {
                final image = await pickImage(ImageSource.camera, picker);

                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text("Choose from gallery"),
              onTap: () async {
                final image = await pickImage(ImageSource.gallery, picker);

                if (context.mounted) {
                  Navigator.pop(context, image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
