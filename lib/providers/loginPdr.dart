// lib/providers/loginPdr.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? token;
  String? role; // <-- add this
  bool isCustomerLogin = true; // User's selected login role

  void toggleLoginRole(bool isCustomer) {
    if (isCustomerLogin == isCustomer) return;
    isCustomerLogin = isCustomer;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final uri = Uri.parse("https://backendlinc.up.railway.app/api/auth/login");
    final body = jsonEncode({"email": email, "password": password});

    try {
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      isLoading = false;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        // store token + role
        token = data["token"] as String;
        role = data["user"]["role"] as String; // <-- extract role

        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(resp.body);
        errorMessage = data["message"] ?? "Login failed";
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      errorMessage = "Something went wrong";
      notifyListeners();
      return false;
    }
  }
}
