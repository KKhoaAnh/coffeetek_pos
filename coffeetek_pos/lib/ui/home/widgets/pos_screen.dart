import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../view_model/pos_view_model.dart';
import 'product_item.dart';
import 'cart_section.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../view_model/cart_view_model.dart';
import '../../../domain/models/category.dart';
import '../../auth/widgets/login_screen.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 900;

        return Scaffold(
          appBar: AppBar(
            leading: widget.isBackButtonEnabled 
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
                
            title: Consumer<CartViewModel>(
              builder: (_, cart, __) => Text(
                isMobile ? (cart.tableName ?? 'Mang về') : "CoffeeTek POS - ${cart.tableName ?? 'Mang về'}", 
                style: const TextStyle(color: Colors.white)
              ),
            ),
            backgroundColor: Colors.brown,
            elevation: 0,
            
            actions: isMobile 
                ? [_buildMobileMenuActions(context)]
                : [
                    IconButton(
                      icon: const Icon(Icons.screen_share_outlined, color: Colors.white),
                      tooltip: 'Mở màn hình khách',
                      onPressed: _openCustomerScreen,
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
                              right: 8, top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text('${cartVM.parkedOrders.length}', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
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
                      onPressed: () async {
                        // 1. Xác nhận (Optional - cho chuyên nghiệp)
                        bool confirm = await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Đăng xuất"),
                            content: const Text("Bạn có chắc chắn muốn thoát?"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý", style: TextStyle(color: Colors.red))),
                            ],
                          )
                        ) ?? false;

                        if (!confirm) return;

                        // 2. Xử lý Logout
                        if (!context.mounted) return;
                        await Provider.of<AuthViewModel>(context, listen: false).logout();

                        // 3. Chuyển màn hình
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                        }
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

                      if (viewModel.isLoading) return const Center(child: CircularProgressIndicator());
                      if (viewModel.errorMessage.isNotEmpty) return Center(child: Text(viewModel.errorMessage, style: const TextStyle(color: Colors.red)));

                      final List<Color> _categoryColors = [
                        const Color(0xFFE3F2FD), const Color(0xFFFFF3E0), const Color(0xFFF3E5F5),
                        const Color(0xFFE8F5E9), const Color(0xFFFFEBEE), const Color(0xFFFFF8E1),
                      ];
                      double catHeight = isMobile ? 90 : 110; 
                      double catWidth = isMobile ? 90 : 110;
                      double iconSize = isMobile ? 32 : 40;
                      double fontSize = isMobile ? 12 : 14;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: catHeight,
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
                                      width: catWidth, // <--- Chiều rộng thay đổi
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Giảm padding dọc chút
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.brown[500] : baseColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: isSelected 
                                            ? Border.all(color: Colors.brown[600]!, width: 2) 
                                            : Border.all(color: Colors.transparent, width: 2),
                                        boxShadow: isSelected 
                                            ? [BoxShadow(color: Colors.brown.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] 
                                            : [],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Ảnh / Icon cũng cần co giãn
                                          Builder(
                                            builder: (context) {
                                              if (cat.imageUrl == null || cat.imageUrl!.isEmpty) {
                                                return Icon(Icons.category, size: iconSize, color: isSelected ? Colors.white70 : Colors.brown[300]);
                                              }
                                              
                                              if (cat.imageUrl!.startsWith('../assets/')) {
                                                return Image.asset(
                                                  cat.imageUrl!,
                                                  height: iconSize, width: iconSize, fit: BoxFit.contain,
                                                  errorBuilder: (_,__,___) => Icon(Icons.local_cafe, size: iconSize, color: isSelected ? Colors.white70 : Colors.brown[300]),
                                                );
                                              }

                                              return Image.network(
                                                  cat.imageUrl!, 
                                                  height: iconSize, width: iconSize, fit: BoxFit.contain, 
                                                  errorBuilder: (_,__,___) => Icon(Icons.local_cafe, size: iconSize, color: isSelected ? Colors.white70 : Colors.brown[300])
                                                );
                                            }
                                          ),
                                          
                                          const SizedBox(height: 6), // Giảm khoảng cách
                                          
                                          Text(
                                            cat.name, 
                                            textAlign: TextAlign.center, 
                                            maxLines: 2, 
                                            overflow: TextOverflow.ellipsis, 
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.brown[900], 
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                                              fontSize: fontSize // <--- Font chữ thay đổi
                                            )
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
                                    builder: (context, boxConstraints) {
                                      double minItemWidth = 160; 
                                      int responsiveCount = (boxConstraints.maxWidth / minItemWidth).floor();
                                      if (responsiveCount < 2) responsiveCount = 2; // Tối thiểu 2 cột

                                      int finalCrossAxisCount;
                                      if (viewModel.selectedCategoryId == 'ALL') {
                                        finalCrossAxisCount = responsiveCount;
                                      } else {
                                        finalCrossAxisCount = currentCategory.gridCount > 0 
                                            ? currentCategory.gridCount 
                                            : responsiveCount;
                                      }

                                      return GridView.builder(
                                        padding: EdgeInsets.only(bottom: isMobile ? 80 : 20),
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

              if (!isMobile)
                const Expanded(
                  flex: 3,
                  child: CartSection(),
                ),
            ],
          ),

          floatingActionButton: isMobile ? Consumer<CartViewModel>(
            builder: (ctx, cartVM, child) {
               if (cartVM.items.isEmpty) return const SizedBox.shrink();
               
               return FloatingActionButton.extended(
                 backgroundColor: Colors.brown,
                 icon: const Icon(Icons.shopping_cart, color: Colors.white),
                 label: Text(
                   NumberFormat.currency(locale: 'vi', symbol: 'đ').format(cartVM.totalAmount),
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                 ),
                 onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => Container(
                        height: MediaQuery.of(context).size.height * 0.85,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              width: 40, height: 4,
                              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                            ),
                            const Expanded(child: CartSection()),
                          ],
                        ),
                      ),
                    );
                 },
               );
            }
          ) : null,
        );
      },
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

  void _openCustomerScreen() {
     final baseUrl = html.window.location.href.split('#')[0];
     html.window.open('$baseUrl#/customer', 'customer_display_window', 'width=1000,height=800,menubar=no,toolbar=no');
  }

  Widget _buildMobileMenuActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      // [CẬP NHẬT] Thêm async để chờ logout xong mới chuyển màn hình
      onSelected: (val) async {
        // Sửa lại đoạn logic này:
        if (val == 'logout') {
          // 1. Gọi hàm logout
          try {
            await Provider.of<AuthViewModel>(context, listen: false).logout();
          } catch(e) {
            print("Lỗi logout backend: $e");
            // Dù lỗi backend vẫn cho thoát ra ngoài UI
          }

          // 2. [QUAN TRỌNG] Đặt lệnh chuyển màn hình RA NGOÀI try/catch
          // Để dù thành công hay thất bại đều chuyển về Login
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()), 
              (Route<dynamic> route) => false, 
            );
          }
        }

        if (val == 'refresh') Provider.of<PosViewModel>(context, listen: false).loadProducts();
        if (val == 'customer') _openCustomerScreen();
        if (val == 'parked') {
          Provider.of<CartViewModel>(context, listen: false).fetchPendingOrders();
          _showParkedOrdersDialog(context);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'parked', child: Text('Đơn tạm tính')),
        const PopupMenuItem<String>(value: 'customer', child: Text('Màn hình khách')),
        const PopupMenuItem<String>(value: 'refresh', child: Text('Tải lại món')),
        const PopupMenuItem<String>(value: 'logout', child: Text('Đăng xuất')),
      ],
    );
  }
}