import 'api_client.dart';

class UserApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches the current user's profile and addresses.
  /// Calls POST /api/users/me
  Future<Map<String, dynamic>> getMe() async {
    // This endpoint requires authentication
    final response = await _apiClient.post(
      '/api/users/me',
      {},
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Adds a new address for the current user.
  /// Calls POST /api/users/addresses
  Future<Map<String, dynamic>> addAddress({
    required String label,
    required String street,
    required String city,
    required String state,
    required String pincode,
    String? phone,
  }) async {
    final body = {
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
    };
    // This endpoint requires authentication
    final response = await _apiClient.post(
      '/api/users/addresses',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Updates an existing address.
  /// Calls POST /api/users/updateAddress
  Future<Map<String, dynamic>> updateAddress(
    String addressId,
    Map<String, dynamic> updates,
  ) async {
    // Add the addressId to the body
    final body = {'addrId': addressId, ...updates};
    final response = await _apiClient.post(
      '/api/users/updateAddress',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Deletes an existing address.
  /// Calls POST /api/users/deleteAddress
  Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    final body = {
      'addrId': addressId, // Pass addrId in the body
    };
    final response = await _apiClient.post(
      '/api/users/deleteAddress',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }
}
