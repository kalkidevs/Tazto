import 'api_client.dart';

/// API service dedicated to all seller-side operations.
class SellerApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches the seller's store profile.
  /// Calls GET /api/seller/store
  Future<Map<String, dynamic>> getMyStore() async {
    final response = await _apiClient.get(
      '/api/seller/store',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Creates a new store profile for the seller.
  /// Calls POST /api/seller/store
  Future<Map<String, dynamic>> createStore({
    required String storeName,
    required String address,
    required String pincode,
    double? lat,
    double? lng,
  }) async {
    final body = {
      'storeName': storeName,
      'address': address,
      'pincode': pincode,
      if (lat != null && lng != null) 'coordinates': [lng, lat],
    };
    final response = await _apiClient.post(
      '/api/seller/store',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Updates an existing store profile.
  /// Calls PUT /api/seller/store
  Future<Map<String, dynamic>> updateStore(Map<String, dynamic> updates) async {
    final response = await _apiClient.put(
      '/api/seller/store',
      updates,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Adds a single new product.
  /// Calls POST /api/seller/products
  Future<Map<String, dynamic>> addProduct(
    Map<String, dynamic> productData,
  ) async {
    final response = await _apiClient.post(
      '/api/seller/products',
      productData,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Adds multiple products in bulk.
  /// Calls POST /api/seller/products/bulk
  Future<Map<String, dynamic>> bulkAddProducts(
    List<Map<String, dynamic>> products,
  ) async {
    final body = {'products': products};
    final response = await _apiClient.post(
      '/api/seller/products/bulk',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Fetches all products for the seller's store.
  /// Calls GET /api/seller/products
  Future<Map<String, dynamic>> getMyProducts() async {
    final response = await _apiClient.get(
      '/api/seller/products',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Fetches all orders for the seller's store.
  /// Calls GET /api/seller/orders
  Future<Map<String, dynamic>> getMyOrders() async {
    final response = await _apiClient.get(
      '/api/seller/orders',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Updates the status of a specific order.
  /// Calls PUT /api/seller/orders/:id
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final response = await _apiClient.put('/api/seller/orders/$orderId', {
      'status': status,
    }, requireAuth: true);
    return response as Map<String, dynamic>;
  }

  /// Fetches dashboard analytics (placeholder).
  /// Calls GET /api/seller/analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    // --- UPDATED: This now calls the real backend endpoint ---
    final response = await _apiClient.get(
      '/api/seller/analytics',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
    // --- END UPDATE ---
  }
}
