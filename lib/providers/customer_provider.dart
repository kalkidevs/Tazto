import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/product_provider.dart';
import '../customer/models/addressMdl.dart';
import '../customer/models/cart_itemMdl.dart';
import '../customer/models/orderMdl.dart';
import '../customer/models/productMdl.dart';
import '../customer/models/userMdl.dart';

class CustomerProvider with ChangeNotifier {
  final ProductApi _productApi = ProductApi();

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

  List<Product> _products = [];
  bool _isLoadingProducts = false;
  String? _productsError;
  final List<CartItem> _cart = [];
  final List<Order> _orders = [];

  // Getters
  User get user => _user;

  List<Product> get products => [..._products];

  bool get isLoadingProducts => _isLoadingProducts;

  String? get productsError => _productsError;

  List<CartItem> get cart => [..._cart];

  List<Order> get orders => [..._orders];

  /// Fetches all products from the backend. This method now works correctly
  /// because the underlying API service and model have been updated.
  Future<void> fetchProducts() async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final List<dynamic> productData = await _productApi.getAllProducts();

      _products = productData
          .map((data) => Product.fromJson(data as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _productsError = "Server error: ${e.message}";
    } catch (e) {
      debugPrint("CustomerProvider fetchProducts Error: $e");
      _productsError = "An unexpected error occurred while fetching products.";
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // --- Cart and Order Methods ---

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

  void placeOrder() {
    if (_cart.isEmpty) return;
    final total = _cart.fold<double>(
      0,
      (sum, c) => sum + c.quantity * c.product.price,
    );

    _orders.insert(
      0,
      Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        items: List.from(_cart),
        total: total,
        date: DateTime.now(),
      ),
    );
    _cart.clear();
    notifyListeners();
  }
}
