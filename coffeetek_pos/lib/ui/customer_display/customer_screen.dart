import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../ui/home/view_model/cart_view_model.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({Key? key}) : super(key: key);

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isPortrait = constraints.maxWidth < 800;

          if (isPortrait) {
            return Column(
              children: [
                Expanded(
                  flex: 4, 
                  child: _buildAdsSection(),
                ),
                Expanded(
                  flex: 6,
                  child: Consumer<CartViewModel>(
                    builder: (context, cartVM, child) {
                      if (cartVM.cartItems.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }
                      return _buildOrderDetailsSection(context, cartVM);
                    },
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Consumer<CartViewModel>(
                    builder: (context, cartVM, child) {
                      if (cartVM.cartItems.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }
                      return _buildOrderDetailsSection(context, cartVM);
                    },
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _buildAdsSection(),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildOrderDetailsSection(BuildContext context, CartViewModel cartVM) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kính chào quý khách!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown[800]),
                ),
                Text(
                  '${cartVM.tableName ?? "Mang về"} ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          Expanded(
            child: cartVM.cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Mời quý khách gọi món', style: TextStyle(color: Colors.grey[400], fontSize: 20)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: cartVM.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartVM.cartItems[index];
                    return _buildItemRow(item, currencyFormat);
                  },
                ),
          ),

          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG CỘNG:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                
                // [RESPONSIVE]: Xử lý tổng tiền màn hình khách
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                       // Logic tính tiền trực tiếp (như đã bàn trước đó)
                      currencyFormat.format(
                        cartVM.cartItems.fold(0.0, (sum, item) {
                          double modifiersPrice = (item.selectedModifiers ?? []).fold(0.0, (s, m) => s + m.extraPrice);
                          return sum + (item.product.price + modifiersPrice) * item.quantity;
                        })
                      ),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item, NumberFormat currencyFormat) {
    final String productName = item.product.name;
    final int quantity = item.quantity;
    
    double price = item.product.price;
    double modifiersPrice = 0;
    
    final List modifiers = item.selectedModifiers ?? [];

    if (modifiers.isNotEmpty) {
       modifiersPrice = modifiers.fold(0.0, (sum, m) => sum + m.extraPrice);
    }
    double totalLinePrice = (price + modifiersPrice) * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Số lượng
          Container(
            width: 36, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.brown[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown.shade100),
            ),
            child: Text(
              '$quantity',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[600], fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 2),
                  child: Text(
                    currencyFormat.format(item.product.price),
                    style: TextStyle(
                      color: Colors.brown[500], 
                      fontSize: 13, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
                
                if (modifiers.isNotEmpty)
                  ...modifiers.map((m) {
                    String priceStr = '';
                    if (m.extraPrice > 0) {
                      priceStr = ' + ${currencyFormat.format(m.extraPrice)}';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontFamily: 'Roboto',
                            fontStyle: FontStyle.italic,
                          ),
                          children: [
                            const TextSpan(text: '- '),
                            TextSpan(text: m.name),
                            if (priceStr.isNotEmpty)
                              TextSpan(
                                text: ' $priceStr',
                                style: const TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontStyle: FontStyle.normal,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),

          const SizedBox(width: 8),

          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                currencyFormat.format(totalLinePrice),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsSection() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
               return const Center(child: Text("CoffeeTek Promotion", style: TextStyle(color: Colors.white)));
            },
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MUA 1 TẶNG 1',
                    style: TextStyle(color: Colors.yellow, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Áp dụng cho dòng Cold Brew khung giờ vàng 14h-16h',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}