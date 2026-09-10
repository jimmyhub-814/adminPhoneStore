import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/home_widget/widget/manage_product/add_category.dart';
import 'package:admin/widget/home_widget/widget/manage_product/add_product.dart';
import 'package:admin/widget/home_widget/widget/manage_product/view_product_category.dart';
import 'package:flutter/material.dart';

class ManageProduct extends StatefulWidget {
  static const routeName = '/manage-product';
  const ManageProduct({super.key});

  @override
  State<ManageProduct> createState() => _AddPageState();
}

class _AddPageState extends State<ManageProduct> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( 
        leading: AppbarIcon(),
        title: const Text(
          "Quản lý sản phẩm",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.dark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
            children: [
              AdminActionCard(
                icon: Icons.category_rounded,
                title: 'Add category',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AddCategory.routeName,
                  );
                },
              ),
              AdminActionCard(
                icon: Icons.phone_android_rounded,
                title: 'Add product',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AddProduct.routeName,
                  );
                },
              ),
              AdminActionCard(
                icon: Icons.edit_note_rounded,
                title: 'View category',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    ViewItemCategory.routeName,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const AdminActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primaryDark.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        icon,
                        size: 30,
                        color: AppColors.surface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage $title',
                      style: TextStyle(
                        color: AppColors.surface.withValues(alpha: 0.7),
                        fontSize: 11,
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
