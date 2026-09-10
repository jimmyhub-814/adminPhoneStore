import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/order.dart';
import 'package:admin/provider/order.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/home_widget/hamburger_menu/feedback.dart';
import 'package:admin/widget/home_widget/hamburger_menu/order_status.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class OrderInfoPage extends StatefulWidget {
  const OrderInfoPage({super.key});
  static const routeName = '/manage-order';

  @override
  State<OrderInfoPage> createState() => _OrderInfoPageState();
}

class _OrderInfoPageState extends State<OrderInfoPage> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: AppbarIcon(),
        title: const Text(
          'Quản lý đơn hàng',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder(
        stream:
            Provider.of<OrderProvider>(context, listen: false).streamOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            Scaffold(
              backgroundColor: AppColors.surface,
              body: Center(
                child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primary,
                  size: 60,
                ),
              ),
            );
          }

          final data = snapshot.data ?? [];

          int waitingAccept = data
              .where((e) => e.orderInfo.orderStatus == OrderStatus.pending.name)
              .length;
          int waitingPrepare = data
              .where(
                  (e) => e.orderInfo.orderStatus == OrderStatus.confirmed.name)
              .length;
          int waitingDelivery = data
              .where(
                  (e) => e.orderInfo.orderStatus == OrderStatus.shipping.name)
              .length;
          int returnOrder = data
              .where(
                  (e) => e.orderInfo.orderStatus == OrderStatus.returned.name)
              .length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: size.width,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đánh giá',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            UserFeedback.routeName,
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'Xem các đánh giá mới',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.dark.withValues(alpha: 0.54),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: size.width,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Đơn hàng",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          buildStatusItem(
                            count: waitingAccept,
                            index: 0,
                            title: "Chờ xác nhận",
                            icon: Icons.task_alt_outlined,
                            color: Colors.orange,
                          ),
                          buildStatusItem(
                            count: waitingPrepare,
                            index: 1,
                            title: "Chờ giao",
                            icon: Icons.local_shipping_outlined,
                            color: Colors.blue,
                          ),
                          buildStatusItem(
                            count: waitingDelivery,
                            index: 2,
                            title: "Đang giao",
                            icon: Icons.delivery_dining,
                            color: Colors.teal,
                          ),
                          buildStatusItem(
                            count: returnOrder,
                            index: 4,
                            title: "Trả hàng",
                            icon: Icons.restart_alt,
                            color: Colors.red,
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // -----------------------------
  // ITEM UI ĐẸP
  // -----------------------------
  Widget buildStatusItem({
    required int count,
    required int index,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          OrderStatusPage.routeName,
          arguments: OrderStatusPage(index: index),
        );
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          )
        ],
      ),
    );
  }
}
