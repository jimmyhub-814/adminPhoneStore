import 'package:admin/app_constants/app_colors.dart';
import 'package:admin/app_constants/app_text_styles.dart';
import 'package:admin/models/product.dart';
import 'package:admin/widget/home_widget/widget/manage_product/product_detail.dart';
import 'package:admin/widget/shared_widgets/safe_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  const CustomCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (onTap ??
          () {
            Navigator.pushNamed(context, ProductDetail.routeName,
                arguments: ProductDetail(id: product.id));
          }),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(11)),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
            ),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11),
                        ),
                        child: SafeImage(
                          url: product.mainImage,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 3,
                            horizontal: 5,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(2),
                            ),
                          ),
                          child: Text(
                            '${product.listVariants[0].phoneDiscount.toStringAsFixed(0)}%',
                            textAlign: TextAlign.center,
                            style: AppTextstyles.headingH7.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.title,
                          style: AppTextstyles.headingH7Bold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              product.fbInfo.averageRating.toString(),
                              style: AppTextstyles.smallText,
                            ),
                            const Icon(
                              Icons.star,
                              color: AppColors.star,
                              size: 11,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${NumberFormat("#,###", "en_US").format(
                                product.listVariants[0].phonePrice -
                                    ((product.listVariants[0].phonePrice *
                                            product.listVariants[0]
                                                .phoneDiscount) /
                                        100),
                              )}đ',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                                letterSpacing: 0.38,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Đã bán ${product.salesVolume}',
                                style: AppTextstyles.extraSmallText),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
