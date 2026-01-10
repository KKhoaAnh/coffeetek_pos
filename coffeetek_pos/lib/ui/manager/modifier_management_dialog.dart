import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/modifier/modifier_group.dart';
import '../../utils/modifier_service.dart';
import '../../domain/models/modifier/modifier.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ModifierManagementDialog extends StatefulWidget {
  const ModifierManagementDialog({Key? key}) : super(key: key);

  @override
  State<ModifierManagementDialog> createState() => _ModifierManagementDialogState();
}

class _ModifierManagementDialogState extends State<ModifierManagementDialog> {
  final ModifierService _service = ModifierService();
  List<ModifierGroup> _groups = [];
  bool _isLoading = true;
  String _selectedGroupId = 'ALL';

  final Color _primaryColor = Colors.brown;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await _service.getAllModifiers();
    setState(() {
      _groups = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lọc dữ liệu hiển thị
    List<Modifier> displayedModifiers = [];
    if (_selectedGroupId == 'ALL') {
      for (var g in _groups) {
        displayedModifiers.addAll(g.modifiers);
      }
    } else {
      if (_groups.isNotEmpty) {
        var group = _groups.firstWhere((g) => g.id == _selectedGroupId, orElse: () => _groups[0]);
        displayedModifiers = group.modifiers;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 10,
      child: Container(
        width: 900,
        height: 650,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // --- 1. HEADER HIỆN ĐẠI ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.tune, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 15),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("QUẢN LÝ TÙY CHỌN", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          Text("Thiết lập Topping, Size, Mức đường...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white), 
                    onPressed: () => Navigator.pop(context),
                    tooltip: "Đóng",
                  )
                ],
              ),
            ),

            // --- 2. BODY CHIA 2 CỘT ---
            Expanded(
              child: Row(
                children: [
                  // --- CỘT TRÁI: DANH SÁCH NHÓM ---
                  Container(
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(right: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 20, color: Colors.white),
                            label: const Text("TẠO NHÓM MỚI"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2
                            ),
                            onPressed: () => _showAddGroupDialog(),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            children: [
                              _buildSidebarItem('ALL', 'Tất cả tùy chọn', null, null, _selectedGroupId == 'ALL'),
                              ..._groups.map((g) => _buildSidebarItem(g.id, g.name, g.isMultiSelect, g.isRequired, _selectedGroupId == g.id))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // --- CỘT PHẢI: DANH SÁCH MODIFIER ---
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Toolbar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedGroupId == 'ALL' ? "Tất cả tùy chọn" : _groups.firstWhere((g) => g.id == _selectedGroupId).name,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.brown[900]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text("Tìm thấy ${displayedModifiers.length} mục", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.white,),
                                  label: const Text("Thêm Modifier"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600], 
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  onPressed: () => _showAddModifierDialog(),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 25, endIndent: 25),
                          
                          // List Content
                          Expanded(
                            child: _isLoading 
                              ? Center(child: CircularProgressIndicator(color: _primaryColor))
                              : displayedModifiers.isEmpty 
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.all(25),
                                    itemCount: displayedModifiers.length,
                                    itemBuilder: (ctx, i) {
                                      final mod = displayedModifiers[i];
                                      return _buildModifierCard(mod);
                                    },
                                  ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: ITEM SIDEBAR ĐẸP ---
  Widget _buildSidebarItem(String id, String name, bool? isMulti, bool? isRequired, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
        border: isSelected ? Border.all(color: _primaryColor.withOpacity(0.2)) : Border.all(color: Colors.transparent)
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => setState(() => _selectedGroupId = id),
        leading: Icon(
          id == 'ALL' ? Icons.apps : Icons.folder_open,
          color: isSelected ? _primaryColor : Colors.grey[400]
        ),
        title: Text(
          name, 
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? _primaryColor : Colors.grey[700],
            fontSize: 14
          )
        ),
        subtitle: id == 'ALL' ? null : Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 4,
            children: [
              if(isMulti == true) _buildMiniTag("Chọn nhiều", Colors.blue),
              if(isRequired == true) _buildMiniTag("Bắt buộc", Colors.red),
            ],
          ),
        ),
        trailing: isSelected ? Icon(Icons.arrow_forward_ios, size: 14, color: _primaryColor) : null,
      ),
    );
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }

  // --- WIDGET: CARD MODIFIER ITEM ---
  Widget _buildModifierCard(Modifier mod) {
    String groupName = "";
    try {
      groupName = _groups.firstWhere((g) => g.id == mod.groupId).name;
    } catch (_) {}

    return GestureDetector(
      onTap: () => _showEditModifierDialog(mod),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            // Icon Avatar
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                mod.name.isNotEmpty ? mod.name[0].toUpperCase() : "?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.orange[800]),
              ),
            ),
            const SizedBox(width: 15),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(mod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      // [MỚI] Icon chỉ báo đây là Input field
                      if (mod.allowInput) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_note, size: 12, color: Colors.blue),
                              SizedBox(width: 4),
                              Text("Nhập text", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.folder, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(groupName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),

            // Price Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: mod.extraPrice > 0 ? Colors.green[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mod.extraPrice > 0 ? Colors.green.withOpacity(0.2) : Colors.transparent)
              ),
              child: Text(
                mod.extraPrice > 0 ? "+${NumberFormat('#,###').format(mod.extraPrice)}đ" : "Miễn phí",
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: mod.extraPrice > 0 ? Colors.green[700] : Colors.grey[600],
                  fontSize: 13
                ),
              ),
            ),
            
            const SizedBox(width: 10),
            
            // Menu Action
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) async {
                if (value == 'edit') {
                  _showEditModifierDialog(mod);
                } else if (value == 'delete') {
                  bool confirm = await showDialog(
                    context: context, 
                    builder: (ctx) => AlertDialog(
                      title: const Text("Xác nhận xóa"),
                      content: Text("Bạn có chắc muốn xóa '${mod.name}' không?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true), 
                          child: const Text("Xóa", style: TextStyle(color: Colors.white))
                        ),
                      ],
                    )
                  ) ?? false;

                  if (confirm) {
                    await _service.deleteModifier(mod.id);
                    _loadData();
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 10), Text('Chỉnh sửa')]),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 10), Text('Xóa bỏ')]),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.checklist_rtl_rounded, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 15),
        Text("Chưa có dữ liệu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[400])),
        const SizedBox(height: 5),
        Text("Hãy chọn nhóm khác hoặc tạo mới", style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ],
    );
  }

  // --- DIALOG THÊM NHÓM ---
  void _showAddGroupDialog() {
    final nameCtrl = TextEditingController();
    bool isMulti = false;
    bool isRequired = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TẠO NHÓM MỚI", style: TextStyle(fontWeight: FontWeight.w900, color: _primaryColor, fontSize: 18)),
                const SizedBox(height: 25),
                
                _buildModernTextField(controller: nameCtrl, label: "Tên nhóm", hint: "VD: Size, Mức đường, Topping"),
                const SizedBox(height: 20),
                
                _buildSwitchTile("Chọn nhiều", "Khách có thể chọn nhiều món cùng lúc (VD: Topping)", isMulti, (v) => setStateDialog(() => isMulti = v)),
                const Divider(),
                _buildSwitchTile("Bắt buộc", "Khách phải chọn ít nhất 1 (VD: Size)", isRequired, (v) => setStateDialog(() => isRequired = v)),
                
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("Hủy"))),
                    const SizedBox(width: 15),
                    Expanded(child: ElevatedButton(
                      onPressed: () async {
                        if(nameCtrl.text.isEmpty) return;
                        Navigator.pop(ctx);
                        await _service.createGroup(nameCtrl.text, isMulti, isRequired);
                        _loadData();
                      }, 
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text("TẠO NHÓM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    )),
                  ],
                )
              ],
            ),
          ),
        ),
      )
    );
  }

  // --- DIALOG THÊM MODIFIER ---
  void _showAddModifierDialog() {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng tạo Nhóm trước!")));
      return;
    }

    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: "0");
    String selectedGroup = _selectedGroupId == 'ALL' ? _groups[0].id : _selectedGroupId;
    bool hasPrice = false;
    // [MỚI] Biến trạng thái cho phép nhập text
    bool allowInput = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(25),
            child: SingleChildScrollView( // Thêm scroll vì nội dung dài hơn
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("THÊM TÙY CHỌN MỚI", style: TextStyle(fontWeight: FontWeight.w900, color: _primaryColor, fontSize: 18)),
                  const SizedBox(height: 25),

                  Text("Thuộc nhóm", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGroup,
                        isExpanded: true,
                        items: _groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedGroup = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildModernTextField(controller: nameCtrl, label: "Tên tùy chọn", hint: "VD: 50% Đường, Size L"),
                  const SizedBox(height: 20),

                  // Switch Giá
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Có tính thêm tiền không?", style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: hasPrice,
                        activeColor: Colors.green,
                        onChanged: (val) => setStateDialog(() {
                          hasPrice = val;
                          if (!val) priceCtrl.text = "0";
                        }),
                      ),
                    ],
                  ),
                  
                  if (hasPrice) ...[
                    const SizedBox(height: 10),
                    _buildModernTextField(controller: priceCtrl, label: "Giá thêm (VNĐ)", hint: "0", isNumber: true),
                    const SizedBox(height: 15),
                  ],

                  // [MỚI] Switch cho phép nhập ghi chú
                  const Divider(),
                  _buildSwitchTile(
                    "Cho phép nhập ghi chú", 
                    "Thu ngân có thể nhập văn bản (VD: Mã Voucher, Ghi chú đặc biệt)", 
                    allowInput, 
                    (val) => setStateDialog(() => allowInput = val)
                  ),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("Hủy"))),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton(
                        onPressed: () async {
                          if(nameCtrl.text.isEmpty) return;
                          Navigator.pop(ctx);
                          // [GỌI API] Truyền allowInput
                          await _service.createModifier(
                            nameCtrl.text, 
                            selectedGroup, 
                            double.tryParse(priceCtrl.text) ?? 0,
                            allowInput
                          );
                          _loadData();
                        }, 
                        style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("THÊM NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      )),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  // --- DIALOG CẬP NHẬT MODIFIER ---
  void _showEditModifierDialog(Modifier mod) {
    final nameCtrl = TextEditingController(text: mod.name);
    final priceCtrl = TextEditingController(text: mod.extraPrice.toInt().toString());
    
    bool hasPrice = mod.extraPrice > 0;
    // [MỚI] Khởi tạo từ model
    bool allowInput = mod.allowInput;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(25),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.brown[50], shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.brown, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text("CẬP NHẬT TÙY CHỌN", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.brown, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  _buildModernTextField(controller: nameCtrl, label: "Tên tùy chọn", hint: "VD: 50% Đường"),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Có tính thêm tiền không?", style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: hasPrice,
                        activeColor: Colors.brown,
                        onChanged: (val) => setStateDialog(() {
                          hasPrice = val;
                          if (!val) priceCtrl.text = "0";
                        }),
                      ),
                    ],
                  ),
                  
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: hasPrice ? 1.0 : 0.5,
                    child: AbsorbPointer(
                      absorbing: !hasPrice,
                      child: Column(
                        children: [
                           const SizedBox(height: 10),
                           _buildModernTextField(controller: priceCtrl, label: "Giá thêm (VNĐ)", hint: "0", isNumber: true),
                           const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),

                  // [MỚI] Switch cho phép nhập ghi chú (Edit)
                  const Divider(),
                  _buildSwitchTile(
                    "Cho phép nhập ghi chú", 
                    "Thu ngân có thể nhập văn bản (VD: Mã Voucher, Ghi chú đặc biệt)", 
                    allowInput, 
                    (val) => setStateDialog(() => allowInput = val)
                  ),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text("Hủy"))),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton(
                        onPressed: () async {
                          if(nameCtrl.text.isEmpty) return;
                          
                          Navigator.pop(ctx);
                          
                          // [GỌI API] Truyền allowInput cập nhật
                          bool success = await _service.updateModifier(
                            mod.id, 
                            nameCtrl.text, 
                            double.tryParse(priceCtrl.text) ?? 0,
                            allowInput
                          );

                          if(success) {
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green)
                            );
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Lỗi cập nhật!"), backgroundColor: Colors.red)
                            );
                          }
                        }, 
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.brown[600], padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      )),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      )
    );
  }

  // Helper Widgets
  Widget _buildModernTextField({required TextEditingController controller, required String label, String? hint, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      activeColor: _primaryColor,
      onChanged: onChanged,
    );
  }
}