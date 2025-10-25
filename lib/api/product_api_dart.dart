import 'api_client.dart';

class ProductApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches all products.
  /// Calls POST /api/products/getAllProducts
  Future<Map<String, dynamic>> getAllProducts() async {
    // Your backend expects an empty POST request.
    final response = await _apiClient.post('/api/products/getAllProducts', {});
    return response as Map<String, dynamic>;
  }

  /// Fetches a single product by its ID.
  /// Calls POST /api/products/getProductById
  Future<Map<String, dynamic>> getProductById(String id) async {
    final body = {'id': id};
    final response = await _apiClient.post('/api/products/getProductById', body);
    return response as Map<String, dynamic>;
  }
}

