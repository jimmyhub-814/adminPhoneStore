import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/app_utils.dart';
import 'package:admin/models/category.dart';
import 'package:admin/models/product.dart';
import 'package:admin/models/variant.dart';
import 'package:admin/provider/category.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/shared_widgets/safe_image.dart';
import 'package:admin/widget/home_widget/widget/manage_product/check_final.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_cropper/image_cropper.dart';

class AddProduct extends StatefulWidget {
  final Product? product;
  static const routeName = '/addProduct';
  const AddProduct({super.key, this.product});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> with TickerProviderStateMixin {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController _categorySearchController;
  late String? mainImage = widget.product?.mainImage;
  late List<String> listImg;

  late List<Variants> variantsList = widget.product?.listVariants ?? [];
  final TextEditingController priceController = TextEditingController();
  final TextEditingController variantController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  final picker = ImagePicker();
  String? _variantImagePath;

  late String categoryId = widget.product?.categoryId ?? '';
  String? _pickedVariantsImage;
  late String categoryName;
  List<Category> _categories = [];
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    variantsList = List<Variants>.from(
      widget.product?.listVariants ?? [],
    );
    listImg = List<String>.from(
      widget.product?.extraImages ?? [],
    );

    nameController = TextEditingController(text: widget.product?.title ?? '');

    _categorySearchController = TextEditingController(text: '');
    descriptionController =
        TextEditingController(text: widget.product?.phoneDescription ?? '');
  }

