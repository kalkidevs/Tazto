import 'api_client.dart';

class ProductApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches all products.
  Future<Map<String, dynamic>> getAllProducts({
    double? lat,
    double? lng,
  }) async {
    String endpoint = '/api/customer/products';
    if (lat != null && lng != null) {
      endpoint += '?lat=$lat&lng=$lng';
    }
    final response = await _apiClient.get(endpoint, requireAuth: true);
    return response as Map<String, dynamic>;
  }

  /// Fetches a single product by its ID.
  Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _apiClient.get(
      '/api/customer/products/$id',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAllCategories() async {
    final response = await _apiClient.get(
      '/api/customer/categories',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// --- ADDED: Submit a review for a product ---
  Future<void> addReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    await _apiClient.post('/api/customer/products/$productId/reviews', {
      'rating': rating,
      'comment': comment,
    }, requireAuth: true);
  }
}
