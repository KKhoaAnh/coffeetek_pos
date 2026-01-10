class Product {
  final dynamic id;        
  final String name;
  final String categoryId;
  final String? categoryName;
  final String? categoryImage;
  final String? description;
  final String? imageUrl;
  final int? gridCount;
  final bool isActive;
  final double price;       
  final bool hasModifiers;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.categoryImage,
    this.description,
    this.imageUrl,
    this.gridCount,
    required this.isActive,
    required this.price,
    this.hasModifiers = false,
  });

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    String? categoryImage,
    String? description,
    String? imageUrl,
    bool? isActive,
    double? price,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryImage: categoryImage ?? this.categoryImage,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      price: price ?? this.price,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['product_id'] ?? '').toString(),
      name: json['product_name'] ?? 'Tên món lỗi',
      
      categoryId: (json['category_id'] ?? '').toString(), 
      categoryName: json['category_name'],
      
      description: json['description'],
      imageUrl: json['image_url'],
      
      price: double.tryParse(json['price_value']?.toString() ?? '0') ?? 0.0,
      hasModifiers: json['has_modifiers'] == 1 || json['has_modifiers'] == true,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'product_name': name,
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
      'image_url': imageUrl,
      'price_value': price,
      'is_active': isActive,
    };
  }
}