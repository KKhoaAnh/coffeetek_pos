import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_model/cart_view_model.dart';
import '../widgets/modifier_selection_dialog.dart';
import '../../../domain/models/modifier/modifier.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../widgets/payment_dialog.dart';
import '../../../utils/printer_service.dart';
import '../../../domain/models/table_model.dart';
import '../widgets/table_selection_dialog.dart';

class CartSection extends StatelessWidget {
  const CartSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final currentUserId = authVM.currentUser?.id ?? '0';
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Consumer<CartViewModel>(
      builder: (context, cartVM, child) {
        bool canReprint = cartVM.currentOrderId != null;
        final cartEntries = cartVM.items.entries.toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              // --- HEADER HÓA ĐƠN ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.brown[50],
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hóa đơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                        
                        // Nút chọn nhiều / Xóa
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                cartVM.isSelectionMode ? Icons.check_box : Icons.check_box_outline_blank,
                                color: Colors.brown,
                              ),
                              tooltip: cartVM.isSelectionMode ? 'Hủy chọn' : 'Chọn nhiều',
                              onPressed: () => cartVM.toggleSelectionMode(),
                            ),
                            
                            IconButton(
                              icon: Icon(
                                cartVM.isSelectionMode ? Icons.delete : Icons.delete_outline, 
                                color: Colors.red
                              ),
                              tooltip: cartVM.isSelectionMode ? 'Xóa đã chọn' : 'Xóa tất cả',
                              onPressed: () {
                                if (cartVM.isSelectionMode) {
                                  if (cartVM.selectedKeys.isNotEmpty) {
                                    cartVM.deleteSelectedItems();
                                  }
                                } else {
                                  if (cartVM.items.isNotEmpty) _showClearCartConfirmDialog(context, cartVM);
                                }
                              },
                            )
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // --- KHU VỰC THÔNG TIN BÀN & LOẠI ĐƠN ---
                    Row(
                      children: [
                        // 1. Dropdown Loại đơn (Giữ lại để switch Tại bàn/Mang về)
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.brown.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: cartVM.orderType,
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: 'DINE_IN', child: Text("Tại bàn", style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 'TAKE_AWAY', child: Text("Mang đi", style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (val) {
                                  if (val != null) cartVM.setOrderType(val);
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        
                        // 2. [ĐÃ SỬA]: Hiển thị Tên bàn cố định (Read-only)
                        // Chỉ hiện khi là DINE_IN
                        if (cartVM.orderType == 'DINE_IN')
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 40,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100], // Màu xám nhạt thể hiện không sửa được
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                // Nếu null thì hiện text fallback, nhưng theo logic mới thì luôn có bàn
                                cartVM.tableName ?? 'Chưa chọn bàn',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold, // In đậm tên bàn
                                  color: Colors.brown[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),
              
              // --- DANH SÁCH MÓN ĂN (Giữ nguyên logic cũ) ---
              Expanded(
                child: cartEntries.isEmpty
                    ? const Center(child: Text("Chưa có món nào", style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: cartEntries.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final entry = cartEntries[i];
                          final key = entry.key;
                          final item = entry.value;
                          final sortedModifiers = List<Modifier>.from(item.selectedModifiers);
                          final isSelected = cartVM.selectedKeys.contains(key);

                          int getPriority(String groupId) {
                            if (groupId == 'g_size') return 0;
                            if (groupId == 'g_sugar') return 1;
                            if (groupId.startsWith('g_topping')) return 2;
                            return 3; 
                          }

                          sortedModifiers.sort((a, b) {
                            final priorityA = getPriority(a.groupId);
                            final priorityB = getPriority(b.groupId);
                            return priorityA.compareTo(priorityB);
                          });

                          Widget itemContent = Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            color: isSelected ? Colors.brown[50] : Colors.transparent, 
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (cartVM.isSelectionMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12, top: 4),
                                    child: Icon(
                                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                      color: isSelected ? Colors.brown : Colors.grey,
                                    ),
                                  ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                                        child: Text(
                                          currencyFormat.format(item.product.price),
                                          style: TextStyle(
                                            color: Colors.brown[300], 
                                            fontSize: 13, 
                                            fontWeight: FontWeight.w500
                                          ),
                                        ),
                                      ),

                                      if (sortedModifiers.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: sortedModifiers.map((modifier) {
                                              final hasExtraPrice = modifier.extraPrice > 0;
                                              final priceString = hasExtraPrice
                                                  ? '+${currencyFormat.format(modifier.extraPrice)}'
                                                  : '';
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 2),
                                                child: RichText(
                                                  text: TextSpan(
                                                    style: TextStyle(fontSize: 13, color: Colors.grey[700], fontFamily: 'Roboto'),
                                                    children: [
                                                      const TextSpan(text: '- '),
                                                      TextSpan(text: modifier.name, style: const TextStyle(fontStyle: FontStyle.italic)),
                                                      if (hasExtraPrice)
                                                        TextSpan(
                                                          text: ' ($priceString)',
                                                          style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 12),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(item.subtotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    if (!cartVM.isSelectionMode)
                                      Container(
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () => cartVM.removeSingleItem(key),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Icon(Icons.remove_circle_outline, size: 22, color: Colors.grey),
                                              ),
                                            ),
                                            Container(
                                              constraints: const BoxConstraints(minWidth: 24),
                                              alignment: Alignment.center,
                                              child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            ),
                                            InkWell(
                                              onTap: () => cartVM.addToCart(item.product, modifiers: item.selectedModifiers),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Icon(Icons.add_circle_outline, size: 22, color: Colors.green),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                  ],
                                ),
                              ],
                            ),
                          );

                          return InkWell(
                            onTap: () {
                              if (cartVM.isSelectionMode) {
                                cartVM.toggleItemSelection(key);
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => ModifierSelectionDialog(
                                    product: item.product,
                                    initialSelections: item.selectedModifiers,
                                    isEditing: true,
                                    onConfirm: (newModifiers) {
                                      cartVM.updateCartItem(key, newModifiers);
                                    },
                                  ),
                                );
                              }
                            },
                            child: cartVM.isSelectionMode
                                ? itemContent
                                : Dismissible(
                                    key: ValueKey(key),
                                    direction: DismissDirection.startToEnd,
                                    background: Container(
                                      color: Colors.red[100],
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 30),
                                      child: const Icon(Icons.delete, color: Colors.red),
                                    ),
                                    onDismissed: (direction) {
                                      cartVM.removeCartItemRow(key);
                                    },
                                    child: itemContent,
                                  ),
                          );
                        },
                      ),
              ),

              // --- FOOTER THANH TOÁN (Giữ nguyên) ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tìm đoạn này trong cart_section.dart và thay thế:
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng cộng:', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8), // Khoảng cách an toàn
                            
                            // [RESPONSIVE]: Dùng Expanded và FittedBox để giá tiền không bị vỡ dòng
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown, // Tự thu nhỏ font nếu hết chỗ
                                alignment: Alignment.centerRight, // Căn lề phải
                                child: Text(
                                  currencyFormat.format(cartVM.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        if (cartVM.orderType == 'DINE_IN' && cartVM.tableName != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.compare_arrows),
                              label: const Text("CHUYỂN / GỘP BÀN"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                foregroundColor: Colors.blue[800],
                                side: BorderSide(color: Colors.blue.shade200),
                              ),
                              onPressed: () => _handleMoveOrMergeTable(context, cartVM),
                            ),
                          ),

                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.print, color: Colors.grey),
                            label: const Text("IN LẠI PHIẾU BẾP"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: Colors.green[800],
                              side: BorderSide(
                                color: canReprint ? Colors.green : Colors.grey.shade300,
                              ),
                            ),
                            onPressed: canReprint
                                ? () async {
                                    final int printCount = await cartVM.requestReprintKitchen();
                                    if (printCount > 0) {
                                      final printer = PrinterService();
                                      final currentOrder = cartVM.buildOrderObject(
                                        userId: currentUserId,
                                        isPaid: false,
                                      );
                                      await printer.printKitchen(
                                        currentOrder,
                                        reprintCount: printCount,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đang in lại phiếu bếp (Lần $printCount)')),
                                      );
                                    }
                                  }
                                : null,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero, // Giảm padding nếu chữ quá to
                                    side: const BorderSide(color: Colors.orange, width: 2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: cartVM.items.isEmpty
                                      ? null
                                      : () => _handleOrderAction(context, isPending: true),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('LƯU ĐƠN', style: TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: Colors.brown,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: cartVM.items.isEmpty
                                      ? null
                                      : () => _handleOrderAction(context, isPending: false),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('THANH TOÁN', style: TextStyle(fontSize: 16, color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearCartConfirmDialog(BuildContext context, CartViewModel cartVM) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ món đang chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              cartVM.clearCart(keepTable: true);
              Navigator.of(ctx).pop();
            },
            child: const Text('Xóa hết', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOrderAction(BuildContext context, {required bool isPending}) async {
    final cartVM = Provider.of<CartViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    if (cartVM.orderType == 'DINE_IN' && (cartVM.tableName == null || cartVM.tableName!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số bàn!'), backgroundColor: Colors.red),
        );
        return;
    }

    final currentUserId = authVM.currentUser?.id ?? 'UNKNOWN';

    if (isPending) {
      final preCalculatedDeltaOrder = cartVM.buildKitchenPrintOrder(userId: currentUserId);
      
      bool isSupplementary = false;
      if (preCalculatedDeltaOrder != null) {
        isSupplementary = cartVM.orderItems.values.any((item) => item.committedQuantity > 0);
      }

      final savedOrder = await cartVM.submitOrder(
        userId: currentUserId, 
        isPaid: false
      );
      
      if (savedOrder != null) {
        if (preCalculatedDeltaOrder != null) {
          final finalPrintOrder = preCalculatedDeltaOrder.copyWith(
              id: savedOrder.id,
              orderCode: savedOrder.orderCode,
              tableName: savedOrder.tableName
          );

          try {
            final printer = PrinterService();
            await printer.printKitchen(
              finalPrintOrder, 
              reprintCount: 0, 
              customTitle: isSupplementary ? 'MÓN GỌI THÊM' : 'PHIẾU BẾP'
            );
          } catch (e) {
            print("Lỗi in bếp: $e");
          }
        }

        cartVM.syncCommittedQuantities();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu đơn hàng thành công!')),
        );

        await Future.delayed(const Duration(milliseconds: 500)); 
        if (context.mounted) {
          Navigator.of(context).pop(); 
        }
      }      
    } else {
      showDialog(
        context: context,
        builder: (ctx) => PaymentDialog(
          totalAmount: cartVM.totalAmount,
            onConfirm: (paymentMethod, amountReceived, discountAmount, discountType) async {
        
            bool isImmediateOrder = cartVM.currentOrderId == null;

            // [SỬA LỖI] Truyền thêm thông tin giảm giá vào hàm submitOrder
            final completedOrder = await cartVM.submitOrder(
              userId: currentUserId, 
              isPaid: true,
              paymentMethod: paymentMethod,
              amountReceived: amountReceived,
              discountAmount: discountAmount, // <--- Mới
              discountType: discountType      // <--- Mới
            );

            if (completedOrder != null) {
              final printer = PrinterService();
              
              // In bếp (nếu là đơn mới và ăn tại bàn)
              if (cartVM.orderType == 'DINE_IN' && isImmediateOrder) {
                  await printer.printKitchen(completedOrder, reprintCount: 0);
                  await Future.delayed(const Duration(milliseconds: 2000));
              }

              // In hóa đơn thanh toán
              await printer.printBill(
                completedOrder, 
                isProvisional: false, 
                amountReceived: amountReceived
                // Lưu ý: completedOrder trả về từ API nên đã chứa thông tin discount
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanh toán thành công!')),
              );

              await Future.delayed(const Duration(milliseconds: 500));
              if (context.mounted) Navigator.of(context).pop(); 

            } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lỗi thanh toán!'), backgroundColor: Colors.red),
                );
            }
          },
        ),
      );
    }
  }

  Future<void> _handleMoveOrMergeTable(BuildContext context, CartViewModel cartVM) async {
    // 1. Mở dialog chọn bàn đích
    // Import file table_selection_dialog.dart ở đầu file nhé
    final targetTable = await showDialog<TableModel>(
      context: context,
      builder: (ctx) => TableSelectionDialog(currentTableId: cartVM.tableId ?? -1),
    );

    if (targetTable == null) return; // Người dùng bấm Hủy

    // 2. Xác định hành động (Move hay Merge)
    bool isMerge = targetTable.isOccupied; // Nếu bàn đích có khách -> Gộp
    String actionName = isMerge ? "GỘP" : "CHUYỂN";
    String confirmMsg = isMerge 
        ? "Bạn có chắc muốn GỘP bàn ${cartVM.tableName} vào ${targetTable.name}?" 
        : "Bạn có chắc muốn CHUYỂN từ ${cartVM.tableName} sang ${targetTable.name}?";

    // 3. Hỏi xác nhận
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Xác nhận $actionName bàn"),
        content: Text(confirmMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text("Đồng ý", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );

    if (confirm != true) return;

    // 4. Gọi API thực hiện
    // Hiện loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    bool success = false;
    if (isMerge) {
      success = await cartVM.mergeTable(targetTable.id);
    } else {
      success = await cartVM.moveTable(targetTable.id);
    }

    Navigator.pop(context); // Tắt loading

    // 5. Xử lý kết quả
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã $actionName bàn thành công!")));
      
      // Thành công thì thoát ra ngoài màn hình Sơ đồ bàn để chọn lại
      // Vì bàn hiện tại đã bị chuyển đi hoặc gộp mất rồi
      cartVM.clearCart(); // Xóa giỏ hàng local
      Navigator.of(context).pop(); // Back về TableScreen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi thao tác, vui lòng thử lại!"), backgroundColor: Colors.red));
    }
  }
}