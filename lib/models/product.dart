// models/product.dart
class Product {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  Product(
      {required this.id,
      required this.name,
      required this.price,
      this.imageUrl});

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        name: m['name'] ?? '—',
        price: (m['price'] ?? 0).toDouble(),
        imageUrl: m['image'] as String?,
      );
}
