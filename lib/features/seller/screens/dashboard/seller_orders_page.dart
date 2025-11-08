// lib/screens/seller/seller_orders_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/providers/seller_provider.dart';



class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<SellerProvider>().orders;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Order #${o.id}'),
            subtitle: Text('${o.quantity} × ${o.productId}\n${o.orderDate.toLocal()}'),
            trailing: Text(o.status.name.toUpperCase()),
          ),
        );
      },
    );
  }
}
