import '../../domain/models/product.dart';

class ProductApiModel {
  final String productId;
  final String productName;
  final String categoryId;
  final String categoryName;
  final String? categoryImage;
  final String? description;
  final String? imageUrl;
  final int? gridCount;
  final int isActive;
  final double currentPrice;
  final bool hasModifiers;

  ProductApiModel({
    required this.productId,
    required this.productName,
    required this.categoryId,
    required this.categoryName,
    this.categoryImage,
    this.description,
    this.imageUrl,
    required this.gridCount,
    required this.isActive,
    required this.currentPrice,
    required this.hasModifiers,
  });

  factory ProductApiModel.fromJson(Map<String, dynamic> json) {
    return ProductApiModel(
      productId: json['product_id'].toString(),
      productName: json['product_name'] ?? '',
      categoryId: json['category_id']?.toString() ?? 'OTHER',
      categoryName: json['category_name'] ?? 'OTHER',
      categoryImage: json['category_image'],
      description: json['description'],
      imageUrl: json['image_url'],
      gridCount: int.tryParse(json['grid_column_count'].toString()),
      isActive: json['is_active'] == 1 ? 1 : 0, 
      currentPrice: double.tryParse(json['price_value'].toString()) ?? 0.0,
      hasModifiers: json['has_modifiers'] == true,
    );
  }

  Product toDomain() {
    return Product(
      id: productId,
      name: productName,
      categoryId: categoryId,
      categoryName: categoryName,
      categoryImage: categoryImage,
      description: description,
      imageUrl: imageUrl,
      gridCount: gridCount,
      isActive: isActive == 1,
      price: currentPrice,
      hasModifiers: hasModifiers,
    );
  }
}