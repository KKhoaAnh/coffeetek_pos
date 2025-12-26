class Product {
  final dynamic id;        
  final String name;
  final String categoryId;
  final String categoryName;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      price: (json['price'] is int) 
          ? (json['price'] as int).toDouble() 
          : (json['price'] as double? ?? 0.0),
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}