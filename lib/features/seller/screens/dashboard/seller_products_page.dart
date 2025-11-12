import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/seller/models/seller_product_model.dart';
import 'package:tazto/features/seller/screens/add_edit_products_screen.dart';
import 'package:tazto/features/seller/screens/upload/product_upload_page.dart';
import 'package:tazto/providers/seller_provider.dart';

/// New Product Management page based on the UI design (Image 5)
class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SellerProvider>();
    final products = provider.products;
    final isLoading = provider.isLoadingProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildStatCards(products),
          _buildActionButtons(context),
          _buildSearchBar(),
          Expanded(
            child: isLoading && products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? const Center(child: Text('No products found.'))
                : _buildProductList(products),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // --- UPDATED: Navigate to Add Product screen ---
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductPage()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCards(List<SellerProduct> products) {
    int lowStock = products.where((p) => p.stock < 20).length; // Example logic
    int outOfStock = products.where((p) => p.stock == 0).length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        childAspectRatio: 2.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _InfoCard(title: 'Total Products', value: products.length.toString()),
          _InfoCard(
              title: 'Low Stock', value: lowStock.toString(), isWarning: true),
          _InfoCard(
              title: 'Active Products',
              value: (products.length - outOfStock).toString()),
          _InfoCard(
              title: 'Out of Stock',
              value: outOfStock.toString(),
              isWarning: true),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Import'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProductUploadPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Export'),
              onPressed: () {
                // TODO: Implement CSV Export
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search products by name, SKU...',
          prefixIcon: const Icon(Icons.search),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(List<SellerProduct> products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.05),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageURL != null &&
                  product.imageURL!.isNotEmpty
                  ? Image.network(
                product.imageURL!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              )
                  : Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            title: Text(product.title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            subtitle: Text(
              '${product.category} • SKU: ${product.sku ?? 'N/A'}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
                Text(
                  'Stock: ${product.stock}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: product.stock < 20 ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
            onTap: () {
              // TODO: Navigate to Edit Product screen
            },
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isWarning;
  const _InfoCard(
      {required this.title, required this.value, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red.shade600 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}