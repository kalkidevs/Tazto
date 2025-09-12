import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterProvider with ChangeNotifier {
  bool isCustomer = true;
  bool isLoading = false;
  String? errorMessage;

  void toggleRole(bool customer) {
    if (isCustomer == customer) return;
    isCustomer = customer;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final uri = Uri.parse('https://backendlinc.up.railway.app/api/auth/register');
    final body = jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': isCustomer ? 'customer' : 'seller',
    });

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      isLoading = false;

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(resp.body);
        errorMessage = data['message'] ?? 'Registration failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'Network error, please try again';
      notifyListeners();
      return false;
    }
  }
}
