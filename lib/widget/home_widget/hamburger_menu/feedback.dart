import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/feedback.dart';
import 'package:admin/models/order.dart';
import 'package:admin/provider/feedBack.dart';
import 'package:admin/provider/order.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/shared_widgets/safe_image.dart';
import 'package:admin/widget/home_widget/hamburger_menu/reply_feed_back.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserFeedback extends StatefulWidget {
  const UserFeedback({super.key});
  static const routeName = '/feed-back-screen';
  @override
  State<UserFeedback> createState() => _UserFeedbackState();
}

class _UserFeedbackState extends State<UserFeedback>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _initialTabIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadData());
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: _initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    context.read<OrderProvider>().loadOrders();
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();

    final difference = now.difference(date);

    if (difference.inMinutes < 1) return "Vừa xong";
    if (difference.inMinutes < 60) return "${difference.inMinutes} phút trước";
    if (difference.inHours < 24) return "${difference.inHours} giờ trước";
    if (difference.inDays < 7) return "${difference.inDays} ngày trước";

    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 245, 245, 245),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          leading: AppbarIcon(),
          title: const Text(
            'Đánh giá',
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
                Tab(text: "Chưa phản hồi"),
                Tab(text: "Đã phản hồi"),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TabBarView(
            controller: _tabController,
            children: [
              feedBack(context, OrderStatus.reviewed.name, false),
              feedBack(context, OrderStatus.reviewed.name, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget feedBack(BuildContext context, String orderStatus, bool isReply) {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    return StreamBuilder<List<UserOrder>>(
      stream: provider.streamOrdersByStatus(orderStatus),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No orders"));
        }

        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_shopping_cart_rounded, size: 80),
                SizedBox(height: 16),
                Text("Bạn chưa có đơn hàng nào"),
              ],
            ),
          );
        }

        final Map<String, Map<String, String>> itemMap = {};

        for (var order in orders) {
          for (var item in order.orderProduct) {
            final feedbackId = "${order.id}_${item.variantsId}";

            itemMap[feedbackId] = {
              "productId": item.id,
              "feedbackId": feedbackId,
            };
          }
        }

        return FutureBuilder<Map<String, FeedBack?>>(
          future: context.read<FeedBackProvider>().getAllFeedBack(itemMap),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Chưa có feedback"));
            }

            final feedbackMap = snapshot.data!;

            final List<Map<String, dynamic>> itemsToShow = [];

            for (var order in orders) {
              for (var item in order.orderProduct) {
                final feedbackId = "${order.id}_${item.variantsId}";
                final fb = feedbackMap[feedbackId];

                if (fb != null) {
                  final hasReply =
                      fb.adminReply != null && fb.adminReply!.isNotEmpty;

                  if ((isReply && hasReply) || (!isReply && !hasReply)) {
                    itemsToShow.add({
                      "item": item,
                      "feedback": fb,
                      "feedbackId": feedbackId,
                    });
                  }
                }
              }
            }

            if (itemsToShow.isEmpty) {
              return const Center(
                child: Text("Không có phản hồi nào cần trả lời"),
              );
            }
            itemsToShow.sort((a, b) {
              final t1 = (a["feedback"] as FeedBack).time;
              final t2 = (b["feedback"] as FeedBack).time;

              return t2.compareTo(t1);
            });
            return ListView.builder(
              itemCount: itemsToShow.length,
              itemBuilder: (context, index) {
                final data = itemsToShow[index];
                final item = data["item"] as OrderProduct;
                final fb = data["feedback"] as FeedBack;

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.dark.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: NetworkImage(fb.userAvatar),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fb.userName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (index) => Icon(
                                        Icons.star_rounded,
                                        size: 12,
                                        color: index < fb.vote
                                            ? AppColors.star
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          !isReply
                              ? Align(
                                  alignment: AlignmentGeometry.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, ReplyUserFeedback.routeName,
                                          arguments: ReplyUserFeedback(
                                            feedBack: fb,
                                            productId: item.id,
                                          ));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.blue
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: const Text(
                                        "Phản hồi",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Phân loại: ${fb.variantName}',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.iconDisabled,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (fb.feedBackText.isNotEmpty)
                        Text(
                          fb.feedBackText,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: SafeImage(
                              url: item.phoneImage,
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.phoneName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  item.variantsName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.iconDisabled,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatTime(fb.time),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (fb.adminReply?.isNotEmpty ?? false)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.store,
                                color: Colors.blue,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fb.adminReply!,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
