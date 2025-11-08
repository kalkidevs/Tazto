// // lib/screens/customer/product_detail_page.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:tazto/providers/customer_provider.dart';
//
// import '../models/seller_product_model.dart';
//
// class ProductDetailPage extends StatelessWidget {
//   final Product product;
//   const ProductDetailPage({required this.product, super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final prov = context.read<CustomerProvider>();
//     return Scaffold(
//       appBar: AppBar(title: Text(product.name)),
//       body: Column(
//         children: [
//           Image.network(product.imageUrl, height: 250, fit: BoxFit.cover),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(product.description),
//           ),
//           Text('\$${product.price}', style: const TextStyle(fontSize: 24)),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   prov.addToCart(product);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Added to cart')),
//                   );
//                 },
//                 child: const Text('Add to Cart'),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
