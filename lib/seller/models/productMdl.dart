// lib/models/product.dart
class Product {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final int stock;

  Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
  });
}
