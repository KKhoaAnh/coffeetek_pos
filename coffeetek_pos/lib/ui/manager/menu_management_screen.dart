import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/product.dart';
import '../../domain/models/category.dart';
import '../../utils/menu_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';
import 'dart:typed_data';
import '../manager/modifier_management_dialog.dart';
import '../../domain/models/modifier/modifier_group.dart';
import '../../utils/modifier_service.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({Key? key}) : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final MenuService _menuService = MenuService();
  int _imageVersionKey = 0;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  final ModifierService _modifierService = ModifierService(); // [MỚI]
  List<ModifierGroup> _allModifierGroups = [];
  
  String _selectedCategoryId = 'ALL';
  bool _isLoading = true;
  final Color _primaryColor = Colors.brown;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final products = await _menuService.getAllProducts();
    final categories = await _menuService.getAllCategories();
    final modGroups = await _modifierService.getAllModifiers();
    
    // Thêm mục "Tất cả" vào đầu danh sách Categories
    if (categories.isNotEmpty && categories[0].id != 'ALL') {
      categories.insert(0, Category(id: 'ALL', name: 'Tất cả'));
    }

    setState(() {
      _allProducts = products;
      _categories = categories;
      _imageVersionKey = DateTime.now().millisecondsSinceEpoch;
      _filterProducts();
      _isLoading = false;
      _allModifierGroups = modGroups;
    });
  }

  void _filterProducts() {
    if (_selectedCategoryId == 'ALL') {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("QUẢN LÝ THỰC ĐƠN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: _primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: _primaryColor)) 
          : Column(
              children: [
                // 1. THANH LỌC DANH MỤC
                Container(
                  height: 60,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final isSelected = cat.id == _selectedCategoryId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(cat.name, style: TextStyle(color: isSelected ? Colors.white : Colors.brown[800], fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          selectedColor: _primaryColor,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _primaryColor.withOpacity(0.5)),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = cat.id;
                              _filterProducts();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // 2. DANH SÁCH SẢN PHẨM
                Expanded(
                  child: _filteredProducts.isEmpty 
                    ? Center(child: Text("Không có món nào trong danh mục này", style: TextStyle(color: Colors.grey[600])))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildProductCard(_filteredProducts[index]);
                        },
                      ),
                ),
              ],
            ),

        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QUẢN LÝ TÙY CHỌN (đảo màu)
            FloatingActionButton.extended(
              heroTag: 'modifierBtn',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const ModifierManagementDialog(),
                );
              },
              backgroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: _primaryColor, width: 1.5),
              ),
              icon: Icon(Icons.tune, color: _primaryColor),
              label: Text(
                "QUẢN LÝ TÙY CHỌN",
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // THÊM MÓN MỚI (màu chuẩn)
            FloatingActionButton.extended(
              heroTag: 'addProductBtn',
              onPressed: () => _showAddEditDialog(),
              backgroundColor: _primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "THÊM MÓN MỚI",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildProductCard(Product product) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showAddEditDialog(product: product),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ảnh món
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 70, height: 70,
                    color: Colors.grey[100],
                    child: _buildImageWidget(product.imageUrl),
                  ),
                ),
                const SizedBox(width: 15),
                
                // Thông tin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown[900]),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.categoryName ?? "Chưa phân loại",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(product.price),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                      if (product.hasModifiers)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.tune, size: 12, color: Colors.orange[800]),
                              const SizedBox(width: 4),
                              Text("Có tùy chọn (Topping/Size)", style: TextStyle(fontSize: 10, color: Colors.orange[800])),
                            ],
                          ),
                        )
                    ],
                  ),
                ),

                // Switch Active
                Column(
                  children: [
                    Switch(
                      value: product.isActive,
                      activeColor: Colors.green,
                      onChanged: (val) async {
                         bool success = await _menuService.toggleStatus(product.id, val);
                         if (success) _loadData();
                      },
                    ),
                    Text(product.isActive ? "Đang bán" : "Ngừng bán", style: TextStyle(fontSize: 10, color: product.isActive ? Colors.green : Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog({Product? product}) {
    final isEditing = product != null;
    
    // Controllers
    final nameCtrl = TextEditingController(text: product?.name ?? "");
    final priceCtrl = TextEditingController(text: product?.price.toInt().toString() ?? "");
    final descCtrl = TextEditingController(text: product?.description ?? "");

    String? serverImageName = product?.imageUrl; 
    Uint8List? _localImageBytes; 
    final ImagePicker _picker = ImagePicker();

    final validCategories = _categories.where((c) => c.id != 'ALL').toList();
    String? selectedCatId = product?.categoryId;
    if (!isEditing && validCategories.isNotEmpty && selectedCatId == null) {
      selectedCatId = validCategories[0].id;
    }

    // [MỚI] State cho phần chọn Modifier
    Set<String> selectedModifierIds = {}; // Lưu các ID modifier được chọn
    bool isLoadingModifiers = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // [LOGIC MỚI] Load modifier đã chọn nếu là Edit
            if (isLoadingModifiers) {
              if (isEditing) {
                _menuService.getProductModifierIds(product!.id).then((ids) {
                  setStateDialog(() {
                    selectedModifierIds = ids.toSet();
                    isLoadingModifiers = false;
                  });
                });
              } else {
                isLoadingModifiers = false; // Tạo mới thì không cần load
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Container(
                width: 600, // Tăng độ rộng để hiển thị modifier thoải mái
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- HEADER ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        isEditing ? "CẬP NHẬT MÓN" : "THÊM MÓN MỚI",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),

                    // --- BODY ---
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Tên & Giá
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildModernTextField(controller: nameCtrl, label: "Tên món", icon: Icons.coffee)),
                                const SizedBox(width: 15),
                                Expanded(flex: 2, child: _buildModernTextField(controller: priceCtrl, label: "Giá bán", icon: Icons.attach_money, isNumber: true)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // 2. Danh mục & Ảnh
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cột Trái: Danh mục & Mô tả
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Danh mục", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: selectedCatId,
                                            isExpanded: true,
                                            items: validCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                                            onChanged: (val) => setStateDialog(() => selectedCatId = val), 
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildModernTextField(controller: descCtrl, label: "Mô tả", icon: Icons.description_outlined, maxLines: 3),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                
                                // Cột Phải: Ảnh
                                GestureDetector(
                                  onTap: () async {
                                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      setStateDialog(() => _localImageBytes = bytes);
                                      String? uploaded = await _menuService.uploadImage(image);
                                      if (uploaded != null) setStateDialog(() => serverImageName = uploaded);
                                    }
                                  },
                                  child: Container(
                                    width: 140, height: 140,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1.5),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: _buildPreviewImage(localBytes: _localImageBytes, serverName: serverImageName),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 30),

                            // ===========================================
                            // [MỚI] KHU VỰC CHỌN MODIFIER (ACCORDION)
                            // ===========================================
                            Row(
                              children: [
                                Icon(Icons.tune, size: 20, color: Colors.brown[800]),
                                const SizedBox(width: 8),
                                Text("CẤU HÌNH TÙY CHỌN (Topping, Size...)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[800], fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!)
                              ),
                              child: isLoadingModifiers 
                                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                                : Column(
                                    children: _allModifierGroups.map((group) {
                                      // Logic Checkbox nhóm
                                      bool isAllSelected = group.modifiers.isNotEmpty && group.modifiers.every((m) => selectedModifierIds.contains(m.id));
                                      bool hasAnySelected = group.modifiers.any((m) => selectedModifierIds.contains(m.id));

                                      return Theme(
                                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                        child: ExpansionTile(
                                          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                          leading: Checkbox(
                                            value: isAllSelected,
                                            activeColor: _primaryColor,
                                            onChanged: (val) {
                                              setStateDialog(() {
                                                if (val == true) {
                                                  selectedModifierIds.addAll(group.modifiers.map((m) => m.id));
                                                } else {
                                                  selectedModifierIds.removeAll(group.modifiers.map((m) => m.id));
                                                }
                                              });
                                            },
                                          ),
                                          title: Text(group.name, style: TextStyle(fontWeight: hasAnySelected ? FontWeight.bold : FontWeight.normal, color: hasAnySelected ? _primaryColor : Colors.black87)),
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                              child: Wrap(
                                                spacing: 8, runSpacing: 8,
                                                children: group.modifiers.map((mod) {
                                                  bool isSelected = selectedModifierIds.contains(mod.id);
                                                  bool isOpenInput = mod.allowInput;

                                                  return FilterChip(
                                                    label: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (isOpenInput) ...[Icon(Icons.edit_note, size: 14, color: isSelected ? Colors.white : Colors.blue), const SizedBox(width: 4)],
                                                        Text(mod.name),
                                                        if (mod.extraPrice > 0) Text(" +${NumberFormat('#,###').format(mod.extraPrice)}", style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
                                                      ],
                                                    ),
                                                    selected: isSelected,
                                                    showCheckmark: false,
                                                    selectedColor: isOpenInput ? Colors.blue[600] : _primaryColor,
                                                    checkmarkColor: Colors.white,
                                                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                                                    backgroundColor: Colors.white,
                                                    onSelected: (val) {
                                                      setStateDialog(() {
                                                        if (val) selectedModifierIds.add(mod.id);
                                                        else selectedModifierIds.remove(mod.id);
                                                      });
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- FOOTER BUTTONS ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: const Text("HỦY BỎ"),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty || selectedCatId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin!")));
                                  return;
                                }
                                
                                Navigator.pop(ctx);
                                
                                final data = {
                                  'product_name': nameCtrl.text,
                                  'category_id': selectedCatId,
                                  'description': descCtrl.text,
                                  'image_url': serverImageName,
                                  'price': double.tryParse(priceCtrl.text) ?? 0,
                                  // [QUAN TRỌNG] Gửi kèm danh sách modifier
                                  'modifier_ids': selectedModifierIds.toList(),
                                };

                                bool success;
                                if (isEditing) success = await _menuService.updateProduct(product!.id, data);
                                else success = await _menuService.createProduct(data);

                                if (success) {
                                  _loadData(); 
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lưu thành công!"), backgroundColor: Colors.green));
                                }
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: const Text("LƯU LẠI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    String? hint,
    bool isNumber = false, 
    int maxLines = 1
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, color: _primaryColor.withOpacity(0.7), size: 22),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewImage({Uint8List? localBytes, String? serverName}) {
    
    Widget imageContent;

    if (localBytes != null) {
      imageContent = Image.memory(
        localBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (serverName != null && serverName.isNotEmpty) {
      String baseUrl = AppConstants.baseUrl.replaceAll('/api', '');
      String fullUrl = '$baseUrl/uploads/$serverName?t=${DateTime.now().millisecondsSinceEpoch}';

      imageContent = Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, color: Colors.red)),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 32, color: _primaryColor.withOpacity(0.4)),
          const SizedBox(height: 8),
          Text("Tải ảnh lên", style: TextStyle(fontSize: 11, color: _primaryColor.withOpacity(0.6), fontWeight: FontWeight.bold))
        ],
      );
    }

    return imageContent;
  }

  Widget _buildImageWidget(String? filename) {
    if (filename == null || filename.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.coffee, size: 40, color: Colors.brown),
      );
    }

    String baseUrl = AppConstants.baseUrl.replaceAll('/api', '');
    String fullUrl = '$baseUrl/uploads/$filename?v=$_imageVersionKey';

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (ctx, _, __) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }
}