import 'dart:async';
import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/app_text_styles.dart';
import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/conversation.dart';
import 'package:admin/models/user.dart';
import 'package:admin/provider/conversation.dart';
import 'package:admin/provider/user_provider.dart';
import 'package:admin/widget/home_widget/widget/chat_widget/chat.dart';
import 'package:admin/widget/shared_widgets/appbar_icon.dart';
import 'package:admin/widget/shared_widgets/safe_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConversationList extends StatefulWidget {
  static const routeName = '/conversation';

  const ConversationList({super.key});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  late final Stream<List<Conversation?>> _conversationStream;

  @override
  void initState() {
    super.initState();

    _conversationStream =
        context.read<ConversationProvider>().streamConversation();
  }

  String formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));

    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;

    if (isToday) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    if (isYesterday) {
      return 'Hôm qua';
    }

    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Conversation?>>(
      stream: _conversationStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final conversations = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F18),
          appBar: AppBar(
            leading: AppbarIcon(),
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text(
              'Tin nhắn',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          body: conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notification_important_outlined,
                        color: AppColors.iconDisabled,
                        size: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có tin nhắn nào!',
                        style: AppTextstyles.headingH6.copyWith(
                          color: AppColors.iconDisabled,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 20,
                  ),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final cvs = conversations[index];

                    if (cvs == null) {
                      return const SizedBox.shrink();
                    }

                    return ConversationTile(
                      cvs: cvs,
                      timeText: formatTime(cvs.lastMessageTime),
                    );
                  },
                ),
        );
      },
    );
  }
}

class ConversationTile extends StatelessWidget {
  final Conversation cvs;
  final String timeText;

  const ConversationTile({
    super.key,
    required this.cvs,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = cvs.lastMessageBy == UnreadCountBy.user.name &&
        cvs.unreadCount[UnreadCountBy.admin.name] > 0;

    return Material(
      color: Colors.transparent,
      child: FutureBuilder(
        future: context.read<UserProvider>().getUserInfo(cvs.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 72);
          }
          final user = snapshot.data;
          if (user == null) return const SizedBox.shrink();

          return InkWell(
            onTap: () async {
              final ref = Collections.conversations.doc(cvs.userId);

              ref.update(
                {
                  '${Conversation.unreadCountField}.${UnreadCountBy.admin.name}':
                      0,
                },
              );

              Navigator.pushNamed(
                context,
                UserChat.routeName,
                arguments: UserChat(id: cvs.userId),
              );
            },
            splashColor: const Color(0xFF6C63FF).withValues(alpha: 0.08),
            highlightColor: const Color(0xFF6C63FF).withValues(alpha: 0.04),
            child: Container(
              color: hasUnread
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.05)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildAvatar(user),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.userName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: hasUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: hasUnread
                                            ? AppColors.surface
                                            : const Color(0xFFD0D0E0),
                                      ),
                                    ),
                                  ),
                                  if (hasUnread) ...[
                                    const SizedBox(width: 8),
                                    _buildBadge(cvs
                                        .unreadCount[UnreadCountBy.admin.name]),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeText,
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? const Color(0xFF6C63FF)
                                    : const Color(0xFF555567),
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (cvs.lastMessageBy ==
                                UnreadCountBy.admin.name) ...[
                              const Icon(
                                Icons.done_all_rounded,
                                size: 14,
                                color: Color(0xFF555567),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                cvs.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: hasUnread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: hasUnread
                                      ? const Color(0xFFAAAAAA)
                                      : const Color(0xFF555567),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(UserApp user) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SafeImage(
          url: user.userAvatar,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : count.toString(),
        style: const TextStyle(
          color: AppColors.surface,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
