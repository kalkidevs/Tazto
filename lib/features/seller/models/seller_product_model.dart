// Based on the backend Product.js model
class SellerProduct {
  final String id;
  final String storeId;
  final String title;
  final String? description;
  final double price;
  final String category;
  final int stock;
  final String? imageURL;

  // Add other fields as needed, e.g., SKU from your UI
  final String? sku;

  SellerProduct({
    required this.id,
    required this.storeId,
    required this.title,
    this.description,
    required this.price,
    required this.category,
    required this.stock,
    this.imageURL,
    this.sku,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    return SellerProduct(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Uncategorized',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageURL: json['imageURL'] as String?,
      sku: json['sku'] as String?, // Assuming SKU might be in the model
    );
  }
}
