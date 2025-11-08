// lib/screens/seller/seller_products_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/providers/seller_provider.dart';

class SellerProductsPage extends StatelessWidget {
  const SellerProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<SellerProvider>().products;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(p.name),
            subtitle: Text('\$${p.price.toStringAsFixed(2)} — In stock: ${p.stock}'),
            trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {/* edit */}),
          ),
        );
      },
    );
  }
}
