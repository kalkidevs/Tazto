import 'package:flutter/material.dart';
import 'package:tazto/api/seller_api.dart';
import 'package:tazto/features/seller/models/seller_analytics_model.dart';
import 'package:tazto/features/seller/models/seller_order_model.dart';
import 'package:tazto/features/seller/models/seller_product_model.dart';
import 'package:tazto/features/seller/models/seller_store_model.dart';
import 'package:tazto/features/seller/screens/upload/product_upload_page.dart';

class SellerProvider with ChangeNotifier {
  final SellerApi _sellerApi = SellerApi();

  // State variables
  Store? _store;
  SellerAnalytics? _analytics;
  List<SellerProduct> _products = [];
  List<SellerOrder> _orders = [];

  bool _isLoadingStore = false;
  bool _isLoadingAnalytics = false;
  bool _isLoadingProducts = false;
  bool _isLoadingOrders = false;

  String? _storeError;
  String? _analyticsError;
  String? _productsError;
  String? _ordersError;

  // Getters
  Store? get store => _store;

  SellerAnalytics? get analytics => _analytics;

  List<SellerProduct> get products => _products;

  List<SellerOrder> get orders => _orders;

  bool get isLoadingStore => _isLoadingStore;

  bool get isLoadingAnalytics => _isLoadingAnalytics;

  bool get isLoadingProducts => _isLoadingProducts;

  bool get isLoadingOrders => _isLoadingOrders;

  String? get storeError => _storeError;

  String? get analyticsError => _analyticsError;

  String? get productsError => _productsError;

  String? get ordersError => _ordersError;

  /// Fetches the seller's store profile.
  /// This is the first thing that should be called upon seller login.
  Future<void> fetchStoreProfile() async {
    if (_isLoadingStore) return;
    _isLoadingStore = true;
    _storeError = null;
    notifyListeners();

    try {
      final storeData = await _sellerApi.getMyStore();
      _store = Store.fromJson(storeData);
      _storeError = null;
      // --- ADDED: If store is found, fetch other data ---
      _fetchAllSellerData();
      // --------------------------------------------------
    } catch (e) {
      debugPrint("fetchStoreProfile Error: $e");
      // --- ADDED: Handle 404 (Store not found) gracefully ---
      if (e.toString().contains('404') ||
          e.toString().contains('Seller profile not found')) {
        _storeError = 'NOT_FOUND'; // Special code for the UI to check
        _store = null;
      } else {
        _storeError = e.toString();
        _store = null;
      }
      // ------------------------------------------------------
    } finally {
      _isLoadingStore = false;
      notifyListeners();
    }
  }

  /// NEW: Helper to fetch all data *after* store is confirmed
  Future<void> _fetchAllSellerData() async {
    // Run all fetches in parallel
    Future.wait([fetchDashboardAnalytics(), fetchProducts(), fetchOrders()]);
  }

  /// NEW: Creates the seller's store profile.
  Future<bool> createStoreProfile({
    required String storeName,
    required String address,
    required String pincode,
    required double lat,
    required double lng,
  }) async {
    _isLoadingStore = true; // Use the main store loader
    _storeError = null;
    notifyListeners();

    try {
      final newStoreData = await _sellerApi.createStore(
        storeName: storeName,
        address: address,
        pincode: pincode,
        lat: lat,
        lng: lng,
      );
      _store = Store.fromJson(newStoreData); // Set the new store
      _storeError = null;

      // --- ADDED: Fetch other data now that store is created ---
      _fetchAllSellerData();
      return true;
      // --------------------------------------------------------
    } catch (e) {
      debugPrint("createStoreProfile Error: $e");
      _storeError = e.toString();
      _store = null; // Stay null on error
      notifyListeners(); // Notify to show error
      return false;
    } finally {
      _isLoadingStore = false;
      notifyListeners(); // Notify to stop loading
    }
  }

