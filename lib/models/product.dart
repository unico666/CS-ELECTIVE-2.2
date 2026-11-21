class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;

  bool get inStock => stock > 0;

  factory Product.fromMap(Map<String, dynamic> map) {
    final categoryMap = map['categories'] as Map?;
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      stock: (map['stock'] as num).toInt(),
      categoryId: (map['category_id'] as num?)?.toInt(),
      categoryName: categoryMap?['name'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }
}
