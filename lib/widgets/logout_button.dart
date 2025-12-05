import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../auth/login_screen.dart';
import '../providers/login_provider.dart';

/// A shared function to trigger the Joyful Logout Dialog
void showJoyfulLogoutDialog(BuildContext context) {
  HapticFeedback.lightImpact();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black87.withOpacity(0.7),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim1, curve: Curves.elasticOut)),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: _JoyfulLogoutDialogContent(ctx: ctx),
          ),
        ),
      );
    },
  );
}

/// A standard ListTile for Drawers that triggers the logout flow
class LogoutListTile extends StatelessWidget {
  final Color? color;

  const LogoutListTile({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Colors.red.shade700;
    final bgColor = color?.withOpacity(0.1) ?? Colors.red.shade50;

    return ListTile(
      onTap: () {
        Navigator.pop(context); // Close drawer if open
        showJoyfulLogoutDialog(context);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: bgColor,
      leading: Icon(Icons.logout_rounded, color: themeColor),
      title: Text(
        'Log Out',
        style: GoogleFonts.poppins(
          color: themeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The original big, animated logout button for Profile screens
class ReusableLogoutButton extends StatefulWidget {
  const ReusableLogoutButton({super.key});

  @override
  State<ReusableLogoutButton> createState() => _ReusableLogoutButtonState();
}

class _ReusableLogoutButtonState extends State<ReusableLogoutButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _glowAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    final shakeTweenSequence = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]);
    _shakeAnimation = shakeTweenSequence.animate(_shakeController);

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            _shakeController,
            _glowController,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed
                  ? 0.92
                  : (_isHovered ? _pulseAnimation.value : 1.0),
              child: Transform.rotate(
                angle: _shakeAnimation.value,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(
                          0.4 * _glowAnimation.value,
                        ),
                        blurRadius: 20 + (10 * _glowAnimation.value),
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade600,
                          Colors.red.shade700,
                          Colors.red.shade800,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _shakeController.forward(from: 0);
                          HapticFeedback.mediumImpact();
                          Future.delayed(const Duration(milliseconds: 300), () {
                            showJoyfulLogoutDialog(context);
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.yellowAccent,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// --- INTERNAL WIDGETS (Not exported to keep namespace clean) ---

class _JoyfulLogoutDialogContent extends StatelessWidget {
  final BuildContext ctx;

  const _JoyfulLogoutDialogContent({required this.ctx});

  void _performJoyfulLogout(BuildContext context) {
    final loginProvider = context.read<LoginProvider>();
    final navigator = Navigator.of(context);

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '✨ Logging out ✨',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Come back soon!',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      loginProvider.logout(context);
      navigator.pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.orange.shade400],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade200,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'See You Soon! 👋',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Stay',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade500, Colors.red.shade700],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade300.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      HapticFeedback.heavyImpact();
                      _performJoyfulLogout(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
