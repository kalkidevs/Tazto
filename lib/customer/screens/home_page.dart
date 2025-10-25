// lib/screens/customer/home_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/customer/models/categoryMdl.dart';
import 'package:tazto/customer/models/productMdl.dart';

import '../../providers/customer_provider.dart';

// Helper function to get category-based icons
IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'mobile':
    case 'phone':
      return Icons.smartphone;
    case 'electronics':
    case 'electronic':
      return Icons.devices;
    case 'clothing':
    case 'clothes':
    case 'fashion':
      return Icons.shopping_bag;
    case 'books':
    case 'book':
      return Icons.menu_book;
    case 'home':
    case 'furniture':
      return Icons.home;
    case 'sports':
    case 'fitness':
      return Icons.fitness_center;
    case 'food':
    case 'grocery':
      return Icons.restaurant;
    case 'beauty':
    case 'cosmetics':
      return Icons.face;
    case 'toys':
    case 'games':
      return Icons.toys;
    case 'automotive':
    case 'car':
      return Icons.directions_car;
    default:
      return Icons.shopping_cart;
  }
}

// Fallback banner for products without images
Widget _buildFallbackBanner(Product product, BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.primary.withOpacity(0.7),
          Theme.of(context).colorScheme.secondary.withOpacity(0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(product.category),
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            '₹${product.price.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CustomerProvider>();

    // loading / error
    if (prov.isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (prov.productsError != null) {
      return Center(child: Text(prov.productsError!));
    }

    final products = prov.products;
    // take up to 5 for banners
    final banners = products.take(5).toList();

    return CustomScrollView(
      slivers: [
        // 1) Pinned AppBar with location + actions
        SliverAppBar(
          pinned: true,
          elevation: 1,
          backgroundColor: Colors.white,
          titleSpacing: 0,
          title: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.location_on, color: Colors.black54),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Deliver to: ${prov.user.addresses.isNotEmpty ? prov.user.addresses.first.city : 'Select Address'}',
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                color: Colors.black54,
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                color: Colors.black54,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),

        // 2) Pinned search bar
        SliverPersistentHeader(pinned: true, delegate: _SearchBarDelegate()),

        // 3) Categories horizontal list
        // if (categories.isNotEmpty)
        //   SliverToBoxAdapter(
        //     child: SizedBox(
        //       height: 96,
        //       child: ListView.separated(
        //         padding: const EdgeInsets.symmetric(
        //           horizontal: 16,
        //           vertical: 8,
        //         ),
        //         scrollDirection: Axis.horizontal,
        //         separatorBuilder: (_, __) => const SizedBox(width: 12),
        //         itemCount: categories.length,
        //         itemBuilder: (_, i) => _CategoryTile(category: categories[i]),
        //       ),
        //     ),
        //   ),

        // 4) Banner carousel from real product images
        if (banners.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: banners.length,
                itemBuilder: (ctx, i) {
                  final p = banners[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: p.imageURL != null
                          ? null
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.2),
                    ),
                    child: p.imageURL != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  'https://backendlinc.up.railway.app/${p.imageURL}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackBanner(p, context),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '₹${p.price.toStringAsFixed(0)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildFallbackBanner(p, context),
                  );
                },
              ),
            ),
          ),

        // 5) Product grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 280,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ProductCard(product: products[i]),
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }
}

/// Search bar that stays pinned under the AppBar
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.black38),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search for products',
                  hintStyle: TextStyle(color: Colors.black38),
                  isDense: true,
                ),
                onSubmitted: (q) {
                  // TODO: navigate to search results
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

/// Category avatar + label
class _CategoryTile extends StatelessWidget {
  final Category category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(category.imageUrl),
          backgroundColor: Colors.grey.shade100,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
          child: Text(
            category.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Product card with image, title, price, rating & add-to-cart
class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<CustomerProvider>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image or category icon
          Expanded(
            child: product.imageURL != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      'https://backendlinc.up.railway.app/${product.imageURL}',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(product.category),
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(product.category),
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
          ),

          // title
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // price & rating
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star, size: 14, color: Colors.amber),
                Text(
                  product.rating.rate.toStringAsFixed(1),
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // add to cart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  prov.addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
