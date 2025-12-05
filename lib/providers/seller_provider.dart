import 'package:flutter/foundation.dart'; // Import foundation for compute
import 'package:flutter/material.dart';
import 'package:tazto/api/seller_api.dart';
import 'package:tazto/features/seller/models/seller_analytics_model.dart';
import 'package:tazto/features/seller/models/seller_order_model.dart';
import 'package:tazto/features/seller/models/seller_product_model.dart';
import 'package:tazto/features/seller/models/seller_store_model.dart';
import 'package:tazto/features/seller/screens/upload/product_upload_page.dart';

// --- TOP-LEVEL FUNCTIONS FOR BACKGROUND PROCESSING ---
List<SellerProduct> _parseProductsInIsolate(List<dynamic> rawList) {
  return rawList
      .map((json) => SellerProduct.fromJson(json as Map<String, dynamic>))
      .toList();
}

List<SellerOrder> _parseOrdersInIsolate(List<dynamic> rawList) {
  return rawList
      .map((json) => SellerOrder.fromJson(json as Map<String, dynamic>))
      .toList();
}

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
  Future<void> fetchStoreProfile() async {
    if (_isLoadingStore) return;
    _isLoadingStore = true;
    _storeError = null;
    notifyListeners();

    try {
      final storeData = await _sellerApi.getMyStore();
      _store = Store.fromJson(storeData);
      _storeError = null;
      _fetchAllSellerData();
    } catch (e) {
      debugPrint("fetchStoreProfile Error: $e");
      if (e.toString().contains('404') ||
          e.toString().contains('Seller profile not found')) {
        _storeError = 'NOT_FOUND';
        _store = null;
      } else {
        _storeError = e.toString();
        _store = null;
      }
    } finally {
      _isLoadingStore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAllSellerData() async {
    Future.wait([fetchDashboardAnalytics(), fetchProducts(), fetchOrders()]);
  }

  Future<bool> createStoreProfile({
    required String storeName,
    required String address,
    required String pincode,
    required double lat,
    required double lng,
  }) async {
    _isLoadingStore = true;
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
      _store = Store.fromJson(newStoreData);
      _storeError = null;
      _fetchAllSellerData();
      return true;
    } catch (e) {
      debugPrint("createStoreProfile Error: $e");
      _storeError = e.toString();
      _store = null;
      notifyListeners();
      return false;
    } finally {
      _isLoadingStore = false;
      notifyListeners();
    }
  }

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

  Future<void> fetchProducts() async {
    // Guard clause: prevents multiple simultaneous fetches
    if (_isLoadingProducts) return;

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final data = await _sellerApi.getMyProducts();
      final List<dynamic> productList = (data['products'] is List)
          ? data['products'] as List<dynamic>
          : [];

      // Parse in background to avoid UI jank
      _products = await compute(_parseProductsInIsolate, productList);

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

      _orders = await compute(_parseOrdersInIsolate, orderList);

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

  // --- BULK UPLOAD LOGIC ---
  Future<bool> bulkAddProducts(List<ParsedProduct> parsedProducts) async {
    // 1. Set loading to true initially
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      const int batchSize = 50;
      final productMaps = parsedProducts.map((p) => p.toJson()).toList();

      int totalUploaded = 0;
      List<String> errors = [];

      for (var i = 0; i < productMaps.length; i += batchSize) {
        final end = (i + batchSize < productMaps.length)
            ? i + batchSize
            : productMaps.length;
        final batch = productMaps.sublist(i, end);

        debugPrint("Uploading batch: $i to $end");

        try {
          await _sellerApi.bulkAddProducts(batch);
          totalUploaded += batch.length;
        } catch (e) {
          debugPrint("Batch failed: $e");
          errors.add("Batch ${i ~/ batchSize + 1}: Failed to upload");
        }
      }

      if (errors.isNotEmpty) {
        throw Exception("Partial upload completed. Errors in some batches.");
      }

      // --- FIX: Reset loading state BEFORE calling fetch functions ---
      // We must set this to false because fetchProducts() has a guard clause:
      // 'if (_isLoadingProducts) return;'
      // If we don't set it to false here, fetchProducts will think a load is
      // already in progress and return immediately, leaving the UI stuck.
      _isLoadingProducts = false;

      // 2. Refresh Products & Analytics
      // Using Future.wait to update both the product list and the dashboard stats simultaneously
      await Future.wait([fetchProducts(), fetchDashboardAnalytics()]);

      return true;
    } catch (e) {
      debugPrint("bulkAddProducts Error: $e");
      _productsError = e.toString();
      _isLoadingProducts = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addProduct(Map<String, dynamic> productData) async {
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final newProductData = await _sellerApi.addProduct(productData);
      final newProduct = SellerProduct.fromJson(newProductData);
      _products.insert(0, newProduct);

      // Also update analytics after adding single product
      fetchDashboardAnalytics();

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

  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    _ordersError = null;
    notifyListeners();

    try {
      final updatedOrderData = await _sellerApi.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      final updatedOrder = SellerOrder.fromJson(updatedOrderData);

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
      }

      // Refresh analytics as order status change affects revenue/counts
      fetchDashboardAnalytics();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("updateOrderStatus Error: $e");
      _ordersError = e.toString();
      notifyListeners();
      return false;
    }
  }

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
