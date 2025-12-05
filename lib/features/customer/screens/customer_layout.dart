// lib/screens/customer/customer_layout.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/api/api_client.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/customer_provider.dart';
import 'package:tazto/widgets/permission_guard.dart';

import 'cart_page.dart';
import 'customer_orders_page.dart';
import 'customer_profile_page.dart';
import 'home_page.dart';

class CustomerLayout extends StatefulWidget {
  const CustomerLayout({super.key});

  @override
  State<CustomerLayout> createState() => CustomerLayoutState();
}

class CustomerLayoutState extends State<CustomerLayout> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final GlobalKey<CustomerProfilePageState> _profilePageKey =
      GlobalKey<CustomerProfilePageState>();
  bool _isInitializing = true;
  String? _initialError;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const CustomerOrdersPage(),
      const CartPage(),
      CustomerProfilePage(key: _profilePageKey),
    ];
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Ensure it only runs once and resets error
    setState(() {
      _isInitializing = true;
      _initialError = null;
    });
    try {
      // This single call now handles user, location, and product fetching
      await context.read<CustomerProvider>().fetchUserProfile();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _initialError = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initialError = e.toString().replaceAll("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /// Changes the tab and optionally triggers the address form
  void changeTab(int index, {bool autoShowAddress = false}) {
    setState(() => _currentIndex = index);
    if (index == 3 && autoShowAddress) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _profilePageKey.currentState?.checkAndShowAddressForm();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();

    // While provider fetches user profile
    if (_isInitializing || provider.isLoadingUser) {
      return _buildLoadingScreen("Loading your profile...");
    }

    // After user is fetched, while location is being checked
    if (provider.isLoadingLocation) {
      return _buildLoadingScreen(
        provider.currentLocationMessage ?? "Finding nearby stores...",
      );
    }

    // If any error occurred during the initial load
    if (_initialError != null) {
      return _buildErrorScreen(_initialError!);
    }

    // If no user and no error (shouldn't happen, but safe)
    if (provider.user == null) {
      return _buildErrorScreen("Could not load user profile.");
    }
    return PermissionGuard(
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          type: BottomNavigationBarType.fixed,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'My Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  /// NEW: A reusable full-screen loading widget
  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NEW: A reusable full-screen error widget
  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Initialization Failed',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInitialData, // Retry button
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
