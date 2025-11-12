import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A custom exception to handle API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() {
    return message;
  }
}

class ApiClient {
  // ---  DEVELOPMENT TOGGLE ---
  // Set this to 'true' to test against your local server.
  // Set this to 'false' to use your live 'onrender.com' server.
  static const bool _isTestingLocally = true;

  // --- API URLS ---
  // Live URL
  static const String _liveUrl = "https://backend-linc-2.onrender.com";

  // Local URL for Android Emulator
  // (10.0.2.2 points from the emulator back to your computer's localhost)
  // static const String _localUrl = "http://10.0.2.2:3000"; // <-- OLD

  // (If testing on an iOS Simulator, you can use: "http://localhost:3000")

  static const String _localUrl = "http://localhost:3000";

  // Use adb reverse (for Android only, emulator or USB debugging):
  //Terminal Run: "adb reverse tcp:3000 tcp:3000"

  // (If testing on a REAL PHONE, use your computer's Wi-Fi IP, e.g., "http://192.168.1.5:3000")

  // The final URL the app will use
  static final String _baseUrl = _isTestingLocally ? _localUrl : _liveUrl;

  // --- TOKEN MANAGEMENT ---

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // --- CORE HTTP METHODS ---

  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (requireAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint("Auth token is null, but request requires auth.");
      }
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response, String endpoint) {
    // Check if the server response is valid JSON
    final contentType = response.headers['content-type'];
    if (contentType == null || !contentType.contains('application/json')) {
      debugPrint("API Response (Not JSON) from $endpoint: ${response.body}");
      throw ApiException(
        "Invalid response from server (Expected JSON, but got HTML or text). Please check the API endpoint and server logs.",
      );
    }

    final dynamic responseBody = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      final errorMessage =
          responseBody['message'] ?? 'An unknown server error occurred.';
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  /// Makes a POST request.
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = false,
  }) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    debugPrint("POST > $uri \nBody: $body");

    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response, endpoint);
    } on SocketException {
      throw ApiException(
        "Network error. Could not connect to the server. Is your local server running?",
      );
    } catch (e) {
      debugPrint("ApiClient POST Error hitting $uri: $e");
      if (e is ApiException) rethrow; // Re-throw our custom error
      throw ApiException("An unexpected error occurred. Please try again.");
    }
  }

  /// Makes a GET request.
  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    debugPrint("GET > $uri");

    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response, endpoint);
    } on SocketException {
      throw ApiException(
        "Network error. Could not connect to the server. Is your local server running?",
      );
    } catch (e) {
      debugPrint("ApiClient GET Error hitting $uri: $e");
      if (e is ApiException) rethrow;
      throw ApiException("An unexpected error occurred. Please try again.");
    }
  }

  /// Makes a PUT request (for updating).
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    debugPrint("PUT > $uri \nBody: $body");

    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response, endpoint);
    } on SocketException {
      throw ApiException(
        "Network error. Could not connect to the server. Is your local server running?",
      );
    } catch (e) {
      debugPrint("ApiClient PUT Error hitting $uri: $e");
      if (e is ApiException) rethrow;
      throw ApiException("An unexpected error occurred. Please try again.");
    }
  }

  /// Makes a DELETE request.
  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    debugPrint("DELETE > $uri");

    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.delete(uri, headers: headers);
      return _handleResponse(response, endpoint);
    } on SocketException {
      throw ApiException(
        "Network error. Could not connect to the server. Is your local server running?",
      );
    } catch (e) {
      debugPrint("ApiClient DELETE Error hitting $uri: $e");
      if (e is ApiException) rethrow;
      throw ApiException("An unexpected error occurred. Please try again.");
    }
  }
}
