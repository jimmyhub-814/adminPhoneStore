import 'package:flutter/material.dart';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/widget/home_widget/widget/chat_widget/user_order.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/shared_widgets/safe_image.dart';

class UserDetail extends StatefulWidget {
  static const routeName = '/user-detail';

  final String userId;
  final String userAvatar;
  final String userName;

  const UserDetail(
      {super.key,
      required this.userId,
      required this.userAvatar,
      required this.userName});

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        leading: AppbarIcon(),
        centerTitle: true,
        title: Text(
          'Thông tin khách hàng',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.dark.withValues(alpha: 0.87),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 28,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Hero(
                    tag: widget.userId,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: SafeImage(
                        url: widget.userAvatar,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.userName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.dark.withValues(alpha: 0.87),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.userId,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.iconDisabled,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildActionTile(
              icon: Icons.shopping_bag_outlined,
              iconColor: AppColors.primary,
              title: 'Danh sách đơn hàng',
              subtitle: 'Xem toàn bộ đơn hàng của khách hàng',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  UserOrder.routeName,
                  arguments: UserOrder(
                    userId: widget.userId,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildActionTile(
              icon: Icons.person_outline_rounded,
              iconColor: AppColors.success,
              title: 'Hồ sơ người dùng',
              subtitle: 'Xem thông tin tài khoản chi tiết',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
