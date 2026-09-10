import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/feedback.dart';
import 'package:admin/models/product.dart';
import 'package:admin/models/variant.dart';
import 'package:admin/provider/product.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/shared_widgets/custom_card.dart';
import 'package:admin/widget/shared_widgets/safe_image.dart';
import 'package:admin/widget/home_widget/widget/search_screen.dart';
import 'package:admin/widget/home_widget/widget/manage_product/add_product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class ProductDetail extends StatefulWidget {
  static const routeName = '/product-detail';

  final String id;

  const ProductDetail({super.key, required this.id});

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  late final PageController _pageController =
      PageController(viewportFraction: 1);
  final ValueNotifier<int> selectedVariantIndex = ValueNotifier<int>(0);
  late Future<Product?> _productFuture;
  Future<List<FeedBack>>? feedbackFuture;
  Future<List<Product>>? _relatedFuture;
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  bool _initialized = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    final productProvider = context.read<ProductProvider>();

    _productFuture = productProvider.getProduct(widget.id);

    feedbackFuture ??= context.read<ProductProvider>().getFeedBack(widget.id);

    _productFuture.then((product) {
      if (product != null) {
        _relatedFuture ??=
            productProvider.relatedItem(product.id, product.categoryId);
        setState(() {});
      }
    });

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (_currentPageNotifier.value != page) {
        _currentPageNotifier.value = page;
      }
    });

    _initialized = true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    selectedVariantIndex.dispose();
    super.dispose();
  }

  void _onVariantSelected(int index, Product product) {
    selectedVariantIndex.value = index;

    final variantImage = product.listVariants[index].image;
    final allImages = [
      if (product.mainImage.isNotEmpty) product.mainImage,
      ...product.extraImages,
      ...product.listVariants.map((v) => v.image),
    ];

    final pageIndex = allImages.indexOf(variantImage);
    if (pageIndex != -1) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<ProductProvider>().getProduct(widget.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color.fromARGB(255, 255, 248, 248),
            body: Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return _buildEmpty();
        }

        final product = snapshot.data!;
        return _buildProductUI(product);
      },
    );
  }

  Widget _buildProductUI(Product product) {
    final List<String> allImages = [
      if (product.mainImage.isNotEmpty) product.mainImage,
      ...product.extraImages,
      ...product.listVariants.map((v) => v.image ?? product.mainImage),
    ];

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
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    ),
                    child: Hero(
                      tag: 'search-bar',
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: Color(
                                  0xFFBDBDBD,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Tìm kiếm...',
                                style: TextStyle(
                                  color: Color(0xFFBDBDBD),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AddProduct.routeName,
                      arguments: AddProduct(product: product),
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 25,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: const Color(0xFFEEEEEE),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: AppColors.surface,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 300,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: allImages.length,
                          itemBuilder: (context, i) {
                            return SafeImage(
                              url: allImages[i],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      if (allImages.length > 1)
                        Positioned(
                          bottom: 15,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ValueListenableBuilder<int>(
                              valueListenable: _currentPageNotifier,
                              builder: (context, currentPage, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    allImages.length,
                                    (i) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
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
                                );
                              },
                            ),
                          ),
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
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
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
                                    color: Color(0xFFF59E0B),
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
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                                onTap: () => _onVariantSelected(i, product),
                                child: AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 200,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
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
                      const SizedBox(height: 12),
                      FutureBuilder(
                        future: feedbackFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: LoadingAnimationWidget.waveDots(
                                  color: AppColors.primary, size: 40),
                            );
                          }

                          final feedbacks = snapshot.data ?? [];

                          if (feedbacks.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Chưa có đánh giá nào',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            );
                          }

                          final isExpanded = ValueNotifier(false);

                          return ValueListenableBuilder(
                            valueListenable: isExpanded,
                            builder: (context, expanded, _) {
                              final displayed = expanded
                                  ? feedbacks
                                  : feedbacks.take(1).toList();
                              return Column(
                                children: [
                                  ...displayed
                                      .map((item) => _buildReviewItem(item)),
                                  if (feedbacks.length > 1)
                                    TextButton(
                                      onPressed: () =>
                                          isExpanded.value = !expanded,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            expanded
                                                ? 'Ẩn bớt'
                                                : 'Xem thêm ${feedbacks.length - 1} đánh giá',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.primary),
                                          ),
                                          Icon(
                                            expanded
                                                ? Icons
                                                    .keyboard_arrow_up_rounded
                                                : Icons
                                                    .keyboard_arrow_down_rounded,
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
                      const Text(
                        'Sản phẩm liên quan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder(
                        future: _relatedFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: LoadingAnimationWidget.waveDots(
                                  color: AppColors.primary, size: 40),
                            );
                          }
                          final related = snapshot.data ?? [];
                          if (related.isEmpty) {
                            return const Center(
                              child: Text(
                                'Không có sản phẩm liên quan',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            );
                          }
                          return GridView.builder(
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
                            itemCount: related.length,
                            itemBuilder: (_, i) =>
                                CustomCard(product: related[i]),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context, variant, finalPrice),
        );
      },
    );
  }

  Widget _buildBottomBar(
      BuildContext context, Variants variant, double finalPrice) {
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
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_shopping_cart_outlined,
              ),
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
                    const Text(
                      'Mua ngay',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.surface,
                          fontWeight: FontWeight.w500),
                    ),
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

  Widget _buildReviewItem(FeedBack item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SafeImage(
              url: item.userAvatar,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        item.vote,
                        (_) => const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.feedBackText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.feedBackText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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

    final isExpanded = ValueNotifier(false);
    return ValueListenableBuilder<bool>(
      valueListenable: isExpanded,
      builder: (context, expanded, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Text(
                '${text.substring(0, threshold)}...',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              secondChild: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => isExpanded.value = !expanded,
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có sản phẩm nào',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
