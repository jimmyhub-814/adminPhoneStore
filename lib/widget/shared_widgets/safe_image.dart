import 'dart:io';
import 'package:admin/app_constants/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SafeImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SafeImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return fallback();
    }

    /// NETWORK
    if (url!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) {
          return shimmer();
        },
        errorWidget: (_, __, ___) {
          return fallback();
        },
      );
    }

    /// LOCAL FILE
    return Image.file(
      File(url!),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return fallback();
      },
    );
  }

  Widget shimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        color: AppColors.surface,
      ),
    );
  }

  Widget fallback() {
    return Image.asset(
      'assets/img/no_internet.png',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
