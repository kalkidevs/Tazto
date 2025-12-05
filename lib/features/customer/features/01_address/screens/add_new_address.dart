import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../../../../../widgets/error_dialog.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _labelController = TextEditingController(text: 'Home');
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onSaveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<CustomerProvider>().addAddress(
        label: _labelController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Address saved successfully!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context,
          'Save Failed',
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Add Delivery Address',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Label chips row (Home / Work / Other)
              Row(
                children: [
                  _buildLabelChip('Home'),
                  const SizedBox(width: 8),
                  _buildLabelChip('Work'),
                  const SizedBox(width: 8),
                  _buildLabelChip('Other'),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _streetController,
                decoration: _fieldDecoration('Street Address / House No.'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter address'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: _fieldDecoration('City'),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter city'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _stateController,
                decoration: _fieldDecoration('State (Optional)'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pincodeController,
                decoration: _fieldDecoration('Pincode'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter pincode'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: _fieldDecoration('Phone Number (Optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Updated button text as requested
              ElevatedButton(
                onPressed: _isLoading ? null : _onSaveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip(String label) {
    final isSelected = _labelController.text == label;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _labelController.text = label);
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
