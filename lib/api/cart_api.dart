import 'api_client.dart';

/// This API service is now updated to work with the
/// backend routes defined in `Backend_LINC/routes/customerRoutes.js`.
class CartApi {
  final ApiClient _apiClient = ApiClient();

  /// Gets the current user's cart.
  /// Calls GET /api/customer/cart
  Future<Map<String, dynamic>> getMyCart() async {
    // UPDATED: Changed from POST to GET and corrected the path.
    final response = await _apiClient.get(
      '/api/customer/cart',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Adds an item to the user's cart or updates its quantity.
  /// The backend controller handles both add and update with this one route.
  /// Calls POST /api/customer/cart
  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
  }) async {
    final body = {'productId': productId, 'quantity': quantity};
    // UPDATED: Corrected the path from /api/cart/add
    final response = await _apiClient.post(
      '/api/customer/cart',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Updates an item's quantity in the cart.
  /// Calls PUT /api/customer/cart/:productId
  Future<Map<String, dynamic>> updateCartItem({
    required String productId,
    required int quantity,
  }) async {
    // The backend controller for PUT expects only the quantity in the body.
    final body = {'quantity': quantity};
    // UPDATED: Changed from POST to PUT and corrected the path.
    final response = await _apiClient.put(
      '/api/customer/cart/$productId',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Removes an item from the cart.
  /// Calls DELETE /api/customer/cart/:productId
  Future<Map<String, dynamic>> removeCartItem({
    required String productId,
  }) async {
    // UPDATED: Changed from POST to DELETE and corrected the path.
    // This method doesn't require a body.
    final response = await _apiClient.delete(
      '/api/customer/cart/$productId',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Clears all items from the cart.
  /// Calls DELETE /api/customer/cart
  Future<Map<String, dynamic>> clearCart() async {
    // UPDATED: Changed from POST to DELETE and corrected the path.
    final response = await _apiClient.delete(
      '/api/customer/cart',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }
}
