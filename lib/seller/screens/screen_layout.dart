// lib/screens/seller/seller_layout.dart
import 'package:flutter/material.dart';
import 'package:tazto/seller/screens/profile/seller_settings_page.dart';

import 'dashboard/seller_dashboard_page.dart';
import 'dashboard/seller_orders_page.dart';
import 'dashboard/seller_products_page.dart';

class SellerLayout extends StatefulWidget {
  const SellerLayout({super.key});

  @override
  State<SellerLayout> createState() => _SellerLayoutState();
}

class _SellerLayoutState extends State<SellerLayout> {
  int _currentIndex = 0;
  final _pages = const [
    SellerDashboardPage(),
    SellerProductsPage(),
    SellerOrdersPage(),
    SellerSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        centerTitle: true,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),

    );
  }
}
