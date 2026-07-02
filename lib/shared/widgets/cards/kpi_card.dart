import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? variation;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.variation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight.isFinite && constraints.maxHeight < 170;
        final dense =
            constraints.maxHeight.isFinite && constraints.maxHeight <= 120;
        final padding = dense ? 10.0 : (compact ? 12.0 : 18.0);
        final iconPadding = dense ? 7.0 : (compact ? 8.0 : 12.0);
        final iconSize = dense ? 18.0 : (compact ? 20.0 : 24.0);
        final titleSize = dense ? 12.0 : (compact ? 14.0 : 15.0);
        final valueSize = dense ? 21.0 : (compact ? 26.0 : 34.0);
        final subtitleSize = dense ? 10.0 : (compact ? 11.0 : 12.0);

        return Card(
          elevation: 0,
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dense ? 14 : 18),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(dense ? 10 : 12),
                      ),
                      child: Icon(icon, color: color, size: iconSize),
                    ),
                    const Spacer(),
                    if (variation != null)
                      Flexible(
                        child: Text(
                          variation!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: compact ? 15 : 18,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: dense ? 5 : (compact ? 6 : 16)),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: titleSize,
                  ),
                ),
                SizedBox(height: dense ? 1 : (compact ? 2 : 8)),
                SizedBox(
                  height: dense ? 24 : (compact ? 30 : 42),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: valueSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: dense ? 1 : (compact ? 2 : 8)),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: subtitleSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
