import 'dart:async';
import 'package:admin/app_constants/app_local_messages.dart';
import 'package:equatable/equatable.dart';
import 'package:admin/app_constants/providers.dart';
import 'package:admin/models/conversation.dart';
import 'package:admin/models/message.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class MessageState extends Equatable {
  final String userId;
  final bool isLoading;
  final bool isLoadingMore;
  final List<Message> messages;
  final ProductMessage? productMessage;

  const MessageState({
    this.userId = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.messages = const [],
    this.productMessage,
  });

  MessageState copyWith({
    String? userId,
    bool? isLoading,
    bool? isLoadingMore,
    List<Message>? messages,
    ProductMessage? productMessage,
  }) {
    return MessageState(
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      messages: messages ?? this.messages,
      productMessage: productMessage ?? this.productMessage,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        isLoading,
        isLoadingMore,
        messages,
        productMessage,
      ];
}

class MessageCubit extends Cubit<MessageState> {
  MessageCubit() : super(const MessageState());

  final adminId = FirebaseAuth.instance.currentUser!.uid;

  late Box localBox;

  Future<void> init(String userId) async {
    final boxName = AppLocalMessages.localMessages(userId);

    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }

    localBox = Hive.box(boxName);

    emit(state.copyWith(userId: userId));
  }

  Stream<Message> streamMessage(int after, String userId) {
    return Collections.messages(userId)
        .where('time', isGreaterThan: after)
        .snapshots(includeMetadataChanges: true)
        .expand((snapshot) => snapshot.docs)
        .where((doc) {
          return !doc.metadata.hasPendingWrites;
        })
        .map((doc) {
          try {
            return Message.fromMap(doc.data());
          } catch (e) {
            debugPrint('❌ Skip invalid message ${doc.id}: $e');
            return null;
          }
        })
        .where((m) => m != null)
        .cast<Message>();
  }
  // =========================
  // GET MESSAGE
  // =========================

  Future<List<Message>> getMessage(String userId) async {
    final querySnapshot = await Collections.messages(userId)
        .orderBy('time', descending: true)
        .limit(20)
        .get();

    List<Message> result = [];

    for (var doc in querySnapshot.docs) {
      try {
        result.add(Message.fromMap(doc.data()));
      } catch (_) {}
    }

    return result;
  }

  // =========================
  // GET MESSAGE BEFORE
  // =========================
  Future<List<Message>> getMessageBefore(String userId, int before) async {
    final querySnapshot = await Collections.messages(userId)
        .where('time', isLessThan: before)
        .orderBy('time', descending: true)
        .limit(10)
        .get();

    List<Message> result = [];

    for (var doc in querySnapshot.docs) {
      try {
        result.add(
          Message.fromMap(doc.data()).copyWith(
            statusMessage: StatusMessage.sent,
          ),
        );
      } catch (_) {}
    }

    return result;
  }
  // =========================
  // LOAD MORE
  // =========================

  Future<void> loadMore(String userId) async {
    if (state.isLoadingMore) return;

    final firebaseMessages = state.messages
        .where((e) => e.statusMessage == StatusMessage.sent)
        .toList();

    if (firebaseMessages.isEmpty) return;

    emit(
      state.copyWith(
        isLoadingMore: true,
      ),
    );

    try {
      firebaseMessages.sort(
        (a, b) => a.time.compareTo(b.time),
      );

      final oldest = firebaseMessages.first;

      final olderMessages = await getMessageBefore(
        userId,
        oldest.time,
      );

      final updated = [...state.messages];

      for (final msg in olderMessages) {
        final exists = updated.any((e) => e.id == msg.id);

        if (!exists) {
          updated.add(msg);
        }
      }

      updated.sort(
        (a, b) => b.time.compareTo(a.time),
      );

      emit(
        state.copyWith(
          messages: updated,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingMore: false,
        ),
      );
    }
  }

  // =========================
  // LOCAL
  // =========================
  List<Message> loadLocalMessages(String userId) {
    return localBox
        .toMap()
        .entries
        .where((e) => e.key.toString().startsWith('${userId}_'))
        .map((e) {
          try {
            if (e.value is Map) {
              return Message.fromMap(
                Map<String, dynamic>.from(e.value),
              );
            }
          } catch (e, s) {
            debugPrint(e.toString());
            debugPrint(s.toString());
          }

          return null;
        })
        .whereType<Message>()
        .toList();
  }
  // =========================
  // INIT
  // =========================

  Future<void> initMessages(String userId) async {
    final localMessages = loadLocalMessages(userId);

    emit(
      state.copyWith(
        isLoading: true,
        messages: localMessages,
      ),
    );

    try {
      final firebaseMessages = await getMessage(userId);

      final Map<String, Message> mergedMap = {};

      // firebase trước
      for (final msg in firebaseMessages) {
        mergedMap[msg.id] = msg.copyWith(
          statusMessage: StatusMessage.sent,
        );
      }

      // local override firebase
      for (final local in localMessages) {
        mergedMap[local.id] = local;
      }

      final merged = mergedMap.values.toList();

      merged.sort((a, b) => b.time.compareTo(a.time));

      emit(
        state.copyWith(
          messages: merged,
          isLoading: false,
        ),
      );

      for (final msg in merged) {
        if (msg.statusMessage == StatusMessage.sending) {
          await localBox.put('${userId}_${msg.id}', {
            ...msg.toMap(),
            'statusMessage': StatusMessage.failed.name,
          });

          updateMessageStatus(
            msg.id,
            StatusMessage.failed,
          );
        }
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  // =========================
  // FIREBASE MESSAGE
  // =========================
  List<Message> _sortMessages(List<Message> messages) {
    messages.sort(
      (a, b) => b.time.compareTo(a.time),
    );

    return messages;
  }

  Future<void> onFirebaseMessage(Message firebaseMsg) async {
    await localBox.delete(firebaseMsg.id);

    final updated = [...state.messages];

    updated.removeWhere((m) => m.id == firebaseMsg.id);

    updated.add(
      firebaseMsg.copyWith(
        statusMessage: StatusMessage.sent,
      ),
    );

    emit(
      state.copyWith(
        messages: _sortMessages(updated),
      ),
    );
  }

  // =========================
  // UPDATE STATUS
  // =========================

  void updateMessageStatus(
    String id,
    StatusMessage status,
  ) {
    final updated = state.messages.map((m) {
      if (m.id == id) {
        return m.copyWith(
          statusMessage: status,
        );
      }

      return m;
    }).toList();

    emit(
      state.copyWith(
        messages: updated,
      ),
    );
  }

  // =========================
  // SEND PROCESS
  // =========================

  Future<void> sendProcess(
    String text,
    String userId,
    BuildContext context,
  ) async {
    final id = const Uuid().v4();

    Message localMsg = Message(
      id: id,
      senderId: adminId,
      statusMessage: StatusMessage.sending,
      message: text,
      time: Timestamp.now().millisecondsSinceEpoch,
      product: null,
    );

    await localBox.put(
      '${userId}_${localMsg.id}',
      localMsg.toMap(),
    );

    emit(
      state.copyWith(
        messages: [
          localMsg,
          ...state.messages,
        ],
      ),
    );

    Timer(const Duration(seconds: 10), () async {
      final current = state.messages.where((e) => e.id == id).firstOrNull;

      if (current != null && current.statusMessage == StatusMessage.sending) {
        await localBox.put('${userId}_${localMsg.id}', {
          ...current.toMap(),
          Message.statusMessageField: StatusMessage.failed.name,
        });

        updateMessageStatus(
          id,
          StatusMessage.failed,
        );
      }
    });

    try {
      localMsg = Message(
        id: id,
        senderId: adminId,
        statusMessage: StatusMessage.sent,
        message: text,
        time: Timestamp.now().millisecondsSinceEpoch,
        product: null,
      );
      await sendMessage(localMsg, userId, context);
    } catch (e, s) {
      debugPrint('SEND ERROR: $e');
      debugPrintStack(stackTrace: s);

      await localBox.put('${userId}_${localMsg.id}', {
        ...localMsg.toMap(),
        Message.statusMessageField: StatusMessage.failed.name,
      });

      updateMessageStatus(
        id,
        StatusMessage.failed,
      );
    }
  }

  // =========================
  // RETRY
  // =========================

  Future<void> retry(
    Message msg,
    String userId,
    BuildContext context,
  ) async {
    final retryMsg = msg.copyWith(
      statusMessage: StatusMessage.sending,
      time: Timestamp.now().millisecondsSinceEpoch,
    );

    await localBox.put(
      '${userId}_${msg.id}',
      retryMsg.toMap(),
    );

    final updated = state.messages.map((e) {
      return e.id == msg.id ? retryMsg : e;
    }).toList();

    emit(state.copyWith(messages: updated));

    Timer(const Duration(seconds: 10), () async {
      final current = state.messages.where((e) => e.id == msg.id).firstOrNull;

      if (current != null && current.statusMessage == StatusMessage.sending) {
        await localBox.put('${userId}_${msg.id}', {
          ...current.toMap(),
          Message.statusMessageField: StatusMessage.failed.name,
        });

        updateMessageStatus(
          msg.id,
          StatusMessage.failed,
        );
      }
    });

    try {
      await sendMessage(retryMsg, userId, context);
    } catch (_) {
      await localBox.put('${userId}_${msg.id}', {
        ...retryMsg.toMap(),
        Message.statusMessageField: StatusMessage.failed.name,
      });

      updateMessageStatus(
        msg.id,
        StatusMessage.failed,
      );
    }
  }

  // =========================
  // SEND FIREBASE
  // =========================

  Future<void> sendMessage(
    Message message,
    String userId,
    BuildContext context,
  ) async {
    if (message.message.isEmpty) return;

    final ref = Collections.conversations.doc(userId);

    final messageRef = Collections.messages(userId).doc(message.id);

    final now = Timestamp.now().millisecondsSinceEpoch;

    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      ref,
      {
        Conversation.userIdField: userId,
        Conversation.lastMessageField: message.message,
        Conversation.lastMessageByField: UnreadCountBy.admin.name,
        Conversation.lastMessageTimeField: now,
        Conversation.unreadCountField: {
          UnreadCountBy.admin.name: 0,
          UnreadCountBy.user.name: FieldValue.increment(1)
        },
      },
      SetOptions(merge: true),
    );

    batch.set(
      messageRef,
      {
        ...message.toMap(),
        Message.timeField: now,
        Message.statusMessageField: StatusMessage.sent.name,
      },
    );

    await batch.commit();
  }
}
