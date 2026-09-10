import 'package:admin/widget/shared_widgets/safe_image.dart';
import 'package:provider/provider.dart';
import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/order.dart';
import 'package:admin/provider/order.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/home_widget/widget/order_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class UserOrder extends StatefulWidget {
  static const routeName = '/user_order';

  final String userId;
  const UserOrder({super.key, required this.userId});

  @override
  State<UserOrder> createState() => _UserOrderState();
}

class _UserOrderState extends State<UserOrder> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AppbarIcon(),
        title: const Text(
          'Đơn hàng của người dùng',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFEEEEEE),
          ),
        ),
      ),
      body: FutureBuilder(
        future: context.read<OrderProvider>().getAllOrderUser(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 50,
              ),
            );
          }

          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có đơn hàng nào',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final isExpanded = ValueNotifier(false);

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    OrderDetail.routeName,
                    arguments: OrderDetail(orderId: orders[index].id),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: isExpanded,
                      builder: (context, expanded, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đơn hàng #${order.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF9E9E9E),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                _buildStatusBadge(order.orderInfo.orderStatus),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AnimatedCrossFade(
                              firstChild: Column(
                                children: [
                                  _buildProductItem(
                                      context, order.orderProduct[0]),
                                ],
                              ),
                              secondChild: Column(
                                children: order.orderProduct
                                    .map((item) =>
                                        _buildProductItem(context, item))
                                    .toList(),
                              ),
                              crossFadeState: expanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                            if (order.orderProduct.length > 1)
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => isExpanded.value = !expanded,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: Icon(
                                    expanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 18,
                                    color: const Color(0xFFBDBDBD),
                                  ),
                                  label: Text(
                                    expanded ? 'Ẩn bớt' : 'Xem thêm',
                                    style: const TextStyle(
                                      color: Color(0xFFBDBDBD),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            Container(
                              height: 1,
                              color: const Color(0xFFF0F0F0),
                              margin: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            if (order.orderInfo.orderStatus ==
                                OrderStatus.cancelledByAdmin.name)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.danger.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 14, color: AppColors.accent),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Đơn hàng đã bị hủy. Liên hệ để được tư vấn!',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${order.orderProduct.length} sản phẩm',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'Tổng: ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF9E9E9E),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            '${NumberFormat("#,###", "en_US").format(order.orderInfo.totalPrice)}đ',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF59E0B);
        label = 'Chờ xác nhận';
        icon = Icons.access_time_rounded;
        break;
      case 'confirmed':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF22C55E);
        label = 'Đã xác nhận';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'shipping':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF3B82F6);
        label = 'Đang giao';
        icon = Icons.local_shipping_outlined;
        break;
      case 'delivered':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF16A34A);
        label = 'Đã nhận hàng';
        icon = Icons.done_all_rounded;
        break;
      default:
        bgColor = const Color(0xFFFFEBEE);
        textColor = AppColors.accent;
        label = 'Đã hủy';
        icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, OrderProduct order) {
    final discountedPrice =
        order.phonePrice - ((order.phonePrice * order.phoneDiscount) / 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SafeImage(
              url: order.phoneImage,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.phoneName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.variantsName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBDBDBD),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${NumberFormat("#,###", "en_US").format(discountedPrice)}đ',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'x${order.quantity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
