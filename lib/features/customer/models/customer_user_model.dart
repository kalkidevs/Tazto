import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'customer_address_model.dart';

class CustomerUser {
  final String id;
  String name;
  String email;
  String? phone; // Make phone nullable
  List<CustomerAddress> addresses;
  final DateTime? createdAt; // <-- ADDED: To store "Member Since" date

  CustomerUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone, // Include phone in constructor
    List<CustomerAddress>? addresses,
    this.createdAt, // <-- ADDED: To constructor
  }) : addresses = addresses ?? []; // Default to empty list if null

  /// Factory constructor to create a User from JSON data.
  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    // Parse addresses safely
    List<CustomerAddress> parsedAddresses = [];
    if (json['addresses'] is List) {
      parsedAddresses = (json['addresses'] as List)
          .map((addrJson) {
            try {
              if (addrJson is Map<String, dynamic>) {
                return CustomerAddress.fromJson(addrJson);
              }
              return null; // Skip invalid items
            } catch (e) {
              debugPrint(
                "Error parsing address in User.fromJson: $addrJson - $e",
              );
              return null;
            }
          })
          .whereType<CustomerAddress>()
          .toList(); // Filter out any nulls
      parsedAddresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return 0;
      });
    }

    // Handle potential _id vs id key
    String userId = json['_id'] as String? ?? json['id'] as String? ?? '';

    return CustomerUser(
      id: userId,
      name: json['name'] as String? ?? 'No Name',
      email: json['email'] as String? ?? 'No Email',
      phone: json['phone'] as String?,
      // Parse phone
      addresses: parsedAddresses,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  String get memberSince {
    if (createdAt == null) return 'N/A';
    try {
      // Using intl package for nice formatting
      return DateFormat.yMMMMd().format(createdAt!);
    } catch (e) {
      return 'N/A';
    }
  }
}
