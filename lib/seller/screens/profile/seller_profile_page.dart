// lib/seller/screens/profile/seller_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/seller_provider.dart';

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;

  @override
  void initState() {
    super.initState();
    final store = context.read<SellerProvider>().stores.first;
    _nameController = TextEditingController(text: store.name);
    _addressController = TextEditingController(text: store.address);
    _cityController = TextEditingController(text: store.city);
    _pincodeController = TextEditingController(text: store.pincode);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // TODO: Call a provider method to update the store info
      // e.g., context.read<SellerProvider>().updateStoreInfo(...);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Store Information', style: textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Store Name'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a store name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Store Address'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a city' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Please enter a pincode' : null,
              ),
              const SizedBox(height: 32),
              Text('Contact Information', style: textTheme.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('vendor.email@example.com'),
                subtitle: const Text('Email (cannot be changed)'),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('+91 98765 43210'),
                subtitle: const Text('Phone Number'),
                trailing: TextButton(
                  child: const Text('Edit'),
                  onPressed: () {
                    // TODO: Implement phone number change flow
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}