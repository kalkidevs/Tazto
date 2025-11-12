import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/seller_provider.dart';
import 'package:tazto/widgets/error_dialog.dart';

/// A full-screen page to force a new seller to create their store profile.
class CreateStorePage extends StatefulWidget {
  const CreateStorePage({super.key});

  @override
  State<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState extends State<CreateStorePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isGettingLocation = false;
  Position? _currentPosition;

  final _storeNameC = TextEditingController();
  final _addressC = TextEditingController();
  final _pincodeC = TextEditingController();

  @override
  void dispose() {
    _storeNameC.dispose();
    _addressC.dispose();
    _pincodeC.dispose();
    super.dispose();
  }

  /// Fetches the device's current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isGettingLocation = false;
      });
      if (mounted) {
        // --- THIS IS THE FIX ---
        // The onOk callback is now empty, because the
        // SuccessDialog handles popping itself.
        showSuccessDialog(
          context,
          'Location Set!',
          'Your store location has been set to your current coordinates.',
          () {}, // <-- FIX: Was () => Navigator.of(context).pop()
        );
        // --- END OF FIX ---
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        showErrorDialog(context, 'Location Error', e.toString());
      }
    }
  }

  /// Submits the form to create the store
  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      showErrorDialog(
        context,
        'Missing Location',
        'Please set your store location using the button before creating the store.',
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<SellerProvider>();
    final success = await provider.createStoreProfile(
      storeName: _storeNameC.text,
      address: _addressC.text,
      pincode: _pincodeC.text,
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
    );

    if (mounted) {
      if (success) {
        // No need to do anything else. The provider will notify
        // SellerLayout, which will rebuild and show the dashboard.
      } else {
        setState(() => _isLoading = false);
        showErrorDialog(
          context,
          'Creation Failed',
          provider.storeError ?? 'An unknown error occurred.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome, Partner!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Let\'s set up your store to get started.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  _storeNameC,
                  'Store Name',
                  Icons.storefront,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _addressC,
                  'Store Address',
                  Icons.location_on_outlined,
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _pincodeC,
                  'Pincode',
                  Icons.pin_outlined,
                  isRequired: true,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _currentPosition == null
                              ? Icons.my_location
                              : Icons.check_circle,
                          color: _currentPosition == null
                              ? AppColors.primary
                              : Colors.green,
                        ),
                  label: Text(
                    _currentPosition == null
                        ? 'Set Store Location'
                        : 'Location Set!',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _currentPosition == null
                        ? AppColors.primary
                        : Colors.green,
                    side: BorderSide(
                      color: _currentPosition == null
                          ? AppColors.primary
                          : Colors.green,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          'Create Store',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
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
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}
