// lib/models/product.dart
import 'rating.dart';

class Product {
  final String id;
  final String title;
  final double price;
  final String description;
  final String category;
  final int stock;
  final Rating rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.stock,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['_id'] as String,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    description: json['description'] as String,
    category: json['category'] as String,
    stock: json['stock'] as int,
    rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
