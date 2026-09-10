import 'package:admin/app_constants/app_colors.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class AppbarIcon extends StatelessWidget {
  Color? color;
  VoidCallback? onTap;
  AppbarIcon({super.key, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color == null
              ? AppColors.primary.withValues(alpha: 0.1)
              : color?.withValues(alpha: 0.1),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onTap ?? () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 14,
            color: color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
