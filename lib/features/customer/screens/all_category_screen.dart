import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/models/customer_category_model.dart';
import 'package:tazto/features/customer/screens/category_products_screen.dart';
import 'package:tazto/features/customer/widgets/custom_appbar.dart';
import 'package:tazto/providers/customer_provider.dart';

import 'home_page.dart' hide getCategoryIcon;

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final categories = provider.categories; // Get categories from provider

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ShoppingAppBar(
        title: 'All Categories',
        showBackButton: true,
      ),
      body: provider.isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : provider.categoriesError != null
          ? Center(child: Text('Error: ${provider.categoriesError}'))
          : categories.isEmpty
          ? const Center(child: Text('No categories found.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 columns for a clean grid
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.8, // Adjust aspect ratio for text below
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _CategoryGridTile(category: categories[index]);
              },
            ),
    );
  }
}

class _CategoryGridTile extends StatelessWidget {
  final CustomerCategory category;

  const _CategoryGridTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsPage(category: category),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 70,
              width: 70,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Image.network(
                category.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  getCategoryIcon(category.name),
                  color: AppColors.primary,
                  size: 28,
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
