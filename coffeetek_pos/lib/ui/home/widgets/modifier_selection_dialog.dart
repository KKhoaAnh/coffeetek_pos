import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/product.dart';
import '../../../domain/models/modifier/modifier.dart';
import '../../../domain/models/modifier/modifier_group.dart';
import '../../../data/repositories/product_repository_impl.dart';

class ModifierSelectionDialog extends StatefulWidget {
  final Product product;
  final List<Modifier> initialSelections;
  final Function(List<Modifier>) onConfirm;
  final bool isEditing;

  const ModifierSelectionDialog({
    Key? key,
    required this.product,
    this.initialSelections = const [],
    required this.onConfirm,
    this.isEditing = false,
  }) : super(key: key);

  @override
  State<ModifierSelectionDialog> createState() => _ModifierSelectionDialogState();
}

class _ModifierSelectionDialogState extends State<ModifierSelectionDialog> {
  // Dùng List để lưu các lựa chọn hiện tại
  List<Modifier> _currentSelections = [];
  List<ModifierGroup> _modifierGroups = [];
  bool _isLoading = true;
  
  // Controller để quản lý focus cho bàn phím
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    // Copy danh sách cũ để chỉnh sửa
    _currentSelections = List.from(widget.initialSelections);
    _fetchModifiers();
  }
  
  @override
  void dispose() {
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchModifiers() async {
    final repo = ProductRepositoryImpl();
    try {
      final groups = await repo.getProductModifiers(widget.product.id);
      
      print("--- DEBUG MODIFIERS ---");
      print("Số nhóm nhận được: ${groups.length}");
      for (var g in groups) {
        print("Nhóm: ${g.name}");
        for (var m in g.modifiers) {
          // QUAN TRỌNG: Kiểm tra xem allowInput có là true không
          print(" - Món: ${m.name} | Giá: ${m.extraPrice} | allowInput: ${m.allowInput}");
        }
      }
      print("-----------------------");
      if (mounted) {
        setState(() {
          _modifierGroups = groups;
          _isLoading = false;
        });
      }

      if (!widget.isEditing && widget.initialSelections.isEmpty) {
        _applyDefaultSelections(groups);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Lỗi load modifier: $e");
    }
  }

  void _applyDefaultSelections(List<ModifierGroup> groups) {
    for (var group in groups) {
      if (group.isRequired && group.modifiers.isNotEmpty) {
        bool hasSelected = _currentSelections.any((m) => m.groupId == group.id);
        if (!hasSelected) {
           _currentSelections.add(group.modifiers[0]);
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _toggleModifier(ModifierGroup group, Modifier modifier) {
    setState(() {
      if (!group.isMultiSelect) {
        // Chọn 1: Xóa cái cũ cùng nhóm
        _currentSelections.removeWhere((item) => item.groupId == group.id);
        _currentSelections.add(modifier);
      } else {
        // Chọn nhiều
        final index = _currentSelections.indexWhere((item) => item.id == modifier.id);
        if (index != -1) {
          _currentSelections.removeAt(index);
        } else {
          _currentSelections.add(modifier);
        }
      }
    });
  }
  
  // Cập nhật Ghi chú (Note)
  void _updateModifierNote(Modifier modifier, String text) {
    setState(() {
      int index = _currentSelections.indexWhere((m) => m.id == modifier.id);
      if (index != -1) {
        _currentSelections[index] = _currentSelections[index].copyWith(userInput: text);
      }
    });
  }

  // Cập nhật Giá (Price Override)
  void _updateModifierPrice(Modifier modifier, String priceText) {
    double? newPrice = double.tryParse(priceText.replaceAll(RegExp(r'[^0-9]'), ''));
    if (newPrice != null) {
      setState(() {
        int index = _currentSelections.indexWhere((m) => m.id == modifier.id);
        if (index != -1) {
          // Tạo bản sao với giá mới (Logic copyWith cần hỗ trợ extraPrice, nếu chưa có thì phải sửa model)
          // Giả sử copyWith hỗ trợ hoặc ta tạo mới object
          var old = _currentSelections[index];
          _currentSelections[index] = Modifier(
            id: old.id,
            name: old.name,
            groupId: old.groupId,
            allowInput: old.allowInput,
            userInput: old.userInput,
            extraPrice: newPrice, // Cập nhật giá mới
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // Tính tổng tiền realtime
    double totalExtra = _currentSelections.fold(0, (sum, item) => sum + item.extraPrice);
    double finalPrice = widget.product.price + totalExtra;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // Tăng kích thước Dialog để chứa nhiều thông tin (như màn hình Tablet/POS)
      child: Container(
        width: 900, 
        height: 650,
        child: Column(
          children: [
            // --- 1. HEADER COMPACT ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: const BoxDecoration(
                color: Colors.brown,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("${currencyFormat.format(widget.product.price)}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))
                ],
              ),
            ),

            // --- 2. BODY KHÔNG CẦN SCROLL NHIỀU ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _modifierGroups.isEmpty
                      ? const Center(child: Text("Không có tùy chọn nào."))
                      : SingleChildScrollView( // Vẫn giữ scroll phòng hờ màn hình bé, nhưng thiết kế sẽ compact
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _modifierGroups.map((group) => _buildCompactGroup(group, currencyFormat)).toList(),
                          ),
                        ),
            ),

            // --- 3. FOOTER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(color: Colors.brown[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("Tổng cộng: ", style: TextStyle(fontSize: 16, color: Colors.black54)),
                      Text(currencyFormat.format(finalPrice), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown[900])),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text(widget.isEditing ? "CẬP NHẬT" : "XÁC NHẬN", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    onPressed: () {
                      // Validate Bắt buộc
                      for (var group in _modifierGroups) {
                        if (group.isRequired) {
                          bool hasSelected = _currentSelections.any((m) => m.groupId == group.id);
                          if (!hasSelected) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chưa chọn ${group.name}'), backgroundColor: Colors.red, duration: const Duration(seconds: 1)));
                             return;
                          }
                        }
                      }
                      widget.onConfirm(_currentSelections);
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCompactGroup(ModifierGroup group, NumberFormat currencyFormat) {
    // Tìm modifier loại "Nhập liệu" đang được chọn trong nhóm này (nếu có)
    Modifier? activeInputModifier;
    try {
      activeInputModifier = _currentSelections.firstWhere(
        (m) => m.groupId == group.id && m.allowInput
      );
      print("Found Active Input for Group ${group.name}: ${activeInputModifier.name}");
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề nhóm
          Row(
            children: [
              Text(group.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.brown[800])),
              const SizedBox(width: 8),
              if (group.isRequired) 
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)), child: const Text("Bắt buộc", style: TextStyle(fontSize: 10, color: Colors.red))),
              if (group.isMultiSelect)
                Container(margin: const EdgeInsets.only(left: 5), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)), child: const Text("Chọn nhiều", style: TextStyle(fontSize: 10, color: Colors.blue))),
            ],
          ),
          const SizedBox(height: 8),

          // Danh sách Options (Ngang - Wrap)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.modifiers.map((mod) {
              final isSelected = _currentSelections.any((m) => m.id == mod.id);
              return FilterChip(
                selected: isSelected,
                showCheckmark: false,
                label: Text(
                  "${mod.name} ${mod.extraPrice > 0 ? '+${NumberFormat('#,###').format(mod.extraPrice)}' : ''}",
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
                  ),
                ),
                backgroundColor: Colors.grey[100],
                selectedColor: mod.allowInput ? Colors.blue[600] : Colors.brown, // Màu khác cho loại nhập liệu
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Padding nhỏ gọn
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6), 
                  side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!)
                ),
                onSelected: (_) => _toggleModifier(group, mod),
              );
            }).toList(),
          ),

          // [LOGIC MỚI] Hiển thị ô nhập liệu NGAY TẠI ĐÂY nếu chọn loại "Khác/Ghi chú"
          if (activeInputModifier != null)
             _buildInputPanel(activeInputModifier)
        ],
      ),
    );
  }

  // Widget hiển thị thanh nhập liệu đặc biệt
  Widget _buildInputPanel(Modifier modifier) {
    if (!_focusNodes.containsKey(modifier.id)) {
      _focusNodes[modifier.id] = FocusNode();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!)
      ),
      child: Row(
        children: [
          // Ô nhập Ghi chú
          Expanded(
            flex: 3,
            child: TextField(
              focusNode: _focusNodes[modifier.id],
              controller: TextEditingController(text: modifier.userInput)
                ..selection = TextSelection.collapsed(offset: modifier.userInput?.length ?? 0), // Giữ con trỏ cuối
              decoration: const InputDecoration(
                labelText: "Ghi chú món / Tên tùy chỉnh",
                labelStyle: TextStyle(fontSize: 12, color: Colors.blue),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                prefixIcon: Icon(Icons.edit, size: 16, color: Colors.blue),
              ),
              onChanged: (val) => _updateModifierNote(modifier, val),
            ),
          ),
          const SizedBox(width: 10),
          
          // Ô nhập Giá (Cho phép sửa giá)
          Expanded(
            flex: 1,
            child: TextField(
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: modifier.extraPrice.toInt().toString()),
              decoration: const InputDecoration(
                labelText: "Giá tiền",
                labelStyle: TextStyle(fontSize: 12, color: Colors.blue),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                suffixText: "đ"
              ),
              onChanged: (val) => _updateModifierPrice(modifier, val),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Nút Bàn phím (Hỗ trợ màn hình cảm ứng POS)
          IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.keyboard, color: Colors.blue),
            tooltip: "Mở bàn phím ảo",
            onPressed: () {
              // Yêu cầu focus vào ô nhập để kích hoạt bàn phím hệ thống
              _focusNodes[modifier.id]?.requestFocus();
            },
          )
        ],
      ),
    );
  }
}