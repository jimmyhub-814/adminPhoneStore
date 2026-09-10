import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/models/feedback.dart';
import 'package:admin/provider/feedBack.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';

class ReplyUserFeedback extends StatefulWidget {
  static const routeName = '/reply-feedback';
  final FeedBack feedBack;
  final String productId;
  const ReplyUserFeedback(
      {super.key, required this.feedBack, required this.productId});

  @override
  State<ReplyUserFeedback> createState() => _ReplyUserFeedbackState();
}

class _ReplyUserFeedbackState extends State<ReplyUserFeedback>
    with SingleTickerProviderStateMixin {
  final TextEditingController replyController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    replyController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime =
        DateFormat('dd/MM/yyyy • HH:mm').format(widget.feedBack.time.toDate());

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        centerTitle: true,
        leading: AppbarIcon(),
        title: const Text(
          'Trả lời đánh giá',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              NetworkImage(widget.feedBack.userAvatar),
                          radius: 22,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.feedBack.userName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        widget.feedBack.vote,
                        (index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.feedBack.feedBackText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.dark,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                "Phản hồi của admin",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: TextField(
                  controller: replyController,
                  maxLines: 5,
                  maxLength: 200,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "Nhập phản hồi của bạn...",
                    hintStyle: const TextStyle(color: AppColors.iconDisabled),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        height: 80,
        child: GestureDetector(
          onTap: () async {
            final feedbackText = replyController.text.trim();
            if (feedbackText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Vui lòng nhập phản hồi!"),
                ),
              );
              return;
            }

            await Provider.of<FeedBackProvider>(context, listen: false)
                .replyFeedBack(
                    widget.productId, feedbackText, widget.feedBack.id);

            Navigator.pop(context);
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.26),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: const Text(
              "Gửi phản hồi",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
