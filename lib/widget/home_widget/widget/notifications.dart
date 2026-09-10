import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/admin_notification.dart';
import 'package:admin/provider/category.dart';
import 'package:admin/provider/data.dart';
import 'package:admin/provider/notification.dart';
import 'package:admin/provider/product.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/home_widget/widget/order_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class NotificationScreen extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Stream<List<AdminNotification>>? _notificationStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notiProvider = context.read<NotificationProvider>();

      _notificationStream = notiProvider.getNotificationList();
      setState(() {});
    });
  }

  Future<void> loadData() async {
    await context.read<CategoryProvider>().fetchCategoriesList();
    await context.read<ProductProvider>().fetchProductsList();
    await context.read<DataProvider>().fetchCarousel();
  }

  String formatSmartTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final timeFormatter = DateFormat('HH:mm');

    // Nếu là hôm nay
    if (now.day == date.day &&
        now.month == date.month &&
        now.year == date.year) {
      return "Hôm nay ${timeFormatter.format(date)}";
    }

    // Nếu là hôm qua
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == date.day &&
        yesterday.month == date.month &&
        yesterday.year == date.year) {
      return "Hôm qua ${timeFormatter.format(date)}";
    }

    // Các ngày khác
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        centerTitle: true,
        shadowColor: AppColors.dark.withValues(alpha: 0.12),
        leading: AppbarIcon(),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ),
      body: _notificationStream == null
          ? Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            )
          : StreamBuilder<List<AdminNotification>>(
              stream: _notificationStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final notiGroups = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 100,
                    top: 2,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: notiGroups.length,
                  itemBuilder: (context, index) {
                    final noti = notiGroups[index];
                    return _buildNotiCard(noti);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_rounded,
              color: AppColors.primaryDark,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Bạn chưa có bất kỳ thông báo nào!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.iconDisabled,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      color: AppColors.surface,
                    ),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 200, color: AppColors.surface),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 100, color: AppColors.surface),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotiCard(AdminNotification noti) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            OrderDetail.routeName,
            arguments: OrderDetail(orderId: noti.orderId),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              noti.status == 'createOrder'
                  ? 'Có đơn hàng mới'
                  : 'Đơn đã bị hủy',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noti.status == 'createOrder'
                  ? 'Đơn hàng #${noti.orderId} được tạo'
                  : 'Đơn hàng #${noti.orderId} đã bị hủy',
            ),
            const SizedBox(height: 6),
            Text(
              formatSmartTime(noti.orderDate),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
