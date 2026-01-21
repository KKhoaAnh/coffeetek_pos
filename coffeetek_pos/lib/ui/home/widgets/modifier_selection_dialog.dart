import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../domain/models/product.dart';
import '../../../domain/models/modifier/modifier.dart';
import '../../../domain/models/modifier/modifier_group.dart';
import '../../../data/repositories/product_repository_impl.dart';

// ==========================================
// CLASS CHÍNH: MODIFIER DIALOG
// ==========================================
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
  List<Modifier> _currentSelections = [];
  List<ModifierGroup> _modifierGroups = [];
  bool _isLoading = true;

  // --- STATE QUẢN LÝ BÀN PHÍM & INPUT ---
  bool _isVirtualKeyboardOpen = false;
  
  // Cache Controller & FocusNode để giữ trạng thái nhập liệu ổn định
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  // Map lưu GlobalKey để phục vụ việc Scroll tự động
  final Map<String, GlobalKey> _inputKeys = {};
  
  // ID của ô đang được bàn phím ảo điều khiển
  String? _activeFieldId; 

  final Color _primaryColor = Colors.brown;
  final Color _accentColor = Colors.brown[700]!;

  @override
  void initState() {
    super.initState();
    _currentSelections = List.from(widget.initialSelections);
    _fetchModifiers();
  }

  @override
  void dispose() {
    for (var c in _controllers.values) c.dispose();
    for (var f in _focusNodes.values) f.dispose();
    super.dispose();
  }

  Future<void> _fetchModifiers() async {
    final repo = ProductRepositoryImpl();
    try {
      final groups = await repo.getProductModifiers(widget.product.id);
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
        _currentSelections.removeWhere((item) => item.groupId == group.id);
        _currentSelections.add(modifier);
      } else {
        final index = _currentSelections.indexWhere((item) => item.id == modifier.id);
        if (index != -1) {
          _currentSelections.removeAt(index);
        } else {
          _currentSelections.add(modifier);
        }
      }
      
      // [LOGIC MỚI] Không đóng bàn phím khi chọn món, chỉ đóng khi người dùng muốn.
      // Tuy nhiên nếu modifier đang nhập bị bỏ chọn -> cần clear focus
      if (!_currentSelections.any((m) => m.id == modifier.id) && _activeFieldId?.startsWith(modifier.id) == true) {
         _isVirtualKeyboardOpen = false;
         _activeFieldId = null;
         FocusScope.of(context).unfocus();
      }
    });
  }

  TextEditingController _getController(String key, String initialText) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialText);
    }
    if (_controllers[key]!.text != initialText && !_focusNodes[key]!.hasFocus) {
       _controllers[key]!.text = initialText;
    }
    return _controllers[key]!;
  }

  FocusNode _getFocusNode(String key) {
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
      _focusNodes[key]!.addListener(() {
        // [LOGIC HYBRID]
        // Nếu focus vào ô này (do tap tay), mà không phải do bật bàn phím ảo
        // Thì tắt bàn phím ảo đi để dùng bàn phím OS
        if (_focusNodes[key]!.hasFocus && _activeFieldId != key) {
           setState(() {
             _isVirtualKeyboardOpen = false;
             _activeFieldId = null; 
           });
        }
      });
    }
    return _focusNodes[key]!;
  }

  // Hàm cuộn xuống ô nhập liệu
  void _scrollToInput(String modifierId) {
    final key = _inputKeys[modifierId];
    if (key == null || key.currentContext == null) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
      }
    });
  }

  // --- LOGIC KÍCH HOẠT BÀN PHÍM ẢO ---
  void _activateVirtualKeyboard(String fieldId, String modifierId) {
    // 1. Nếu đang ở ô khác thì chuyển qua
    // 2. Nếu chưa mở thì mở lên
    setState(() {
      _activeFieldId = fieldId;
      _isVirtualKeyboardOpen = true;
    });

    // 3. Focus vào ô để hiện con trỏ (nhưng readOnly=true chặn OS keyboard)
    Future.delayed(Duration.zero, () {
      _focusNodes[fieldId]?.requestFocus();
    });
    
    // 4. Scroll tới ô đó
    _scrollToInput(modifierId);
  }

  void _onVirtualKeyInput(String key) {
    if (_activeFieldId == null) return;
    final controller = _controllers[_activeFieldId];
    if (controller == null) return;

    final text = controller.text;
    final selection = controller.selection;
    
    final int start = selection.baseOffset == -1 ? text.length : selection.baseOffset;
    final int end = selection.extentOffset == -1 ? text.length : selection.extentOffset;
    
    final int selStart = math.min(start, end);
    final int selEnd = math.max(start, end);

    String newText = text;
    int newCursorPos = selStart;

    if (key == 'BACKSPACE') {
      if (selStart != selEnd) {
        newText = text.substring(0, selStart) + text.substring(selEnd);
        newCursorPos = selStart;
      } else if (selStart > 0) {
        newText = text.substring(0, selStart - 1) + text.substring(selEnd);
        newCursorPos = selStart - 1;
      }
    } else if (key == 'SPACE') {
       newText = text.substring(0, selStart) + " " + text.substring(selEnd);
       newCursorPos = selStart + 1;
    } else {
       newText = text.substring(0, selStart) + key + text.substring(selEnd);
       newCursorPos = selStart + 1;
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    // Update Model
    final parts = _activeFieldId!.split('_');
    if (parts.length >= 2) {
      _updateModelFromInput(parts[0], parts[1], newText);
    }
  }

  void _updateModelFromInput(String modifierId, String type, String value) {
    int index = _currentSelections.indexWhere((m) => m.id == modifierId);
    if (index != -1) {
      if (type == 'note') {
        _currentSelections[index] = _currentSelections[index].copyWith(userInput: value);
      } else if (type == 'price') {
        double? price = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
        if (price != null) {
          _currentSelections[index] = _currentSelections[index].copyWith(extraPrice: price);
          setState(() {}); 
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    double totalExtra = _currentSelections.fold(0, (sum, item) => sum + item.extraPrice);
    double finalPrice = widget.product.price + totalExtra;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // [QUAN TRỌNG] Bỏ GestureDetector đóng bàn phím ở đây theo yêu cầu của bạn
      child: Container(
        width: 900,
        height: 700,
        color: Colors.transparent, 
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(color: _primaryColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.product.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("${currencyFormat.format(widget.product.price)}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ]),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white))
                ],
              ),
            ),

            // BODY
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _modifierGroups.isEmpty
                    ? const Center(child: Text("Không có tùy chọn nào."))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _modifierGroups.map((g) => _buildCompactGroup(g)).toList(),
                        ),
                      ),
            ),

            // BÀN PHÍM ẢO (Slide Up)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: _isVirtualKeyboardOpen ? 280 : 0,
              // Gọi Widget bàn phím riêng
              child: _isVirtualKeyboardOpen 
                  ? CoffeetekVirtualKeyboard(
                      onKeyPress: _onVirtualKeyInput,
                      onClose: () {
                        setState(() {
                          _isVirtualKeyboardOpen = false;
                          _activeFieldId = null;
                        });
                        FocusScope.of(context).unfocus();
                      },
                    ) 
                  : const SizedBox.shrink(),
            ),

            // FOOTER (Chỉ hiện khi bàn phím đóng)
            if (!_isVirtualKeyboardOpen)
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
                    label: Text(widget.isEditing ? "CẬP NHẬT" : "THÊM VÀO ĐƠN", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    onPressed: () {
                      for (var group in _modifierGroups) {
                        if (group.isRequired) {
                          if (!_currentSelections.any((m) => m.groupId == group.id)) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chưa chọn ${group.name}'), backgroundColor: Colors.red));
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

  Widget _buildCompactGroup(ModifierGroup group) {
    Modifier? activeInputModifier;
    try {
      activeInputModifier = _currentSelections.firstWhere(
        (selected) => selected.allowInput && group.modifiers.any((groupMod) => groupMod.id == selected.id)
      );
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.brown.withOpacity(0.1))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(group.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown[900])),
              const SizedBox(width: 10),
              if (group.isRequired) _buildTag("Bắt buộc", Colors.red),
              if (group.isMultiSelect) _buildTag("Chọn nhiều", Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: group.modifiers.map((mod) {
              final isSelected = _currentSelections.any((m) => m.id == mod.id);
              return FilterChip(
                selected: isSelected,
                showCheckmark: false,
                label: Text(
                  "${mod.name} ${mod.extraPrice > 0 ? '+${NumberFormat('#,###').format(mod.extraPrice)}' : ''}",
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.brown[800],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal
                  ),
                ),
                backgroundColor: Colors.brown[50],
                selectedColor: mod.allowInput ? Colors.blue[600] : _primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? Colors.transparent : Colors.brown[100]!)),
                onSelected: (_) => _toggleModifier(group, mod),
              );
            }).toList(),
          ),
          if (activeInputModifier != null) _buildInputPanel(activeInputModifier)
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInputPanel(Modifier modifier) {
    final noteKey = "${modifier.id}_note";
    final priceKey = "${modifier.id}_price";

    if (!_inputKeys.containsKey(modifier.id)) {
      _inputKeys[modifier.id] = GlobalKey();
    }

    return Container(
      key: _inputKeys[modifier.id],
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.blue[50]!.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue[200]!)),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHybridTextField(
            id: noteKey,
            initialValue: modifier.userInput ?? '',
            label: "Ghi chú món",
            icon: Icons.edit_note,
            onTap: () {
               // Nếu click vào text field khi bàn phím đang mở:
               // 1. Nếu đang ở ô khác -> chuyển focus sang ô này nhưng vẫn GIỮ bàn phím ảo
               // 2. Nếu đang ở chính ô này -> Giữ nguyên để người dùng di chuyển con trỏ
               if (_isVirtualKeyboardOpen) {
                 if (_activeFieldId != noteKey) {
                   _activateVirtualKeyboard(noteKey, modifier.id);
                 }
               }
            },
            onChanged: (val) => _updateModelFromInput(modifier.id, 'note', val)
          )),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _buildHybridTextField(
            id: priceKey,
            initialValue: modifier.extraPrice.toInt().toString(),
            label: "Giá tiền",
            icon: Icons.attach_money,
            isNumber: true,
            suffix: "đ",
            onTap: () {
               if (_isVirtualKeyboardOpen) {
                 if (_activeFieldId != priceKey) {
                   _activateVirtualKeyboard(priceKey, modifier.id);
                 }
               }
            },
            onChanged: (val) => _updateModelFromInput(modifier.id, 'price', val)
          )),
        ],
      ),
    );
  }

  Widget _buildHybridTextField({
    required String id,
    required String initialValue,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    VoidCallback? onTap,
    bool isNumber = false,
    String? suffix,
  }) {
    final controller = _getController(id, initialValue);
    final focusNode = _getFocusNode(id);
    final bool isControlledByVirtual = (_activeFieldId == id);

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          // Nếu đang được điều khiển bởi Virtual KB -> ReadOnly=true để chặn OS KB
          // Nhưng vẫn cho phép thao tác con trỏ (selection)
          readOnly: isControlledByVirtual, 
          showCursor: true, 
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: onChanged,
          onTap: onTap, // Gọi callback xử lý logic giữ/đóng bàn phím
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 13, color: Colors.blue[800]),
            isDense: true,
            contentPadding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, size: 18, color: Colors.blue),
            suffixText: suffix,
          ),
        ),
        Positioned(
          right: 4,
          child: IconButton(
            icon: Icon(Icons.keyboard_alt_outlined, color: isControlledByVirtual ? Colors.blue[800] : Colors.blue),
            tooltip: "Bàn phím POS ảo",
            style: IconButton.styleFrom(backgroundColor: isControlledByVirtual ? Colors.blue[100] : Colors.blue[50]),
            onPressed: () {
               // Logic: Nếu đang ở ô này rồi mà bấm icon -> Không làm gì hoặc đóng?
               // Thường bấm icon nghĩa là muốn MỞ.
               _activateVirtualKeyboard(id, id.split('_')[0]);
            },
          ),
        )
      ],
    );
  }
}

