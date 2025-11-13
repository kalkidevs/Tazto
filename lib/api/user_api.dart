import 'api_client.dart';

class UserApi {
  final ApiClient _apiClient = ApiClient();

  /// Fetches the current logged-in user's profile and addresses.
  /// Calls GET /api/customer/profile (protected route)
  Future<Map<String, dynamic>> getMyProfile() async {
    // *** FIXED: Changed from POST /api/users/me to GET /api/customer/profile ***
    final response = await _apiClient.get(
      '/api/customer/profile',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Adds a new address for the current user.
  /// Calls POST /api/customer/addresses (protected route)
  Future<Map<String, dynamic>> addAddress({
    required String label,
    required String street,
    required String city,
    String? state,
    required String pincode,
    String? phone,
  }) async {
    final body = {
      'label': label,
      'street': street,
      'city': city,
      if (state != null) 'state': state,
      'pincode': pincode,
      if (phone != null) 'phone': phone,
    };
    // *** FIXED: Updated path from /api/users/addresses to /api/customer/addresses ***
    final response = await _apiClient.post(
      '/api/customer/addresses',
      body,
      requireAuth: true,
    );
    // This route returns the new address object, not the full user
    // The provider will need to handle adding this to the user's list
    return response as Map<String, dynamic>;
  }

  /// Updates an existing address for the current user.
  /// Calls PUT /api/customer/addresses/:id
  Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    String? label,
    String? street,
    String? city,
    String? state,
    String? pincode,
    String? phone,
    bool? isDefault, // <-- ADDED
  }) async {
    final body = {
      // Body only contains fields to update
      if (label != null) 'label': label,
      if (street != null) 'street': street,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (phone != null) 'phone': phone,
      if (isDefault != null) 'isDefault': isDefault, // <-- ADDED
    };
    if (body.isEmpty) {
      throw ArgumentError("No fields to update.");
    }

    // *** FIXED: Updated path to use PUT /api/customer/addresses/:id ***
    final response = await _apiClient.put(
      '/api/customer/addresses/$addressId',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Deletes an address for the current user.
  /// Calls DELETE /api/customer/addresses/:id
  Future<Map<String, dynamic>> deleteAddress({
    required String addressId,
  }) async {
    // *** FIXED: Updated path to use DELETE /api/customer/addresses/:id ***
    final response = await _apiClient.delete(
      '/api/customer/addresses/$addressId',
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }

  /// Updates user profile details (e.g., name, phone).
  /// Calls PUT /api/customer/profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String
    userId, // This param is no longer needed by the API, but we'll leave it
    String? name,
    String? phone,
  }) async {
    final body = {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
    };
    if (body.isEmpty) {
      throw ArgumentError("No fields for update.");
    }
    final response = await _apiClient.put(
      '/api/customer/profile',
      body,
      requireAuth: true,
    );
    return response as Map<String, dynamic>;
  }
}
