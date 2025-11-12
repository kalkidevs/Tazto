import 'api_client.dart';

class ProductApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches all products.
  /// Calls GET /api/customer/products
  /// --- UPDATED: Now sends latitude and longitude as query params ---
  Future<Map<String, dynamic>> getAllProducts({
    double? lat,
    double? lng,
  }) async {
    // Start with the base endpoint
    String endpoint = '/api/customer/products';

    // Append query parameters if lat and lng are provided
    if (lat != null && lng != null) {
      endpoint += '?lat=$lat&lng=$lng';
    }

    // FIX: Changed from POST to GET and updated the endpoint.
    // This now matches your customerRoutes.js file.
    final response = await _apiClient.get(
      endpoint, // Use the new endpoint with query params
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
