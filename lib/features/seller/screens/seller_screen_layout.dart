import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/auth/login_screen.dart';
import 'package:tazto/features/seller/screens/dashboard/seller_orders_page.dart';
import 'package:tazto/features/seller/screens/dashboard/seller_products_page.dart';
import 'package:tazto/features/seller/screens/dashboard/seller_store_onboarding_screen.dart';
import 'package:tazto/features/seller/screens/profile/seller_settings_page.dart';
import 'package:tazto/providers/login_provider.dart';
import 'package:tazto/providers/seller_provider.dart';

import 'dashboard/seller_dashboard_page.dart';

/// This is the new main layout for the Seller app, based on your UI design.
/// It uses a BottomNavigationBar and now handles the new seller onboarding flow.
class SellerLayout extends StatefulWidget {
  const SellerLayout({super.key});

  @override
  State<SellerLayout> createState() => _SellerLayoutState();
}

class _SellerLayoutState extends State<SellerLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SellerDashboardPage(),
    const SellerProductsPage(),
    const SellerOrdersPage(),
    const SellerSettingsPage(),
    // We will add Payments and Analytics pages here later
  ];

  final List<String> _titles = [
    'Dashboard',
    'My Products',
    'Orders',
    'Settings',
  ];

  // --- REMOVED initState fetching logic ---
  // The provider now handles this, triggered by LoginProvider

  @override
  Widget build(BuildContext context) {
    final sellerProvider = context.watch<SellerProvider>();
    final storeName = sellerProvider.store?.storeName ?? 'Kirana Partner';

    // --- NEW: Onboarding Logic ---
    // This is the "gatekeeper" you described.
    if (sellerProvider.isLoadingStore) {
      // Show a full-screen loader while checking for a store
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (sellerProvider.store == null) {
      // If loading is done and store is still null (e.g., 404 error),
      // show the Create Store onboarding page.
      return const CreateStorePage();
    }
    // --- END: Onboarding Logic ---

    // If we get here, it means sellerProvider.store is NOT null,
    // so we can show the main app.
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        // A simple hamburger menu icon, though the main nav is the bottom bar
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      // Side drawer (as shown in Image 13)
      drawer: _buildAppDrawer(context, storeName),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary.withOpacity(0.7),
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Builds the side drawer based on Image 13
  Widget _buildAppDrawer(BuildContext context, String storeName) {
    final provider = context.read<LoginProvider>();

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Store Open',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: _currentIndex == 0,
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Products'),
            selected: _currentIndex == 1,
            onTap: () {
              setState(() => _currentIndex = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Orders'),
            selected: _currentIndex == 2,
            onTap: () {
              setState(() => _currentIndex = 2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            selected: _currentIndex == 3,
            onTap: () {
              setState(() => _currentIndex = 3);
              Navigator.pop(context);
            },
          ),
          // --- Placeholders for future pages ---
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('Analytics'),
            onTap: () {
              // TODO: Navigate to Analytics page
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment_outlined),
            title: const Text('Payments'),
            onTap: () {
              // TODO: Navigate to Payments page
            },
          ),
          ListTile(
            leading: const Icon(Icons.message_outlined),
            title: const Text('Messages'),
            trailing: const CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Text(
                '3',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            onTap: () {
              // TODO: Navigate to Messages page
            },
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              // --- 2. REPLACE THIS ONTAP ---
              // First, pop the drawer so it's not open during the transition
              Navigator.pop(context);

              // Call the provider's logout method to clear all data
              provider.logout(context);

              // Then, navigate to the LoginPage and remove all other screens
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
              // --- END OF FIX ---
            },
          ),
        ],
      ),
    );
  }
}
