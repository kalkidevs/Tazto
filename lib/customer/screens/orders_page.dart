// lib/screens/customer/orders_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<CustomerProvider>().orders;
    if (orders.isEmpty) {
      return const Center(child: Text('No orders yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Order #${o.id}'),
            subtitle: Text(
              '${o.items.length} items • \$${o.total.toStringAsFixed(2)}\n${o.date.toLocal()}',
            ),
            trailing: Text(o.status.name.toUpperCase()),
          ),
        );
      },
    );
  }
}