// ==========================================
// WIDGET TÁCH RIÊNG: BÀN PHÍM ẢO COFFEETEK
// ==========================================
class CoffeetekVirtualKeyboard extends StatefulWidget {
  final Function(String) onKeyPress;
  final VoidCallback onClose;

  const CoffeetekVirtualKeyboard({
    Key? key,
    required this.onKeyPress,
    required this.onClose,
  }) : super(key: key);

  @override
  State<CoffeetekVirtualKeyboard> createState() => _CoffeetekVirtualKeyboardState();
}

class _CoffeetekVirtualKeyboardState extends State<CoffeetekVirtualKeyboard> {
  bool _isShiftEnabled = false; // Trạng thái viết hoa

  @override
  Widget build(BuildContext context) {
    // Layout phím (Chữ thường)
    final rowsLower = [
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['SHIFT', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'BACKSPACE'],
      ['SPACE']
    ];
    
    // Layout phím (Chữ hoa)
    final rowsUpper = [
      ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['SHIFT', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'BACKSPACE'],
      ['SPACE']
    ];

    final currentRows = _isShiftEnabled ? rowsUpper : rowsLower;

    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Header Bàn phím
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.grey[300],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: widget.onClose, // Chỉ đóng khi bấm vào đây
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: const Row(
                      children: [
                        Icon(Icons.keyboard_hide, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Các hàng phím
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                children: currentRows.map((row) {
                  return Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: row.map((key) {
                        int flex = 1;
                        if (key == 'SPACE') flex = 6;
                        if (key == 'BACKSPACE' || key == 'SHIFT') flex = 2;
                        
                        // Màu sắc đặc biệt cho phím chức năng
                        Color btnColor = Colors.white;
                        Color txtColor = Colors.brown;
                        if (key == 'BACKSPACE') { btnColor = Colors.red[50]!; txtColor = Colors.red; }
                        if (key == 'SHIFT') { 
                          btnColor = _isShiftEnabled ? Colors.blue[100]! : Colors.grey[200]!; 
                          txtColor = _isShiftEnabled ? Colors.blue[900]! : Colors.black87; 
                        }

                        return Expanded(
                          flex: flex,
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Material(
                              color: btnColor,
                              borderRadius: BorderRadius.circular(5),
                              elevation: 1,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(5),
                                onTap: () {
                                  if (key == 'SHIFT') {
                                    setState(() => _isShiftEnabled = !_isShiftEnabled);
                                  } else {
                                    widget.onKeyPress(key);
                                  }
                                },
                                child: Center(child: _buildKeyLabel(key, txtColor)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyLabel(String key, Color color) {
    if (key == 'BACKSPACE') return Icon(Icons.backspace_outlined, size: 20, color: color);
    if (key == 'SPACE') return Text("DẤU CÁCH", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color));
    if (key == 'SHIFT') return Icon(Icons.arrow_upward, size: 20, color: Colors.brown);
    return Text(key, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color));
  }
}