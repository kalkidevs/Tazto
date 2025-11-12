import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/seller_provider.dart';
import 'package:tazto/widgets/error_dialog.dart';

/// A screen for manually adding or editing a product.
class AddEditProductPage extends StatefulWidget {
  // final SellerProduct? product; // TODO: Add this for editing
  // const AddEditProductPage({super.key, this.product});
  const AddEditProductPage({super.key});

  @override
  State<AddEditProductPage> createState() => _AddEditProductPageState();
}

class _AddEditProductPageState extends State<AddEditProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for all product fields
  final _titleC = TextEditingController();
  final _descriptionC = TextEditingController();
  final _priceC = TextEditingController();
  final _stockC = TextEditingController();
  final _categoryC = TextEditingController();
  final _skuC = TextEditingController();

  @override
  void dispose() {
    _titleC.dispose();
    _descriptionC.dispose();
    _priceC.dispose();
    _stockC.dispose();
    _categoryC.dispose();
    _skuC.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return; // Validation failed
    }
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final productData = {
      'title': _titleC.text.trim(),
      'description': _descriptionC.text.trim(),
      'price': double.tryParse(_priceC.text.trim()) ?? 0.0,
      'stock': int.tryParse(_stockC.text.trim()) ?? 0,
      'category': _categoryC.text.trim(),
      'sku': _skuC.text.trim(),
      // 'imageURL': '...' // TODO: Add image upload logic
    };

    final provider = context.read<SellerProvider>();
    final success = await provider.addProduct(productData);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        showSuccessDialog(
          context,
          'Product Added',
          '${_titleC.text.trim()} has been added to your inventory.',
          () => Navigator.of(context).pop(), // Pop dialog
        );
      } else {
        showErrorDialog(
          context,
          'Save Failed',
          provider.productsError ?? 'An unknown error occurred.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Product',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Image Upload Section ---
              _buildImageUpload(),
              const SizedBox(height: 24),
              // --- Product Details Section ---
              _buildTextField(
                _titleC,
                'Product Title',
                Icons.label_outline,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _descriptionC,
                'Description',
                Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _categoryC,
                'Category',
                Icons.category_outlined,
                isRequired: true,
              ),
              const SizedBox(height: 24),
              // --- Pricing & Inventory ---
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _priceC,
                      'Price (₹)',
                      Icons.attach_money,
                      isRequired: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _stockC,
                      'Stock',
                      Icons.inventory_2_outlined,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _skuC,
                'SKU (Optional)',
                Icons.qr_code_scanner_outlined,
              ),
              const SizedBox(height: 32),
              // --- Save Button ---
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Product',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return DottedBorder(
      options: CustomPathDottedBorderOptions(
        padding: const EdgeInsets.all(0),
        color: Colors.grey.shade400,
        strokeWidth: 1.2,
        dashPattern: const [6, 3],
        customPath: (size) {
          final path = Path();
          path.moveTo(0, 0);
          path.lineTo(size.width, 0); // top
          path.lineTo(size.width, size.height); // right
          path.lineTo(0, size.height); // bottom
          path.close(); // left side
          return path;
        },
      ),
      child: Container(
        height: 160,
        width: double.infinity,
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: Colors.grey.shade500,
                size: 42,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Product Image',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'PNG, JPG supported',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isRequired = false,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        if (keyboardType != null &&
            keyboardType.toString().contains('number')) {
          if (double.tryParse(value ?? '') == null) {
            return 'Please enter a valid number';
          }
        }
        return null;
      },
    );
  }
}
