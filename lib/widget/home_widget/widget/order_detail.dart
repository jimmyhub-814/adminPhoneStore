import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/order.dart';
import 'package:admin/provider/order.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class OrderDetail extends StatefulWidget {
  static const routeName = '/order-detail';
  
  final String orderId;
  const OrderDetail({super.key, required this.orderId});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  bool expandedAddress = false;
  late Future _orderFuture;

  @override
  void initState() {
    super.initState();

    _orderFuture = context.read<OrderProvider>().getUserOrder(widget.orderId);
  }

  String formatDateTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy • HH:mm').format(date);
  }

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
          'Chi tiết đơn hàng',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEEEEEE)),
        ),
      ),
      body: FutureBuilder(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primary, size: 50),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy đơn hàng',
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

          final order = snapshot.data!;
          final isCancelled = order.orderInfo.orderStatus ==
                  OrderStatus.cancelled.name ||
              order.orderInfo.orderStatus == OrderStatus.cancelledByAdmin.name;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Status timeline ──────────────────────────────────────
              _buildStatusTimeline(order, isCancelled),
              const SizedBox(height: 12),

              // ── Shipping + Address card ───────────────────────────────
              _buildCard(
                children: [
                  if (!isCancelled) ...[
                    _buildSectionTitle('Thông tin vận chuyển'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_shipping_outlined,
                            size: 18,
                            color: Color(
                              0xFF3B82F6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Giao hàng nhanh',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDivider(),
                    const SizedBox(height: 14),
                  ],
                  _buildSectionTitle('Địa chỉ nhận hàng'),
                  if (order.orderInfo.orderNote.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildNoteBox(order.orderInfo.orderNote),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.person_rounded,
                    text: order.userInfo.userName,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.location_on_rounded,
                    text: expandedAddress
                        ? order.userInfo.userAddress
                        : _truncate(order.userInfo.userAddress),
                    onTap: () =>
                        setState(() => expandedAddress = !expandedAddress),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.phone_rounded,
                    text: order.userInfo.userPhone,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildCard(
                children: [
                  _buildSectionTitle('Sản phẩm'),
                  const SizedBox(height: 12),
                  ...order.orderProduct.map((item) {
                    final discounted = item.phonePrice -
                        ((item.phonePrice * item.phoneDiscount) / 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.phoneImage,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.variantsName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.phoneName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFFBDBDBD)),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${NumberFormat("#,###", "en_US").format(item.phonePrice)}đ',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFBDBDBD),
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${NumberFormat("#,###", "en_US").format(discounted)}đ',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F6FA),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'x${item.quantity}',
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
                  }),
                  _buildDivider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF9E9E9E))),
                      Text(
                        '${NumberFormat("#,###", "en_US").format(order.orderInfo.totalPrice)}đ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Order info card ───────────────────────────────────────
              _buildCard(
                children: [
                  _buildSectionTitle('Thông tin đơn hàng'),
                  const SizedBox(height: 12),
                  _buildMetaRow(
                    label: 'Mã đơn hàng',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: order.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã sao chép mã đơn hàng'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.copy_rounded,
                                    size: 11, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    label: 'Phương thức thanh toán',
                    value: order.orderInfo.methodPayment,
                  ),
                  const SizedBox(height: 14),
                  _buildDivider(),
                  const SizedBox(height: 14),
                  _buildSectionTitle('Lịch sử trạng thái'),
                  const SizedBox(height: 10),
                  ...order.statusHistory.map((e) {
                    final label = _statusLabel(e.status);
                    if (label == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(label,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280))),
                          ),
                          Text(
                            formatDateTime(e.time),
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF9E9E9E)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // ── Status progress bar ──────────────────────────────────────────────
  Widget _buildStatusTimeline(order, bool isCancelled) {
    final steps = isCancelled
        ? ['Đặt hàng', 'Đã hủy']
        : ['Đặt hàng', 'Xác nhận', 'Vận chuyển', 'Hoàn thành'];

    final statusMap = {
      OrderStatus.pending.name: 0,
      OrderStatus.confirmed.name: 1,
      OrderStatus.shipping.name: 2,
      OrderStatus.delivered.name: 3,
      OrderStatus.reviewed.name: 3,
      OrderStatus.cancelled.name: 1,
      OrderStatus.cancelledByAdmin.name: 1,
    };

    final currentStep = statusMap[order.orderInfo.orderStatus] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i <= currentStep;
          final isLast = i == steps.length - 1;
          final isCancelledStep = isCancelled && i == 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCancelledStep
                              ? AppColors.accent
                              : isActive
                                  ? AppColors.primary
                                  : const Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCancelledStep
                              ? Icons.close_rounded
                              : Icons.check_rounded,
                          size: 14,
                          color: isActive
                              ? AppColors.surface
                              : const Color(0xFFBDBDBD),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        steps[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isCancelledStep
                              ? AppColors.accent
                              : isActive
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFFBDBDBD),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: i < currentStep
                            ? AppColors.primary
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildDivider() => Container(
        height: 1,
        color: const Color(0xFFF0F0F0),
      );

  Widget _buildNoteBox(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign_rounded,
                size: 16, color: Colors.orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lưu ý giao hàng',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(note,
                    style: const TextStyle(
                        fontSize: 12, height: 1.5, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFBDBDBD)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
              softWrap: true,
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: Color(
                0xFFBDBDBD,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
      {required String label, String? value, Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(
              0xFF9E9E9E,
            ),
          ),
        ),
        trailing ??
            Text(
              value ?? '',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
      ],
    );
  }

  String _truncate(String text) =>
      text.length < 35 ? text : '${text.substring(0, 34)}...';

  String? _statusLabel(String status) {
    const map = {
      'pending': 'Đơn hàng đã được đặt',
      'confirmed': 'Người bán đã xác nhận',
      'shipping': 'Đơn vị vận chuyển đã lấy hàng',
      'delivered': 'Giao hàng thành công',
      'reviewed': 'Giao hàng thành công',
      'cancelled': 'Đã hủy bởi người mua',
      'cancelledByAdmin': 'Đã hủy bởi DM Store',
    };
    return map[status];
  }
}
