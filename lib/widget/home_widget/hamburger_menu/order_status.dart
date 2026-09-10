import 'package:admin/widget/home_widget/widget/chat_widget/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/notification.dart';
import 'package:admin/models/order.dart';
import 'package:admin/models/statistics.dart';
import 'package:admin/provider/order.dart';
import 'package:admin/provider/product.dart';
import 'package:admin/provider/statistics.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/home_widget/widget/order_detail.dart';

class OrderStatusPage extends StatefulWidget {
  static const routeName = '/order_status';
  final int index;

  const OrderStatusPage({super.key, required this.index});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _initialTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadData());
    _tabController =
        TabController(length: 5, vsync: this, initialIndex: _initialTabIndex);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        final tabIndex = widget.index;
        if (tabIndex >= 0 && tabIndex < 5) {
          setState(() {
            _tabController.index = tabIndex;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    context.read<OrderProvider>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          leading: AppbarIcon(),
          title: const Text(
            'Theo dõi đơn hàng',
            style: TextStyle(
              color: AppColors.primary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: "Chờ xác nhận"),
                Tab(text: "Chờ giao hàng"),
                Tab(text: "Đang giao hàng"),
                Tab(text: "Đã giao hàng"),
                Tab(text: "Đã hủy đơn"),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TabBarView(
            controller: _tabController,
            children: [
              orderItem(context, OrderStatus.pending.name),
              orderItem(context, OrderStatus.confirmed.name),
              orderItem(context, OrderStatus.shipping.name),
              orderItem(context, OrderStatus.delivered.name),
              orderItem(context, OrderStatus.cancelled.name),
            ],
          ),
        ),
      ),
    );
  }

  Widget orderItem(BuildContext context, String status) {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    return StreamBuilder<List<UserOrder>>(
      stream: status == OrderStatus.cancelled.name
          ? provider.streamOrdersByStatuses(
              [OrderStatus.cancelled.name, OrderStatus.cancelledByAdmin.name])
          : provider.streamOrdersByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _emptyWidget();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyWidget();
        }

        final orders = snapshot.data!;
        return _AnimatedOrderList(
          orders: orders,
          status: status,
          productProvider: productProvider,
          buildTile: _buildOrderTile,
          actionButton: _actionButton,
        );
      },
    );
  }

  Widget _emptyWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('Bạn chưa có đơn hàng nào',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required Color textColor,
    VoidCallback? onPressed,
  }) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 120),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: color,
          animationDuration: const Duration(milliseconds: 120),
          overlayColor: textColor.withValues(alpha: 0.1),
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _shortUid(String uid) {
    if (uid.length <= 10) return uid;
    return '${uid.substring(0, 6)}...${uid.substring(uid.length - 4)}';
  }

  Widget _buildOrderTile(
    BuildContext context,
    UserOrder order,
    Animation<double> animation,
    String status,
    ProductProvider productProvider,
  ) {
    final ValueNotifier<bool> isExpanded = ValueNotifier(false);
    num total = 0;

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              OrderDetail.routeName,
              arguments: OrderDetail(orderId: order.id),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: isExpanded,
              builder: (context, value, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _shortUid(order.userInfo.userId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: order.userInfo.userId));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép UID'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  UserChat.routeName,
                                  arguments:
                                      UserChat(id: order.userInfo.userId),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Text(
                                  'Liên hệ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.iconDisabled,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.userInfo.userAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Color(0xffEFEFEF),
                    ),
                    const SizedBox(height: 8),
                    ...order.orderProduct.asMap().entries.map(
                      (entry) {
                        int index = entry.key;
                        var item = entry.value;

                        total += item.quantity;
                        if (index > 0 && !value) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    item.phoneImage,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.orderProduct[index].phoneName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        order.orderProduct[index].variantsName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'x${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${NumberFormat("#,###", "en_US").format(order.orderProduct[index].phonePrice)}đ',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${NumberFormat("#,###", "en_US").format(
                                              order.orderProduct[index]
                                                      .phonePrice -
                                                  ((order.orderProduct[index]
                                                              .phonePrice *
                                                          order
                                                              .orderProduct[
                                                                  index]
                                                              .phoneDiscount) /
                                                      100),
                                            )}đ',
                                            style: const TextStyle(
                                              color: Color(0xffEF6A62),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                    if (order.orderProduct.length > 1)
                      TextButton(
                        onPressed: () {
                          isExpanded.value = !isExpanded.value;
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              value ? "Ẩn bớt" : "Xem thêm",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
                              ),
                            ),
                            Icon(
                              value
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: RichText(
                          text: TextSpan(
                            text: 'Tổng số tiền ($total sản phẩm): ',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '${NumberFormat("#,###", "en_US").format(order.orderInfo.totalPrice)} đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    order.orderInfo.orderStatus != OrderStatus.delivered.name &&
                            order.orderInfo.orderStatus !=
                                OrderStatus.cancelledByAdmin.name &&
                            order.orderInfo.orderStatus !=
                                OrderStatus.cancelled.name &&
                            order.orderInfo.orderStatus !=
                                OrderStatus.returned.name
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _actionButton(
                                text: 'Xác nhận',
                                color: AppColors.primaryDark,
                                textColor: AppColors.surface,
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Thông báo'),
                                      content: const Text(
                                        'Bạn có chắc chắn muốn xác nhận đơn hàng không?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('HỦY'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primaryDark),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'XÁC NHẬN',
                                            style: TextStyle(
                                              color: AppColors.surface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    BuildContext? loadingCtx;
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (dialogContext) {
                                        loadingCtx = dialogContext;
                                        return Center(
                                          child:
                                              LoadingAnimationWidget.waveDots(
                                            color: AppColors.primary,
                                            size: 60,
                                          ),
                                        );
                                      },
                                    );

                                    try {
                                      if (order.orderInfo.orderStatus ==
                                          OrderStatus.pending.name) {
                                        await context
                                            .read<OrderProvider>()
                                            .updateInfo(order.id,
                                                OrderStatus.confirmed.name);

                                        String id = const Uuid().v4();
                                        final time = Timestamp.now();

                                        final noti = NotificationList(
                                          id: id,
                                          title: "Cập nhật trạng thái đơn hàng",
                                          body:
                                              "Đơn hàng #${order.id} đang được người bán chuẩn bị",
                                          timestamp: time,
                                        );

                                        final notiRef =
                                            Collections.notification(
                                                    order.userInfo.userId)
                                                .doc(order.id);

                                        await notiRef.set({
                                          NotificationModel
                                                  .notificationListField:
                                              FieldValue.arrayUnion(
                                                  [noti.toMap()]),
                                          NotificationList.idField: order.id,
                                          NotificationModel.readField: false,
                                        }, SetOptions(merge: true));
                                      } else if (order.orderInfo.orderStatus ==
                                          OrderStatus.confirmed.name) {
                                        await context
                                            .read<OrderProvider>()
                                            .updateInfo(order.id,
                                                OrderStatus.shipping.name);

                                        String id = const Uuid().v4();

                                        final noti = NotificationList(
                                          id: id,
                                          title: "Cập nhật trạng thái đơn hàng",
                                          body:
                                              "Đơn hàng #${order.id} đã được bàn giao cho đơn vị vận chuyển",
                                          timestamp: Timestamp.now(),
                                        );

                                        final notiRef =
                                            Collections.notification(
                                                    order.userInfo.userId)
                                                .doc(order.id);

                                        await notiRef.set({
                                          NotificationModel
                                                  .notificationListField:
                                              FieldValue.arrayUnion(
                                                  [noti.toMap()]),
                                          NotificationList.idField: order.id,
                                          NotificationModel.readField: false,
                                        }, SetOptions(merge: true));
                                      } else if (order.orderInfo.orderStatus ==
                                          OrderStatus.shipping.name) {
                                        await context
                                            .read<OrderProvider>()
                                            .updateInfo(order.id,
                                                OrderStatus.delivered.name);
                                        context
                                            .read<StatisticsProvider>()
                                            .updateStatistics(
                                                order.orderInfo.totalPrice,
                                                1,
                                                order.orderProduct.length,
                                                Statistics.completedOrderField);

                                        String id = const Uuid().v4();

                                        final noti = NotificationList(
                                          id: id,
                                          title: "Giao kiện hàng thành công",
                                          body:
                                              "Đơn hàng #${order.id} đã được giao thành công",
                                          timestamp: Timestamp.now(),
                                        );

                                        final notiRef =
                                            Collections.notification(
                                                    order.userInfo.userId)
                                                .doc(order.id);

                                        await notiRef.set({
                                          NotificationModel
                                                  .notificationListField:
                                              FieldValue.arrayUnion(
                                                  [noti.toMap()]),
                                          NotificationList.idField: order.id,
                                          NotificationModel.readField: false,
                                        }, SetOptions(merge: true));

                                        List<Map<String, int>> idList = [];
                                        for (var item in order.orderProduct) {
                                          idList.add(
                                            {item.id: item.quantity},
                                          );
                                        }

                                        await productProvider
                                            .increaseSalesVolume(idList);
                                      }
                                    } catch (e) {
                                      print(e);
                                    } finally {
                                      if (loadingCtx != null &&
                                          Navigator.canPop(loadingCtx!)) {
                                        Navigator.pop(loadingCtx!);
                                      }
                                    }
                                  }
                                },
                              ),
                              status != OrderStatus.shipping.name
                                  ? Row(
                                      children: [
                                        const SizedBox(
                                          width: 15,
                                        ),
                                        _actionButton(
                                          text: 'Hủy đơn',
                                          color: AppColors.surface,
                                          textColor: AppColors.primaryDark,
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Thông báo',
                                                ),
                                                content: const Text(
                                                  'Bạn có chắc chắn muốn xác nhận đơn hàng không?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('HỦY'),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                AppColors
                                                                    .primaryDark),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: const Text(
                                                      'XÁC NHẬN',
                                                      style: TextStyle(
                                                        color:
                                                            AppColors.surface,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await context
                                                  .read<OrderProvider>()
                                                  .updateInfo(
                                                      order.id,
                                                      OrderStatus
                                                          .cancelledByAdmin
                                                          .name);

                                              context
                                                  .read<StatisticsProvider>()
                                                  .updateStatistics(
                                                    order.orderInfo.totalPrice,
                                                    1,
                                                    order.orderProduct.length,
                                                    Statistics
                                                        .cancelledOrderField,
                                                  );

                                              String id = const Uuid()
                                                  .v4()
                                                  .replaceAll('-', '')
                                                  .substring(0, 12);

                                              final noti = NotificationList(
                                                id: id,
                                                title: "Đơn hàng đã bị hủy",
                                                body:
                                                    "Đơn hàng #${order.id} đã bị hủy vì vài lí do. Liên hệ shop để được hỗ trợ.",
                                                timestamp: Timestamp.now(),
                                              );

                                              final notiRef =
                                                  Collections.notification(
                                                          order.userInfo.userId)
                                                      .doc(order.id);

                                              await notiRef.set(
                                                {
                                                  NotificationModel
                                                          .notificationListField:
                                                      FieldValue.arrayUnion(
                                                          [noti.toMap()]),
                                                  NotificationList.idField:
                                                      order.id,
                                                  NotificationModel.readField:
                                                      false,
                                                },
                                                SetOptions(
                                                  merge: true,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedOrderList extends StatefulWidget {
  final List<UserOrder> orders;
  final String status;
  final ProductProvider productProvider;
  final Widget Function(
    BuildContext,
    UserOrder,
    Animation<double>,
    String,
    ProductProvider,
  ) buildTile;
  final Widget Function({
    required String text,
    required Color color,
    required Color textColor,
    VoidCallback? onPressed,
  }) actionButton;

  const _AnimatedOrderList({
    required this.orders,
    required this.status,
    required this.productProvider,
    required this.buildTile,
    required this.actionButton,
  });

  @override
  State<_AnimatedOrderList> createState() => _AnimatedOrderListState();
}

class _AnimatedOrderListState extends State<_AnimatedOrderList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<UserOrder> _currentOrders;

  @override
  void initState() {
    super.initState();
    _currentOrders = List.from(widget.orders);
  }

  @override
  void didUpdateWidget(_AnimatedOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newOrders = widget.orders;
    final oldOrders = _currentOrders;

    for (int i = oldOrders.length - 1; i >= 0; i--) {
      final old = oldOrders[i];
      final stillExists = newOrders.any((o) => o.id == old.id);
      if (!stillExists) {
        final removedOrder = old;
        _currentOrders.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => widget.buildTile(
            context,
            removedOrder,
            animation,
            widget.status,
            widget.productProvider,
          ),
          duration: const Duration(milliseconds: 400),
        );
      }
    }

    for (int i = 0; i < newOrders.length; i++) {
      final isNew = !_currentOrders.any((o) => o.id == newOrders[i].id);
      if (isNew) {
        _currentOrders.insert(i, newOrders[i]);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _currentOrders.length,
      itemBuilder: (context, index, animation) {
        return widget.buildTile(
          context,
          _currentOrders[index],
          animation,
          widget.status,
          widget.productProvider,
        );
      },
    );
  }
}
