import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/product.dart';
import 'modifier_selection_dialog.dart';
import '../view_model/cart_view_model.dart';
import '../../../utils/constants.dart';


class ProductItem extends StatelessWidget {
  final Product product;

  const ProductItem({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return GestureDetector(
      onTap: () {
        if (product.hasModifiers) {
          showDialog(
            context: context,
            builder: (ctx) => ModifierSelectionDialog(
              product: product,
              isEditing: false,
              onConfirm: (selectedModifiers) {
                Provider.of<CartViewModel>(context, listen: false).addToCart(
                  product, 
                  modifiers: selectedModifiers
                );
              },
            ),
          );
        } else {
          Provider.of<CartViewModel>(context, listen: false).addToCart(
            product, 
            modifiers: []
          );
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm ${product.name}'), 
              duration: const Duration(milliseconds: 500),
            )
          );
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. HÌNH ẢNH (Expanded để chiếm phần lớn diện tích) ---
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildProductImage(product.imageUrl),
              ),
            ),
            
            // --- 2. THÔNG TIN (Padding + LayoutBuilder để tránh overflow) ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, // Căn giữa chiều dọc
                children: [
                  // Tên món
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Cắt bớt nếu quá dài
                  ),
                  const SizedBox(height: 4),
                  
                  // Giá tiền - Dùng FittedBox để tự thu nhỏ nếu giá quá lớn
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      currencyFormat.format(product.price),
                      style: TextStyle(color: Colors.brown[700], fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hàm xử lý ảnh thông minh cho ProductItem
  Widget _buildProductImage(String? filename) {
    if (filename == null || filename.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.coffee, size: 40, color: Colors.brown),
      );
    }

    // Ghép Base URL của Server vào tên file
    // AppConstants.baseUrl ví dụ là 'http://localhost:3000/api' -> cần cắt bớt '/api' nếu folder uploads nằm ở root
    // GIẢ SỬ AppConstants.baseUrl = 'http://localhost:3000/api'
    // Thì đường dẫn ảnh là 'http://localhost:3000/uploads/$filename'
    
    // Cách xử lý URL an toàn:
    String baseUrl = AppConstants.baseUrl.replaceAll('/api', ''); // Bỏ đuôi /api
    String fullUrl = '$baseUrl/uploads/$filename';

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