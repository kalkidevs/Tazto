import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter/services.dart'; // Import for PlatformException

import 'api_client.dart';

class AuthApi {
  final ApiClient _apiClient = ApiClient();

  /// Calls the backend to register a new user.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    final body = {
      'name': name,
      'email': email.toLowerCase(), // <-- CHANGED
      'password': password,
      'roles': roles,
    };
    // Makes a POST request to /api/auth/register
    final response = await _apiClient.post('/api/auth/register', body);

    // Save the token upon successful registration, with error handling
    if (response['token'] != null) {
      try {
        await _apiClient.saveToken(response['token']);
      } on PlatformException catch (e) {
        // Log the error but don't crash the app
        debugPrint("Error saving token after registration: ${e.message}");
        // Optionally, you could throw a custom exception here
        // to inform the provider/UI that token saving failed.
      }
    }
    return response as Map<String, dynamic>;
  }

  /// Calls the backend to log in an existing user.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final body = {
      'email': email.toLowerCase(), // <-- CHANGED
      'password': password,
    };
    // Makes a POST request to /api/auth/login
    final response = await _apiClient.post('/api/auth/login', body);

    // Save the token upon successful login, with error handling
    if (response['token'] != null) {
      try {
        await _apiClient.saveToken(response['token']);
      } on PlatformException catch (e) {
        // Log the error but don't crash the app
        debugPrint("Error saving token after login: ${e.message}");
        // Optionally, inform the provider/UI.
      }
    }
    return response as Map<String, dynamic>;
  }
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.put(
      '/api/auth/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      requireAuth: true,
    );
  }

  /// Logs out the user by deleting the token.
  Future<void> logout() async {
    try {
      await _apiClient.deleteToken();
    } on PlatformException catch (e) {
      debugPrint("Error deleting token during logout: ${e.message}");
    }
  }
}
