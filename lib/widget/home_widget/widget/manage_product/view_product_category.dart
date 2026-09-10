import 'package:admin/widget/home_widget/widget/category.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/category.dart';
import 'package:admin/provider/category.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/home_widget/widget/manage_product/edit_category.dart';

class ViewItemCategory extends StatefulWidget {
  static const String routeName = '/view-item-category';
  const ViewItemCategory({super.key});

  @override
  State<ViewItemCategory> createState() => _ViewItemCategoryState();
}

class _ViewItemCategoryState extends State<ViewItemCategory> {
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).resetCheckBox();
    });
  }

  void _loadCategories() {
    _categoriesFuture =
        Provider.of<CategoryProvider>(context, listen: false).getCategories();
  }

  void _refresh() {
    setState(() {
      _loadCategories();
    });
  }

  Future<void> _deleteOne(
      BuildContext ctx, CategoryProvider provider, String id) async {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Center(
        child: LoadingAnimationWidget.waveDots(
          color: AppColors.primary,
          size: 60,
        ),
      ),
    );
    await provider.deleteCategoryWithProducts(id);
    if (ctx.mounted) Navigator.pop(ctx);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        _snackBar('Xóa danh mục thành công'),
      );
    }
    _refresh();
  }

  Future<void> _deleteSelected(
      BuildContext ctx, CategoryProvider provider) async {
    Navigator.pop(ctx);

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => Center(
        child: LoadingAnimationWidget.waveDots(
          color: AppColors.primary,
          size: 60,
        ),
      ),
    );
    await provider.deleteSelectedCategories();
    if (ctx.mounted) Navigator.pop(ctx);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        _snackBar('Đã xóa các danh mục được chọn'),
      );
    }
    _refresh();
  }

  SnackBar _snackBar(String msg) => SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF1C1C1E),
        content: Text(
          msg,
          style: const TextStyle(
            color: AppColors.surface,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: _buildAppBar(),
      body: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonList();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmpty();
          }
          return _buildList(snapshot.data!);
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
      shadowColor: Colors.black12,
      scrolledUnderElevation: 1,
      centerTitle: true,
      leading: AppbarIcon(),
      title: const Text(
        'Danh mục',
        style: TextStyle(
          color: Color(0xFF1C1C1E),
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.3,
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1C1C1E)),
      actions: [
        Consumer<CategoryProvider>(
          builder: (context, provider, _) {
            final isSelecting = provider.isTrue;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelecting
                    ? TextButton(
                        key: const ValueKey('cancel'),
                        onPressed: provider.resetCheckBox,
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemBuilder: (_, i) => _SkeletonTile(delay: i * 80),
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
            child: Icon(Icons.category_outlined,
                size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có danh mục nào',
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

  Widget _buildList(List<Category> categories) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        itemCount: categories.length,
        itemBuilder: (ctx, index) {
          final cat = categories[index];
          final isChecked = provider.selectedItems[cat.id] ?? false;

          return _CategoryTile(
            category: cat,
            isSelecting: provider.isTrue,
            isChecked: isChecked,
            onCheckToggle: () => provider.toggleSelection(cat.id),
            onTap: () => Navigator.pushNamed(
              ctx,
              CategoryPage.routeName,
              arguments: CategoryPage(
                  categoryId: cat.id, categoryName: cat.categoryName),
            ),
            onEdit: () => Navigator.pushNamed(
              ctx,
              EditCategoryScreen.route,
              arguments: cat,
            ),
            onDelete: () => _deleteOne(ctx, provider, cat.id),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<CategoryProvider>(
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
                      ? () => _showDeleteConfirmDialog(
                          context, provider, selectedCount)
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            _snackBar('Chưa chọn danh mục nào'),
                          ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: hasSelection
                            ? [const Color(0xFFFF3B30), const Color(0xFFFF6B6B)]
                            : [Colors.grey.shade400, Colors.grey.shade300],
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
                                  'Xóa danh mục',
                                  style: TextStyle(
                                    color: AppColors.surface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  hasSelection
                                      ? '$selectedCount mục đã chọn'
                                      : 'Chưa chọn mục nào',
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
                                  horizontal: 10, vertical: 4),
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

  void _showDeleteConfirmDialog(
      BuildContext ctx, CategoryProvider provider, int count) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'Bạn sắp xóa $count danh mục. Toàn bộ sản phẩm trong các danh mục này cũng sẽ bị xóa vĩnh viễn.',
          style: const TextStyle(color: Colors.black54, height: 1.4),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
            onPressed: () => _deleteSelected(ctx, provider),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final Category category;
  final bool isSelecting;
  final bool isChecked;
  final VoidCallback onCheckToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.isSelecting,
    required this.isChecked,
    required this.onCheckToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTapDown: (_) => _controller.reverse(),
          onTapUp: (_) {
            _controller.forward();
            if (widget.isSelecting) {
              widget.onCheckToggle();
            } else {
              widget.onTap();
            }
          },
          onTapCancel: () => _controller.forward(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: widget.isChecked
                  ? Border.all(color: Colors.red.shade300, width: 1.5)
                  : Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: widget.isSelecting
                      ? GestureDetector(
                          onTap: widget.onCheckToggle,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.isChecked
                                    ? Colors.red
                                    : Colors.transparent,
                                border: Border.all(
                                  color: widget.isChecked
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: widget.isChecked
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: AppColors.surface,
                                    )
                                  : null,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.category.categoryImage,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.categoryName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') widget.onEdit();
                    if (value == 'delete') widget.onDelete();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  elevation: 6,
                  shadowColor: Colors.black26,
                  icon: Icon(Icons.more_vert_rounded,
                      color: Colors.grey.shade500),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 10),
                          const Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Xóa',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  final int delay;
  const _SkeletonTile({this.delay = 0});

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FadeTransition(
        opacity: Tween(begin: 0.4, end: 1.0).animate(_anim),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
