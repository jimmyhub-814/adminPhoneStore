import 'dart:convert';

import 'package:admin/widget/home_widget/hamburger_menu/manage_product.dart';
import 'package:admin/widget/home_widget/widget/category.dart';
import 'package:admin/widget/home_widget/hamburger_menu/change_pass.dart';
import 'package:admin/widget/home_widget/widget/chat_widget/chat.dart';
import 'package:admin/widget/home_widget/widget/search_screen.dart';
import 'package:admin/widget/home_widget/widget/chat_widget/user_detail_chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:admin/app_constants/providers.dart';
import 'package:admin/auth/auth_page.dart';
import 'package:admin/cubit/messages_cubic.dart';
import 'package:admin/firebase_options.dart';
import 'package:admin/models/admin.dart';
import 'package:admin/provider/admin.dart';
import 'package:admin/provider/category.dart';
import 'package:admin/provider/conversation.dart';
import 'package:admin/provider/data.dart';
import 'package:admin/provider/feedBack.dart';
import 'package:admin/provider/notification.dart';
import 'package:admin/provider/order.dart';
import 'package:admin/provider/product.dart';
import 'package:admin/provider/statistics.dart';
import 'package:admin/provider/user_provider.dart';
import 'package:admin/service/notification_service.dart';
import 'package:admin/widget/home_widget/hamburger_menu/admin_info.dart';
import 'package:admin/widget/home.dart';
import 'package:admin/widget/home_widget/widget/add_carousel.dart';
import 'package:admin/widget/home_widget/hamburger_menu/account.dart';
import 'package:admin/widget/home_widget/hamburger_menu/chart.dart';
import 'package:admin/widget/home_widget/widget/notifications.dart';
import 'package:admin/widget/home_widget/widget/manage_product/product_detail.dart';
import 'package:admin/widget/home_widget/widget/chat_widget/user_order.dart';
import 'package:admin/widget/home_widget/widget/manage_product/add_category.dart';
import 'package:admin/widget/home_widget/widget/manage_product/add_product.dart';
import 'package:admin/widget/home_widget/widget/manage_product/check_final.dart';
import 'package:admin/widget/home_widget/widget/chat_widget/conversation_list.dart';
import 'package:admin/widget/home_widget/widget/order_detail.dart';
import 'package:admin/widget/home_widget/widget/manage_product/edit_category.dart';
import 'package:admin/widget/home_widget/hamburger_menu/feedback.dart';
import 'package:admin/widget/home_widget/hamburger_menu/manage_order.dart';
import 'package:admin/widget/home_widget/hamburger_menu/order_status.dart';
import 'package:admin/widget/home_widget/hamburger_menu/reply_feed_back.dart';
import 'package:admin/widget/home_widget/widget/manage_product/view_product_category.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final plugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));

  final title = message.data['title'] ?? 'Thông báo mới';
  final body = message.data['body'] ?? '';
  final payload = jsonEncode(message.data);

  await plugin.show(
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
    payload: payload,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  final status = await Permission.notification.status;

  if (status.isDenied) {
    await Permission.notification.request();
  } else if (status.isPermanentlyDenied) {
    await openAppSettings();
  }

  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => MessageCubit(),
      ),
    ],
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FeedBackProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  ));
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await FirebaseMessaging.instance.requestPermission();

          FirebaseAuth.instance.authStateChanges().listen((user) {
            if (user != null) {
              setupTokenAndFcm();
            }
          });
        });
        notificationService.initialize(context);

        notificationService.handleKilledStateMessage();

        _checkGooglePlayServices();
        debugPrint("✅ App init done, UI ready");
        await Hive.initFlutter();
      },
    );
  }

  Future<void> _checkGooglePlayServices() async {
    GooglePlayServicesAvailability result = await GoogleApiAvailability.instance
        .checkGooglePlayServicesAvailability();

    debugPrint("🔍 Google Play Status: $result");

    if (result != GooglePlayServicesAvailability.success) {
      ScaffoldMessenger.of(MyApp.navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Thiết bị không hỗ trợ Google Play Services đầy đủ!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> setupTokenAndFcm() async {
    final notificationService = NotificationService();

    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    final token = await notificationService.getDeviceToken();
    if (token.isEmpty) return;

    final uid = admin.uid;
    final adminRef = Collections.admin.doc(uid);
    final tokenRef = Collections.adminNotifications.doc('tokens');

    final snapshot = await adminRef.get();

    List<String> tokens = [];

    if (snapshot.exists &&
        snapshot.data()![Admin.adminDeviceTokensField] != null) {
      tokens =
          List<String>.from(snapshot.data()![Admin.adminDeviceTokensField]);
    }

    if (!tokens.contains(token)) {
      tokens.add(token);

      await adminRef.update(
        {
          Admin.adminDeviceTokensField: tokens,
        },
      );

      await tokenRef.set({
        Admin.adminDeviceTokensField: tokens,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Flutter',
        routes: {
          '/': (context) => const AuthGate(),
          '/home-screen': (context) => const HomeScreen(),
          '/view-item-category': (context) => const ViewItemCategory(),
          '/manage-product': (context) => const ManageProduct(),
          '/add-category': (context) => const AddCategory(),
          '/add-carousel': (context) => const AddCarousel(),
          '/manage-order': (context) => const OrderInfoPage(),
          '/conversation': (context) => const ConversationList(),
          '/chart': (context) => const Chart(),
          '/account': (context) => const AccountPage(),
          '/admin-info': (context) => const AdminInfoScreen(),
          '/notifications': (context) => const NotificationScreen(),
          '/feed-back-screen': (context) => const UserFeedback(),
          '/search': (context) => const SearchScreen(),
          '/edit-category': (context) => const EditCategoryScreen(),
        },
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case CategoryPage.routeName:
              final args = settings.arguments as CategoryPage;

              return MaterialPageRoute(
                builder: (context) => CategoryPage(
                  categoryId: args.categoryId,
                  categoryName: args.categoryName,
                ),
              );
            case UserOrder.routeName:
              final args = settings.arguments as UserOrder;

              return MaterialPageRoute(
                builder: (context) => UserOrder(
                  userId: args.userId,
                ),
              );
            case UserDetailChat.routeName:
              final args = settings.arguments as UserDetailChat;

              return MaterialPageRoute(
                builder: (context) => UserDetailChat(
                  userId: args.userId,
                  userAvatar: args.userAvatar,
                  userName: args.userName,
                ),
              );
            case OrderDetail.routeName:
              final args = settings.arguments as OrderDetail;

              return MaterialPageRoute(
                builder: (context) => OrderDetail(
                  orderId: args.orderId,
                ),
              );

            case ProductDetail.routeName:
              final args = settings.arguments as ProductDetail;

              return MaterialPageRoute(
                builder: (context) => ProductDetail(
                  id: args.id,
                ),
              );

            case AddProduct.routeName:
              final args = settings.arguments as AddProduct?;

              return MaterialPageRoute(
                builder: (context) => AddProduct(
                  product: args?.product,
                ),
              );
            case OrderStatusPage.routeName:
              final args = settings.arguments as OrderStatusPage;

              return MaterialPageRoute(
                builder: (context) => OrderStatusPage(
                  index: args.index,
                ),
              );
            case ReplyUserFeedback.routeName:
              final args = settings.arguments as ReplyUserFeedback;

              return MaterialPageRoute(
                builder: (context) => ReplyUserFeedback(
                  feedBack: args.feedBack,
                  productId: args.productId,
                ),
              );
            case UserChat.routeName:
              final args = settings.arguments as UserChat;

              return MaterialPageRoute(
                builder: (context) => UserChat(
                  id: args.id,
                ),
              );
            case CheckFinal.routeName:
              final args = settings.arguments as CheckFinal;

              return MaterialPageRoute(
                builder: (context) => CheckFinal(
                  product: args.product,
                  status: args.status,
                ),
              );
            case ChangeAdminPass.routeName:
              final args = settings.arguments as ChangeAdminPass;

              return MaterialPageRoute(
                builder: (context) => ChangeAdminPass(
                  email: args.email,
                ),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}
