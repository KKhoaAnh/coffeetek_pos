// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../view_model/cart_view_model.dart';
// import '../../../domain/models/table_model.dart';

// class TableMapDialog extends StatefulWidget {
//   const TableMapDialog({Key? key}) : super(key: key);

//   @override
//   State<TableMapDialog> createState() => _TableMapDialogState();
// }

// class _TableMapDialogState extends State<TableMapDialog> {
//   bool _isSelectingTarget = false;
//   TableModel? _sourceTable;

//   @override
//   void initState() {
//     super.initState();
//     Provider.of<CartViewModel>(context, listen: false).fetchTables();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Container(
//         width: 700,
//         height: 600,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Text(
//               _isSelectingTarget 
//                   ? "CHỌN BÀN ĐÍCH CHO ${_sourceTable?.name}" 
//                   : "SƠ ĐỒ BÀN",
//               style: TextStyle(
//                 fontSize: 22, 
//                 fontWeight: FontWeight.bold,
//                 color: _isSelectingTarget ? Colors.brown : Colors.black
//               ),
//             ),

//             if (_isSelectingTarget)
//               TextButton.icon(
//                 icon: const Icon(Icons.cancel),
//                 label: const Text("Hủy thao tác chuyển"),
//                 onPressed: () {
//                   setState(() {
//                     _isSelectingTarget = false;
//                     _sourceTable = null;
//                   });
//                 },
//               ),

//             const Divider(),
//             _buildLegend(),
//             const SizedBox(height: 10),
//             Expanded(
//               child: Consumer<CartViewModel>(
//                 builder: (context, cartVM, child) {
//                   return GridView.builder(
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 5,
//                       crossAxisSpacing: 15,
//                       mainAxisSpacing: 15,
//                       childAspectRatio: 1.2,
//                     ),
//                     itemCount: cartVM.tables.length,
//                     itemBuilder: (ctx, i) {
//                       final table = cartVM.tables[i];
//                       return _buildTableItem(context, table, cartVM);
//                     },
//                   );
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTableItem(BuildContext context, TableModel table, CartViewModel cartVM) {
//     Color bgColor = Colors.green;
//     Color textColor = Colors.white;
//     IconData icon = Icons.table_restaurant;

//     if (table.isOccupied) {
//       bgColor = Colors.red;
//       icon = Icons.person;
//     } else if (table.isCleaning) {
//       bgColor = Colors.amber;
//       textColor = Colors.black;
//       icon = Icons.cleaning_services;
//     }

//     return InkWell(
//       onTap: () => _handleTableClick(context, table, cartVM),
//       child: Container(
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 30, color: textColor),
//             const SizedBox(height: 5),
//             Text(table.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
//             if (table.isOccupied)
//                const Text("Đang dùng", style: TextStyle(color: Colors.white70, fontSize: 12)),
//              if (table.isCleaning)
//                const Text("Chờ dọn", style: TextStyle(color: Colors.black54, fontSize: 12)),
//           ],
//         ),
//       ),
//     );
//   }
  
//   void _handleTableClick(BuildContext context, TableModel clickedTable, CartViewModel cartVM) {
//     if (_isSelectingTarget && _sourceTable != null) {
//       if (clickedTable.id == _sourceTable!.id) return;

//       if (clickedTable.isAvailable) {
//         _confirmAction(context, "Chuyển bàn", "Chuyển từ ${_sourceTable!.name} sang ${clickedTable.name}?", () async {
//             final success = await cartVM.orderRepositoryIml.moveTable(_sourceTable!.id, clickedTable.id);
//             if (success) {
//                await cartVM.fetchTables();
//                setState(() { _isSelectingTarget = false; _sourceTable = null; });
//                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chuyển bàn thành công")));
//             }
//         });
//       } else if (clickedTable.isOccupied) {
//         _confirmAction(context, "Gộp bàn", "Gộp đơn của ${_sourceTable!.name} VÀO ${clickedTable.name}?", () async {
//             final success = await cartVM.orderRepositoryIml.mergeTable(_sourceTable!.id, clickedTable.id);
//             if (success) {
//                await cartVM.fetchTables();
//                setState(() { _isSelectingTarget = false; _sourceTable = null; });
//                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gộp bàn thành công")));
//             }
//         });
//       }
//       return;
//     }

//     if (clickedTable.isAvailable) {
//       cartVM.startNewOrderForTable(clickedTable);
//       Navigator.of(context).pop();
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã chọn ${clickedTable.name}')));
//     } else if (clickedTable.isOccupied) {
//        _showOccupiedTableOptions(context, clickedTable, cartVM);
//     } 
//     else if (clickedTable.isCleaning) {
//        showDialog(
//          context: context,
//          builder: (ctx) => AlertDialog(
//            title: Text("Dọn bàn ${clickedTable.name}?"),
//            content: const Text("Xác nhận bàn đã dọn dẹp sạch sẽ và sẵn sàng đón khách mới."),
//            actions: [
//              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Hủy")),
//              ElevatedButton(
//                onPressed: () async {
//                  await cartVM.clearTable(clickedTable.id); 
                 
//                  Navigator.of(ctx).pop();
//                }, 
//                child: const Text("Đã dọn xong")
//              ),
//            ],
//          )
//        );
//     }
//   }

//   void _confirmAction(BuildContext context, String title, String content, VoidCallback onConfirm) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(title),
//         content: Text(content),
//         actions: [
//           TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Hủy")),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(ctx).pop();
//               onConfirm();
//             },
//             child: const Text("Xác nhận")
//           )
//         ],
//       )
//     );
//   }

//   void _showOccupiedTableOptions(BuildContext context, TableModel table, CartViewModel cartVM) {
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) => Container(
//         height: 200,
//         child: Column(
//           children: [
//             Text("Thao tác: ${table.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.receipt_long, color: Colors.blue),
//               title: const Text("Xem đơn hàng / Thanh toán"),
//               onTap: () {
//                  if (table.currentOrderId != null) {
//                     cartVM.restoreOrderToCart(table.currentOrderId.toString());
//                     Navigator.of(ctx).pop();
//                     Navigator.of(context).pop();
//                  }
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.swap_horiz, color: Colors.orange),
//               title: const Text("Chuyển bàn / Gộp bàn"),
//               onTap: () {
//                 Navigator.of(ctx).pop(); // Đóng menu dưới
                
//                 // Kích hoạt chế độ chọn bàn đích
//                 setState(() {
//                   _isSelectingTarget = true;
//                   _sourceTable = table;
//                 });
//               },
//             ),
//           ],
//         ),
//       )
//     );
//   }

//   Widget _buildLegend() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _legendItem(Colors.green, "Trống"),
//         const SizedBox(width: 15),
//         _legendItem(Colors.red, "Có khách"),
//         const SizedBox(width: 15),
//         _legendItem(Colors.amber, "Chờ dọn/Đã TT"),
//       ],
//     );
//   }

//   Widget _legendItem(Color color, String label) {
//     return Row(children: [
//       Container(width: 16, height: 16, color: color),
//       const SizedBox(width: 5),
//       Text(label)
//     ]);
//   }
// }