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
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Column(
                      children: [
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

/// An enhanced, animated success dialog with modern Material Design 3 styling.
///
/// Features:
/// - Smooth fade, scale, and slide animations
/// - Material 3 design with elevated surface
/// - Animated checkmark with celebration effect
/// - Customizable appearance and callbacks
class SuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText,
    this.onDismiss,
  });

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _dialogController;
  late AnimationController _iconController;
  late AnimationController _celebrationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();

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

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeOut,
    );

    _dialogController.forward();
    _iconController.forward();
    _celebrationController.forward();
  }

  @override
  void dispose() {
    _dialogController.dispose();
    _iconController.dispose();
    _celebrationController.dispose();
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
    final successColor = Colors.green.shade600;

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
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Column(
                      children: [
                        // Animated success icon with celebration effect
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Celebration ring
                            FadeTransition(
                              opacity: _celebrationAnimation,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.8,
                                  end: 1.8,
                                ).animate(_celebrationAnimation),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: successColor.withOpacity(
                                        1 - _celebrationAnimation.value,
                                      ),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Main icon
                            ScaleTransition(
                              scale: _checkAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: successColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 48,
                                  color: successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _closeDialog,
                        style: FilledButton.styleFrom(
                          backgroundColor: successColor,
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
                            color: Colors.white,
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

// Helper function to show the error dialog
void showErrorDialog(
  BuildContext context,
  String title,
  String message, {
  String? buttonText,
  VoidCallback? onDismiss,
}) {
  showDialog(
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

// Helper function to show the success dialog
void showSuccessDialog(
  BuildContext context,
  String title,
  String message,
  VoidCallback onOk, {
  String? buttonText,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SuccessDialog(
      title: title,
      message: message,
      buttonText: buttonText,
      onDismiss: onOk,
    ),
  );
}
