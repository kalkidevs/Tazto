import 'api_client.dart';

/// This API service fetches categories from the backend.
class CategoryApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches all available product categories.
  /// Calls GET /api/customer/categories
  Future<Map<String, dynamic>> getAllCategories() async {
    final response = await _apiClient.get(
      '/api/customer/categories',
      requireAuth: true, // Requires auth as it's a customer route
    );
    return response as Map<String, dynamic>;
  }
}