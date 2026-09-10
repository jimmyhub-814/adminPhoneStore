import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/product.dart';
import 'package:admin/provider/product.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/shared_widgets/custom_card.dart';
import 'package:admin/widget/home_widget/widget/manage_product/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

class CategoryPage extends StatefulWidget {
  static const routeName = '/category';

  final String categoryId;
  final String categoryName;

  const CategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().resetCheckBox();
    });
    _productsFuture = context
        .read<ProductProvider>()
        .getProductsSameCategory(widget.categoryId);
  }

  void _loadProducts() {
    _productsFuture = context
        .read<ProductProvider>()
        .getProductsSameCategory(widget.categoryId);
  }

  void _refresh() {
    setState(() => _loadProducts());
  }

  Future<void> _deleteSelected(ProductProvider provider) async {
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: LoadingAnimationWidget.waveDots(
          color: AppColors.primary,
          size: 60,
        ),
      ),
    );

    await provider.deleteSelectedProducts();

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF1C1C1E),
        content: const Text(
          'Xóa sản phẩm thành công',
          style: TextStyle(
            color: AppColors.surface,
          ),
        ),
      ),
    );
    _refresh();
  }

  void _showDeleteConfirm(BuildContext ctx, ProductProvider provider) {
    final selectedCount = provider.selectedItems.values.where((e) => e).length;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'Bạn sắp xóa $selectedCount sản phẩm. Hành động này không thể hoàn tác.',
          style: TextStyle(
            color: AppColors.dark.withValues(alpha: 0.54),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
            ),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
            ),
            onPressed: () => _deleteSelected(provider),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: _buildAppBar(),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonGrid();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmpty();
          }
          return _buildGrid(snapshot.data!);
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.dark.withValues(alpha: 0.12),
      centerTitle: true,
      leading: AppbarIcon(),
      title: Text(
        widget.categoryName,
        style: const TextStyle(
          color: Color(0xFF1C1C1E),
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
      actions: [
        Consumer<ProductProvider>(
          builder: (context, provider, _) {
            final isSelecting = provider.isTrue;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelecting
                    ? TextButton(
                        key: const ValueKey('cancel'),
                        onPressed: () {
                          provider.clearSelectedItems();
                          provider.toggleCheckBoxVisible();
                        },
                        child: const Text(
                          'Huỷ',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : IconButton(
                        key: const ValueKey('delete'),
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.red,
                        ),
                        tooltip: 'Chọn để xóa',
                        onPressed: provider.toggleCheckBoxVisible,
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
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

  Widget _buildGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Consumer<ProductProvider>(
          builder: (context, provider, _) {
            final isChecked = provider.selectedItems[product.id] ?? false;
            return Stack(
              children: [
                CustomCard(
                  product: product,
                  onTap: () => provider.isTrue
                      ? provider.toggleSelection(product.id)
                      : Navigator.pushNamed(context, ProductDetail.routeName,
                          arguments: ProductDetail(id: product.id)),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  top: 8,
                  left: 8,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: provider.isTrue ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !provider.isTrue,
                      child: GestureDetector(
                        onTap: () => provider.toggleSelection(product.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isChecked ? Colors.red : AppColors.surface,
                            border: Border.all(
                              color:
                                  isChecked ? Colors.red : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.dark.withValues(alpha: 0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isChecked
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: AppColors.surface,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final selectedCount =
            provider.selectedItems.values.where((e) => e).length;
        final hasSelection = selectedCount > 0;

        return AnimatedSlide(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          offset: provider.isTrue ? Offset.zero : const Offset(0, 1.2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: provider.isTrue ? 1 : 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GestureDetector(
                  onTap: hasSelection
                      ? () => _showDeleteConfirm(context, provider)
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  14,
                                ),
                              ),
                              backgroundColor: const Color(0xFF1C1C1E),
                              content: const Text(
                                'Chưa chọn sản phẩm nào',
                                style: TextStyle(color: AppColors.surface),
                              ),
                            ),
                          ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: hasSelection
                            ? [const Color(0xFFFF3B30), const Color(0xFFFF6B6B)]
                            : [
                                Colors.grey.shade400,
                                Colors.grey.shade300,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: hasSelection
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              )
                            ]
                          : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: AppColors.surface,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Xóa sản phẩm',
                                  style: TextStyle(
                                    color: AppColors.surface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  hasSelection
                                      ? '$selectedCount sản phẩm đã chọn'
                                      : 'Chưa chọn sản phẩm nào',
                                  style: TextStyle(
                                    color: AppColors.surface
                                        .withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasSelection)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.surface.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$selectedCount',
                                style: const TextStyle(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
