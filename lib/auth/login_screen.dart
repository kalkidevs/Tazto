// on login add switch customers, sellers , sellers can also make account as customer
// add flagging for customer = 1 , seller = 1.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/auth/signup_screen.dart';
import 'package:tazto/features/customer/screens/customer_layout.dart';
import 'package:tazto/features/seller/screens/screen_layout.dart';
import 'package:tazto/helper/dialog_helper.dart';

import '../app/config/app_theme.dart';
import '../helper/roleToggle.dart';
import '../providers/login_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  late final AnimationController _cardAnim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();

    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut));

    _cardAnim.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _cardAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loginProv = context.watch<LoginProvider>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.12),
                    cs.secondaryContainer.withOpacity(0.12),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative blob
            Positioned(
              top: -120,
              right: -80,
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(140),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withOpacity(0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            // Login card
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: Border.all(color: cs.outline.withOpacity(0.08)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 56,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "LINC",
                            style: GoogleFonts.montserrat(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Login to your account",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Role toggle
                          RoleToggle(
                            isCustomer: loginProv.isCustomerLogin,
                            onChanged: loginProv.toggleLoginRole,
                          ),
                          const SizedBox(height: 20),

                          // Email field
                          _AnimatedField(
                            focusNode: _emailFocus,
                            child: TextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _passwordFocus.requestFocus(),
                              decoration: InputDecoration(
                                labelText: "Email",
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: cs.surface.withOpacity(0.7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password field
                          _AnimatedField(
                            focusNode: _passwordFocus,
                            child: TextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              // *** FIXED: Pass context to _submit ***
                              onSubmitted: (_) => _submit(context),
                              decoration: InputDecoration(
                                labelText: "Password",
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                                filled: true,
                                fillColor: cs.surface.withOpacity(0.7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Error message removed from here
                          const SizedBox(height: 10), // Added padding
                          // Login button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: loginProv.isLoading ? 0 : 2,
                              ),
                              onPressed: loginProv.isLoading
                                  ? null
                                  // *** FIXED: Pass context to _submit ***
                                  : () => _submit(context),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: loginProv.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text("Login"),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Sign Up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don’t have an account? ",
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext ctx) async {
    FocusScope.of(ctx).unfocus();
    // Use read() here as we are in a function
    final prov = ctx.read<LoginProvider>();

    // *** FIXED: Pass context to the login method ***
    final success = await prov.login(
      ctx, // Pass the BuildContext
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // route based on selected role preference
      if (prov.isCustomerLogin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerLayout()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SellerLayout()),
        );
      }
    } else {
      // Use the new dialog helper
      // The provider's errorMessage will have the user-friendly message
      showErrorDialog(
        context,
        "Login Failed",
        prov.errorMessage ?? "An unknown error occurred.",
      );
    }
  }
}

class _AnimatedField extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;

  const _AnimatedField({required this.focusNode, required this.child});

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: widget.child,
    );
  }
}
