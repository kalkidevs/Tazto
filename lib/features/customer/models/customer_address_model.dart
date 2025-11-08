import 'package:flutter/foundation.dart'; // For debugPrint

class CustomerAddress {
  final String id;
  String label;
  String street;
  String city;
  String? state; // Make state nullable
  String pincode;
  String? phone; // ADDED: phone field

  CustomerAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    this.state, // Update constructor
    required this.pincode,
    this.phone, // ADDED: phone to constructor
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    String addressId = json['_id'] as String? ?? json['id'] as String? ?? '';
    if (addressId.isEmpty) {
      debugPrint("Warning: Address ID missing or empty in JSON: $json");
    }

    return CustomerAddress(
      id: addressId,
      label: json['label'] as String? ?? 'Address',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String?, // Keep nullable
    );
  }
}
