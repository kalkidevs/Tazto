import 'rating.dart';

class Product {
  final String id;
  final String title;
  final double price;
  final String description;
  final String category;
  final int stock;
  final String? imageURL;
  final Rating rating;

  // Made these fields optional as they are not in the new API response
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.stock,
    this.imageURL,
    required this.rating,
    this.createdAt,
    this.updatedAt,
  });

  /// This factory constructor now correctly parses the new product data structure.
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    // **FIX:** Changed from '_id' to 'id' to match the new API response.
    id: json['id'] as String,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    description: json['description'] as String,
    category: json['category'] as String,
    stock: json['stock'] as int,
    imageURL: json['imageURL'] as String?,
    rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
    // **FIX:** Handle potentially null date fields gracefully.
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );
}
