// lib/models/user.dart
import 'package:tazto/customer/models/addressMdl.dart';

class User {
  final String id;
  String name;
  String email;
  String phone;
  List<Address> addresses;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    List<Address>? addresses,
  }) : addresses = addresses ?? [];
}
