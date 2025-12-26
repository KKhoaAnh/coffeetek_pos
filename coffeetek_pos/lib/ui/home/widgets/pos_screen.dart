import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_model/pos_view_model.dart';
import 'product_item.dart';
import 'cart_section.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../view_model/cart_view_model.dart';
import '../../../domain/models/category.dart';
import 'dart:html' as html;

class PosScreen extends StatefulWidget {
  final bool isBackButtonEnabled;
  const PosScreen({
    Key? key, 
    this.isBackButtonEnabled = false
  }) : super(key: key);
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PosViewModel>(context, listen: false).loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        leading: widget.isBackButtonEnabled 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                   Navigator.pop(context); 
                },
              )
            : null,
            
        title: Consumer<CartViewModel>(
          builder: (_, cart, __) => Text("CoffeeTek POS - ${cart.tableName ?? 'Mang về'}", style: const TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.brown,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.screen_share_outlined, color: Colors.white),
            tooltip: 'Mở màn hình khách',
            onPressed: () {
              final baseUrl = html.window.location.href.split('#')[0];
              html.window.open('$baseUrl#/customer', 'customer_display_window', 'width=1000,height=800,menubar=no,toolbar=no');
            },
          ),
          Consumer<CartViewModel>(
            builder: (_, cartVM, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.receipt_long, color: Colors.white),
                  tooltip: 'Đơn tạm tính',
                  onPressed: () {
                    Provider.of<CartViewModel>(context, listen: false).fetchPendingOrders();
                    _showParkedOrdersDialog(context);
                  },
                ),
                if (cartVM.parkedOrders.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cartVM.parkedOrders.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => Provider.of<PosViewModel>(context, listen: false).loadProducts(),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: () {
              Provider.of<AuthViewModel>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(10),
              child: Consumer<PosViewModel>(
                builder: (context, viewModel, child) {
                  final currentCategory = viewModel.categories.firstWhere(
                    (c) => c.id == viewModel.selectedCategoryId,
                    orElse: () => Category(id: 'ALL', name: 'Tất cả', gridCount: 0),
                  );

                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (viewModel.errorMessage.isNotEmpty) {
                    return Center(child: Text(viewModel.errorMessage, style: const TextStyle(color: Colors.red)));
                  }

                  final List<Color> _categoryColors = [
                  const Color(0xFFE3F2FD), // Xanh dương nhạt
                  const Color(0xFFFFF3E0), // Cam nhạt
                  const Color(0xFFF3E5F5), // Tím nhạt
                  const Color(0xFFE8F5E9), // Xanh lá nhạt
                  const Color(0xFFFFEBEE), // Hồng nhạt
                  const Color(0xFFFFF8E1), // Vàng nhạt
                  ];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: viewModel.categories.length,
                          itemBuilder: (ctx, i) {
                            final cat = viewModel.categories[i];
                            final isSelected = cat.id == viewModel.selectedCategoryId;
                            
                            final Color baseColor = _categoryColors[i % _categoryColors.length];

                            return Padding(
                              padding: const EdgeInsets.only(right: 15, bottom: 5),
                              child: InkWell(
                                onTap: () => viewModel.selectCategory(cat.id),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: 110,
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.brown[500] : baseColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected 
                                        ? Border.all(color: Colors.brown[600]!, width: 2)
                                        : Border.all(color: Colors.transparent, width: 2),
                                    boxShadow: isSelected 
                                        ? [
                                            BoxShadow(
                                              color: Colors.brown.withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4)
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedScale(
                                        scale: isSelected ? 1.1 : 1.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                cat.imageUrl!,
                                                height: 40,
                                                width: 40,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_,__,___) => Icon(
                                                  Icons.local_cafe, 
                                                  size: 40, 
                                                  color: isSelected ? Colors.white70 : Colors.brown[300]
                                                ),
                                              )
                                            : Icon(
                                                Icons.category, 
                                                size: 40, 
                                                color: isSelected ? Colors.white70 : Colors.brown[300]
                                              ),
                                      ),
                                      
                                      const SizedBox(height: 8),

                                      Text(
                                        cat.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.brown[900],
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 10),

                      Expanded(
                        child: viewModel.filteredProducts.isEmpty
                            ? Center(child: Text("Không có món nào", style: TextStyle(color: Colors.grey[600])))
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  double minItemWidth = 160; 
                                  int responsiveCount = (constraints.maxWidth / minItemWidth).floor();
                                  if (responsiveCount < 2) responsiveCount = 2;

                                  int finalCrossAxisCount;
                                  
                                  if (viewModel.selectedCategoryId == 'ALL') {
                                    finalCrossAxisCount = responsiveCount;
                                  } else {
                                    finalCrossAxisCount = currentCategory.gridCount > 0 
                                        ? currentCategory.gridCount 
                                        : responsiveCount;
                                  }

                                  return GridView.builder(
                                    padding: const EdgeInsets.only(bottom: 80),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: finalCrossAxisCount,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: viewModel.filteredProducts.length,
                                    itemBuilder: (ctx, i) {
                                      return ProductItem(product: viewModel.filteredProducts[i]);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const Expanded(
            flex: 3,
            child: CartSection(),
          ),
        ],
      ),
    );
  }

  void _showParkedOrdersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer<CartViewModel>(
          builder: (context, cartVM, child) {
            return AlertDialog(
              title: const Text("Danh sách Đơn tạm tính"),
              content: SizedBox(
                width: 400,
                height: 400,
                child: cartVM.parkedOrders.isEmpty
                    ? const Center(child: Text("Không có đơn nào đang chờ."))
                    : ListView.builder(
                        itemCount: cartVM.parkedOrders.length,
                        itemBuilder: (ctx, i) {
                          final order = cartVM.parkedOrders[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  order.tableName ?? "Mang về", 
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              title: Text(
                                "Đơn ${order.orderCode}", 
                                style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                              subtitle: Text(
                                "${DateFormat('HH:mm dd/MM').format(order.createdDate)} - ${NumberFormat.currency(locale: 'vi', symbol: '₫').format(order.totalAmount)}"
                              ),
                              trailing: const Icon(Icons.restore, color: Colors.brown),
                              onTap: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đang tải chi tiết đơn hàng...'))
                                );

                                final success = await cartVM.restoreOrderToCart(order.id.toString());
                                
                                Navigator.of(ctx).pop();

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Đã nạp lại đơn hàng thành công!'))
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Không thể tải đơn hàng.'), backgroundColor: Colors.red)
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Đóng"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}