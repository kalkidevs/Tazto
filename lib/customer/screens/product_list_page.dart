// // lib/screens/customer/product_list_page.dart
// import 'package:flutter/material.dart';
// import 'package:tazto/customer/models/categoryMdl.dart';
// import '../../providers/customerPdr.dart';
// import 'product_detail_page.dart';
// import 'package:provider/provider.dart';
//
// class ProductListPage extends StatelessWidget {
//   final Category category;
//   const ProductListPage({required this.category, super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final list = context.watch<CustomerProvider>()
//         .productsByCategory(category.id);
//     return Scaffold(
//       appBar: AppBar(title: Text(category.name)),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: list.length,
//         itemBuilder: (_, i) {
//           final p = list[i];
//           return Card(
//             margin: const EdgeInsets.only(bottom: 12),
//             child: ListTile(
//               leading: Image.network(p.imageUrl, width: 50, height: 50),
//               title: Text(p.name),
//               subtitle: Text('\$${p.price}'),
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ProductDetailPage(product: p)),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
