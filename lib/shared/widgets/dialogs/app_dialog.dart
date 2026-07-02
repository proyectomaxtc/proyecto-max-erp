import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 720,
    this.maxHeight = 700,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 760;
    final horizontalInset = compact ? 10.0 : 24.0;
    final verticalInset = compact ? 10.0 : 24.0;
    final availableWidth = math.max(280.0, size.width - horizontalInset * 2);
    final availableHeight = math.max(360.0, size.height - verticalInset * 2);

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(maxWidth, availableWidth),
            maxHeight: math.min(maxHeight, availableHeight),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: compact ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: "Cerrar",
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 12 : 20),
                Expanded(child: SingleChildScrollView(child: child)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
