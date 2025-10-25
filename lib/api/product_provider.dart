import 'api_client.dart';

/// Service class for handling product-related API calls.
/// See "3. Product APIs" in the documentation.
class ProductApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches all products.
  /// Corresponds to "3.1 Get All Products".
  Future<List<dynamic>> getAllProducts() async {
    // **FIX:** Updated the endpoint from '/getProducts' to '/getAllProducts'.
    final response = await _apiClient.post('/api/products/getAllProducts', {});

    // The API now returns a Map: {"products": [...]}, not a direct list.
    if (response is Map<String, dynamic> && response.containsKey('products')) {
      // **FIX:** Extract the list from the 'products' key before returning.
      return response['products'] as List<dynamic>;
    } else {
      // If the response format is not what we expect, throw an error.
      throw ApiException(
          "Unexpected response format from server for getAllProducts.");
    }
  }
}
