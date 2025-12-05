import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/features/customer/screens/customer_layout.dart';
import 'package:tazto/features/customer/screens/privacy_screen.dart';
import 'package:tazto/features/seller/screens/seller_screen_layout.dart';
import 'package:tazto/providers/login_provider.dart';

import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Artificial delay for branding (optional, keep it short)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check auth status via Provider
    final loginProvider = context.read<LoginProvider>();
    final destination = await loginProvider.checkLoginStatus(context);

    if (!mounted) return;

    Widget nextScreen;
    switch (destination) {
      case 'SELLER_HOME':
        nextScreen = const SellerLayout();
        break;
      case 'CUSTOMER_HOME':
        nextScreen = const CustomerLayout();
        break;
      case 'PRIVACY_CONSENT':
        nextScreen = const PrivacyConsentScreen();
        break;
      case 'LOGIN':
      default:
        nextScreen = const LoginPage();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flash_on, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              "LINC",
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Local Instant Commerce",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            // Small loader
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
