import 'package:flutter/material.dart';

class TablePage extends StatefulWidget {
  final String title;
  final List<String> columns;
  const TablePage({required this.title, required this.columns, super.key});

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  List<List<String>> data = [];
  List<List<String>> filteredData = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    data = List.generate(
        20, (index) => List.generate(widget.columns.length, (col) => "${widget.title} $index"));
    filteredData = List.from(data);
  }

  void _filterData(String query) {
    setState(() {
      searchQuery = query;
      filteredData = data
          .where((row) =>
              row.any((cell) => cell.toLowerCase().contains(query.toLowerCase())))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            onChanged: _filterData,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search ${widget.title}",
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[850],
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateColor.resolveWith((states) => Colors.grey[800]!),
              dataRowColor:
                  WidgetStateColor.resolveWith((states) => Colors.grey[850]!),
              headingTextStyle:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              dataTextStyle: const TextStyle(color: Colors.white),
              columns: widget.columns.map((col) => DataColumn(label: Text(col))).toList(),
              rows: filteredData
                  .map((row) => DataRow(
                        cells: row.map((cell) => DataCell(Text(cell))).toList(),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
