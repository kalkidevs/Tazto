// lib/seller/screens/upload/product_upload_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// A simple model to hold parsed product data and validation status
class ParsedProduct {
  final String name;
  final double price;
  final int stock;
  final String description;
  final bool isValid;
  final String error;

  ParsedProduct({
    required this.name,
    required this.price,
    required this.stock,
    required this.description,
    this.isValid = true,
    this.error = '',
  });
}

class ProductUploadPage extends StatefulWidget {
  const ProductUploadPage({super.key});

  @override
  State<ProductUploadPage> createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends State<ProductUploadPage> {
  String? _filePath;
  List<ParsedProduct> _parsedProducts = [];
  bool _isLoading = false;

  /// Step 1: Pick a CSV file from device storage
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        setState(() {
          _filePath = result.files.single.path;
          _parsedProducts = []; // Reset on new file pick
        });
        _processFile();
      }
    } catch (e) {
      _showErrorDialog('File Picking Error', 'Failed to pick file: $e');
    }
  }

  /// Step 2: Process the picked CSV file
  Future<void> _processFile() async {
    if (_filePath == null) return;

    setState(() => _isLoading = true);
    try {
      final file = File(_filePath!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter(shouldParseNumbers: false)) // Read all as string first
          .toList();

      // Remove header row
      if (fields.isNotEmpty) {
        fields.removeAt(0);
      }

      List<ParsedProduct> products = [];
      for (var row in fields) {
        products.add(_validateRow(row));
      }

      setState(() {
        _parsedProducts = products;
      });
    } catch (e) {
      _showErrorDialog('File Processing Error', 'Could not read or process the CSV file. Please ensure it is correctly formatted.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Step 3: Validate each row from the CSV
  ParsedProduct _validateRow(List<dynamic> row) {
    // Expected format: name, price, stock, description
    if (row.length < 4) {
      return ParsedProduct(name: 'Invalid Row', price: 0, stock: 0, description: 'Incorrect number of columns', isValid: false, error: 'Expected 4 columns, found ${row.length}');
    }

    String name = row[0].toString().trim();
    String priceStr = row[1].toString().trim();
    String stockStr = row[2].toString().trim();
    String description = row[3].toString().trim();

    String currentError = '';

    // Validate Name
    if (name.isEmpty) currentError += 'Product name is missing. ';

    // Validate Price
    double? price = double.tryParse(priceStr);
    if (price == null || price <= 0) currentError += 'Price must be a positive number. ';

    // Validate Stock
    int? stock = int.tryParse(stockStr);
    if (stock == null || stock < 0) currentError += 'Stock must be a non-negative integer. ';

    // Validate Description
    if (description.isEmpty) currentError += 'Description is missing. ';

    if (currentError.isNotEmpty) {
      return ParsedProduct(name: name, price: price ?? 0, stock: stock ?? 0, description: description, isValid: false, error: currentError.trim());
    }

    return ParsedProduct(name: name, price: price!, stock: stock!, description: description);
  }

  /// Step 4: Submit valid products to the provider/backend
  void _uploadProducts() {
    final validProducts = _parsedProducts.where((p) => p.isValid).toList();
    if (validProducts.isEmpty) {
      _showErrorDialog('Upload Failed', 'There are no valid products to upload. Please fix the errors in your CSV file and try again.');
      return;
    }

    // TODO: Call a provider method to handle the upload
    // e.g., context.read<SellerProvider>().bulkAddProducts(validProducts);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Successful'),
        content: Text('${validProducts.length} products have been successfully added to your inventory.'),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back from upload page
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCount = _parsedProducts.where((p) => p.isValid).length;
    final invalidCount = _parsedProducts.length - validCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Product Upload')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructionsCard(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Select CSV File'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _pickFile,
            ),
            if (_filePath != null) ...[
              const SizedBox(height: 12),
              Center(child: Text('Selected: ${Uri.file(_filePath!).pathSegments.last}', style: const TextStyle(fontStyle: FontStyle.italic))),
            ],
            if (_parsedProducts.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildValidationSummary(validCount, invalidCount),
              const SizedBox(height: 16),
              _buildProductPreviewTable(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _parsedProducts.isNotEmpty && validCount > 0
          ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          child: Text('Upload $validCount Valid Products'),
          onPressed: _uploadProducts,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16)
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to Upload Products', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('1. Download our CSV template (or create your own).'),
            const SizedBox(height: 8),
            const Text('2. The CSV must have 4 columns in this exact order: name, price, stock, description.'),
            const SizedBox(height: 8),
            const Text('3. Do not include a header row in the file you upload.'),
            const SizedBox(height: 8),
            const Text('4. Select the file, review the validated data, and click upload.'),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.download_for_offline_outlined),
                label: const Text('Download Template (Coming Soon)'),
                onPressed: () {
                  // TODO: Implement template download functionality
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSummary(int valid, int invalid) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(valid.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                const Text('Valid Products'),
              ],
            ),
            Column(
              children: [
                Text(invalid.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                const Text('Invalid Products'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPreviewTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview & Validation Results', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _parsedProducts.length,
          itemBuilder: (context, index) {
            final product = _parsedProducts[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: product.isValid ? Colors.white : Colors.red.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.isValid ? Colors.green : Colors.red,
                  child: Icon(product.isValid ? Icons.check : Icons.close, color: Colors.white, size: 20),
                ),
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(product.isValid
                    ? 'Price: ₹${product.price.toStringAsFixed(2)} | Stock: ${product.stock}'
                    : 'Error: ${product.error}'),
                isThreeLine: !product.isValid,
              ),
            );
          },
        ),
      ],
    );
  }
}