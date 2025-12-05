import 'package:flutter/material.dart';
import 'package:tazto/app/config/app_theme.dart';

/// A reusable loading overlay that can be wrapped around any widget.
/// It shows a smooth fade-in/out transition and a custom loading indicator.
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Animated opacity for smooth transition
        IgnorePointer(
          ignoring: !isLoading,
          child: AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              color: Colors.white.withOpacity(0.8), // Glassmorphism-like background
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Custom animated loader
                    const _PulsingLogoLoader(),
                    const SizedBox(height: 24),
                    if (message != null)
                      Material(
                        color: Colors.transparent,
                        child: Text(
                          message!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsingLogoLoader extends StatefulWidget {
  const _PulsingLogoLoader();

  @override
  State<_PulsingLogoLoader> createState() => _PulsingLogoLoaderState();
}

class _PulsingLogoLoaderState extends State<_PulsingLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20 * _controller.value,
                    spreadRadius: 5 * _controller.value,
                  ),
                ],
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }
}