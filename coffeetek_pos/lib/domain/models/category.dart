class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final int gridCount;

  Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.gridCount = 4,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['category_id'].toString(),
      name: json['category_name'],
      imageUrl: json['image_url'],
      gridCount: json['grid_column_count'] ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': id,
      'category_name': name,
      'image_url': imageUrl,
      'grid_column_count': gridCount,
    };
  }
}
