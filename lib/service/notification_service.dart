import 'dart:convert';
import 'dart:io';
import 'package:admin/main.dart';
import 'package:admin/widget/home_widget/widget/order_detail.dart'; 
import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('🔔 Notification tapped (background): ${notificationResponse.payload}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize(BuildContext context) async {
    await initLocalNotifications();
    await getDeviceToken();
    configureFCMListeners();
    requestPermission();
  } 

  Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        Get.snackbar(
          'Notification Permission',
          'Please enable notifications in settings.',
          snackPosition: SnackPosition.BOTTOM,
        );

        Future.delayed(const Duration(seconds: 3)).then((_) {
          AppSettings.openAppSettings(type: AppSettingsType.notification);
        });
      } else {
        print("✅ Notification permission granted");
      }
    } catch (e) {
      print("❌ Error requesting permission: $e");
    }
  }

  Future<String> getDeviceToken() async {
    try {
      print("🔍 Đang gọi _messaging.getToken()");
      String? token = await _messaging.getToken();
      if (token != null) {
        print("📱 FCM Token: $token");
      } else {
        print("⚠️ getToken() trả về null");
      }

      _messaging.onTokenRefresh.listen((newToken) {
        print("🔄 New FCM Token: $newToken");
      });

      return token ?? '';
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return '';
    }
  }

  Future<void> initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) { 
        _handleMessage(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    const channel = AndroidNotificationChannel(
      'default_channel',
      'Thông báo chung',
      description: 'Kênh mặc định cho tất cả thông báo',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> handleKilledStateMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return; 
 
    int attempts = 0;
    while (MyApp.navigatorKey.currentState == null && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 250));
      attempts++;
      print("⏳ Waiting for navigator... attempt $attempts");
    }

    if (MyApp.navigatorKey.currentState == null) {
      print("❌ Navigator vẫn null sau ${attempts * 250}ms, bỏ qua");
      return;
    }

    print("✅ Navigator ready sau ${attempts * 250}ms");
    _handleMessage(jsonEncode(message.data));
  }
  
  void configureFCMListeners() { 
    FirebaseMessaging.onMessage.listen((message) {
      print("🔥 FOREGROUND");
      final title = message.data['title'];
      final body = message.data['body'];
      if (message.data.isEmpty && message.notification == null) {
        print("🚫 Empty message ignored");
        return;
      }
      _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Thông báo chung',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });
 
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("🔥 OPENED APP");
      _handleMessage(jsonEncode(message.data));
    });
  }

  Future<void> checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      _handleMessage(jsonEncode(message.data));
    }
  }

  void _handleMessage(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      print("📌 Handle message data: $data");

      final orderId = data['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) {
        print("⚠️ orderId null hoặc rỗng");
        return;
      }

      print("🎯 Navigate to DetailOrder: $orderId");

      MyApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => OrderDetail(orderId: orderId),
        ),
      );
    } catch (e) {
      print("❌ Error handling message: $e");
    }
  }
}
