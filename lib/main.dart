import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/customer_provider.dart';
import 'package:tazto/providers/login_provider.dart';
import 'package:tazto/providers/seller_provider.dart';
import 'package:tazto/providers/signupPdr.dart';
import 'package:tazto/splash_screen.dart';

// --- GLOBAL NAVIGATION KEY ---
// This allows us to trigger navigation (like Logout) from non-UI classes like ApiClient
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => SellerProvider()),

        ChangeNotifierProvider(
          create: (_) {
            final customerProv = CustomerProvider();
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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'LINC',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      scrollBehavior: const ScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
        scrollbars: false,
      ),
      home: const SplashScreen(),
    );
  }
}
