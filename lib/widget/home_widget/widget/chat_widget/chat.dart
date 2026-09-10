import 'dart:async';
import 'package:admin/widget/home_widget/widget/chat_widget/user_detail_chat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shimmer/shimmer.dart';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/cubit/messages_cubic.dart';
import 'package:admin/models/message.dart';
import 'package:admin/models/user.dart';
import 'package:admin/provider/user_provider.dart';
import 'package:admin/widget/home_widget/widget/manage_product/product_detail.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/shared_widgets/safe_image.dart';

class UserChat extends StatefulWidget {
  static const routeName = '/chat';

  final String id;

  const UserChat({super.key, required this.id});

  @override
  State<UserChat> createState() => _UserChatState();
}

class _UserChatState extends State<UserChat> {
  final chatController = TextEditingController();
  final adminId = FirebaseAuth.instance.currentUser!.uid;
  final ScrollController _scrollController = ScrollController();
  late Future<UserApp?> userFuture;
  StreamSubscription<Message>? _messageSub;
  bool _initialized = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _messageSub?.cancel();

    _scrollController.addListener(_onScroll);
    _scrollController.addListener(_onLoadMore);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;
    userFuture = context.read<UserProvider>().getUserInfo(widget.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  Future<void> _initChat() async {
    if (!mounted) return;
    final cubit = context.read<MessageCubit>();

    await cubit.init(widget.id);
    if (!mounted) return;

    await cubit.initMessages(widget.id);
    if (!mounted) return;

    final after =
        cubit.state.messages.isNotEmpty ? cubit.state.messages.last.time : 0;

    _messageSub = cubit.streamMessage(after, widget.id).listen((msg) {
      if (mounted) cubit.onFirebaseMessage(msg);
    });
  }

  void _onLoadMore() async {
    if (!mounted) return;
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50 &&
        !context.read<MessageCubit>().state.isLoadingMore) {
      await context.read<MessageCubit>().loadMore(widget.id);
    }
  }

  void _onScroll() {
    final show = _scrollController.offset > 200;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Widget buildStatus(StatusMessage status, Message? msg) {
    switch (status) {
      case StatusMessage.sending:
        return SizedBox(
          height: 10,
          width: 10,
          child: Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primary,
              size: 10,
            ),
          ),
        );

      case StatusMessage.sent:
        return const Icon(Icons.check, size: 14);
      case StatusMessage.failed:
        return const Icon(Icons.error, size: 14, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MessageCubit>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        leadingWidth: 56,
        leading: AppbarIcon(),
        title: FutureBuilder<UserApp?>(
          future: userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null) {
              return Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                      ),
                    ),
                    padding: const EdgeInsets.all(1.5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.5),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 35,
                          width: 35,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.5),
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey,
                      highlightColor: Colors.grey,
                      child: Container(
                        height: 15,
                        width: 60,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                    ),
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.5),
                    child: SafeImage(
                      url: user.userAvatar,
                      width: 35,
                      height: 35,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: Text(
                    user.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface,
                      letterSpacing: -0.3,
                    ),
                  ),
                )
              ],
            );
          },
        ),
        actions: [
          FutureBuilder(
            future: userFuture,
            builder: (context, asyncSnapshot) {
              final user = asyncSnapshot.data;
              if (user == null) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.surface.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: () => Navigator.pushNamed(
                  context,
                  UserDetailChat.routeName,
                  arguments: UserDetailChat(
                    userId: user.id,
                    userAvatar: user.userAvatar,
                    userName: user.userName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F18)],
          ),
        ),
        child: BlocBuilder<MessageCubit, MessageState>(
          builder: (context, state) {
            if (state.isLoading || state.messages.isEmpty) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A1A2E), Color(0xFF0F0F18)],
                  ),
                ),
              );
            }

            return Stack(
              children: [
                ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10, top: 30),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    final dt = DateTime.fromMillisecondsSinceEpoch(msg.time);
                    final dateText = DateFormat('dd/MM').format(dt);

                    bool showDate = false;

                    if (index == state.messages.length - 1) {
                      showDate = true;
                    } else {
                      final nextMsg = state.messages[index + 1];
                      final nextDt =
                          DateTime.fromMillisecondsSinceEpoch(nextMsg.time);

                      final nextDateText = DateFormat('dd/MM').format(nextDt);

                      if (dateText != nextDateText) {
                        showDate = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.surface.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  dateText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888899),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        _chatWidget(context, msg),
                      ],
                    );
                  },
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  bottom: _showScrollToBottom ? 12 : -60,
                  right: 16,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _showScrollToBottom ? 1.0 : 0.0,
                    child: GestureDetector(
                      onTap: _scrollToBottom,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dark.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF6C63FF),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                top: BorderSide(
                  color: AppColors.surface.withValues(alpha: 0.06),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF888899),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.surface.withValues(alpha: 0.07),
                      ),
                    ),
                    child: TextField(
                      controller: chatController,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: Color(0xFF444455)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: chatController,
                  builder: (context, value, _) {
                    final isEmpty = value.text.trim().isEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isEmpty
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                              ),
                        color: isEmpty ? const Color(0xFF2A2A3E) : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isEmpty
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF6C63FF)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.send_rounded,
                          color: isEmpty
                              ? const Color(0xFF444455)
                              : AppColors.surface,
                          size: 20,
                        ),
                        onPressed: isEmpty
                            ? null
                            : () async {
                                final text = chatController.text;
                                chatController.clear();
                                await cubit.sendProcess(
                                    text, widget.id, context);
                              },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatWidget(BuildContext context, Message msg) {
    final isMe = msg.senderId == adminId;
    final dt = DateTime.fromMillisecondsSinceEpoch(msg.time);
    final timeText =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? 64 : 12,
        right: isMe ? 12 : 64,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.product != null)
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  ProductDetail.routeName,
                  arguments: ProductDetail(id: msg.product!.productId),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.12)
                        : const Color(0xFFF0F0F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isMe
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                          : const Color(0xFFE0E0E8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SafeImage(
                          url: msg.product?.productImage,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.product!.productName.length > 18
                                ? '${msg.product!.productName.substring(0, 18)}...'
                                : msg.product!.productName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${NumberFormat("#,##0", "en_US").format(msg.product?.productPrice)}đ',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6C63FF) : const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      msg.message,
                      style: TextStyle(
                        color:
                            isMe ? AppColors.surface : const Color(0xFF1A1A2E),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? AppColors.surface.withValues(alpha: 0.65)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        buildStatus(msg.statusMessage, msg),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (msg.statusMessage == StatusMessage.failed)
              GestureDetector(
                onTap: () =>
                    context.read<MessageCubit>().retry(msg, widget.id, context),
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.red, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Gửi lại',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _messageSub?.cancel();
    chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
