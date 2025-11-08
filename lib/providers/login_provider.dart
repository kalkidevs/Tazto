import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/api/api_client.dart';
import 'package:tazto/api/auth_api.dart';
import 'package:tazto/providers/customer_provider.dart'; // Import provider

class LoginProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();

  bool isLoading = false;
  String? errorMessage;
  String? token;

  String? sessionRole;
  bool isCustomerLogin = true;

  void toggleLoginRole(bool isCustomer) {
    if (isCustomerLogin == isCustomer) return;
    isCustomerLogin = isCustomer;
    notifyListeners();
  }

  Future<bool> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final String selectedRole = isCustomerLogin ? "customer" : "seller";

    try {
      final data = await _authApi.login(email: email, password: password);

      if (data.containsKey('token') &&
          data.containsKey('user') &&
          data['user'] is Map) {
        final userMap = data['user'] as Map<String, dynamic>;
        if (userMap.containsKey('roles') && userMap['roles'] is List) {
          final List<String> userRoles = List<String>.from(userMap['roles']);

          if (userRoles.contains(selectedRole)) {
            // Role is valid
            token = data["token"] as String;
            sessionRole = selectedRole;

            // *** NEW: SET THE USER IN CUSTOM*S**
            // Use context.read() to get CustomerProvider without listening
            // This will trigger fetchUserProfile(), which in turn fetches
            // products, cart, and orders.
            context.read<CustomerProvider>().setUser(userMap);
            // ***********************************************

            isLoading = false;
            notifyListeners();
            return true;
          } else {
            // Role validation failed
            throw ApiException(
              "Access denied. You do not have a '$selectedRole' account.",
            );
          }
        } else {
          throw Exception("Login error: 'roles' key not found.");
        }
      } else {
        throw Exception("Login error: Invalid response from server.");
      }
    } on ApiException catch (e) {
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

  /// NEW: Logout method
  /// This handles clearing the auth token and all user data.
  Future<void> logout(BuildContext context) async {
    try {
      // 1. Call AuthApi to delete the token from secure storage
      await _authApi.logout();
    } catch (e) {
      // Log if deletion fails, but proceed with local logout anyway
      debugPrint("Error deleting token from storage: $e");
    }

    // 2. Clear this provider's state
    token = null;
    sessionRole = null;

    // 3. Clear the CustomerProvider's state (user data, cart, orders)
    try {
      // Use context.read() as we're in a method, not rebuilding
      context.read<CustomerProvider>().clearUser();
    } catch (e) {
      debugPrint("Error clearing CustomerProvider: $e");
    }

    // 4. Notify all listeners that auth state has changed
    notifyListeners();
  }
}
