import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/widgets/error_dialog.dart';

import '../../../../providers/seller_provider.dart';

// A simple model to hold parsed product data and validation status
class ParsedProduct {
  final String title;
  final double price;
  final int stock;
  final String description;
  final String category;
  final String? sku;
  final bool isValid;
  final String error;

  ParsedProduct({
    required this.title,
    required this.price,
    required this.stock,
    required this.description,
    required this.category,
    this.sku,
    this.isValid = true,
    this.error = '',
  });

  // Convert product to JSON format for API submission
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'stock': stock,
      'description': description,
      'category': category,
      'sku': sku,
    };
  }
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
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInitialPermission();
    });
  }

  /// Request storage permissions based on Android version
  /// Android 13+ (API 33): No longer needs WRITE_EXTERNAL_STORAGE
  /// Android 11-12 (API 30-32): May need manageExternalStorage for Downloads
  /// Android 10 and below: Uses legacy storage permission
  Future<void> _requestInitialPermission() async {
    if (!Platform.isAndroid) return;

    try {
      // Check Android version to request appropriate permissions
      final androidInfo = await Permission.storage.status;

      // For Android 13+ (API 33), scoped storage is default
      // For Android 10-12, request storage permission
      if (androidInfo.isDenied) {
        await Permission.storage.request();
      }

      // For Android 11+, consider manageExternalStorage for broad access
      if (await Permission.manageExternalStorage.isDenied) {
        // Note: This is a sensitive permission, only request if absolutely necessary
        await Permission.manageExternalStorage.request();
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
    }
  }

  /// Step 1: Pick a CSV file from device storage
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false, // Only allow single file selection
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _filePath = result.files.single.path;
          _parsedProducts = []; // Reset on new file pick
        });
        _processCsvFile();
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'File Picking Error',
          'Failed to pick file: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _processCsvFile() async {
    if (_filePath == null) return;
    setState(() => _isLoading = true);

    try {
      final file = File(_filePath!);

      // 1) Read raw bytes to allow trying multiple encodings
      final Uint8List bytes = await file.readAsBytes();

      // 2) Quick check: detect binary formats (xlsx zip files start with PK)
      final headerBytes = bytes.length > 4 ? bytes.sublist(0, 4) : bytes;
      final headerString = String.fromCharCodes(headerBytes);
      if (headerString.startsWith('PK') ||
          headerString.contains('<html') ||
          headerString.contains('<?xml')) {
        throw Exception(
          'The selected file does not appear to be a CSV (maybe .xlsx, HTML or XML). Please upload a proper .csv file.',
        );
      }

      // 3) Try decode UTF-8 first (strip BOM if present), fall back to latin1
      String content;
      try {
        content = const Utf8Decoder(allowMalformed: true).convert(bytes);
      } catch (_) {
        content = latin1.decode(bytes);
      }
      // Remove UTF-8 BOM if present
      if (content.startsWith('\uFEFF'))
        content = content.replaceFirst('\uFEFF', '');

      // 4) Quick sanity: if file is tiny or has no newline, likely wrong format
      if (!content.contains('\n') && !content.contains('\r')) {
        throw Exception(
          'CSV file appears to have no line breaks. Please check the file and try again.',
        );
      }

      // 5) Detect delimiter by inspecting first few lines
      final lines = content.split(RegExp(r'\r\n|\n|\r'));
      final sampleLines = lines.take(min(5, lines.length)).toList();
      final delimiter = _detectDelimiter(sampleLines);

      // 6) Convert using CsvToListConverter with detected delimiter
      final converter = CsvToListConverter(
        shouldParseNumbers: false,
        fieldDelimiter: delimiter,
        eol: '\n', // unify eol
      );

      final rows = converter.convert(content);

      debugPrint('CSV parsed rows: ${rows.length} (delimiter="$delimiter")');

      if (rows.isEmpty) {
        throw Exception('No rows found in CSV after parsing.');
      }

      // 7) Remove header row (only if first row matches expected header tokens)
      // If you always require header removal per your app, just remove index 0
      final header = rows.first.map((c) => c.toString().toLowerCase()).toList();
      final expected = ['title', 'price', 'stock', 'description', 'category'];
      final hasHeader = expected.every((e) => header.any((h) => h.contains(e)));
      if (hasHeader) {
        rows.removeAt(0);
      }

      // 8) Map rows to ParsedProduct objects
      final List<ParsedProduct> products = [];
      for (var row in rows) {
        // ensure list length >=5
        if (row.length < 5) {
          products.add(
            ParsedProduct(
              title: 'Invalid Row',
              price: 0,
              stock: 0,
              description: '',
              category: '',
              isValid: false,
              error: 'Expected 5+ columns, found ${row.length}',
            ),
          );
          continue;
        }

        final title = row[0].toString().trim();
        final priceStr = row[1].toString().trim();
        final stockStr = row[2].toString().trim();
        final description = row[3].toString().trim();
        final category = row[4].toString().trim();
        final sku = row.length > 5 ? row[5].toString().trim() : null;

        double? p = double.tryParse(
          priceStr.replaceAll(',', ''),
        ); // remove thousand separators if present
        int? s = int.tryParse(stockStr.replaceAll(',', ''));

        String currentError = '';
        if (title.isEmpty) currentError += 'Title missing. ';
        if (p == null || p <= 0) currentError += 'Price invalid. ';
        if (s == null || s < 0) currentError += 'Stock invalid. ';
        if (category.isEmpty) currentError += 'Category missing. ';

        if (currentError.isNotEmpty) {
          products.add(
            ParsedProduct(
              title: title.isEmpty ? 'Invalid' : title,
              price: p ?? 0,
              stock: s ?? 0,
              description: description,
              category: category,
              sku: sku,
              isValid: false,
              error: currentError.trim(),
            ),
          );
        } else {
          products.add(
            ParsedProduct(
              title: title,
              price: p!,
              stock: s!,
              description: description,
              category: category,
              sku: sku,
            ),
          );
        }
      }

      setState(() {
        _parsedProducts = products;
      });
    } catch (e, st) {
      debugPrint('CSV processing error: $e\n$st');
      if (mounted) {
        showErrorDialog(context, 'File Processing Error', e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Heuristic delimiter detection from sample lines
  String _detectDelimiter(List<String> sampleLines) {
    final candidates = [',', ';', '\t', '|'];
    String best = ',';
    int bestScore = -1;

    for (final d in candidates) {
      int score = 0;
      for (final line in sampleLines) {
        score += line.split(d).length;
      }
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best;
  }

  /// Step 3: Validate each row from the CSV
  /// Expected format: title, price, stock, description, category, sku (optional)
  ParsedProduct _validateRow(List<dynamic> row, int rowNumber) {
    if (row.length < 5) {
      return ParsedProduct(
        title: 'Invalid Row $rowNumber',
        price: 0,
        stock: 0,
        description: '',
        category: '',
        isValid: false,
        error:
            'Expected at least 5 columns (title, price, stock, description, category), found ${row.length}',
      );
    }

    String title = row[0].toString().trim();
    String priceStr = row[1].toString().trim();
    String stockStr = row[2].toString().trim();
    String description = row[3].toString().trim();
    String category = row[4].toString().trim();
    String? sku = row.length > 5 ? row[5].toString().trim() : null;

    String currentError = '';

    // Validate Title
    if (title.isEmpty) {
      currentError += 'Title is missing. ';
    } else if (title.length > 200) {
      currentError += 'Title exceeds 200 characters. ';
    }

    // Validate Price
    double? price = double.tryParse(priceStr.replaceAll(',', ''));
    if (price == null) {
      currentError += 'Price must be a valid number. ';
    } else if (price <= 0) {
      currentError += 'Price must be greater than 0. ';
    } else if (price > 1000000) {
      currentError += 'Price exceeds maximum limit. ';
    }

    // Validate Stock
    int? stock = int.tryParse(stockStr);
    if (stock == null) {
      currentError += 'Stock must be a valid integer. ';
    } else if (stock < 0) {
      currentError += 'Stock cannot be negative. ';
    }

    // Validate Category
    if (category.isEmpty) {
      currentError += 'Category is missing. ';
    }

    // Validate SKU if provided
    if (sku != null && sku.isNotEmpty && sku.length > 50) {
      currentError += 'SKU exceeds 50 characters. ';
    }

    if (currentError.isNotEmpty) {
      return ParsedProduct(
        title: title.isNotEmpty ? title : 'Row $rowNumber',
        price: price ?? 0,
        stock: stock ?? 0,
        description: description,
        category: category,
        sku: sku,
        isValid: false,
        error: currentError.trim(),
      );
    }

    return ParsedProduct(
      title: title,
      price: price!,
      stock: stock!,
      description: description,
      category: category,
      sku: sku,
    );
  }

  /// Step 4: Submit valid products to the provider/backend
  Future<void> _uploadProducts() async {
    final validProducts = _parsedProducts.where((p) => p.isValid).toList();

    if (validProducts.isEmpty) {
      showErrorDialog(
        context,
        'Upload Failed',
        'There are no valid products to upload. Please fix the errors in your CSV file and try again.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final startTime = DateTime.now();
    bool success = false;

    try {
      final provider = context.read<SellerProvider>();

      // 🔹 Start upload
      success = await provider.bulkAddProducts(validProducts);

      // 🔹 Enforce a minimum loading time of 5–6 seconds
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed.inSeconds < 6) {
        await Future.delayed(Duration(seconds: 6 - elapsed.inSeconds));
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;

        showSuccessDialog(
          context,
          'Upload Complete',
          '${validProducts.length} products have been uploaded successfully.',
          () async {
            // ✅ Close dialog safely
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }

            // ✅ Navigate to "My Products" screen after short delay
            await Future.delayed(const Duration(milliseconds: 400));

            if (mounted) {
              Navigator.pushReplacementNamed(context, '/myProducts');
            }

            // Optionally, trigger refresh logic if your provider supports it:
            // provider.fetchMyProducts();
          },
        );
      } else {
        if (!mounted) return;
        showErrorDialog(
          context,
          'Upload Failed',
          provider.productsError ??
              'An unknown error occurred during upload. Please try again.',
        );
      }
    } catch (e, st) {
      debugPrint('Upload error: $e\n$st');
      if (mounted) {
        showErrorDialog(context, 'Upload Failed', e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Download CSV template to device
  /// This method handles platform-specific file saving with proper permissions
  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);

    try {
      // Step 1: Handle platform-specific permissions
      if (Platform.isAndroid) {
        // Android 13+ (API 33) doesn't need storage permission for app-specific files
        // For Downloads folder access, we need to check permissions
        final androidVersion = await _getAndroidVersion();

        if (androidVersion < 33) {
          // Android 12 and below
          var storageStatus = await Permission.storage.status;

          if (storageStatus.isDenied) {
            storageStatus = await Permission.storage.request();
          }

          if (storageStatus.isPermanentlyDenied) {
            await openAppSettings();
            throw Exception(
              'Storage permission is required. Please enable it in app settings.',
            );
          }

          if (storageStatus.isDenied) {
            throw Exception(
              'Storage permission is required to save the template.',
            );
          }
        }
        // For Android 13+, we'll save to app-specific directory which doesn't need permission
      } else if (Platform.isIOS) {
        // iOS doesn't require explicit permission for app documents directory
        // But if we need photo library or other access, request it here
      }

      // Step 2: Define CSV template data with clear examples
      final List<List<dynamic>> csvData = [
        // Header row
        ['title', 'price', 'stock', 'description', 'category', 'sku'],
        // Example products
        [
          'Premium Wireless Headphones',
          199.99,
          50,
          'High-quality wireless headphones with noise cancellation',
          'Electronics',
          'ELECT-WH-001',
        ],
        [
          'Organic Green Tea (100g)',
          12.50,
          120,
          'Premium organic green tea leaves from Darjeeling',
          'Groceries',
          'GROC-TEA-002',
        ],
        [
          'Cotton T-Shirt - Blue',
          29.99,
          75,
          'Comfortable cotton t-shirt in royal blue color',
          'Clothing',
          'CLOTH-TS-003',
        ],
      ];

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Step 3: Determine the correct save location based on platform
      Directory? directory;
      String? filePath;

      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();

        if (androidVersion >= 33) {
          // Android 13+: Use app-specific directory (scoped storage)
          // Users can access this via Files app -> Documents
          directory = await getExternalStorageDirectory();
          // Navigate to a more accessible folder
          if (directory != null) {
            final documentsPath = directory.path.split('/Android').first;
            directory = Directory('$documentsPath/Documents');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }
          }
        } else {
          // Android 12 and below: Try to use Downloads folder
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = Directory('/storage/emulated/0/Downloads');
          }
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        }
      } else if (Platform.isIOS) {
        // iOS: Use app documents directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Other platforms (desktop, etc.)
        directory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Unable to access storage directory');
      }

      // Step 4: Create unique filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filePath = '${directory.path}/linc_product_template_$timestamp.csv';

      // Step 5: Write the file
      final file = File(filePath);
      await file.writeAsString(csvString, encoding: utf8);

      // Verify file was created
      if (!await file.exists()) {
        throw Exception('File was not created successfully');
      }

      // Step 6: Show success message with file location
      if (mounted) {
        final fileName = filePath.split('/').last;
        final folderName =
            Platform.isAndroid && await _getAndroidVersion() >= 33
            ? 'Documents folder (accessible via Files app)'
            : 'Downloads folder';

        showSuccessDialog(
          context,
          'Template Downloaded',
          '✅ Template saved successfully!\n\n'
              'File: $fileName\n'
              'Location: $folderName\n\n'
              'Full path: $filePath',
          () => Navigator.of(context).pop(),
        );
      }
    } catch (e) {
      // Step 7: Handle errors gracefully
      if (mounted) {
        showErrorDialog(
          context,
          'Download Failed',
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  /// Helper method to get Android SDK version
  /// Returns 0 if not Android or if unable to determine
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // This is a simplified version - in production, use device_info_plus package
      // Example: DeviceInfoPlugin().androidInfo.then((info) => info.version.sdkInt)
      return 33; // Default to Android 13+ behavior for safety
    } catch (e) {
      return 33; // Default to newer Android behavior
    }
  }

  @override
  Widget build(BuildContext context) {
    final validCount = _parsedProducts.where((p) => p.isValid).length;
    final invalidCount = _parsedProducts.length - validCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bulk Product Upload',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
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
                    icon: const Icon(
                      Icons.file_upload_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Select CSV File',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _pickFile,
                  ),
                  if (_filePath != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Selected: ${Uri.file(_filePath!).pathSegments.last}',
                        style: GoogleFonts.poppins(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
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
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Upload $validCount Valid Product${validCount > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                  onPressed: _isLoading ? null : _uploadProducts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'How to Upload Products',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              '1.',
              'Download our CSV template below to see the correct format.',
            ),
            _buildInstructionStep(
              '2.',
              'Fill in your product data. Required columns: title, price, stock, description, category. Optional: sku.',
            ),
            _buildInstructionStep(
              '3.',
              'You can keep or remove the header row - our system will detect it automatically.',
            ),
            _buildInstructionStep(
              '4.',
              'Click "Select CSV File", review the validation results, and upload.',
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                icon: Icon(
                  _isDownloading
                      ? Icons.hourglass_empty
                      : Icons.download_for_offline_outlined,
                  size: 20,
                ),
                label: Text(
                  _isDownloading ? 'Downloading...' : 'Download Template',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                onPressed: _isDownloading ? null : _downloadTemplate,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildValidationSummary(int valid, int invalid) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              valid.toString(),
              'Valid Products',
              Colors.green.shade700,
              Icons.check_circle_outline,
            ),
            Container(height: 50, width: 1, color: Colors.grey.shade300),
            _buildSummaryItem(
              invalid.toString(),
              'Invalid Products',
              Colors.red.shade700,
              Icons.error_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String count,
    String label,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProductPreviewTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview & Validation Results',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: product.isValid
                      ? Colors.grey.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: product.isValid
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    product.isValid ? Icons.check : Icons.close,
                    color: product.isValid
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    size: 20,
                  ),
                ),
                title: Text(
                  product.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  product.isValid
                      ? 'Price: ₹${product.price.toStringAsFixed(2)} | Stock: ${product.stock} | Category: ${product.category}'
                      : 'Error: ${product.error}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: product.isValid
                        ? AppColors.textSecondary
                        : Colors.red.shade700,
                  ),
                ),
                isThreeLine: !product.isValid,
              ),
            );
          },
        ),
      ],
    );
  }
}
