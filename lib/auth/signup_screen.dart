import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../helper/dialog_helper.dart';
import '../helper/roleToggle.dart';
import '../providers/signupPdr.dart';
import '../app/config/app_theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  // ADDED: Controllers and FocusNodes for the 'name' field
  late final TextEditingController _nameC;
  late final TextEditingController _emailC;
  late final TextEditingController _passC;
  late final FocusNode _focusName, _focusEmail, _focusPass;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // ADDED: Initialize 'name' controller
    _nameC = TextEditingController();
    _emailC = TextEditingController();
    _passC = TextEditingController();

    // ADDED: Initialize 'name' focus node
    _focusName = FocusNode();
    _focusEmail = FocusNode();
    _focusPass = FocusNode();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    for (final node in [
      // ADDED: Dispose 'name' focus node
      _focusName,
      _focusEmail,
      _focusPass,
    ]) {
      node.dispose();
    }

    for (final ctrl in [
      // ADDED: Dispose 'name' controller
      _nameC,
      _emailC,
      _passC,
    ]) {
      ctrl.dispose();
    }

    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Updated to use SignupProvider
    final reg = context.watch<SignupProvider>();
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.1),
                    cs.secondary.withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Floating blob
            Positioned(
              top: -100,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            // Form card
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
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
                            'LINC',
                            style: GoogleFonts.montserrat(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Create your account',
                            style: TextStyle(
                              color: cs.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Role toggle
                          RoleToggle(
                            isCustomer: reg.isCustomerSignup,
                            onChanged: reg.toggleSignupRole,
                          ),
                          const SizedBox(height: 20),

                          // ADDED: Name Field
                          _FieldWrapper(
                            focus: _focusName,
                            child: TextField(
                              controller: _nameC,
                              focusNode: _focusName,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: cs.surface.withOpacity(0.7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onSubmitted: (_) => _focusEmail.requestFocus(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email field
                          _FieldWrapper(
                            focus: _focusEmail,
                            child: TextField(
                              controller: _emailC,
                              focusNode: _focusEmail,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: cs.surface.withOpacity(0.7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onSubmitted: (_) => _focusPass.requestFocus(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password field
                          _FieldWrapper(
                            focus: _focusPass,
                            child: TextField(
                              controller: _passC,
                              focusNode: _focusPass,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _onSubmit(context),
                              decoration: InputDecoration(
                                labelText: 'Password',
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
                          const SizedBox(height: 10),

                          // Error message removed from here
                          const SizedBox(height: 10), // Added padding
                          // Sign Up button
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
                              ),
                              onPressed: reg.isLoading
                                  ? null
                                  : () => _onSubmit(context),
                              child: reg.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign Up'),
                            ),
                          ),

                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Login',
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

  Future<void> _onSubmit(BuildContext context) async {
    // dismiss keyboard
    FocusScope.of(context).unfocus();

    // Use SignupProvider
    final reg = context.read<SignupProvider>();

    // UPDATED: Pass the name to the register function
    final success = await reg.register(
      name: _nameC.text.trim(),
      email: _emailC.text.trim(),
      password: _passC.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      // On success, go to login page (or straight to dashboard)
      // Going to login is often safer
      if (mounted) {
        Navigator.pop(context); // Go back to login
      }
    } else {
      HapticFeedback.heavyImpact();
      // Use the new dialog helper
      showErrorDialog(
        context,
        "Signup Failed",
        reg.errorMessage ?? "An unknown error occurred.",
      );
    }
  }
}

// This widget remains unchanged
class _FieldWrapper extends StatefulWidget {
  final FocusNode focus;
  final Widget child;

  const _FieldWrapper({required this.focus, required this.child});

  @override
  State<_FieldWrapper> createState() => _FieldWrapperState();
}

class _FieldWrapperState extends State<_FieldWrapper> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focus.addListener(_onChange);
    _focused = widget.focus.hasFocus;
  }

  void _onChange() {
    if (!mounted) return;
    setState(() => _focused = widget.focus.hasFocus);
  }

  @override
  void dispose() {
    widget.focus.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: widget.child,
    );
  }
}
