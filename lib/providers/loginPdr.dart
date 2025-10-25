import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';

class LoginProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();

  bool isLoading = false;
  String? errorMessage;
  String? token;

  // This now stores the single, validated role for the current session.
  String? sessionRole;

  // This boolean state is controlled by the RoleToggle widget on the UI.
  bool isCustomerLogin = true;

  void toggleLoginRole(bool isCustomer) {
    if (isCustomerLogin == isCustomer) return;
    isCustomerLogin = isCustomer;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // Determine the role the user is trying to log in as.
    final String selectedRole = isCustomerLogin ? "customer" : "seller";

    try {
      final data = await _authApi.login(email: email, password: password);

      if (data.containsKey('token') &&
          data.containsKey('user') &&
          data['user'] is Map) {
        final userMap = data['user'] as Map<String, dynamic>;

        // The API returns a list of all roles the user has.
        if (userMap.containsKey('roles') && userMap['roles'] is List) {
          final List<String> userRoles = List<String>.from(userMap['roles']);

          // **ROLE VALIDATION LOGIC**
          // Check if the user's list of roles contains the role they selected on the toggle.
          if (userRoles.contains(selectedRole)) {
            // Success! The user has the selected role.
            token = data["token"] as String;
            sessionRole =
                selectedRole; // Store the validated role for this session.

            isLoading = false;
            notifyListeners();
            return true;
          } else {
            // **Validation Failed:** The user does not have the selected role.
            // Example: User chose "Seller" but their account only has the "customer" role.
            throw ApiException(
              "Access denied. You do not have a '$selectedRole' account.",
            );
          }
        } else {
          throw Exception("Login error: 'roles' key not found in user object.");
        }
      } else {
        throw Exception("Login error: Invalid response structure from server.");
      }
    } on ApiException catch (e) {
      // Handles both API errors and our custom role validation error.
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Login Provider Error: ${e.toString()}");
      errorMessage = "An unexpected error occurred.";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
