// lib/providers/customer_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http show get;
import 'package:tazto/customer/models/addressMdl.dart';
import 'package:tazto/customer/models/categoryMdl.dart';
import 'package:tazto/customer/models/userMdl.dart';

import '../customer/models/cart_itemMdl.dart';
import '../customer/models/orderMdl.dart';
import '../customer/models/productMdl.dart';

class CustomerProvider with ChangeNotifier {
  // Sample user
  User _user = User(
    id: 'u1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '1234567890',
    addresses: [
      Address(
        id: 'a1',
        label: 'Home',
        street: '221B Baker St',
        city: 'London',
        state: 'Greater London',
        pincode: 'NW16XE',
      ),
    ],
  );

  // Categories
  final List<Category> _categories = [
    Category(id: 'c1', name: 'Fruits', imageUrl: 'https://i.imgur.com/1.jpg'),
    Category(id: 'c2', name: 'Vegetables', imageUrl: 'https://i.imgur.com/2.jpg'),
    Category(id: 'c3', name: 'Dairy', imageUrl: 'https://i.imgur.com/3.jpg'),
  ];


  // Cart
  final List<CartItem> _cart = [];

  // Orders
  final List<Order> _orders = [];

  // Getters
  User get user => _user;
  List<Category> get categories => [..._categories];
  List<Product> get products => [..._products];
  List<CartItem> get cart => [..._cart];
  List<Order> get orders => [..._orders];
  bool _isLoadingProducts = false;
  String? _productsError;
  List<Product> _products = [];

  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;
  //
  // // Category → products
  // List<Product> productsByCategory(String catId) =>
  //     _products.where((p) => p.categoryId == catId).toList();


  Future<void> fetchProducts() async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    final uri = Uri.parse('https://fakestoreapi.com/products');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final List<dynamic> list = jsonDecode(resp.body) as List<dynamic>;
        _products =
            list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _productsError = 'Server error: ${resp.statusCode}';
      }
    } catch (e) {
      _productsError = 'Network error';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // Cart operations
  void addToCart(Product prod) {
    final idx = _cart.indexWhere((c) => c.product.id == prod.id);
    if (idx >= 0) {
      _cart[idx].quantity++;
    } else {
      _cart.add(CartItem(id: DateTime.now().toString(), product: prod));
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cart.removeWhere((c) => c.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int qty) {
    final idx = _cart.indexWhere((c) => c.id == itemId);
    if (idx >= 0) {
      _cart[idx].quantity = qty;
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // Checkout → new order
  void placeOrder() {
    if (_cart.isEmpty) return;
    final total = _cart.fold<double>(
        0, (sum, c) => sum + c.quantity * c.product.price);

    _orders.insert(
      0,
      Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        items: List.from(_cart),
        total: total,
        date: DateTime.now(),
      ),
    );
    clearCart();
    notifyListeners();
  }

  // Address CRUD
  void addAddress(Address a) {
    _user.addresses.add(a);
    notifyListeners();
  }

  void updateAddress(Address a) {
    final idx = _user.addresses.indexWhere((x) => x.id == a.id);
    if (idx >= 0) _user.addresses[idx] = a;
    notifyListeners();
  }

  void deleteAddress(String addrId) {
    _user.addresses.removeWhere((x) => x.id == addrId);
    notifyListeners();
  }
}
