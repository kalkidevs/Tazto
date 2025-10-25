import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tazto/providers/loginPdr.dart';
import 'package:tazto/providers/signupPdr.dart';
import 'package:tazto/providers/seller_provider.dart';
import 'package:tazto/providers/customer_provider.dart';

import 'package:tazto/splash_screen.dart';
import 'package:tazto/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => SellerProvider()),

        // <- Here we wire up fetchProducts() immediately:
        ChangeNotifierProvider(
          create: (_) {
            final customerProv = CustomerProvider();
            customerProv.fetchProducts();
            return customerProv;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