  @override
  void dispose() {
    _categorySearchController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    discountController.dispose();
    variantController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      final categoryProvider = context.read<CategoryProvider>().getCategories();
      categoryProvider.then((cats) {
        if (!mounted) return;
        setState(() {
          _categories = cats;

          if (widget.product != null) {
            final category = cats.cast<Category?>().firstWhere(
                  (e) => e?.id == widget.product!.categoryId,
                  orElse: () => null,
                );
            _categorySearchController.text = category?.categoryName ?? '';
          }
        });
      }).catchError((_) {});
      _isDataLoaded = true;
    }
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.bg, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryExtraDark,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Category bottom sheet
  // ──────────────────────────────────────────────────
  void _showCategorySearch(BuildContext context) {
    final searchController = TextEditingController();
    List<Category> filtered = List.from(_categories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.85,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Chọn danh mục',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryExtraDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: AppUtils.inputDecoration(
                          label: '',
                          hint: 'Tìm danh mục...',
                          prefix: const Icon(Icons.search_rounded,
                              size: 18, color: AppColors.iconSecondary),
                          suffix: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    searchController.clear();
                                    setModalState(() {
                                      filtered = List.from(_categories);
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            filtered = _categories
                                .where((c) => c.categoryName
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy danh mục',
                                style: TextStyle(
                                  color: AppColors.iconDisabled,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: AppColors.bg,
                              ),
                              itemBuilder: (_, i) {
                                final cat = filtered[i];
                                final isSelected = categoryId == cat.id;
                                return ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  tileColor: isSelected
                                      ? AppColors.surfaceLight
                                      : Colors.transparent,
                                  onTap: () {
                                    setState(() {
                                      categoryId = cat.id;
                                      _categorySearchController.text =
                                          cat.categoryName;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  title: Text(
                                    cat.categoryName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.primaryExtraDark,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded,
                                          color: AppColors.primary, size: 20)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────
  // Image picking
  // ──────────────────────────────────────────────────
  Future<void> _pickImageGalleryType(
      String variant, CropAspectRatio aspectRatio) async {
    if (variant == 'product') {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        List<XFile> croppedImages = [];
        for (final image in images) {
          try {
            final croppedFile = await ImageCropper().cropImage(
              sourcePath: image.path,
              aspectRatio: aspectRatio,
              uiSettings: [
                AndroidUiSettings(
                  toolbarTitle: 'Cắt ảnh',
                  toolbarColor: AppColors.primary,
                  toolbarWidgetColor: AppColors.surface,
                  lockAspectRatio: true,
                ),
                IOSUiSettings(title: 'Cắt ảnh'),
              ],
            );
            if (croppedFile != null) {
              croppedImages.add(XFile(croppedFile.path));
            }
          } catch (e) {
            debugPrint('Lỗi crop: $e');
          }
        }
        if (croppedImages.isNotEmpty) {
          setState(() {
            listImg.addAll(
              croppedImages.map((e) => e.path),
            );
          });
        }
      }
    } else {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        try {
          final croppedFile = await ImageCropper().cropImage(
            sourcePath: image.path,
            aspectRatio: aspectRatio,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Cắt ảnh',
                toolbarColor: AppColors.primary,
                toolbarWidgetColor: AppColors.surface,
                lockAspectRatio: true,
              ),
              IOSUiSettings(title: 'Cắt ảnh'),
            ],
          );
          if (croppedFile != null) {
            setState(() {
              if (variant == 'variants')
                _pickedVariantsImage = croppedFile.path;
              if (variant == 'mainImage') mainImage = croppedFile.path;
            });
          }
        } catch (e) {
          debugPrint('Lỗi crop: $e');
        }
      }
    }
  }

  Future<void> _pickImageCameraType(
      String variant, CropAspectRatio aspectRatio) async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: aspectRatio,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Cắt ảnh',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: AppColors.surface,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Cắt ảnh'),
          ],
        );
        if (croppedFile != null) {
          setState(() {
            if (variant == 'product')
              listImg.add((XFile(croppedFile.path)).toString());
            if (variant == 'variants') _pickedVariantsImage = croppedFile.path;
            if (variant == 'mainImage') mainImage = croppedFile.path;
          });
        }
      } catch (e) {
        debugPrint('Lỗi crop: $e');
      }
    }
  }

  void uploadImage(String variant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Chụp ảnh',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageCameraType(
                      variant, const CropAspectRatio(ratioX: 1, ratioY: 1));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Chọn từ thư viện',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageGalleryType(
                    variant,
                    const CropAspectRatio(ratioX: 1, ratioY: 1),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // Logic
  // ──────────────────────────────────────────────────
  void _addVariant() {
    if (variantController.text.isEmpty ||
        priceController.text.isEmpty ||
        quantityController.text.isEmpty ||
        discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập đầy đủ thông tin phân loại!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (priceController.text.length > 8) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập giá thấp dưới 100 triệu!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (priceController.text.length < 4) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập giá không dưới 1000đ!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (quantityController.text.length > 8) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập số lượng thấp hơn 100 triệu!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (double.parse(quantityController.text) < 1) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập số lượng không dưới 1!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (double.parse(discountController.text) > 99) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập giảm giá không quá 99%!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (double.parse(discountController.text) < 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập giảm giá không dưới 0%!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    final variant = Variants(
      id: const Uuid().v4(),
      image: (_pickedVariantsImage != null && _pickedVariantsImage!.isNotEmpty)
          ? _pickedVariantsImage
          : null, // ← đảm bảo null thật sự, không phải empty string
      phoneType: variantController.text.trim(),
      phoneDiscount: double.parse(discountController.text.trim()),
      phonePrice: double.parse(priceController.text.trim()),
      phoneQuantity: int.parse(quantityController.text.trim()),
    );

    setState(() {
      variantsList.add(variant);
      _pickedVariantsImage = null;
      variantController.clear();
      priceController.clear();
      quantityController.clear();
      discountController.clear();
    });
  }

  void _submitProduct() {
    if (mainImage == null ||
        nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập đủ thông tin sản phẩm!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (variantsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng thêm ít nhất 1 phân loại!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final product = widget.product != null
        ? Product(
            id: widget.product!.id,
            categoryId: categoryId,
            extraImages: listImg,
            mainImage: mainImage!,
            title: nameController.text.trim(),
            listVariants: variantsList,
            phoneDescription: descriptionController.text.trim(),
            salesVolume: widget.product!.salesVolume,
            fbInfo: widget.product!.fbInfo,
          )
        : Product(
            id: const Uuid().v4(),
            categoryId: categoryId,
            extraImages: listImg,
            mainImage: mainImage!,
            title: nameController.text.trim(),
            listVariants: variantsList,
            phoneDescription: descriptionController.text.trim(),
            salesVolume: 0,
            fbInfo: FeedbackInfo(
              averageRating: 0,
              totalRating: 0,
              sumRating: 0,
            ),
          );

    Navigator.pushNamed(
      context,
      CheckFinal.routeName,
      arguments: CheckFinal(
          product: product, status: widget.product != null ? 'update' : 'add'),
    );
  }

  // ──────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryExtraDark,
        titleSpacing: 0,
        centerTitle: true,
        leading: AppbarIcon(onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Thông báo'),
                content: const Text(
                  'Bạn có chắc chắn muốn thoát?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('HỦY'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();

                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(color: AppColors.surface),
                    ),
                  ),
                ],
              );
            },
          );
        }),
        title: Text(
          widget.product != null ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.primaryExtraDark,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.bg, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section 1: Images ──
              _sectionCard(
                title: 'Hình ảnh sản phẩm',
                icon: Icons.photo_library_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ảnh chính',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iconSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: () => uploadImage('mainImage'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            color: mainImage == null
                                ? AppColors.surfaceLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: mainImage == null
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          ),
                          child: mainImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: AppColors.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Thêm ảnh chính',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary
                                            .withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      SafeImage(
                                        url: mainImage!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.contain,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          color: AppColors.dark
                                              .withValues(alpha: 0.38),
                                          child: const Text(
                                            'Nhấn để thay đổi',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppColors.surface,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Ảnh bổ sung',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iconSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 88,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...listImg.map(
                            (img) => Container(
                              margin: const EdgeInsets.only(
                                  right: 6, top: 6, left: 6),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SafeImage(
                                      url: img,
                                      height: 80,
                                      width: 72,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: -6,
                                    right: -6,
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => listImg.remove(img)),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 13, color: AppColors.surface),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => uploadImage('product'),
                            child: Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 28,
                                color: AppColors.primary.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Section 2: Product info ──
              _sectionCard(
                title: 'Thông tin sản phẩm',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _categorySearchController,
                      readOnly: true,
                      onTap: () => _showCategorySearch(context),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.primaryExtraDark),
                      decoration: AppUtils.inputDecoration(
                        label: 'Danh mục',
                        hint: 'Chọn danh mục...',
                        prefix: const Icon(Icons.category_outlined,
                            size: 18, color: AppColors.iconSecondary),
                        suffix: categoryId.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 16, color: AppColors.iconSecondary),
                                onPressed: () => setState(() {
                                  categoryId = '';
                                  _categorySearchController.clear();
                                }),
                              )
                            : const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.iconSecondary,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryExtraDark,
                      ),
                      decoration: AppUtils.inputDecoration(
                        label: 'Tên sản phẩm',
                        suffix: nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: AppColors.iconSecondary,
                                ),
                                onPressed: () => setState(
                                  () {
                                    nameController.clear();
                                  },
                                ),
                              )
                            : null,
                        prefix: const Icon(
                          Icons.label_outline,
                          size: 18,
                          color: AppColors.iconSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.primaryExtraDark),
                      decoration: AppUtils.inputDecoration(
                        label: 'Mô tả sản phẩm',
                        suffix: descriptionController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 16, color: AppColors.iconSecondary),
                                onPressed: () => setState(() {
                                  descriptionController.clear();
                                }),
                              )
                            : null,
                        hint: 'Nhập mô tả chi tiết...',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Section 3: Variants ──
              _sectionCard(
                title: 'Phân loại sản phẩm (Variants)',
                icon: Icons.tune_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Variant form
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.bg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image + variant name row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image picker
                              GestureDetector(
                                onTap: () => uploadImage('variants'),
                                child: _pickedVariantsImage == null &&
                                        (_variantImagePath == null ||
                                            _variantImagePath!.isEmpty)
                                    ? Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.4),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_outlined,
                                                size: 28,
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.7)),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Thêm ảnh',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 84,
                                          height: 84,
                                          child: SafeImage(
                                              width: 84,
                                              height: 84,
                                              url: _pickedVariantsImage != null
                                                  ? _pickedVariantsImage!
                                                  : _variantImagePath!),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: variantController,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primaryExtraDark),
                                      decoration: AppUtils.inputDecoration(
                                        label: 'Tên loại',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.bg),
                          const SizedBox(height: 14),

                          // Label row
                          const Text(
                            'GIÁ & TỒN KHO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iconSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Price field – full width with big font
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                            decoration: AppUtils.inputDecoration(
                              label: 'Giá bán (₫)',
                              hint: '0',
                              prefix: Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: AppColors.bg,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  '₫',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Quantity & discount side by side
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: quantityController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryExtraDark,
                                  ),
                                  decoration: AppUtils.inputDecoration(
                                    label: 'Số lượng',
                                    hint: '0',
                                    prefix: const Icon(
                                      Icons.inventory_outlined,
                                      size: 18,
                                      color: AppColors.iconSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: discountController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                  decoration: AppUtils.inputDecoration(
                                    label: 'Giảm %',
                                    hint: '0',
                                    suffix: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        '%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accent,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _addVariant,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Thêm phân loại',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _pickedVariantsImage = null;
                              _variantImagePath = null;
                              variantController.clear();
                              priceController.clear();
                              quantityController.clear();
                              discountController.clear();
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded,
                              size: 16, color: AppColors.iconSecondary),
                          label: const Text('Đặt lại',
                              style: TextStyle(color: AppColors.iconSecondary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            side: const BorderSide(color: AppColors.bg),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Variants list
                    if (variantsList.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'ĐÃ THÊM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.iconSecondary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${variantsList.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...variantsList.asMap().entries.map((entry) {
                        final v = entry.value;
                        return Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.bg),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(12),
                                ),
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: v.image == null || v.image!.isEmpty
                                      ? Container(
                                          color: AppColors.surfaceLight,
                                          child: const Icon(
                                              Icons.image_outlined,
                                              size: 22,
                                              color: AppColors.primary),
                                        )
                                      : SafeImage(
                                          width: 60,
                                          height: 60,
                                          url: v.image!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.phoneType,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                          color: AppColors.primaryExtraDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_formatPrice(v.phonePrice)}₫',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Row(
                                            children: [
                                              _tag(
                                                  'SL: ${v.phoneQuantity}',
                                                  AppColors.successLight,
                                                  AppColors.success),
                                              const SizedBox(width: 4),
                                              _tag(
                                                  '-${v.phoneDiscount}%',
                                                  AppColors.starLight,
                                                  AppColors.accent),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: AppColors.primary),
                                    onPressed: () {
                                      setState(() {
                                        variantController.text = v.phoneType;
                                        priceController.text =
                                            v.phonePrice.toString();
                                        quantityController.text =
                                            v.phoneQuantity.toString();
                                        discountController.text =
                                            v.phoneDiscount.toString();
                                        _variantImagePath = v.image;
                                        _pickedVariantsImage = v.image;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: AppColors.accent,
                                    ),
                                    onPressed: () =>
                                        setState(() => variantsList.remove(v)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitProduct,
        label: const Text(
          'Tiếp theo',
          style: TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
        icon: const Icon(Icons.arrow_forward_rounded,
            color: AppColors.surface, size: 20),
        backgroundColor: AppColors.primary,
        elevation: 4,
        extendedPadding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    final p = price.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = p.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(p[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}
