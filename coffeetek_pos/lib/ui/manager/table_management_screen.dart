import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/constants.dart';
import '../../domain/models/table_model.dart'; 

class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({Key? key}) : super(key: key);

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  List<TableModel> _tables = [];
  bool _isLoading = true;
  final String _baseUrl = '${AppConstants.baseUrl}/tables'; 

  // [MỚI] Bộ màu chuẩn theo yêu cầu của bạn
  final List<Color> _palette = [
    Colors.white, Colors.grey[200]!, Colors.grey, Colors.black,
    const Color(0xFFFFCDD2), const Color(0xFFE57373), const Color(0xFFF44336), const Color(0xFFB71C1C), // Red
    const Color(0xFFFFF9C4), const Color(0xFFFFF176), const Color(0xFFFFD54F), const Color(0xFFFFB300), // Yellow/Orange
    const Color(0xFFC8E6C9), const Color(0xFF81C784), const Color(0xFF4CAF50), const Color(0xFF1B5E20), // Green
    const Color(0xFFBBDEFB), const Color(0xFF64B5F6), const Color(0xFF2196F3), const Color(0xFF0D47A1), // Blue
    const Color(0xFFE1BEE7), const Color(0xFFBA68C8), const Color(0xFF9C27B0), const Color(0xFF4A148C), // Purple
    const Color(0xFFD7CCC8), const Color(0xFFA1887F), const Color(0xFF795548), const Color(0xFF3E2723), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _tables = data.map((e) => TableModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      print("Lỗi tải bàn: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(TableModel table, bool value) async {
    try {
      String shapeStr = table.shape.toString().split('.').last.toUpperCase();
      String colorStr = '#${table.color.value.toRadixString(16).substring(2).toUpperCase()}';

      final response = await http.put(
        Uri.parse('$_baseUrl/${table.id}/info'), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'table_name': table.name,
          'is_active': value,
          'shape': shapeStr,
          'color': colorStr
        })
      );
      
      if (response.statusCode == 200) {
        _loadTables(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("QUẢN LÝ BÀN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: true,
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.brown))
        : _tables.isEmpty 
            ? _buildEmptyState()
            : Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5, 
                    childAspectRatio: 1.0, 
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _tables.length,
                  itemBuilder: (ctx, i) => _buildTableCard(_tables[i]),
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditTableDialog(),
        backgroundColor: Colors.brown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("THÊM BÀN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTableCard(TableModel table) {
    bool isInactive = !table.isActive;
    
    // [VISUAL] Điều chỉnh kích thước hiển thị dựa trên hình dáng
    double width = 45;
    double height = 45;
    if (table.shape == TableShape.rectangle) {
      width = 70; // Dài hơn
      height = 40;
    }

    return Container(
      decoration: BoxDecoration(
        color: isInactive ? Colors.grey[200] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isInactive ? [] : [
          BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
        ],
        border: isInactive ? Border.all(color: Colors.grey[300]!) : Border.all(color: Colors.transparent),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAddEditTableDialog(table: table),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header: Status + Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isInactive ? Colors.grey[400] : (table.isOccupied ? Colors.red[100] : Colors.green[100]),
                        shape: BoxShape.circle
                      ),
                      child: Icon(
                        isInactive ? Icons.visibility_off : Icons.table_restaurant,
                        size: 14,
                        color: isInactive ? Colors.white : (table.isOccupied ? Colors.red : Colors.green),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.6,
                      child: Switch(
                        value: table.isActive,
                        activeColor: Colors.green,
                        onChanged: (val) => _toggleActive(table, val),
                      ),
                    )
                  ],
                ),

                // Table Shape Visualization & Name
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // [VISUAL] Vẽ hình dáng bàn
                      Container(
                        width: width, 
                        height: height,
                        decoration: BoxDecoration(
                          color: table.color.withOpacity(isInactive ? 0.3 : 1),
                          // Nếu là tròn thì bo tròn, còn lại (vuông/chữ nhật) thì bo góc nhẹ
                          shape: table.shape == TableShape.circle ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: table.shape == TableShape.circle ? null : BorderRadius.circular(6),
                          border: Border.all(color: Colors.brown.withOpacity(0.2), width: 1.5)
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          table.id.toString(), 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            // Nếu màu nền tối quá thì chữ trắng, sáng thì chữ nâu (logic đơn giản)
                            color: table.color.computeLuminance() > 0.5 ? Colors.brown[800] : Colors.white, 
                            fontSize: 14
                          )
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        table.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 14,
                          color: isInactive ? Colors.grey : Colors.brown[900]
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Footer Status Text
                Text(
                  isInactive ? "Ngưng HĐ" : (table.isOccupied ? "Có khách" : "Trống"),
                  style: TextStyle(fontSize: 10, color: isInactive ? Colors.grey : Colors.grey[600]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text("Chưa có bàn nào", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  // --- DIALOG THÊM / SỬA BÀN ---
  void _showAddEditTableDialog({TableModel? table}) {
    final isEditing = table != null;
    final nameCtrl = TextEditingController(text: table?.name ?? "");
    
    TableShape selectedShape = table?.shape ?? TableShape.square;
    
    // Tìm màu trong palette khớp với màu bàn (hoặc mặc định trắng)
    Color selectedColor = table?.color ?? Colors.white;
        
    bool isActive = table?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450, // Rộng hơn xíu để chứa palette màu
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? "CẬP NHẬT BÀN" : "THÊM BÀN MỚI", 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)
                  ),
                  const SizedBox(height: 20),

                  // Tên bàn
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Tên bàn (VD: Bàn 10, VIP 1)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.grey[50]
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hình dáng
                  Text("Hình dáng", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildShapeOption("Vuông", TableShape.square, selectedShape, (val) => setStateDialog(() => selectedShape = val))),
                      const SizedBox(width: 10),
                      Expanded(child: _buildShapeOption("Tròn", TableShape.circle, selectedShape, (val) => setStateDialog(() => selectedShape = val))),
                      const SizedBox(width: 10),
                      // [MỚI] Thêm tùy chọn Chữ nhật
                      Expanded(child: _buildShapeOption("Chữ nhật", TableShape.rectangle, selectedShape, (val) => setStateDialog(() => selectedShape = val))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Màu sắc
                  Text("Màu sắc nhận diện", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  const SizedBox(height: 10),
                  Container(
                    height: 150, // Giới hạn chiều cao cho vùng chọn màu
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!)
                    ),
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7, 
                        crossAxisSpacing: 8, 
                        mainAxisSpacing: 8
                      ),
                      itemCount: _palette.length,
                      itemBuilder: (ctx, i) {
                        final color = _palette[i];
                        final isSelected = selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setStateDialog(() => selectedColor = color),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.brown : Colors.grey[300]!, 
                                width: isSelected ? 3 : 1
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : []
                            ),
                            child: isSelected 
                              ? Icon(Icons.check, size: 16, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white) 
                              : null,
                          ),
                        );
                      }
                    ),
                  ),

                  // Switch Active (nếu đang sửa)
                  if (isEditing) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    SwitchListTile(
                      title: const Text("Đang hoạt động"),
                      subtitle: const Text("Tắt nếu bàn này đang cất kho hoặc hỏng"),
                      value: isActive,
                      activeColor: Colors.green,
                      onChanged: (val) => setStateDialog(() => isActive = val),
                    )
                  ],

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx), 
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("Hủy")
                      )),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty) return;
                          Navigator.pop(ctx);
                          
                          // Convert Enum to String for API
                          String shapeStr = selectedShape.toString().split('.').last.toUpperCase();
                          // Convert Color to Hex String
                          String colorHex = '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';

                          final body = {
                            'table_name': nameCtrl.text,
                            'shape': shapeStr,
                            'color': colorHex,
                            'is_active': isActive
                          };

                          try {
                            if (isEditing) {
                               await http.put(Uri.parse('$_baseUrl/${table!.id}/info'), 
                                  headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
                            } else {
                               await http.post(Uri.parse(_baseUrl), 
                                  headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
                            }
                            _loadTables(); 
                          } catch (e) {
                            print(e);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown, 
                          padding: const EdgeInsets.symmetric(vertical: 16)
                        ),
                        child: const Text("LƯU LẠI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
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

  Widget _buildShapeOption(String label, TableShape value, TableShape groupValue, Function(TableShape) onTap) {
    bool isSelected = value == groupValue;
    
    IconData icon;
    if (value == TableShape.circle) icon = Icons.circle_outlined;
    else if (value == TableShape.rectangle) icon = Icons.rectangle_outlined;
    else icon = Icons.crop_square;

    return InkWell(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.brown[50] : Colors.white,
          border: Border.all(color: isSelected ? Colors.brown : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.brown : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.brown : Colors.black87
            )),
          ],
        ),
      ),
    );
  }
}