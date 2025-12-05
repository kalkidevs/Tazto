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
import '../api/product_api.dart';
import '../api/user_api.dart';

class CustomerProvider with ChangeNotifier {
  final ProductApi _productApi = ProductApi();
  final CartApi _cartApi = CartApi();
  final OrderApi _orderApi = OrderApi();
  final UserApi _userApi = UserApi();
  final CategoryApi _categoryApi = CategoryApi();

  CustomerUser? _user;
  bool _isLoadingUser = false;
  String? _userError;

  bool _isLoadingLocation = false;
  String? _currentLocationMessage;
  Position? _currentPosition;

  String? _connectedStoreName;

  List<CustomerCategory> _availableCategories = [];
  List<CustomerCategory> _masterCategories = [];
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

  bool get isLoadingLocation => _isLoadingLocation;

  String? get currentLocationMessage => _currentLocationMessage;

  Position? get currentPosition => _currentPosition;

  String? get connectedStoreName => _connectedStoreName;

  List<CustomerCategory> get availableCategories => [..._availableCategories];

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
    _isLoadingLocation = false;
    _userError = null;
    if (_user == null) notifyListeners();

    try {
      final userData = await _userApi.getMyProfile();
      _user = CustomerUser.fromJson(userData);
      _userError = null;

      _isLoadingLocation = true;
      notifyListeners();

      await checkAndFetchLocation();

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
      _masterCategories = [];
      _availableCategories = [];
      throw e;
    } catch (e) {
      _handleGenericError(e, 'fetchUserProfile');
      _userError = 'An unexpected error occurred.';
      _user = null;
      _cart = [];
      _orders = [];
      _masterCategories = [];
      _availableCategories = [];
      throw e;
    } finally {
      _isLoadingUser = false;
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> checkAndFetchLocation() async {
    if (_user == null) {
      _currentLocationMessage = null;
      return;
    }

    _currentLocationMessage = "Checking location services...";
    notifyListeners();
    bool serviceEnabled;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      _currentLocationMessage = "Could not check location.";
      notifyListeners();
      throw ApiException('Could not check location services.');
    }

    if (!serviceEnabled) {
      // Use 'disabled' in the string so the UI check works
      _currentLocationMessage = "Location is disabled";
      notifyListeners();
      throw ApiException('Location services are disabled.');
    }

    if (_user!.addresses.isNotEmpty) {
      final defaultAddress = _user!.addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => _user!.addresses.first,
      );
      _currentLocationMessage =
          "${defaultAddress.city}, ${defaultAddress.pincode}";

      if (defaultAddress.coordinates.length == 2) {
        double lng = defaultAddress.coordinates[0];
        double lat = defaultAddress.coordinates[1];

        // *** FIX: If address has invalid (0,0) coordinates, force null so we fetch live GPS ***
        if (lat == 0.0 && lng == 0.0) {
          debugPrint(
            "📍 Saved address has (0,0). Ignoring and fetching live location.",
          );
          _currentPosition = null;
        } else {
          _currentPosition = Position(
            longitude: lng,
            latitude: lat,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        }
      }
    } else {
      _currentLocationMessage = "Finding location...";
    }
    notifyListeners();

    try {
      LocationPermission permission;
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Fetch live location if no address OR if address had (0,0)
      if (_currentPosition == null) {
        _currentLocationMessage = "Getting current location...";
        notifyListeners();
        final position = await Geolocator.getCurrentPosition();
        _currentPosition = position;

        // Only reverse geocode if user has no addresses at all (to update the UI label)
        if (_user!.addresses.isEmpty) {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            final city = pm.locality ?? 'Unknown City';
            final pincode = pm.postalCode ?? '000000';
            _currentLocationMessage = "$city, $pincode";
          }
        }
      }
    } catch (e) {
      _handleGenericError(e, 'checkAndFetchLocation');
      _currentPosition = null;
      if (_user!.addresses.isEmpty) {
        _currentLocationMessage = "Select your address";
      }
      throw ApiException(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // ... (rest of the file remains unchanged, just updating checkAndFetchLocation) ...

  Future<void> fetchProducts() async {
    if (_isLoadingProducts) return;
    _isLoadingProducts = true;
    _productsError = null;
    _connectedStoreName = null;
    notifyListeners();

    try {
      if (_currentPosition == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_currentPosition == null) {
          await checkAndFetchLocation();
        }
      }

      if (_currentPosition == null) {
        throw ApiException(
          "Could not determine your location to find nearby stores.",
        );
      }

      final data = await _productApi.getAllProducts(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      if (data.containsKey('storeName')) {
        _connectedStoreName = data['storeName'] as String?;
      }

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
      _getAvailableCategories();
    } on ApiException catch (e) {
      _handleApiError(e, 'fetchProducts');
      _productsError = e.message;
      _products = [];
      _getAvailableCategories();
    } catch (e) {
      _handleGenericError(e, 'fetchProducts');
      _productsError = 'An unexpected error occurred.';
      _products = [];
      _getAvailableCategories();
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // ... include all other methods from previous versions (addAddress, etc.) ...
  // (Omitting rest of methods for brevity as they are unchanged)

  Future<void> addAddress({
    required String label,
    required String street,
    required String city,
    String? state,
    required String pincode,
    String? phone,
  }) async {
    if (_user == null) throw Exception("User not logged in.");
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
      _user = CustomerUser.fromJson(updatedUserData);
      _updateLocationFromDefaultAddress();
      notifyListeners();
      fetchProducts();
    } on ApiException catch (e) {
      _handleApiError(e, 'addAddress');
      throw Exception(e.message);
    } catch (e) {
      _handleGenericError(e, 'addAddress');
      throw Exception("An unexpected error occurred.");
    } finally {
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
      _updateLocationFromDefaultAddress();
      notifyListeners();
      fetchProducts();
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

  Future<void> setDefaultAddress(String addressId) async {
    if (_user == null) throw Exception("User not logged in.");

    final originalAddresses = List<CustomerAddress>.from(_user!.addresses);
    for (var addr in _user!.addresses) {
      addr.isDefault = addr.id == addressId;
    }
    notifyListeners();

    try {
      final updatedUserData = await _userApi.updateAddress(
        addressId: addressId,
        isDefault: true,
      );
      _user = CustomerUser.fromJson(updatedUserData);
      _updateLocationFromDefaultAddress();
      notifyListeners();
      fetchProducts();
    } on ApiException catch (e) {
      _user!.addresses = originalAddresses;
      _handleApiError(e, 'setDefaultAddress');
      throw Exception(e.message);
    } catch (e) {
      _user!.addresses = originalAddresses;
      _handleGenericError(e, 'setDefaultAddress');
      throw Exception("An unexpected error occurred.");
    } finally {
      notifyListeners();
    }
  }

  void _updateLocationFromDefaultAddress() {
    if (_user == null || _user!.addresses.isEmpty) {
      _currentPosition = null;
      _currentLocationMessage = "Select your address";
      return;
    }

    final defaultAddress = _user!.addresses.firstWhere(
      (addr) => addr.isDefault,
      orElse: () => _user!.addresses.first,
    );

    _currentLocationMessage =
        "${defaultAddress.city}, ${defaultAddress.pincode}";

    if (defaultAddress.coordinates.length == 2) {
      _currentPosition = Position(
        longitude: defaultAddress.coordinates[0],
        latitude: defaultAddress.coordinates[1],
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } else {
      _currentPosition = null;
      debugPrint("Default address has no coordinates. Products may not load.");
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

  List<CustomerProduct> getProductsByCategory(String categoryName) {
    try {
      if (_products.isEmpty) return [];
      final lowerCategoryName = categoryName.toLowerCase().trim();
      if (lowerCategoryName == 'uncategorized') {
        return _products.where((product) {
          final productCategory = product.category.toLowerCase().trim();
          return productCategory.isEmpty;
        }).toList();
      }
      return _products.where((product) {
        final productCategory = product.category.toLowerCase().trim();
        return productCategory == lowerCategoryName;
      }).toList();
    } catch (e) {
      _handleGenericError(e, 'getProductsByCategory');
      return [];
    }
  }

  Future<void> fetchCategories() async {
    if (_isLoadingCategories) return;
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      final data = await _categoryApi.getAllCategories();
      final List<dynamic> categoryList = (data['categories'] is List)
          ? data['categories'] as List<dynamic>
          : [];

      _masterCategories = categoryList
          .map((json) {
            try {
              return CustomerCategory.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              _handleGenericError(e, 'fetchCategories-parsing');
              return null;
            }
          })
          .whereType<CustomerCategory>()
          .toList();

      _categoriesError = null;
    } on ApiException catch (e) {
      _handleApiError(e, 'fetchCategories');
      _categoriesError = e.message;
      _masterCategories = [];
    } catch (e) {
      _handleGenericError(e, 'fetchCategories');
      _categoriesError = 'An unexpected error occurred.';
      _masterCategories = [];
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  void _getAvailableCategories() {
    if (_products.isEmpty) {
      _availableCategories = [];
      notifyListeners();
      return;
    }

    final productCategoryNames = _products
        .map((p) => p.category.toLowerCase().trim())
        .toSet();

    _availableCategories = _masterCategories.where((masterCategory) {
      return productCategoryNames.contains(
        masterCategory.name.toLowerCase().trim(),
      );
    }).toList();

    notifyListeners();
  }

  Future<CustomerProduct?> getProductDetails(
    String productId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      try {
        final existingProduct = _products.firstWhere(
          (p) => p.id.toLowerCase() == productId.toLowerCase(),
        );
        return existingProduct;
      } catch (e) {
        /* fetch */
      }
    }

    try {
      final data = await _productApi.getProductById(productId);
      if (data.containsKey('product')) {
        final product = CustomerProduct.fromJson(data['product']);
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product;
        } else {
          _products.add(product);
        }
        notifyListeners();
        return product;
      }
      return null;
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) return null;
      throw Exception(e.toString());
    }
  }

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
    if (_cart.isNotEmpty && prod.storeId != _cart.first.product.storeId) {
      _cartError = "You can only order from one store at a time.";
      notifyListeners();
      throw ApiException(_cartError!);
    }

    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == prod.id,
    );
    final currentQuantity = existingIndex >= 0
        ? _cart[existingIndex].quantity
        : 0;
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += quantity;
    } else {
      _cart.add(CartItem(id: prod.id, product: prod, quantity: quantity));
    }
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
      if (updatedCartData.containsKey('products')) {
        _updateLocalCartFromServer(updatedCartData);
      }
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

  Future<bool> placeOrder({required CustomerAddress selectedAddress}) async {
    if (_cart.isEmpty) {
      _placeOrderError = "Cart is empty.";
      notifyListeners();
      return false;
    }
    if (_isPlacingOrder) return false;
    _isPlacingOrder = true;
    _placeOrderError = null;
    notifyListeners();

    final CustomerAddress? shippingAddress = selectedAddress;

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
          'street': shippingAddress?.street,
          'city': shippingAddress?.city,
          'state': shippingAddress?.state,
          'pincode': shippingAddress?.pincode,
          'phone': shippingAddress?.phone ?? _user?.phone,
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

  Future<void> addProductReview(
    String productId,
    double rating,
    String comment,
  ) async {
    try {
      await _productApi.addReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );
      await getProductDetails(productId, forceRefresh: true);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  void setUser(Map<String, dynamic> userData) {
    try {
      _user = CustomerUser.fromJson(userData);
      _userError = null;
      _isLoadingUser = false;
      notifyListeners();
      fetchUserProfile();
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
    _currentPosition = null;
    _isLoadingUser = false;
    _masterCategories = [];
    _availableCategories = [];
    _categoriesError = null;
    _isLoadingProducts = false;
    _isLoadingCart = false;
    _isLoadingOrders = false;
    _isLoadingCategories = false;
    notifyListeners();
  }

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
