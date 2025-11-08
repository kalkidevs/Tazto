import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tazto/features/customer/models/cart_itemMdl.dart';
import 'package:tazto/features/customer/models/customer_address_model.dart';
import 'package:tazto/features/customer/models/customer_category_model.dart';
import 'package:tazto/features/customer/models/customer_order_model.dart';
import 'package:tazto/features/customer/models/customer_product_model.dart';
import 'package:tazto/features/customer/models/customer_user_model.dart';

import '../api/api_client.dart';
import '../api/cart_api.dart';
import '../api/category_api.dart';
import '../api/order_api.dart';
import '../api/product_api_dart.dart';
import '../api/user_api.dart';

class CustomerProvider with ChangeNotifier {
  final ProductApi _productApi = ProductApi();
  final CartApi _cartApi = CartApi();
  final OrderApi _orderApi = OrderApi();
  final UserApi _userApi = UserApi();
  final CategoryApi _categoryApi = CategoryApi();

  // --- State Variables ---
  CustomerUser? _user;
  bool _isLoadingUser = false;
  String? _userError;

  // --- ADDED: Location State ---
  String? _currentLocationMessage;

  // ---------------------------

  // final List<CustomerCategory> _categories = [
  //   CustomerCategory(
  //     id: 'c1',
  //     name: 'Vegetables & Fruits',
  //     imageUrl: 'https://placehold.co/100x100/A2E4B8/A2E4B8?text=V',
  //   ),
  //   CustomerCategory(
  //     id: 'c2',
  //     name: 'Dairy & Breakfast',
  //     imageUrl: 'https://placehold.co/100x100/F5D7A4/F5D7A4?text=D',
  //   ),
  //   CustomerCategory(
  //     id: 'c3',
  //     name: 'Cold Drinks & Juices',
  //     imageUrl: 'https://placehold.co/100x100/A4DFF5/A4DFF5?text=C',
  //   ),
  //   CustomerCategory(
  //     id: 'c4',
  //     name: 'Instant & Frozen Food',
  //     imageUrl: 'https://placehold.co/100x100/A4F5E6/A4F5E6?text=I',
  //   ),
  //   CustomerCategory(
  //     id: 'c5',
  //     name: 'Tea & Coffee',
  //     imageUrl: 'https://placehold.co/100x100/E1CBA4/E1CBA4?text=T',
  //   ),
  //   CustomerCategory(
  //     id: 'c6',
  //     name: 'Atta, Rice & Dal',
  //     imageUrl: 'https://placehold.co/100x100/F5EBA4/F5EBA4?text=A',
  //   ),
  //   CustomerCategory(
  //     id: 'c7',
  //     name: 'Masala, Oil & Dry Fruits',
  //     imageUrl: 'https://placehold.co/100x100/F5A4A4/F5A4A4?text=M',
  //   ),
  //   CustomerCategory(
  //     id: 'c8',
  //     name: 'Chicken, Meat & Fish',
  //     imageUrl: 'https://placehold.co/100x100/F5B0A4/F5B0A4?text=C',
  //   ),
  //   CustomerCategory(
  //     id: 'c9',
  //     name: 'Electronics',
  //     imageUrl: 'https://placehold.co/100x100/CCCCCC/CCCCCC?text=E',
  //   ),
  //   CustomerCategory(
  //     id: 'c10',
  //     name: 'Mobile',
  //     imageUrl: 'https://placehold.co/100x100/BDBDBD/BDBDBD?text=P',
  //   ),
  // ];
  List<CustomerCategory> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;
  List<CustomerProduct> _products = [];
  bool _isLoadingProducts = false;
  String? _productsError;
  List<CartItem> _cart = [];
  bool _isLoadingCart = false;
  String? _cartError;
  List<CustomerOrder> _orders = [];
  bool _isPlacingOrder = false;
  String? _placeOrderError;
  bool _isLoadingOrders = false;
  String? _ordersError;

  // --- Getters ---
  CustomerUser? get user => _user;

  bool get isLoadingUser => _isLoadingUser;

  String? get userError => _userError;

  // --- ADDED: Location Getter ---
  String? get currentLocationMessage => _currentLocationMessage;

  List<CustomerCategory> get categories => [..._categories];

  // --- ADDED: Category loading getters ---
  bool get isLoadingCategories => _isLoadingCategories;

  String? get categoriesError => _categoriesError;

  List<CustomerProduct> get products => [..._products];

  bool get isLoadingProducts => _isLoadingProducts;

  String? get productsError => _productsError;

  List<CartItem> get cart => [..._cart];

