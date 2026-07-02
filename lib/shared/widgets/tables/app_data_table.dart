import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AppDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool showCheckboxColumn;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.showCheckboxColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: showCheckboxColumn,
            headingRowHeight: 56,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 60,
            horizontalMargin: 16,
            columnSpacing: 18,
            dividerThickness: 0.5,
            headingTextStyle: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            dataTextStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}
