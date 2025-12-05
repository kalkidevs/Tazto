import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazto/auth/login_screen.dart';
import 'package:tazto/main.dart'; // Import main to access navigatorKey

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
  // --- CONFIGURATION ---
  static const bool _isTestingLocally = true;
  static const String _liveUrl = "https://backend-linc-2.onrender.com";
  static const String _localUrl = "http://192.168.0.101:3000";
  static final String _baseUrl = _isTestingLocally ? _localUrl : _liveUrl;
  static const Duration _timeout = Duration(seconds: 30);

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
      }
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response, String endpoint) {
    // --- GLOBAL 401 HANDLER ---
    if (response.statusCode == 401) {
      debugPrint("⚠️ 401 Unauthorized detected. Logging out...");

      // 1. Delete the invalid token
      deleteToken();

      // 2. Force navigate to Login Screen using global key
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false, // Clear all previous routes
        );

        // Optional: Show a snackbar explaining why
        // We can't easily show a snackbar without a Scaffold context,
        // so we just redirect for now.
      }

      throw ApiException("Session expired. Please login again.", 401);
    }

    final contentType = response.headers['content-type'];
    if (contentType == null || !contentType.contains('application/json')) {
      throw ApiException("Invalid response from server.", response.statusCode);
    }

    final dynamic responseBody = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      final errorMessage = responseBody['message'] ?? 'An unknown server error occurred.';
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool requireAuth = false}) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    debugPrint("POST > $uri");

    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);

      return _handleResponse(response, endpoint);
    } on SocketException {
      throw ApiException("Network error. Cannot connect to server.");
    } on TimeoutException {
      throw ApiException("Connection timed out.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("An unexpected error occurred: $e");
    }
  }

  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    debugPrint("GET > $uri");

    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http.get(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response, endpoint);
    } on SocketException {
      throw ApiException("Network error. Cannot connect to server.");
    } on TimeoutException {
      throw ApiException("Connection timed out.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Error: $e");
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    debugPrint("PUT > $uri");

    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response, endpoint);
    } on SocketException {
      throw ApiException("Network error. Cannot connect to server.");
    } on TimeoutException {
      throw ApiException("Connection timed out.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Error: $e");
    }
  }

  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    final uri = Uri.parse(_baseUrl + endpoint);
    debugPrint("DELETE > $uri");

    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .delete(uri, headers: headers)
          .timeout(_timeout);
      return _handleResponse(response, endpoint);
    } on SocketException {
      throw ApiException("Network error. Cannot connect to server.");
    } on TimeoutException {
      throw ApiException("Connection timed out.");
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException("Error: $e");
    }
  }
}