  bool get isLoadingCart => _isLoadingCart;

  String? get cartError => _cartError;

  double get cartTotal => _cart.fold(
    0.0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );

  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  List<CustomerOrder> get orders => [..._orders];

  bool get isPlacingOrder => _isPlacingOrder;

  String? get placeOrderError => _placeOrderError;

  bool get isLoadingOrders => _isLoadingOrders;

  String? get ordersError => _ordersError;

  // --- User Profile & Address Operations ---
  Future<void> fetchUserProfile() async {
    if (_isLoadingUser) return;
    _isLoadingUser = true;
    _userError = null;
    if (_user == null) notifyListeners();
    try {
      final userData = await _userApi.getMyProfile();
      _user = CustomerUser.fromJson(userData);
      _userError = null;
      // --- MODIFIED: Chain location check after profile fetch ---
      await checkAndFetchLocation();
      // Concurrently fetch cart and orders
      await Future.wait([
        fetchProducts(),
        fetchCart(),
        fetchMyOrders(),
        fetchCategories(),
      ]);
    } on ApiException catch (e) {
      _handleApiError(e, 'fetchUserProfile');
      _userError = e.message;
      _user = null;
      _cart = [];
      _orders = [];
      _categories = [];
    } catch (e) {
      _handleGenericError(e, 'fetchUserProfile');
      _userError = 'An unexpected error occurred.';
      _user = null;
      _cart = [];
      _orders = [];
      _categories = [];
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  // --- ADDED: Location Service Logic ---
  Future<void> checkAndFetchLocation() async {
    // 1. Only run if user is loaded AND has no addresses
    if (_user == null || (_user?.addresses.isNotEmpty ?? true)) {
      _currentLocationMessage = null; // Clear any old message
      return;
    }

    _currentLocationMessage = "Finding location...";
    notifyListeners();

    try {
      // 2. Check for permissions
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      // 3. Get coordinates
      final position = await Geolocator.getCurrentPosition();

      // 4. Convert coordinates to address (placemark)
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final city = pm.locality ?? 'Unknown City';
        final pincode = pm.postalCode ?? '000000';
        _currentLocationMessage = "$city, $pincode";
      } else {
        throw Exception('No address found for location.');
      }
    } catch (e) {
      _handleGenericError(e, 'checkAndFetchLocation');
      _currentLocationMessage = "Select your address"; // Default on error
    } finally {
      notifyListeners();
    }
  }

  /// UPDATED: Method signature changed to accept individual fields
  Future<void> addAddress({
    required String label,
    required String street,
    required String city,
    String? state,
    required String pincode,
    String? phone,
  }) async {
    if (_user == null) throw Exception("User not logged in.");
    // TODO: Add specific loading state, e.g., _isUpdatingAddress = true
    notifyListeners();
    try {
      final updatedUserData = await _userApi.addAddress(
        label: label,
        street: street,
        city: city,
        state: state,
        pincode: pincode,
        phone: phone,
      );
      _user = CustomerUser.fromJson(
        updatedUserData,
      ); // Update user with new address list
      // --- ADDED: Clear location message after adding an address ---
      _currentLocationMessage = null;
      // -----------------------------------------------------------
      notifyListeners();
    } on ApiException catch (e) {
      _handleApiError(e, 'addAddress');
      throw Exception(e.message);
    } catch (e) {
      _handleGenericError(e, 'addAddress');
      throw Exception("An unexpected error occurred.");
    } finally {
      /* _isUpdatingAddress = false; */
      notifyListeners();
    }
  }

  Future<void> updateAddress(CustomerAddress addressData) async {
    if (_user == null) throw Exception("User not logged in.");
    notifyListeners();
    try {
      final updatedUserData = await _userApi.updateAddress(
        addressId: addressData.id,
        label: addressData.label,
        street: addressData.street,
        city: addressData.city,
        state: addressData.state,
        pincode: addressData.pincode,
        phone: addressData.phone,
      );
      _user = CustomerUser.fromJson(updatedUserData);
      notifyListeners();
    } on ApiException catch (e) {
      _handleApiError(e, 'updateAddress');
      throw Exception(e.message);
    } catch (e) {
      _handleGenericError(e, 'updateAddress');
      throw Exception("An unexpected error occurred.");
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String addressId) async {
    if (_user == null) throw Exception("User not logged in.");
    notifyListeners();
    try {
      final updatedUserData = await _userApi.deleteAddress(
        addressId: addressId,
      );
      _user = CustomerUser.fromJson(updatedUserData);
      notifyListeners();
    } on ApiException catch (e) {
      _handleApiError(e, 'deleteAddress');
      throw Exception(e.message);
    } catch (e) {
      _handleGenericError(e, 'deleteAddress');
      throw Exception("An unexpected error occurred.");
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({String? name, String? phone}) async {
    if (_user == null) throw Exception("User not logged in.");
    notifyListeners();
    try {
      final String? phoneToSend = (phone != null && phone.trim().isEmpty)
          ? null
          : phone?.trim();
      final updatedUserJson = await _userApi.updateUserProfile(
        userId: _user!.id,
        name: name?.trim(),
        phone: phoneToSend,
      );

      // Reparse the full user object from the response
      _user = CustomerUser.fromJson(updatedUserJson);
      notifyListeners();
    } on ApiException catch (e) {
      _handleApiError(e, 'updateUserProfile');
      throw Exception(e.message);
    } catch (e) {
      _handleGenericError(e, 'updateUserProfile');
      throw Exception("An unexpected error occurred.");
    } finally {
      notifyListeners();
    }
  }

  // --- Product Fetching ---
  List<CustomerProduct> getProductsByCategory(String categoryName) {
    try {
      if (_products.isEmpty) return [];
      final lowerCategoryName = categoryName.toLowerCase().trim();
      // --- MODIFIED: Also find uncategorized ---
      if (lowerCategoryName == 'uncategorized') {
        return _products.where((product) {
          final productCategory = product.category?.toLowerCase().trim() ?? '';
          return productCategory.isEmpty;
        }).toList();
      }
      // -----------------------------------------
      return _products.where((product) {
        final productCategory = product.category?.toLowerCase().trim() ?? '';
        return productCategory == lowerCategoryName;
      }).toList();
    } catch (e) {
      _handleGenericError(e, 'getProductsByCategory');
      return [];
    }
  }

  // --- ADDED: Method to fetch categories from API ---
  Future<void> fetchCategories() async {
    if (_isLoadingCategories) return;
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners(); // Notify start

    try {
      final data = await _categoryApi.getAllCategories();
      final List<dynamic> categoryList = (data['categories'] is List)
          ? data['categories'] as List<dynamic>
          : [];

      _categories = categoryList
          .map((json) {
            try {
              return CustomerCategory.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              _handleGenericError(e, 'fetchCategories-parsing');
              return null; // Skip invalid item
            }
          })
          .whereType<CustomerCategory>() // Filter out any nulls
          .toList();

      _categoriesError = null;
    } on ApiException catch (e) {
      _handleApiError(e, 'fetchCategories');
      _categoriesError = e.message;
      _categories = [];
    } catch (e) {
      _handleGenericError(e, 'fetchCategories');
      _categoriesError = 'An unexpected error occurred.';
      _categories = [];
    } finally {
      _isLoadingCategories = false;
      notifyListeners(); // Notify end
    }
  }

  Future<void> fetchProducts() async {
    if (_isLoadingProducts) return;
    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();
    try {
      final data = await _productApi.getAllProducts();
      final List<dynamic> productList = (data['products'] is List)
          ? data['products'] as List<dynamic>
          : [];
      _products = productList
          .map((json) {
            try {
              return CustomerProduct.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              _handleGenericError(e, 'fetchProducts-parsing');
              return null;
            }
          })
          .whereType<CustomerProduct>()
          .toList();
      _productsError = null;
    } on ApiException catch (e) {
      _handleApiError(e, 'fetchProducts');
      _productsError = e.message;
      _products = [];
    } catch (e) {
      _handleGenericError(e, 'fetchProducts');
      _productsError = 'An unexpected error occurred.';
      _products = [];
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  Future<CustomerProduct?> getProductDetails(String productId) async {
    try {
      // Find from cache first
      final existingProduct = _products.firstWhere(
        (p) => p.id.toLowerCase() == productId.toLowerCase(),
      );
      return existingProduct;
    } catch (e) {
      /* Not in cache, proceed to fetch */
    }
    // Fetch from API if not in cache
    try {
      final data = await _productApi.getProductById(productId);
      if (data.containsKey('product') &&
          data['product'] != null &&
          data['product'] is Map) {
        final product = CustomerProduct.fromJson(
          data['product'] as Map<String, dynamic>,
        );
        // Add or update in cache
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1)
          _products[index] = product;
        else
          _products.add(product);
        return product;
      } else {
        return null; // Product not found by API
      }
    } on ApiException catch (e) {
      _handleApiError(e, 'getProductDetails');
      if (e.statusCode == 404) return null;
      throw Exception(e.message);
    } catch (e) {
      _handleGenericError(e, 'getProductDetails');
      throw Exception('An unexpected error occurred.');
    }
  }

  // --- Cart Operations ---
  Future<void> fetchCart() async {
    if (_isLoadingCart) return;
    _isLoadingCart = true;
    _cartError = null;
    notifyListeners();
    try {
      final data = await _cartApi.getMyCart();
      _updateLocalCartFromServer(data);
      _cartError = null;
    } on ApiException catch (e) {
      _handleApiError(e, 'fetchCart');
      _cartError = e.message;
      _cart = [];
    } catch (e) {
      _handleGenericError(e, 'fetchCart');
      _cartError = 'An unexpected error occurred.';
      _cart = [];
    } finally {
      _isLoadingCart = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(CustomerProduct prod, {int quantity = 1}) async {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == prod.id,
    );
    final currentQuantity = existingIndex >= 0
        ? _cart[existingIndex].quantity
        : 0;
    if (existingIndex >= 0)
      _cart[existingIndex].quantity += quantity;
    else
      _cart.add(CartItem(id: prod.id, product: prod, quantity: quantity));
    notifyListeners();
    try {
      final updatedCartData = await _cartApi.addToCart(
        productId: prod.id,
        quantity: quantity,
      );
      _updateLocalCartFromServer(updatedCartData);
    } on ApiException catch (e) {
      _revertCartChange(prod.id, currentQuantity);
      _cartError = "Couldn't add item: ${e.message}";
      _handleApiError(e, 'addToCart');
      notifyListeners();
    } catch (e) {
      _revertCartChange(prod.id, currentQuantity);
      _cartError = "An unexpected error occurred.";
      _handleGenericError(e, 'addToCart');
      notifyListeners();
    }
  }

  Future<void> updateItemQuantity(String productId, int newQuantity) async {
    final itemIndex = _cart.indexWhere((item) => item.product.id == productId);
    if (itemIndex == -1) return;
    if (newQuantity <= 0) {
      await removeFromCartByProductId(productId);
      return;
    }
    final originalQuantity = _cart[itemIndex].quantity;
    _cart[itemIndex].quantity = newQuantity;
    notifyListeners();
    try {
      final updatedCartData = await _cartApi.updateCartItem(
        productId: productId,
        quantity: newQuantity,
      );
      _updateLocalCartFromServer(updatedCartData);
    } on ApiException catch (e) {
      _cart[itemIndex].quantity = originalQuantity;
      _cartError = "Update failed: ${e.message}";
      _handleApiError(e, 'updateItemQuantity');
      notifyListeners();
    } catch (e) {
      _cart[itemIndex].quantity = originalQuantity;
      _cartError = "An unexpected error occurred.";
      _handleGenericError(e, 'updateItemQuantity');
      notifyListeners();
    }
  }

  Future<void> removeFromCartByProductId(String productId) async {
    final itemIndex = _cart.indexWhere((item) => item.product.id == productId);
    if (itemIndex == -1) return;
    final originalItem = _cart[itemIndex];
    _cart.removeAt(itemIndex);
    notifyListeners();
    try {
      final updatedCartData = await _cartApi.removeCartItem(
        productId: productId,
      );
      if (updatedCartData.containsKey('products'))
        _updateLocalCartFromServer(updatedCartData);
    } on ApiException catch (e) {
      _cart.insert(itemIndex, originalItem);
      _cartError = "Remove failed: ${e.message}";
      _handleApiError(e, 'removeFromCart');
      notifyListeners();
    } catch (e) {
      _cart.insert(itemIndex, originalItem);
      _cartError = "An unexpected error occurred.";
      _handleGenericError(e, 'removeFromCart');
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    final originalCart = List<CartItem>.from(_cart);
    if (_cart.isEmpty) return;
    _cart.clear();
    notifyListeners();
    try {
      await _cartApi.clearCart();
    } on ApiException catch (e) {
      _cart = originalCart;
      _cartError = "Clear failed: ${e.message}";
      _handleApiError(e, 'clearCart');
      notifyListeners();
    } catch (e) {
      _cart = originalCart;
      _cartError = "An unexpected error occurred.";
      _handleGenericError(e, 'clearCart');
      notifyListeners();
    }
  }

  // --- Order Operations ---
  Future<bool> placeOrder({required CustomerAddress selectedAddress}) async {
    if (_cart.isEmpty) {
      _placeOrderError = "Cart is empty.";
      notifyListeners();
      return false;
    }
    final CustomerAddress? shippingAddress =
        _user?.addresses.isNotEmpty ?? false ? _user!.addresses.first : null;
    if (shippingAddress == null) {
      _placeOrderError = "Please add a shipping address.";
      notifyListeners();
      return false;
    }
    if (_isPlacingOrder) return false;
    _isPlacingOrder = true;
    _placeOrderError = null;
    notifyListeners();
    final List<Map<String, dynamic>> orderItems = _cart
        .map(
          (ci) => {
            'productId': ci.product.id,
            'quantity': ci.quantity,
            'price': ci.product.price,
            'title': ci.product.title,
          },
        )
        .toList();
    final double calculatedTotal = cartTotal;
    try {
      final createdOrderData = await _orderApi.createOrder(
        items: orderItems,
        totalAmount: calculatedTotal,
        shippingAddress: {
          'street': shippingAddress.street,
          'city': shippingAddress.city,
          'state': shippingAddress.state,
          'pincode': shippingAddress.pincode,
          'phone': shippingAddress.phone ?? _user?.phone,
        },
      );
      try {
        _orders.insert(0, CustomerOrder.fromJson(createdOrderData));
      } catch (e) {
        _handleGenericError(e, 'placeOrder-parsing');
      }
      _cart.clear();
      _cartError = null;
      _isPlacingOrder = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _placeOrderError = e.message;
      _isPlacingOrder = false;
      _handleApiError(e, 'placeOrder');
      notifyListeners();
      return false;
    } catch (e) {
      _placeOrderError = 'An unexpected error occurred.';
      _isPlacingOrder = false;
      _handleGenericError(e, 'placeOrder');
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyOrders() async {
    if (_isLoadingOrders) return;
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();
    try {
      final List<dynamic> ordersData = await _orderApi.getMyOrders();
      _orders = ordersData
          .map((json) {
            try {
              return CustomerOrder.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              _handleGenericError(e, 'fetchMyOrders-parsing');
              return null;
            }
          })
          .whereType<CustomerOrder>()
          .toList();
      _ordersError = null;
    } on ApiException catch (e) {
      _ordersError = e.message;
      _orders = [];
      _handleApiError(e, 'fetchMyOrders');
    } catch (e) {
      _ordersError = 'An unexpected error occurred.';
      _orders = [];
      _handleGenericError(e, 'fetchMyOrders');
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  void setUser(Map<String, dynamic> userData) {
    try {
      _user = CustomerUser.fromJson(userData);
      _userError = null;
      _isLoadingUser = false;
      notifyListeners();
      fetchUserProfile(); // Trigger full profile/cart/order fetch
    } catch (e) {
      _user = null;
      _userError = "Failed to process login data.";
      _isLoadingUser = false;
      _handleGenericError(e, 'setUser');
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    _cart = [];
    _orders = [];
    _products = [];
    _userError = null;
    _cartError = null;
    _ordersError = null;
    _productsError = null;
    _currentLocationMessage = null;
    _isLoadingUser = false;
    _categoriesError = null;
    _isLoadingProducts = false;
    _isLoadingCart = false;
    _isLoadingOrders = false;
    _isLoadingCategories = false;
    ApiClient().deleteToken();
    notifyListeners();
  }

  // --- Internal Helpers ---
  void _updateLocalCartFromServer(Map<String, dynamic> serverCartData) {
    try {
      List<CartItem> tempCart = [];
      if (serverCartData.containsKey('products') &&
          serverCartData['products'] is List) {
        final List<dynamic> serverProducts =
            serverCartData['products'] as List<dynamic>;
        tempCart = serverProducts
            .map((item) {
              try {
                final productData = item['productId'] as Map<String, dynamic>?;
                if (productData == null) return null;
                final product = CustomerProduct.fromJson(productData);
                final quantity = item['quantity'] as int? ?? 1;
                return CartItem(
                  id: product.id,
                  product: product,
                  quantity: quantity,
                );
              } catch (e) {
                _handleGenericError(e, 'updateCart-parsing');
                return null;
              }
            })
            .whereType<CartItem>()
            .toList();
      }
      _cart = tempCart;
      _cartError = null;
    } catch (e) {
      _cartError = "Failed to update cart from server.";
      _handleGenericError(e, 'updateCart');
    }
    notifyListeners();
  }

  void _revertCartChange(String productId, int originalQuantity) {
    debugPrint("Reverting cart change for $productId. Refetching cart.");
    fetchCart();
  }

  void _handleApiError(ApiException e, String context) {
    debugPrint("API Error ($context): ${e.message} (Status: ${e.statusCode})");
  }

  void _handleGenericError(dynamic e, String context) {
    debugPrint("Unexpected Error ($context): ${e.toString()}");
  }
}
