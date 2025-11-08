import 'api_client.dart';

class ProductApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches all products.
  /// Calls GET /api/customer/products
  Future<Map<String, dynamic>> getAllProducts() async {
    // FIX: Changed from POST to GET and updated the endpoint.
    // This now matches your customerRoutes.js file.
    final response = await _apiClient.get(
      '/api/customer/products',
      requireAuth: true, // Requires auth as it's a customer route
    );
    return response as Map<String, dynamic>;
  }

  /// Fetches a single product by its ID.
  /// Calls GET /api/customer/products/:id
  Future<Map<String, dynamic>> getProductById(String id) async {
    // FIX: Changed from POST to GET and updated the endpoint to use a URL param.
    // This now matches your customerRoutes.js file.
    final response = await _apiClient.get(
      '/api/customer/products/$id',
      requireAuth: true, // Requires auth as it's a customer route
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAllCategories() async {
    final response = await _apiClient.get(
      '/api/categories',
      requireAuth: true, // Requires auth as it's a customer route
    );
    return response as Map<String, dynamic>;
  }
}
