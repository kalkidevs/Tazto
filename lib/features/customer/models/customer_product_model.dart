import 'package:flutter/foundation.dart';

import 'rating.dart';

class CustomerProduct {
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

  CustomerProduct({
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

  /// This factory constructor now safely parses the product data structure.
  factory CustomerProduct.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse rating
    Rating parseRating(dynamic ratingJson) {
      if (ratingJson is Map<String, dynamic>) {
        try {
          return Rating.fromJson(ratingJson);
        } catch (e) {
          debugPrint("Error parsing rating: $e");
          // Fallback to default rating
          return Rating(rate: 0.0, count: 0);
        }
      }
      // Fallback to default rating if 'rating' is missing or not a map
      return Rating(rate: 0.0, count: 0);
    }

    // Helper function to safely parse date
    DateTime? parseDate(dynamic dateString) {
      if (dateString is String) {
        try {
          return DateTime.parse(dateString);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // FIX: Use _id from Mongoose, provide fallbacks for all fields
    return CustomerProduct(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      // Handle null description
      category: json['category'] as String? ?? 'Uncategorized',
      // Handle null category
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageURL: json['imageURL'] as String?,
      rating: parseRating(json['rating']),
      // Use safe rating parser
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
