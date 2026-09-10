import 'package:cloud_firestore/cloud_firestore.dart';

class FeedBack {
  static const idField = 'id';
  static const userIdField = 'userId';
  static const userNameField = 'userName';
  static const userAvatarField = 'userAvatar';
  static const variantNameField = 'variantName';
  static const feedBackTextField = 'feedBackText';
  static const timeField = 'time';
  static const adminReplyField = 'adminReply';
  static const variantImageField = 'variantImage';
  static const voteField = 'vote';

  String id;
  String userId;
  String userName;
  String userAvatar;
  String variantName;
  int vote;
  String feedBackText;
  Timestamp time;
  String? adminReply;
  String variantImage;

  FeedBack({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.vote,
    required this.feedBackText,
    required this.time,
    required this.variantName,
    required this.variantImage,
    this.adminReply,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      userIdField: userId,
      userNameField: userName,
      userAvatarField: userAvatar,
      timeField: Timestamp.now(),
      voteField: vote,
      feedBackTextField: feedBackText,
      adminReplyField: adminReply,
      variantNameField: variantName,
      variantImageField: variantImage,
    };
  }

  factory FeedBack.fromMap(Map<String, dynamic> map) {
    return FeedBack(
      id: map[idField] as String,
      userId: map[userIdField] as String,
      userName: map[userNameField] as String,
      userAvatar: map[userAvatarField] as String,
      time: map[timeField] as Timestamp,
      vote: map[voteField] as int,
      feedBackText: map[feedBackTextField] as String,
      variantName: map[variantNameField] as String,
      variantImage: map[variantImageField] as String,
      adminReply: map[adminReplyField]?.toString(),
    );
  }
}
