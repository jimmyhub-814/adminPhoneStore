import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/storages.dart';
import 'package:admin/provider/category.dart';
import 'package:admin/provider/data.dart';
import 'package:admin/provider/product.dart';
import 'package:admin/widget/home_widget/widget/recommend_product.dart';
import 'package:admin/widget/home_widget/widget/big_carousel.dart';
import 'package:admin/widget/home_widget/hamburger_menu/hamburger_menu.dart';
import 'package:admin/widget/home_widget/widget/notifications.dart';
import 'package:admin/widget/home_widget/widget/manage_product/category_items.dart';
import 'package:admin/widget/home_widget/widget/search_screen.dart';
import 'package:admin/widget/home_widget/widget/chat_widget/conversation_list.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home-screen';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _dismissAllLoadings();
      loadData();
    });
  }

  Future<void> loadData() async {
    if (isLoading) return;

    isLoading = true;

    try {
      final categoryProvider = context.read<CategoryProvider>();
      final productProvider = context.read<ProductProvider>();
      final dataProvider = context.read<DataProvider>();

      await categoryProvider.fetchCategoriesList();

      await productProvider.fetchProductsList();

      await dataProvider.fetchCarousel();

      await getAllCarousel();
    } catch (e) {
      debugPrint('Load data error: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<List<String>> getAllCarousel() async {
    final ref = Storages.carousels;
    final result = await ref.listAll();
    List<String> urls = [];

    for (var item in result.items) {
      final url = await item.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  void _dismissAllLoadings() {
    final navigator = Navigator.of(context, rootNavigator: true);
    while (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      strokeWidth: 4,
      onRefresh: loadData,
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.textSecondary, AppColors.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.1, 0.4],
              ),
            ),
          ),
          Scaffold(
            drawer: const HamburgerBar(),
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: 80,
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          color: AppColors.surface.withValues(alpha: 0.15),
                          border: Border.all(
                            color: const Color.fromARGB(255, 151, 138, 138)
                                .withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.menu_open_outlined,
                              color: AppColors.surface,
                              size: 18,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Menu',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                  context, NotificationScreen.routeName);
                            },
                            child: const Icon(
                              Icons.notifications_active,
                              color: AppColors.surface,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                  context, ConversationList.routeName);
                            },
                            child: const Icon(
                              Icons.chat,
                              color: AppColors.surface,
                              size: 25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 10,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, SearchScreen.routeName);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'search-bar',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            height: 45,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 20,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    'Tìm kiếm',
                                    style: TextStyle(
                                      color: Color.fromARGB(
                                        255,
                                        82,
                                        82,
                                        82,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: BigCarouselWidget()),
                  const SliverToBoxAdapter(child: CategoryItems()),
                  const SliverToBoxAdapter(child: RecommendProduct()),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
