class Product {
  final dynamic id;
  final String name;
  final double price;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'] ?? '',
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'],
    );
  }
}
