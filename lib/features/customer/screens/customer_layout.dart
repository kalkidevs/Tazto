// lib/screens/customer/customer_layout.dart
import 'package:flutter/material.dart';

import 'cart_page.dart';
import 'customer_profile_page.dart'; // Import the ProfilePage
import 'home_page.dart';
import 'search_page.dart';

class CustomerLayout extends StatefulWidget {
  const CustomerLayout({super.key});

  @override
  State<CustomerLayout> createState() => _CustomerLayoutState();
}

class _CustomerLayoutState extends State<CustomerLayout> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final GlobalKey<CustomerProfilePageState> _profilePageKey =
      GlobalKey<CustomerProfilePageState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onAddressTap: () => changeTab(3, autoShowAddress: true)),
      const SearchPage(),
      const CartPage(),
      CustomerProfilePage(key: _profilePageKey),
    ];
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
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
