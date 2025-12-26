import 'package:flutter/material.dart';
import '../../../domain/models/table_model.dart';
import '../../../utils/table_service.dart';

class TableSelectionDialog extends StatefulWidget {
  final int currentTableId;

  const TableSelectionDialog({Key? key, required this.currentTableId}) : super(key: key);

  @override
  State<TableSelectionDialog> createState() => _TableSelectionDialogState();
}

class _TableSelectionDialogState extends State<TableSelectionDialog> {
  final TableService _tableService = TableService();
  late Future<List<TableModel>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _tablesFuture = _tableService.getTables();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Chọn bàn đích", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 600, // Độ rộng dialog
        height: 400,
        child: FutureBuilder<List<TableModel>>(
          future: _tablesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            }

            final tables = snapshot.data ?? [];
            
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final isCurrent = table.id == widget.currentTableId;

                // Màu sắc hiển thị trạng thái
                Color bgColor = Colors.white;
                Color textColor = Colors.black;
                String statusText = "Trống";

                if (isCurrent) {
                  bgColor = Colors.grey.shade300; // Bàn hiện tại (Disable)
                  textColor = Colors.grey;
                  statusText = "Hiện tại";
                } else if (table.isOccupied) {
                  bgColor = Colors.orange.shade100; // Bàn có khách (Gộp)
                  textColor = Colors.deepOrange;
                  statusText = "Gộp";
                } else if (table.isCleaning) {
                  bgColor = Colors.red.shade50;
                  statusText = "Đang dọn";
                }

                return InkWell(
                  onTap: (isCurrent || table.isCleaning) 
                      ? null 
                      : () {
                          // Trả về bàn được chọn
                          Navigator.pop(context, table);
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          table.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 12, color: textColor, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
      ],
    );
  }
}