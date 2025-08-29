// lib/models/address.dart
class Address {
  final String id;
  String label;
  String street;
  String city;
  String state;
  String pincode;

  Address({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
  });
}
