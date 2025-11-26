import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class DataTableCard extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  const DataTableCard({super.key, required this.title, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
            rows: rows.map((r) => DataRow(cells: r.map((v) => DataCell(Text(v))).toList())).toList(),
          ),
        ),
      ]),
    );
  }
}
