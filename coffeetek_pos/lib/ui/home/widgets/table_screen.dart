import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/table_model.dart';
import '../widgets/pos_screen.dart';
import '../../../ui/home/view_model/cart_view_model.dart';
import '../../../utils/table_service.dart';

class AnimatedTableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const AnimatedTableItem({Key? key, required this.child, required this.onTap}) : super(key: key);
  @override
  State<AnimatedTableItem> createState() => _AnimatedTableItemState();
}
class _AnimatedTableItemState extends State<AnimatedTableItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.0, upperBound: 0.1);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _controller.forward(); await _controller.reverse();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(scale: 1.0 - _controller.value, child: widget.child),
      ),
    );
  }
}

class TableScreen extends StatefulWidget {
  const TableScreen({Key? key}) : super(key: key);
  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final TableService _tableService = TableService();
  List<TableModel> _tables = [];
  bool _isLoading = true;
  bool _isEditMode = false;

  final List<Color> _palette = [
    Colors.white, Colors.grey[200]!, Colors.grey, Colors.black,
    Color(0xFFFFCDD2), Color(0xFFE57373), Color(0xFFF44336), Color(0xFFB71C1C), // Red
    Color(0xFFFFF9C4), Color(0xFFFFF176), Color(0xFFFFD54F), Color(0xFFFFB300), // Yellow/Orange
    Color(0xFFC8E6C9), Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF1B5E20), // Green
    Color(0xFFBBDEFB), Color(0xFF64B5F6), Color(0xFF2196F3), Color(0xFF0D47A1), // Blue
    Color(0xFFE1BEE7), Color(0xFFBA68C8), Color(0xFF9C27B0), Color(0xFF4A148C), // Purple
    Color(0xFFD7CCC8), Color(0xFFA1887F), Color(0xFF795548), Color(0xFF3E2723), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() => _isLoading = true);
    try {
      final tables = await _tableService.getTables();
      int cols = 5;
      for (int i = 0; i < tables.length; i++) {
        if (tables[i].x == 0 && tables[i].y == 0) {
           int row = i ~/ cols;
           int col = i % cols;
           tables[i].x = (col * 0.18) + 0.02;
           tables[i].y = (row * 0.18) + 0.05;
        }
      }
      setState(() {
        _tables = tables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTablePositions() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    bool success = await _tableService.updatePositions(_tables);
    if (!mounted) return;
    Navigator.pop(context);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu sơ đồ bàn!")));
      setState(() => _isEditMode = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi lưu sơ đồ!")));
    }
  }

  void _showColorPicker(TableModel table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Đổi màu bàn: ${table.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  const Text("Hình dáng: ", style: TextStyle(fontWeight: FontWeight.w500)),
                  IconButton(icon: const Icon(Icons.crop_square), onPressed: () => setState(() => table.shape = TableShape.square)),
                  IconButton(icon: const Icon(Icons.circle_outlined), onPressed: () => setState(() => table.shape = TableShape.circle)),
                  IconButton(icon: const Icon(Icons.crop_16_9), onPressed: () => setState(() => table.shape = TableShape.rectangle)),
                ],
              ),
              const Divider(),
              
              const Text("Chọn màu:", style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6, crossAxisSpacing: 10, mainAxisSpacing: 10
                  ),
                  itemCount: _palette.length,
                  itemBuilder: (ctx, i) {
                    final color = _palette[i];
                    return InkWell(
                      onTap: () {
                        setState(() => table.color = color);
                        Navigator.pop(context); // Đóng ngay hoặc giữ lại để chọn tiếp
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: table.color == color 
                              ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, spreadRadius: 1)] 
                              : [],
                        ),
                        child: table.color == color ? const Icon(Icons.check, color: Colors.grey) : null,
                      ),
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  icon: const Icon(Icons.format_paint, color: Colors.white),
                  label: const Text("Áp dụng màu này cho tất cả bàn", style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() {
                      for (var t in _tables) {
                        t.color = table.color;
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã đổi màu toàn bộ bàn!")));
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      appBar: AppBar(
        title: Text(_isEditMode ? 'CHỈNH SỬA SƠ ĐỒ' : 'SƠ ĐỒ BÀN', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _isEditMode ? Colors.orange[800] : Colors.brown[600],
        centerTitle: true,
        actions: [
          if (_isEditMode) IconButton(icon: const Icon(Icons.save, color: Colors.white), onPressed: _saveTablePositions)
          else IconButton(icon: const Icon(Icons.edit_location_alt, color: Colors.white), onPressed: () => setState(() => _isEditMode = true)),
          if (!_isEditMode) IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadTables),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : LayoutBuilder(
              builder: (context, constraints) {
                final double screenW = constraints.maxWidth;
                final double screenH = constraints.maxHeight;

                return Stack(
                  children: [
                    // [BACKGROUND]
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("./table_layout_backup.jpeg"), 
                            fit: BoxFit.cover,
                            opacity: 0.0,
                          ),
                        ),
                      ),
                    ),

                    ..._tables.map((table) {
                      return Positioned(
                        left: table.x * screenW,
                        top: table.y * screenH,
                        child: _buildDraggableTable(table, screenW, screenH),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDraggableTable(TableModel table, double screenW, double screenH) {
    double sizeBase = screenW > 600 ? 100 : 80; 
    double w = table.shape == TableShape.rectangle ? sizeBase * 1.5 : sizeBase;
    double h = sizeBase;

    Widget tableWidget = _buildTableShape(table, w, h);

    if (_isEditMode) {
      return GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            table.x += details.delta.dx / screenW;
            table.y += details.delta.dy / screenH;
            table.x = table.x.clamp(0.0, 1.0 - (w / screenW));
            table.y = table.y.clamp(0.0, 1.0 - (h / screenH));
          });
        },
        onTap: () => _showColorPicker(table),
        child: Stack(
          alignment: Alignment.center,
          children: [
            tableWidget,
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.3)),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            )
          ],
        ),
      );
    } else {
      return AnimatedTableItem(
        onTap: () => _handleTableClick(table),
        child: tableWidget,
      );
    }
  }

  Widget _buildTableShape(TableModel table, double width, double height) {
    // 1. MÀU NỀN
    Color bgColor = table.color; 
    
    // 2. XỬ LÝ TƯƠNG PHẢN
    bool isDarkBg = bgColor.computeLuminance() < 0.5;
    Color baseContentColor = isDarkBg ? Colors.white : Colors.brown[900]!;

    // 3. MÀU TRẠNG THÁI
    Color borderColor = Colors.grey.shade300;
    double borderWidth = 2.0;
    List<BoxShadow> shadows = [
      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(2, 2))
    ];
    
    Widget? statusBadge;

    // LOGIC TRẠNG THÁI 
    if (table.isOccupied) {
      borderColor = Colors.red.shade700; 
      borderWidth = 4.0;
      shadows = [
        BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)
      ];
      
      statusBadge = Positioned(
        top: 4, right: 4,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          child: const Icon(Icons.person, size: 12, color: Colors.white),
        ),
      );

    } else if (table.isCleaning) {
      borderColor = Colors.orange;
      borderWidth = 3.0;
      shadows = [
        BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)
      ];
      
      statusBadge = Positioned(
        top: 4, right: 4,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          child: const Icon(Icons.cleaning_services, size: 12, color: Colors.white),
        ),
      );
    }

    // 4. HÌNH DÁNG
    BoxShape shape = BoxShape.rectangle;
    BorderRadius? borderRadius;
    if (table.shape == TableShape.circle) {
      shape = BoxShape.circle;
    } else {
      borderRadius = BorderRadius.circular(12);
    }

    return Stack(
      children: [
        Container(
          width: width, height: height,
          decoration: BoxDecoration(
            color: bgColor,
            shape: shape,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadows,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                table.shape == TableShape.circle ? Icons.local_cafe : Icons.table_restaurant, 
                color: baseContentColor.withOpacity(0.8),
                size: 24,
              ),
              const SizedBox(height: 4),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  table.name, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: baseContentColor, 
                    fontSize: 14
                  ), 
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              if (table.isOccupied) 
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: const Text(
                    "Có khách", 
                    style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)
                  ),
                ),
                
               if (table.isCleaning)
                 Text(
                   "Dọn dẹp", 
                   style: TextStyle(fontSize: 10, color: baseContentColor.withOpacity(0.9), fontStyle: FontStyle.italic)
                 ),
            ],
          ),
        ),

        if (statusBadge != null) statusBadge,
      ],
    );
  }

  void _handleTableClick(TableModel table) async {
    final cartVM = Provider.of<CartViewModel>(context, listen: false);

    // --- CASE 1: BÀN ĐANG DỌN (Logic cũ) ---
    if (table.isCleaning) { 
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Xác nhận dọn bàn"),
          content: Text("${table.name} đã được dọn sạch sẽ?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Chưa")),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xong")),
          ],
        ),
      );

      if (confirm != true) return;
      
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      await cartVM.clearTable(table.id);
      
      if (!mounted) return;
      Navigator.pop(context);

      cartVM.clearCart(keepTable: false); 

      cartVM.setTable(table);

      _loadTables();
    } 
    
    // --- CASE 2: BÀN CÓ KHÁCH (Occupied) ---
    else if (table.isOccupied && table.currentOrderId != null) {
       
       // Hiển thị loading khi tải đơn
       showDialog(
         context: context, 
         barrierDismissible: false,
         builder: (_) => const Center(child: CircularProgressIndicator())
       );
       
       // Load lại đơn hàng cũ vào Cart
       bool success = await cartVM.restoreOrderToCart(table.currentOrderId.toString());
       
       if (!mounted) return;
       Navigator.pop(context); // Tắt loading

       if (!success) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi tải đơn cũ!")));
         return;
       }

       // [LOGIC MỚI]: KIỂM TRA ĐƠN ĐÃ THANH TOÁN CHƯA?
       // Nếu Status là COMPLETED (đã thanh toán) -> Hỏi dọn bàn
       if (cartVM.currentOrderStatus == 'COMPLETED') {
          bool? action = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text("Bàn ${table.name}"),
              content: const Text("Đơn hàng này đã thanh toán xong.\nKhách đã về và bạn muốn dọn bàn?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false), // Chọn cái này để vào xem lại bill
                  child: const Text("Xem lại đơn", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.cleaning_services, color: Colors.white),
                  label: const Text("Dọn bàn ngay", style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(ctx, true), // Chọn cái này để dọn
                ),
              ],
            ),
          );

          // Nếu chọn Dọn bàn ngay
          if (action == true) {
             showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
             await cartVM.clearTable(table.id);
             if (!mounted) return;
             Navigator.pop(context); // Tắt loading
             
             cartVM.clearCart();
             _loadTables(); // Reload sơ đồ
             return; // Dừng lại, KHÔNG vào POS nữa
          }
       }
       // Nếu chưa thanh toán (PENDING) hoặc chọn "Xem lại đơn" -> Code sẽ chạy tiếp xuống dưới để mở POS
    } 
    
    // --- CASE 3: BÀN TRỐNG ---
    else {
       cartVM.clearCart();
       cartVM.setTable(table);
    }

    // --- CHUYỂN VÀO POS ---
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PosScreen(isBackButtonEnabled: true),
      ),
    ).then((_) {
      // Khi quay lại từ POS -> Reload sơ đồ để cập nhật trạng thái mới
      _loadTables();
    });
  }
}