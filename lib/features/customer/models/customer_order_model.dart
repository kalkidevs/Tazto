import 'package:flutter/foundation.dart'; // For debugPrint

// Ensure CartItem model is imported correctly
import 'cart_itemMdl.dart';
// Ensure Product model is imported correctly for CartItem's product
import 'customer_product_model.dart';

// Enum for Order Status (align with backend)
enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

// Helper function to safely convert String to OrderStatus enum
OrderStatus _parseOrderStatus(String? statusString) {
  statusString = statusString
      ?.toLowerCase(); // Make comparison case-insensitive
  switch (statusString) {
    case 'pending':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'shipped':
      return OrderStatus.shipped;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      debugPrint(
        "Warning: Unknown order status received: $statusString. Defaulting to Pending.",
      );
      return OrderStatus.pending; // Default fallback
  }
}

class CustomerOrder {
  final String id; // Use 'id' to match backend response (_id)
  final List<CartItem> items; // Keep using CartItem locally for consistency
  final double totalAmount; // Match backend field name
  final DateTime orderDate; // Match backend field name
  final OrderStatus status;

  // Add address and payment details if needed
  final Map<String, dynamic>? shippingAddress; // Store address map as received
  final String? paymentMethod;

  CustomerOrder({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    this.shippingAddress,
    this.paymentMethod,
  });

  // Factory constructor to parse JSON from the backend
  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    // Parse items list
    List<CartItem> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((itemJson) {
            try {
              // Backend sends populated product details within items
              // We need to parse this into our local Product model first
              final productData =
                  itemJson['productId'] as Map<String, dynamic>?;
              if (productData == null)
                throw Exception('Missing productId object in order item');

              final product = CustomerProduct.fromJson(
                productData,
              ); // Use Product.fromJson
              final quantity = itemJson['quantity'] as int? ?? 1;
              // Generate a local unique ID for CartItem model consistency
              final cartItemId =
                  product.id + DateTime.now().microsecondsSinceEpoch.toString();
              return CartItem(
                id: cartItemId,
                product: product,
                quantity: quantity,
              );
            } catch (e) {
              debugPrint("Error parsing order item: $itemJson - Error: $e");
              return null; // Skip invalid items
            }
          })
          .whereType<CartItem>()
          .toList();
    }

    // Parse date safely
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(
        json['orderDate'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      );
    } catch (_) {
      parsedDate = DateTime.now(); // Fallback to current time if parsing fails
    }

    return CustomerOrder(
      id: json['_id'] as String,
      // Backend uses _id
      items: parsedItems,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      // Safe parsing for total
      orderDate: parsedDate,
      status: _parseOrderStatus(json['status'] as String?),
      // Use helper to parse status
      shippingAddress: json['shippingAddress'] as Map<String, dynamic>?,
      // Store address as map
      paymentMethod: json['paymentMethod'] as String?, // Payment method
    );
  }

  // Optional: Helper method to format date nicely
  String get formattedOrderDate {
    // Use intl package for better formatting later
    return '${orderDate.day}/${orderDate.month}/${orderDate.year}';
  }

  // Optional: Helper method to get total items count
  int get totalItemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}
