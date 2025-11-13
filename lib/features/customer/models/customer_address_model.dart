import 'package:flutter/foundation.dart'; // For debugPrint

class CustomerAddress {
  final String id;
  String label;
  String street;
  String city;
  String? state; // Make state nullable
  String pincode;
  String? phone; // ADDED: phone field
  bool isDefault; // <-- ADDED
  final List<double> coordinates; // <-- ADDED: [lng, lat]

  CustomerAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    this.state, // Update constructor
    required this.pincode,
    this.phone, // ADDED: phone to constructor
    this.isDefault = false, // <-- ADDED
    List<double>? coordinates, // <-- ADDED
  }) : coordinates = coordinates ?? [0, 0]; // <-- ADDED

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    String addressId = json['_id'] as String? ?? json['id'] as String? ?? '';
    if (addressId.isEmpty) {
      debugPrint("Warning: Address ID missing or empty in JSON: $json");
    }

    // --- ADDED: Parse coordinates ---
    List<double> coords = [0, 0];
    if (json['location'] != null && json['location']['coordinates'] is List) {
      final coordList = json['location']['coordinates'] as List;
      if (coordList.length == 2) {
        coords = [
          (coordList[0] as num).toDouble(), // lng
          (coordList[1] as num).toDouble(), // lat
        ];
      }
    }
    // --- END ADDED ---

    return CustomerAddress(
      id: addressId,
      label: json['label'] as String? ?? 'Address',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String?,
      // Keep nullable
      isDefault: json['isDefault'] as bool? ?? false,
      // <-- ADDED
      coordinates: coords, // <-- ADDED
    );
  }
}
