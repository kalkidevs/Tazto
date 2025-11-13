import 'api_client.dart';

class OrderApi {
  final ApiClient _apiClient = ApiClient();

  /// Creates a new order.
  /// Calls POST /api/orders
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required Map<String, dynamic> shippingAddress,
    String? paymentMethod,
  }) async {
    final body = {
      'items': items,
      'totalAmount': totalAmount,
      'shippingAddress': shippingAddress,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };
    final response = await _apiClient.post(
      '/api/customer/orders',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Fetches the order history for the logged-in user.
  Future<List<dynamic>> getMyOrders() async {
    // *** FIXED: Changed from POST to GET to match customerRoutes.js ***
    final response = await _apiClient.get(
      '/api/customer/orders',
      requireAuth: true,
    );

    // Expecting the response to be a JSON array of orders
    if (response is List) {
      return response;
    } else if (response is Map<String, dynamic> &&
        response.containsKey('orders') &&
        response['orders'] is List) {
      // Handle if backend wraps it (e.g., { "orders": [...] })
      return response['orders'] as List<dynamic>;
    } else {
      throw ApiException('Invalid response format received for order history.');
    }
  }
}
