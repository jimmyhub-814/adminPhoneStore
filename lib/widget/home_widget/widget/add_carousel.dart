import 'dart:io';
import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/storages.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'package:image_cropper/image_cropper.dart';

class AddCarousel extends StatefulWidget {
  static const String routeName = '/add-carousel';
  const AddCarousel({super.key});

  @override
  State<AddCarousel> createState() => _AddCarouselState();
}

class _AddCarouselState extends State<AddCarousel> {
  final ImagePicker picker = ImagePicker();
  List<String> urlDelete = [];
  bool _isUploading = false;
  List<XFile> listImg = [];
  List<String> oldImages = [];

  @override
  void initState() {
    super.initState();
    loadOldImages();
  }

  Future<void> loadOldImages() async {
    oldImages = await getAllCarousel();
    setState(() {});
  }

  Future<List<String>> getAllCarousel() async {
    final ref = Storages.carousels;
    final result = await ref.listAll();
    List<String> urls = [];

    for (var item in result.items) {
      urls.add(await item.getDownloadURL());
    }
    return urls;
  }

  Future<void> _pickImageCamera({required CropAspectRatio aspectRatio}) async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: aspectRatio,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop ảnh',
            toolbarColor: Colors.blueAccent,
            toolbarWidgetColor: AppColors.surface,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop ảnh'),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          listImg.add(XFile(croppedFile.path));
        });
      }
    }
  }

  Future<void> _pickImageGallery({required CropAspectRatio aspectRatio}) async {
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      List<XFile> croppedImages = [];

      for (final image in images) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: aspectRatio,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop ảnh',
              toolbarColor: Colors.blueAccent,
              toolbarWidgetColor: AppColors.surface,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Crop ảnh'),
          ],
        );

        if (croppedFile != null) {
          croppedImages.add(
            XFile(
              croppedFile.path,
            ),
          );
        }
      }

      if (croppedImages.isNotEmpty) {
        setState(
          () => listImg.addAll(
            croppedImages,
          ),
        );
      }
    }
  }

  void uploadImage() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Chọn nguồn ảnh",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                title: const Text("Chụp ảnh"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageCamera(
                    aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 1),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text("Chọn từ thư viện"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageGallery(
                    aspectRatio: const CropAspectRatio(ratioX: 2, ratioY: 1),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> deleteImage(List<String> url) async {
    for (var i in url) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(i);
        await ref.delete();

        oldImages.remove(i);
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Xóa ảnh thành công"),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khi xóa: $e"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.dark,
        leading: AppbarIcon(),
        title: const Text(
          "Thống kê doanh thu",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ảnh hiện tại",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (oldImages.isNotEmpty)
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: oldImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final imgUrl = oldImages[index];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imgUrl,
                                width: 220,
                                height: 160,
                                fit: BoxFit.cover,
                                frameBuilder: (context, child, frame,
                                    wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded) return child;

                                  if (frame == null) {
                                    return Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                        width: 220,
                                        height: 160,
                                        color: Colors.grey,
                                      ),
                                    );
                                  }

                                  return child;
                                },
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: GestureDetector(
                                onTap: () {
                                  urlDelete.add(imgUrl);
                                  print('complete');
                                  print(urlDelete);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.dark.withValues(alpha: 0.54),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: AppColors.surface,
                                  ),
                                ),
                              ),
                            )
                          ],
                        );
                      },
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 220,
                              height: 160,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 220,
                              height: 160,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
            GestureDetector(
              onTap: uploadImage,
              child: Container(
                padding: const EdgeInsets.all(28),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 45,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Chọn ảnh mới",
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (listImg.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  itemCount: listImg.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (_, index) {
                    final file = File(listImg[index].path);

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => listImg.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.dark.withValues(alpha: 0.54),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 15,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  },
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    "Chưa chọn ảnh nào",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () async {
                        if (listImg.isEmpty && urlDelete.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Vui lòng chọn ít nhất 1 ảnh"),
                            ),
                          );
                          return;
                        }

                        setState(() => _isUploading = true);

                        try {
                          deleteImage(urlDelete);
                          for (var img in listImg) {
                            String id = const Uuid().v4();
                            final ref = Storages.carousel(id);
                            await ref.putFile(File(img.path));
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Upload ảnh thành công!"),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Lỗi: $e"),
                            ),
                          );
                        } finally {
                          setState(() => _isUploading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: listImg.isEmpty
                      ? AppColors.border
                      : _isUploading
                          ? AppColors.border
                          : Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isUploading
                    ? LoadingAnimationWidget.waveDots(
                        color: AppColors.primary,
                        size: 60,
                      )
                    : const Text(
                        "Upload All",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.surface,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
