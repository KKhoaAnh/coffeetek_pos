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
            // --- 1. HÌNH ẢNH ---
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildProductImage(product.imageUrl),
              ),
            ),
            
            // --- 2. THÔNG TIN ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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

  // Hàm xử lý ảnh thông minh (Đã tối ưu Cache)
  Widget _buildProductImage(String? filename) {
    if (filename == null || filename.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.coffee, size: 40, color: Colors.brown),
      );
    }

    // 1. Xử lý Base URL
    String baseUrl = AppConstants.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    } else if (baseUrl.endsWith('/api/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 5);
    }

    // 2. Mã hóa tên file (QUAN TRỌNG: Giữ lại cái này để sửa lỗi tên có dấu cách/tiếng Việt)
    String encodedName = Uri.encodeComponent(filename);

    // 3. Tạo URL đầy đủ
    // [THAY ĐỔI]: Bỏ đoạn "?t=..." đi để App sử dụng Cache, không tải lại liên tục
    String fullUrl = '$baseUrl/uploads/$encodedName';

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      
      // Loading Builder: Hiện icon xoay khi đang tải lần đầu
      loadingBuilder: (ctx, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: Colors.brown[200],
          ),
        );
      },

      // Error Builder
      errorBuilder: (ctx, error, stackTrace) {
        // print("Lỗi tải ảnh: $fullUrl");
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 30, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}