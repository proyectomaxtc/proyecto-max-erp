import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_duration.dart';

class CustomCard extends StatelessWidget {
  final Widget child;

  final EdgeInsetsGeometry? padding;

  final VoidCallback? onTap;

  final double? width;

  final double? height;

  final Color? color;

  final bool showBorder;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.width,
    this.height,
    this.color,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = AnimatedContainer(
      duration: AppDuration.normal,

      width: width,

      height: height,

      padding: padding ??
          const EdgeInsets.all(
            AppSpacing.cardPadding,
          ),

      decoration: BoxDecoration(
        color: color ?? AppColors.card,

        borderRadius: BorderRadius.circular(
          AppRadius.lg,
        ),

        border: showBorder
            ? Border.all(
                color: AppColors.border,
              )
            : null,

        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 6),
            color: Colors.black26,
          ),
        ],
      ),

      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: BorderRadius.circular(
        AppRadius.lg,
      ),
      onTap: onTap,
      child: card,
    );
  }
}