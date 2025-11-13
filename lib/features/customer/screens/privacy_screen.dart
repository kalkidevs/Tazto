import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/screens/customer_layout.dart';

class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _isLoading = false;

  Future<void> _grantConsent() async {
    setState(() => _isLoading = true);

    try {
      // 1. Set the flag in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_consented_to_privacy', true);

      // 2. Navigate to the main app layout
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerLayout()),
        );
      }
    } catch (e) {
      // Handle error (e.g., show a snackbar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save preference: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.shield_outlined, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Your Privacy Matters',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To provide you with a personalized shopping experience, LINC needs to access your account data. This includes:',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildPermissionItem(
                'Personal Profile',
                'Your name and email for account management.',
              ),
              _buildPermissionItem(
                'Address Data',
                'To show nearby stores and deliver your orders.',
              ),
              _buildPermissionItem(
                'Order History',
                'To help you reorder items and track purchases.',
              ),
              const Spacer(),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _grantConsent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('I Understand & Agree'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
