import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazto/api/api_client.dart';
import 'package:tazto/api/auth_api.dart';
import 'package:tazto/providers/customer_provider.dart';
import 'package:tazto/providers/seller_provider.dart'; // Import provider

enum LoginStatus {
  loginSuccess,
  firstTimeLogin, // For privacy consent
  loginFailed,
}

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

  Future<LoginStatus> login(
    BuildContext context,
    String email,
    String password,
  ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final String selectedRole = isCustomerLogin ? "customer" : "seller";

    try {
      // This step logs in AND saves the token via AuthApi
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

            // Use context.read() to get providers
            final customerProvider = context.read<CustomerProvider>();
            final sellerProvider = context.read<SellerProvider>();

            if (selectedRole == 'customer') {
              // User is a customer
              sellerProvider.clearSellerData(); // Clear any old seller data
              customerProvider.setUser(
                userMap,
              ); // This triggers all customer data fetching

              // --- NEW: Privacy Consent Check ---
              final prefs = await SharedPreferences.getInstance();
              final bool hasConsented =
                  prefs.getBool('has_consented_to_privacy') ?? false;

              isLoading = false;
              notifyListeners();

              if (hasConsented) {
                return LoginStatus.loginSuccess;
              } else {
                return LoginStatus.firstTimeLogin;
              }
              // --- END NEW ---
            } else {
              // User is a seller
              customerProvider
                  .clearUser(); // Clear any old customer data (this NO LONGER deletes the token)
              sellerProvider
                  .fetchStoreProfile(); // This triggers seller data fetching

              isLoading = false;
              notifyListeners();
              return LoginStatus
                  .loginSuccess; // Sellers don't need the privacy screen
            }
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
      return LoginStatus.loginFailed; // --- UPDATED ---
    } catch (e) {
      debugPrint("Login Provider Error: ${e.toString()}");
      errorMessage = "An unexpected error occurred.";
      isLoading = false;
      notifyListeners();
      return LoginStatus.loginFailed; // --- UPDATED ---
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
      context
          .read<SellerProvider>()
          .clearSellerData(); // --- ADDED: Clear SellerProvider ---
    } catch (e) {
      debugPrint("Error clearing CustomerProvider: $e");
    }

    // 4. Notify all listeners that auth state has changed
    notifyListeners();
  }
}
