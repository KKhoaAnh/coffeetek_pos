class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final int gridCount;

  Category({required this.id, required this.name, this.imageUrl, this.gridCount = 4});
}