// lib/models/category.dart
class CustomerCategory {
  final String id;
  final String name;
  final String imageUrl;

  CustomerCategory({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  /// --- ADDED: Factory constructor to parse JSON from the backend ---
  factory CustomerCategory.fromJson(Map<String, dynamic> json) {
    return CustomerCategory(
      // Handle both '_id' (from backend) and 'id' (local)
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Category',
      imageUrl: json['imageUrl'] as String? ??
          'https_placehold.co/100x100?text=?',
    );
  }
}