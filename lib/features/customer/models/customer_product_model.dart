import 'package:flutter/foundation.dart';
import 'rating.dart';

class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] as String? ?? '',
      userName: json['name'] as String? ?? 'Anonymous',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      date:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class CustomerProduct {
  final String id;
  final String storeId;
  final String title;
  final double price;
  final String description;
  final String category;
  final int stock;
  final String? imageURL;
  final Rating rating;
  final List<Review> reviews; // <-- ADDED: List of reviews

  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerProduct({
    required this.id,
    required this.storeId,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.stock,
    this.imageURL,
    required this.rating,
    this.reviews = const [], // <-- Default empty
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerProduct.fromJson(Map<String, dynamic> json) {
    Rating parseRating(dynamic ratingJson) {
      if (ratingJson is Map<String, dynamic>) {
        try {
          return Rating.fromJson(ratingJson);
        } catch (e) {
          debugPrint("Error parsing rating: $e");
          return Rating(rate: 0.0, count: 0);
        }
      }
      return Rating(rate: 0.0, count: 0);
    }

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

    // --- ADDED: Parse Reviews ---
    List<Review> parsedReviews = [];
    if (json['reviews'] is List) {
      parsedReviews = (json['reviews'] as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList();
      // Sort reviews by date (newest first)
      parsedReviews.sort((a, b) => b.date.compareTo(a.date));
    }

    return CustomerProduct(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Uncategorized',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageURL: json['imageURL'] as String?,
      rating: parseRating(json['rating']),
      reviews: parsedReviews,
      // <-- Assign reviews
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
