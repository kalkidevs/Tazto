// lib/providers/seller_provider.dart
import 'package:flutter/material.dart';
import 'package:tazto/features/seller/models/soreMdl.dart';

import '../features/seller/models/orderMdl.dart';
import '../features/seller/models/seller_product_model.dart';

class SellerProvider with ChangeNotifier {
  // Sample Store
  final List<Store> _stores = [
    Store(
      id: 'store_1',
      name: 'FreshMart Groceries',
      address: '123 Market St',
      city: 'Springfield',
      state: 'Illinois',
      pincode: '62704',
    ),
  ];

  // Sample Products
  final List<SellerProduct> _products = [
    SellerProduct(
      id: 'prod_1',
      storeId: 'store_1',
      name: 'Organic Apples',
      description: 'Crisp and juicy organic apples, 1kg pack',
      price: 3.99,
      stock: 50,
    ),
    SellerProduct(
      id: 'prod_2',
      storeId: 'store_1',
      name: 'Whole Wheat Bread',
      description: 'Freshly baked whole wheat bread loaf',
      price: 2.49,
      stock: 30,
    ),
    SellerProduct(
      id: 'prod_3',
      storeId: 'store_1',
      name: 'Almond Milk',
      description: 'Unsweetened almond milk, 1L',
      price: 2.99,
      stock: 20,
    ),
  ];

  // Sample Orders
  final List<Order> _orders = [
    Order(
      id: 'order_1',
      storeId: 'store_1',
      productId: 'prod_1',
      quantity: 2,
      orderDate: DateTime.now().subtract(const Duration(days: 1)),
      status: OrderStatus.confirmed,
    ),
    Order(
      id: 'order_2',
      storeId: 'store_1',
      productId: 'prod_2',
      quantity: 1,
      orderDate: DateTime.now().subtract(const Duration(days: 2)),
      status: OrderStatus.pending,
    ),
  ];

  List<Store> get stores => [..._stores];
  List<SellerProduct> get products => [..._products];
  List<Order> get orders => [..._orders];

// you can add CRUD methods here and call notifyListeners()
}