  /// Fetches all dashboard analytics data.
  Future<void> fetchDashboardAnalytics() async {
    if (_isLoadingAnalytics) return;
    _isLoadingAnalytics = true;
    _analyticsError = null;
    notifyListeners();

    try {
      final analyticsData = await _sellerApi.getAnalytics();
      _analytics = SellerAnalytics.fromJson(analyticsData);
      _analyticsError = null;
    } catch (e) {
      debugPrint("fetchDashboardAnalytics Error: $e");
      _analyticsError = e.toString();
      _analytics = null;
    } finally {
      _isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  /// Fetches the seller's product list.
  Future<void> fetchProducts() async {
    if (_isLoadingProducts) return;
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final data = await _sellerApi.getMyProducts();
      final List<dynamic> productList = (data['products'] is List)
          ? data['products'] as List<dynamic>
          : [];
      _products = productList
          .map((json) => SellerProduct.fromJson(json as Map<String, dynamic>))
          .toList();
      _productsError = null;
    } catch (e) {
      debugPrint("fetchProducts Error: $e");
      _productsError = e.toString();
      _products = [];
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Fetches the seller's order list.
  Future<void> fetchOrders() async {
    if (_isLoadingOrders) return;
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      final data = await _sellerApi.getMyOrders();
      final List<dynamic> orderList = (data['orders'] is List)
          ? data['orders'] as List<dynamic>
          : [];
      _orders = orderList
          .map((json) => SellerOrder.fromJson(json as Map<String, dynamic>))
          .toList();
      _ordersError = null;
    } catch (e) {
      debugPrint("fetchOrders Error: $e");
      _ordersError = e.toString();
      _orders = [];
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  /// Adds multiple products from a CSV/XLSX file.
  Future<bool> bulkAddProducts(List<ParsedProduct> parsedProducts) async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      // Convert ParsedProduct models to simple Maps
      final productMaps = parsedProducts.map((p) => p.toJson()).toList();

      // Call the API
      final response = await _sellerApi.bulkAddProducts(productMaps);
      debugPrint("Bulk add response: ${response['message']}");

      // Refresh the entire product list from the server
      await fetchProducts();
      _productsError = null;
      return true;
    } catch (e) {
      debugPrint("bulkAddProducts Error: $e");
      _productsError = e.toString();
      _isLoadingProducts = false;
      notifyListeners();
      return false;
    }
  }

  /// Adds a single new product.
  Future<bool> addProduct(Map<String, dynamic> productData) async {
    // Use _isLoadingProducts to show loading on the product list page
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final newProductData = await _sellerApi.addProduct(productData);
      final newProduct = SellerProduct.fromJson(newProductData);
      _products.insert(0, newProduct); // Add to start of list
      _productsError = null;
      return true;
    } catch (e) {
      debugPrint("addProduct Error: $e");
      _productsError = e.toString();
      return false;
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Updates the seller's store profile.
  Future<bool> updateStoreProfile(Map<String, dynamic> updates) async {
    try {
      final updatedStoreData = await _sellerApi.updateStore(updates);
      _store = Store.fromJson(updatedStoreData);
      _storeError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("updateStoreProfile Error: $e");
      _storeError = "Failed to update: $e";
      notifyListeners();
      return false;
    }
  }

  /// Updates the status of a specific order.
  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    _ordersError = null;
    notifyListeners(); // We don't set a loading flag, UI handles it

    try {
      final updatedOrderData = await _sellerApi.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      final updatedOrder = SellerOrder.fromJson(updatedOrderData);

      // Find and update the order in the local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("updateOrderStatus Error: $e");
      _ordersError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clears all seller data on logout.
  void clearSellerData() {
    _store = null;
    _analytics = null;
    _products = [];
    _orders = [];
    _isLoadingStore = false;
    _isLoadingAnalytics = false;
    _isLoadingProducts = false;
    _isLoadingOrders = false;
    _storeError = null;
    _analyticsError = null;
    _productsError = null;
    _ordersError = null;
    notifyListeners();
  }
}
