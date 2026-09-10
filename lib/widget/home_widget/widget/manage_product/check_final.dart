import 'dart:io';
import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/providers.dart';
import 'package:admin/app_constants/storages.dart';
import 'package:admin/provider/product.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/home.dart';
import 'package:admin/widget/shared_widgets/safe_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../models/product.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class CheckFinal extends StatefulWidget {
  final Product product;
  final String status;
  static const routeName = '/checkFinal';
  const CheckFinal({super.key, required this.product, required this.status});

  @override
  State<CheckFinal> createState() => _CheckFinalState();
}

enum CheckFinalStatus { update, add }

class _CheckFinalState extends State<CheckFinal> {
  final ValueNotifier<int> selectedVariantIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _descExpanded = ValueNotifier(false);
  late List<String> allImages;
  bool _isInitialized = false;
  final PageController _pageController = PageController(viewportFraction: 1);
  List<String> extraDelete = [];
  List<String> extraAdd = [];
  List<String> variantsDelete = [];
  List<String> variantsAdd = [];
  bool _isUploading = false;
  String mainImage = '';

  bool isFirebaseUrl(String url) =>
      url.startsWith("https://") || url.startsWith("gs://");
  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (_currentPageNotifier.value != page) {
        _currentPageNotifier.value = page;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    selectedVariantIndex.dispose();
    _currentPageNotifier.dispose();
    _descExpanded.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeData();
    }
  }

  Future<void> safeDeleteImage(String url) async {
    if (isFirebaseUrl(url)) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (e) {
        print(e);
      }
    }
  }

  bool _isLocalFile(String? path) {
    if (path == null || path.trim().isEmpty) return false;
    if (isFirebaseUrl(path)) return false;
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<String> _compressAndUpload(String localPath, Reference ref) async {
    try {
      final bytes = await File(localPath).readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        await ref.putFile(File(localPath));
        return await ref.getDownloadURL();
      }

      final resized =
          decoded.width > 1080 ? img.copyResize(decoded, width: 1080) : decoded;

      final compressed = img.encodeJpg(resized, quality: 75);
      await ref.putData(Uint8List.fromList(compressed));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Compress error: $e');
      await ref.putFile(File(localPath));
      return await ref.getDownloadURL();
    }
  }

  Future<void> _handleUpload(BuildContext context) async {
    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      if (widget.status == CheckFinalStatus.add.name) {
        // Upload TẤT CẢ song song cùng lúc
        await Future.wait([
          // Main image
          if (_isLocalFile(widget.product.mainImage))
            _compressAndUpload(
              widget.product.mainImage,
              Storages.product(widget.product.id),
            ).then((url) => widget.product.mainImage = url),

          // Extra images
          ...widget.product.extraImages
              .asMap()
              .entries
              .where((e) => _isLocalFile(e.value))
              .map((e) async {
            final id = const Uuid().v4();
            widget.product.extraImages[e.key] =
                await _compressAndUpload(e.value, Storages.product(id));
          }),

          // Variant images
          ...widget.product.listVariants
              .where((v) => _isLocalFile(v.image))
              .map((v) async {
            v.image = await _compressAndUpload(
              v.image!,
              Storages.variant(v.id),
            );
          }),
        ]);

        await context.read<ProductProvider>().addItem(widget.product);

        if (!mounted) return;
        _showSnack('Tải lên thành công!');
        Navigator.pushNamedAndRemoveUntil(
            context, HomeScreen.routeName, (route) => false);
      } else if (widget.status == CheckFinalStatus.update.name) {
        final oldMainUrl = mainImage;

        await Future.wait([
          // Main image
          if (_isLocalFile(widget.product.mainImage))
            _compressAndUpload(
              widget.product.mainImage,
              Storages.product(widget.product.id),
            ).then((url) async {
              widget.product.mainImage = url;
              if (isFirebaseUrl(oldMainUrl) && oldMainUrl != url) {
                await safeDeleteImage(oldMainUrl);
              }
            }),

          // Extra images mới
          ...widget.product.extraImages
              .asMap()
              .entries
              .where((e) => _isLocalFile(e.value))
              .map((e) async {
            final id = const Uuid().v4();
            widget.product.extraImages[e.key] =
                await _compressAndUpload(e.value, Storages.product(id));
          }),

          // Variant images mới
          ...widget.product.listVariants
              .where((v) => _isLocalFile(v.image))
              .map((v) async {
            v.image = await _compressAndUpload(
              v.image!,
              Storages.variant(v.id),
            );
          }),

          // Xóa ảnh cũ song song
          ...extraDelete.map(safeDeleteImage),
          ...variantsDelete.map(safeDeleteImage),
        ]);

        await Collections.products
            .doc(widget.product.id)
            .set(widget.product.toMap(), SetOptions(merge: true));

        if (!mounted) return;
        _showSnack('Cập nhật thành công!');
        Navigator.pushNamedAndRemoveUntil(
            context, HomeScreen.routeName, (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Upload error: $e');
      _showSnack('Lỗi khi tải lên: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<String> uploadImageIfLocal(String path, String folder) async {
    if (isFirebaseUrl(path)) return path;
    if (!File(path).existsSync()) return path;
    final id = const Uuid().v4();
    final ref = FirebaseStorage.instance.ref().child('$folder/$id.jpg');
    await ref.putFile(File(path));
    return await ref.getDownloadURL();
  }

  Future<void> _initializeData() async {
    if (widget.status == CheckFinalStatus.update.name) {
      final productProvider = context.read<ProductProvider>();
      final snapshot = await productProvider.getProduct(widget.product.id);

      List<String> extraImagesStr = snapshot!.extraImages;

      List<String> variantsImagesStr = snapshot.listVariants
          .where((v) => v.image != null && v.image!.isNotEmpty)
          .map((v) => v.image!)
          .toList();

      List<String> variantsImagesProduct = widget.product.listVariants
          .where((v) => v.image != null && v.image!.isNotEmpty)
          .map((v) => v.image!)
          .toList();

      if (widget.product.extraImages.isNotEmpty) {
        extraAdd = [
          ...extraImagesStr
              .where((x) => !widget.product.extraImages.contains(x))
        ];
        extraDelete = [
          ...widget.product.extraImages
              .where((x) => !extraImagesStr.contains(x))
        ];
      }

      variantsAdd = [
        ...variantsImagesStr.where((x) => !variantsImagesProduct.contains(x))
      ];

      variantsDelete = widget.product.listVariants
          .where((v) =>
              v.image != null &&
              v.image!.isNotEmpty &&
              !variantsImagesStr.contains(v.image))
          .map((v) => v.image!)
          .toList();

      mainImage = snapshot.mainImage;
    }

    setState(() {
      allImages = [
        if (widget.product.mainImage.trim().isNotEmpty)
          widget.product.mainImage,
        ...widget.product.extraImages.where(
          (e) => e.trim().isNotEmpty,
        ),
        ...widget.product.listVariants
            .where(
              (v) => v.image != null && v.image!.trim().isNotEmpty,
            )
            .map((v) => v.image!),
      ];
      _isInitialized = true;
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (_currentPageNotifier.value != page) {
        _currentPageNotifier.value = page;
      }
    });
  }

  void _onVariantSelected(int index) {
    selectedVariantIndex.value = index;

    final variantImage = widget.product.listVariants[index].image;
    if (variantImage != null && variantImage.isNotEmpty) {
      final targetIndex = allImages.indexOf(variantImage);
      if (targetIndex != -1) {
        _pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(
          color: AppColors.surface,
        )),
      );
    }
    return _buildProductUI(widget.product);
  }

  Widget _buildProductUI(Product product) {
    return ValueListenableBuilder(
      valueListenable: selectedVariantIndex,
      builder: (context, variantIdx, _) {
        final variant = product.listVariants[variantIdx];
        final double price = variant.phonePrice;
        final double discount = variant.phoneDiscount;
        final double finalPrice = price - (price * discount / 100);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: AppbarIcon(),
            title: const Text('Xem'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: const Color(0xFFEEEEEE)),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: allImages.length,
                          itemBuilder: (context, i) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: SafeImage(
                                url: allImages[i],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                      ),
                      if (allImages.length > 1)
                        ValueListenableBuilder<int>(
                          valueListenable: _currentPageNotifier,
                          builder: (context, currentPage, _) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  allImages.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    width: currentPage == i ? 16 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: currentPage == i
                                          ? AppColors.primary
                                          : const Color(0xFFBDBDBD),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                                height: 1.3,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  product.fbInfo.averageRating.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(
                                      0xFFF59E0B,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${product.fbInfo.totalRating} đánh giá)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• Đã bán ${product.salesVolume}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${NumberFormat("#,###", "en_US").format(finalPrice)}đ',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (discount > 0) ...[
                            Text(
                              '${NumberFormat("#,###", "en_US").format(price)}đ',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFBDBDBD),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${discount.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (product.listVariants.length > 1)
                  Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phân loại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            product.listVariants.length,
                            (i) {
                              final isSelected = variantIdx == i;
                              return GestureDetector(
                                onTap: () => _onVariantSelected(i),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                            .withValues(alpha: 0.08)
                                        : AppColors.surface,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.listVariants[i].phoneType,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin sản phẩm',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDescription(product.phoneDescription),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Đánh giá',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 13,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${product.fbInfo.averageRating} (${product.fbInfo.totalRating})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sản phẩm liên quan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        primary: false,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: 4,
                        itemBuilder: (_, i) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context, finalPrice),
          floatingActionButton: FloatingActionButton(
            onPressed: _isUploading ? null : () => _handleUpload(context),
            backgroundColor: Colors.blue,
            child: _isUploading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.surface,
                    ),
                  )
                : const Icon(Icons.upload_rounded, color: AppColors.surface),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, double finalPrice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_shopping_cart_outlined,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Mua ngay',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.surface,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '${NumberFormat("#,###", "en_US").format(finalPrice)}đ',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(String text) {
    const int threshold = 150;
    final bool isLong = text.length > threshold;

    if (!isLong) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          height: 1.6,
        ),
      );
    }

    // FIX #5: Dùng _descExpanded từ state thay vì tạo mới mỗi lần build
    return ValueListenableBuilder<bool>(
      valueListenable: _descExpanded,
      builder: (context, expanded, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Text(
                '${text.substring(0, threshold)}...',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280), height: 1.6),
              ),
              secondChild: Text(
                text,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280), height: 1.6),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _descExpanded.value = !expanded,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Ẩn bớt' : 'Xem thêm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
