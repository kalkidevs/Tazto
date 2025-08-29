import 'package:flutter/material.dart';
import 'package:tazto/profile_screen.dart';

import 'orders_screen.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    Center(child: Text("Home Page")),
    Center(child: Text("Cart Page")),
    OrdersPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Product> products = [
    Product(
      name: 'Fresh Apples',
      description: 'Organic red apples, sweet and crispy',
      price: 120,
      rating: 4.5,
      deliveryTime: '15 mins',
      store: 'Fresh Mart',
      imageUrl: 'assets/images/apple.jpg',
    ),
    Product(
      name: 'Whole Milk',
      description: 'Fresh whole milk, 1 liter',
      price: 65,
      rating: 4.3,
      deliveryTime: '12 mins',
      store: 'Dairy Fresh',
      imageUrl: 'assets/images/milk.jpg',
    ),
    Product(
      name: 'Brown Bread',
      description: 'Healthy brown bread',
      price: 45,
      rating: 4.8,
      deliveryTime: '10 mins',
      store: 'Bakery Fresh',
      imageUrl: 'assets/images/bread.jpg',
    ),
    Product(
      name: 'Bananas',
      description: 'Fresh and yellow bananas',
      price: 30,
      rating: 4.6,
      deliveryTime: '5 mins',
      store: 'Fruit Mart',
      imageUrl: 'assets/images/banana.jpg',
    ),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.delivery_dining, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Deliver to 123 Main St, Your City',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for products...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _selectedIndex == 0
          ? Column(
        children: [
          CategoryBar(),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(product: products[index]);
              },
            ),
          ),
        ],
      )
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.watch_later), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
class CategoryBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CategoryButton(label: 'All', icon: Icons.apps),
            CategoryButton(label: 'Fruits', icon: Icons.local_grocery_store),
            CategoryButton(label: 'Vegetables', icon: Icons.eco),
            CategoryButton(label: 'Dairy', icon: Icons.local_drink),
          ],
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String label;
  final IconData? icon;

  CategoryButton({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Chip(
        avatar: icon != null ? Icon(icon, size: 18, color: Colors.green) : null,
        label: Text(label),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.greenAccent),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class Product {
  final String name;
  final String description;
  final int price;
  final double rating;
  final String deliveryTime;
  final String store;
  final String imageUrl;

  Product({
    required this.name,
    required this.description,
    required this.price,
    required this.rating,
    required this.deliveryTime,
    required this.store,
    required this.imageUrl,
  });
}

class ProductCard extends StatelessWidget {
  final Product product;

  ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(product.imageUrl,
                fit: BoxFit.cover, height: 60, width: double.infinity),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(product.description),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${product.price}'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${product.rating} ★'),
                      Text(product.deliveryTime),
                    ],
                  ),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {},
                  child: Text('Add to Cart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}