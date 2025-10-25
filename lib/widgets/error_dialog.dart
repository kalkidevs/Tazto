import 'dart:async';

import 'package:flutter/material.dart';

/// An enhanced, animated error dialog with modern Material Design 3 styling.
///
/// Features:
/// - Smooth fade, scale, and slide animations
/// - Material 3 design with elevated surface
/// - Pulsing error icon animation
/// - Subtle shadow and blur effects
/// - Customizable appearance
class ErrorDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText,
    this.onDismiss,
  });

  @override
  State<ErrorDialog> createState() => _ErrorDialogState();
}

class _ErrorDialogState extends State<ErrorDialog>
    with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late AnimationController _iconController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _iconPulseAnimation;

  @override
  void initState() {
    super.initState();

    // Main dialog animation
    _dialogController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _dialogController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Icon pulse animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(_iconController);

    _dialogController.forward();
    _iconController.repeat();
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await _dialogController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Dialog(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.0),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surface.withOpacity(0.95),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with animated icon
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Column(
                      children: [
                        // Animated error icon with background
                        ScaleTransition(
                          scale: _iconPulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer.withOpacity(
                                0.3,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Title
                        Text(
                          widget.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Message content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      widget.message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Action button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _closeDialog,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.buttonText ?? 'OK',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to show the enhanced error dialog
Future<void> showEnhancedErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? buttonText,
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => ErrorDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      onDismiss: onDismiss,
    ),
  );
}
