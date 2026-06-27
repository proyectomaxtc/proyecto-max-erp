import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AppTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 58,
            dataRowMinHeight: 58,
            dataRowMaxHeight: 58,
            headingRowColor: WidgetStateProperty.all(
              AppColors.surface,
            ),
            dividerThickness: 0.4,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}