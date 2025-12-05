import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Required for compute
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/widgets/error_dialog.dart';

import '../../../../providers/seller_provider.dart';

// --- DATA MODEL ---
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

// --- ISOLATE LOGIC ---
List<ParsedProduct> _parseCsvContent(String content) {
  final lines = content.split(RegExp(r'\r\n|\n|\r'));
  final sampleLines = lines.take(min(5, lines.length)).toList();
  final candidates = [',', ';', '\t', '|'];
  String delimiter = ',';
  int bestScore = -1;

  for (final d in candidates) {
    int score = 0;
    for (final line in sampleLines) {
      score += line.split(d).length;
    }
    if (score > bestScore) {
      bestScore = score;
      delimiter = d;
    }
  }

  final converter = CsvToListConverter(
    shouldParseNumbers: false,
    fieldDelimiter: delimiter,
    eol: '\n',
  );

  final rows = converter.convert(content);
  if (rows.isEmpty) return [];

  final header = rows.first.map((c) => c.toString().toLowerCase()).toList();
  final expected = ['title', 'price', 'stock', 'description', 'category'];
  final hasHeader = expected.every((e) => header.any((h) => h.contains(e)));
  if (hasHeader) rows.removeAt(0);

  final List<ParsedProduct> products = [];
  for (var row in rows) {
    if (row.length < 5) {
      products.add(
        ParsedProduct(
          title: 'Invalid Row',
          price: 0,
          stock: 0,
          description: '',
          category: '',
          isValid: false,
          error: 'Row has missing columns (Expected 5+)',
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

    double? p = double.tryParse(priceStr.replaceAll(',', ''));
    int? s = int.tryParse(stockStr.replaceAll(',', ''));

    String currentError = '';
    if (title.isEmpty) currentError += 'Title is required. ';
    if (p == null || p <= 0) currentError += 'Price must be > 0. ';
    if (s == null || s < 0) currentError += 'Stock cannot be negative. ';
    if (category.isEmpty) currentError += 'Category is required. ';

    if (currentError.isNotEmpty) {
      products.add(
        ParsedProduct(
          title: title.isEmpty ? 'Untitled Product' : title,
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
  return products;
}

// --- MAIN WIDGET ---
class ProductUploadPage extends StatefulWidget {
  const ProductUploadPage({super.key});

  @override
  State<ProductUploadPage> createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends State<ProductUploadPage>
    with SingleTickerProviderStateMixin {
  String? _filePath;
  String? _fileName;
  List<ParsedProduct> _parsedProducts = [];

  // Upload State
  bool _isUploading = false;
  bool _isParsing = false;
  bool _isDownloading = false;
  double _progressValue = 0.0;
  int _successCount = 0;
  int _processedCount = 0;

  // UI State
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInitialPermission();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _requestInitialPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final androidInfo = await Permission.storage.status;
      if (androidInfo.isDenied) await Permission.storage.request();
      if (await Permission.manageExternalStorage.isDenied)
        await Permission.manageExternalStorage.request();
    } catch (e) {
      debugPrint('Permission error: $e');
    }
  }

  // --- FILE HANDLING ---
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _filePath = result.files.single.path;
          _fileName = result.files.single.name;
          _parsedProducts = [];
        });
        _processCsvFile();
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, 'Error', 'Failed to pick file: $e');
    }
  }

  Future<void> _processCsvFile() async {
    if (_filePath == null) return;
    setState(() => _isParsing = true);

    try {
      final file = File(_filePath!);
      final bytes = await file.readAsBytes();

      // Quick Check
      final headerStr = String.fromCharCodes(
        bytes.length > 4 ? bytes.sublist(0, 4) : bytes,
      );
      if (headerStr.startsWith('PK'))
        throw Exception('This looks like an Excel file. Please save as CSV.');

      String content;
      try {
        content = const Utf8Decoder(allowMalformed: true).convert(bytes);
      } catch (_) {
        content = latin1.decode(bytes);
      }
      if (content.startsWith('\uFEFF'))
        content = content.replaceFirst('\uFEFF', '');

      // Parse in Background
      final products = await compute(_parseCsvContent, content);

      if (mounted) {
        setState(() {
          _parsedProducts = products;
          _isParsing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isParsing = false);
        showErrorDialog(context, 'Parsing Error', e.toString());
      }
    }
  }

  // --- UPLOAD LOGIC (Batched) ---
  Future<void> _uploadProducts() async {
    final validProducts = _parsedProducts.where((p) => p.isValid).toList();
    if (validProducts.isEmpty) return;

    setState(() {
      _isUploading = true;
      _progressValue = 0.0;
      _processedCount = 0;
      _successCount = 0;
    });

    final provider = context.read<SellerProvider>();
    final int total = validProducts.length;
    final int batchSize = 50; // Upload 50 at a time

    try {
      for (var i = 0; i < total; i += batchSize) {
        final end = (i + batchSize < total) ? i + batchSize : total;
        final batch = validProducts.sublist(i, end);

        // Pass only this batch to provider
        final success = await provider.bulkAddProducts(
          batch,
        ); // Ensure Provider method accepts List<ParsedProduct> or Map

        if (mounted) {
          setState(() {
            _processedCount = end;
            if (success) _successCount += batch.length;
            _progressValue = _processedCount / total;
          });
        }

        // Small delay to let UI breathe
        await Future.delayed(const Duration(milliseconds: 50));
      }

      if (mounted) {
        // Success Completion
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _isUploading = false);

        showSuccessDialog(
          context,
          'Upload Complete',
          'Successfully uploaded $_successCount products out of $total processed.',
          () {
            if (mounted) Navigator.of(context).pop();
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        showErrorDialog(context, 'Upload Interrupted', e.toString());
      }
    }
  }

  void _reset() {
    setState(() {
      _filePath = null;
      _fileName = null;
      _parsedProducts = [];
    });
  }

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    if (_isUploading) return _buildProgressScreen();
    if (_isParsing) return _buildParsingScreen();

    final bool hasData = _parsedProducts.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(
          hasData ? 'Review Data' : 'Import Products',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (hasData)
            TextButton(
              onPressed: _reset,
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
        ],
      ),
      body: hasData ? _buildReviewScreen() : _buildUploadScreen(),
      bottomNavigationBar: hasData && !_isUploading ? _buildBottomBar() : null,
    );
  }

  // 1. Upload Screen (Initial)
  Widget _buildUploadScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Bulk Product Import",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload a CSV file to add multiple products at once. We support large files with validation.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 40),
          _buildActionButton(
            label: "Select CSV File",
            icon: Icons.folder_open_rounded,
            onTap: _pickFile,
            isPrimary: true,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: _isDownloading ? "Downloading..." : "Download Template",
            icon: Icons.download_rounded,
            onTap: _isDownloading ? null : _downloadTemplate,
            // Placeholder call
            isPrimary: false,
          ),
        ],
      ),
    );
  }

  // 2. Parsing Loading Screen
  Widget _buildParsingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              "Analyzing File...",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please wait while we validate your data.",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Progress Screen (Dynamic Upload)
  Widget _buildProgressScreen() {
    final int total = _parsedProducts.where((p) => p.isValid).length;
    final int percent = (_progressValue * 100).toInt();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _progressValue,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    "$percent%",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Uploading Products...",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Processed $_processedCount of $total items",
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              // Mini Log
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$_successCount uploaded successfully",
                      style: GoogleFonts.poppins(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Review Screen
  Widget _buildReviewScreen() {
    final validList = _parsedProducts.where((p) => p.isValid).toList();
    final invalidList = _parsedProducts.where((p) => !p.isValid).toList();

    return Column(
      children: [
        // Summary Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Total Rows",
                      "${_parsedProducts.length}",
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Ready",
                      "${validList.length}",
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Errors",
                      "${invalidList.length}",
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: "All Items"),
                  Tab(text: "Ready to Upload"),
                  Tab(text: "Issues Found"),
                ],
              ),
            ],
          ),
        ),
        // Lists
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductList(_parsedProducts),
              _buildProductList(validList),
              _buildProductList(invalidList),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductList(List<ParsedProduct> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No items in this category",
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: item.isValid ? Colors.grey[200]! : Colors.red[100]!,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Status
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.isValid ? Colors.green[50] : Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.isValid ? Icons.check : Icons.priority_high_rounded,
                    size: 16,
                    color: item.isValid ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "₹${item.price.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item.category} • Stock: ${item.stock}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (!item.isValid)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.error,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final int validCount = _parsedProducts.where((p) => p.isValid).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: validCount > 0 ? _uploadProducts : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Text(
              "Upload $validCount Products",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primary : Colors.white,
          foregroundColor: isPrimary ? Colors.white : AppColors.primary,
          elevation: isPrimary ? 2 : 0,
          side: isPrimary
              ? null
              : BorderSide(color: AppColors.primary.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Placeholder for missing download method body
  Future<void> _downloadTemplate() async {
    // ... [Previous download implementation]
    await Future.delayed(const Duration(seconds: 1)); // Mock for now
  }
}
