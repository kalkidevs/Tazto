import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazto/api/api_client.dart';
import 'package:tazto/api/auth_api.dart';
import 'package:tazto/api/user_api.dart'; // Added UserApi
import 'package:tazto/providers/customer_provider.dart';
import 'package:tazto/providers/seller_provider.dart';

enum LoginStatus { loginSuccess, firstTimeLogin, loginFailed }

class LoginProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();
  final UserApi _userApi = UserApi(); // Needed to fetch role on startup

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

  /// --- NEW: Check Login Status on App Start ---
  /// This determines where the user goes when they open the app.
  Future<String> checkLoginStatus(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('jwt_token');

    if (storedToken == null || storedToken.isEmpty) {
      return 'LOGIN'; // No token, go to login screen
    }

    token = storedToken;
    notifyListeners();

    try {
      // 1. Fetch User Profile to get Roles (using the stored token)
      // We use UserApi because it works for both roles to get basic info
      final userData = await _userApi.getMyProfile();

      // 2. Determine Role
      final List<dynamic> roles = userData['roles'] ?? [];

      // 3. Hydrate the correct provider based on role
      if (roles.contains('seller')) {
        sessionRole = 'seller';
        // Initialize Seller Data
        if (context.mounted) {
          await context.read<SellerProvider>().fetchStoreProfile();
        }
        return 'SELLER_HOME';
      } else {
        sessionRole = 'customer';
        // Initialize Customer Data
        if (context.mounted) {
          // Pass the user data we already fetched to save a network call
          context.read<CustomerProvider>().setUser(userData);
        }

        // Check privacy consent
        final bool hasConsented =
            prefs.getBool('has_consented_to_privacy') ?? false;
        return hasConsented ? 'CUSTOMER_HOME' : 'PRIVACY_CONSENT';
      }
    } catch (e) {
      debugPrint("Auto-login failed: $e");
      // Token might be expired or invalid
      await logout(context);
      return 'LOGIN';
    }
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
      final data = await _authApi.login(email: email, password: password);

      if (data.containsKey('token') &&
          data.containsKey('user') &&
          data['user'] is Map) {
        final userMap = data['user'] as Map<String, dynamic>;
        if (userMap.containsKey('roles') && userMap['roles'] is List) {
          final List<String> userRoles = List<String>.from(userMap['roles']);

          if (userRoles.contains(selectedRole)) {
            token = data["token"] as String;
            sessionRole = selectedRole;

            final customerProvider = context.read<CustomerProvider>();
            final sellerProvider = context.read<SellerProvider>();

            if (selectedRole == 'customer') {
              sellerProvider.clearSellerData();
              customerProvider.setUser(userMap);

              final prefs = await SharedPreferences.getInstance();
              final bool hasConsented =
                  prefs.getBool('has_consented_to_privacy') ?? false;

              isLoading = false;
              notifyListeners();

              return hasConsented
                  ? LoginStatus.loginSuccess
                  : LoginStatus.firstTimeLogin;
            } else {
              customerProvider.clearUser();
              // --- CRITICAL: Fetch store profile immediately upon login ---
              await sellerProvider.fetchStoreProfile();

              isLoading = false;
              notifyListeners();
              return LoginStatus.loginSuccess;
            }
          } else {
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
      return LoginStatus.loginFailed;
    } catch (e) {
      debugPrint("Login Provider Error: ${e.toString()}");
      errorMessage = "An unexpected error occurred.";
      isLoading = false;
      notifyListeners();
      return LoginStatus.loginFailed;
    }
  }
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authApi.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll("Exception: ", "");
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _authApi.logout();
    } catch (e) {
      debugPrint("Error deleting token from storage: $e");
    }

    token = null;
    sessionRole = null;

    try {
      if (context.mounted) {
        context.read<CustomerProvider>().clearUser();
        context.read<SellerProvider>().clearSellerData();
      }
    } catch (e) {
      debugPrint("Error clearing providers: $e");
    }

    notifyListeners();
  }
}
