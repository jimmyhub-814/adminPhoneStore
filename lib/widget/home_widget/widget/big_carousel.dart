import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/provider/data.dart';
import 'package:admin/widget/home_widget/widget/add_carousel.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class BigCarouselWidget extends StatefulWidget {
  const BigCarouselWidget({super.key});

  @override
  State<BigCarouselWidget> createState() => _BigCarouselWidgetState();
}

class _BigCarouselWidgetState extends State<BigCarouselWidget> {
  @override
  Widget build(BuildContext context) {
    final images = context.watch<DataProvider>().images;

    if (images.isEmpty) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          height: 131,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.dark,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          height: 131,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Swiper(
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 131,
                        width: double.infinity,
                        color: Colors.grey,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.error));
                  },
                );
              },
              itemCount: images.length,
              autoplay: true,
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AddCarousel.routeName);
            },
            child: const Icon(
              Icons.edit_outlined,
              size: 15,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
