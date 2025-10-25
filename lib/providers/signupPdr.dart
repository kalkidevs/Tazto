import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';

class SignupProvider with ChangeNotifier {
  final AuthApi _authApi = AuthApi();

  bool isLoading = false;
  String? errorMessage;

  // This boolean state is controlled by the RoleToggle widget on the UI.
  // Defaults to true, meaning "Customer" is selected initially.
  bool isCustomerSignup = true;

  /// Toggles the role for registration between "Customer" and "Seller".
  void toggleSignupRole(bool isCustomer) {
    if (isCustomerSignup == isCustomer) return;
    isCustomerSignup = isCustomer;
    notifyListeners();
  }

  /// Registers a new user with the role selected in the UI.
  Future<bool> register({
    required String name, // <-- ADDED: 'name' is now required
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // Determine the role string and format it as a list
    final List<String> selectedRoles = [
      isCustomerSignup ? "customer" : "seller",
    ];

    try {
      // Call the API with all required fields
      await _authApi.register(
        name: name, // <-- ADDED: Pass the name
        email: email,
        password: password,
        roles: selectedRoles, // <-- CHANGED: 'role' is now 'roles' (a list)
      );

      // On success, clear loading state and return true.
      isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      // Handle specific API errors (e.g., "Email already exists").
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Handle unexpected errors.
      debugPrint("Signup Provider Error: ${e.toString()}");
      errorMessage = "An unexpected error occurred during signup.";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
