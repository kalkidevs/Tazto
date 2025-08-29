import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders = [
    {
      "title": "Fresh Apples",
      "date": "21 Aug 2025",
      "price": 120,
      "status": "Completed"
    },
    {
      "title": "Whole Milk",
      "date": "20 Aug 2025",
      "price": 65,
      "status": "Active"
    },
    {
      "title": "Brown Bread",
      "date": "18 Aug 2025",
      "price": 45,
      "status": "Completed"
    },
    {
      "title": "Eggs 12 Pack",
      "date": "17 Aug 2025",
      "price": 90,
      "status": "Active"
    },
  ];

  OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // All, Active, Completed
      child: Scaffold(
        appBar: AppBar(
          title: Text("My Orders"),
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "All Orders"),
              Tab(text: "Active"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ✅ All Orders
            _buildOrdersList(orders),

            // ✅ Active Orders
            _buildOrdersList(
              orders.where((o) => o["status"] == "Active").toList(),
            ),

            // ✅ Completed Orders
            _buildOrdersList(
              orders.where((o) => o["status"] == "Completed").toList(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildOrdersList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(child: Text("No orders found"));
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final order = data[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Icon(Icons.shopping_bag, color: Colors.green),
            title: Text(order["title"]),
            subtitle: Text("${order["date"]} • ${order["status"]}"),
            trailing: Text("₹${order["price"]}"),
          ),
        );
      },
    );
  }
}