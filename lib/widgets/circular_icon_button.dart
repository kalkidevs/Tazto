import 'package:flutter/material.dart';
import 'package:tazto/app/config/app_theme.dart';

/// A generic circular icon button with shadow and splash effects.
/// Useful for AppBars, Floating actions, and list items.
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final double elevation;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.white,
    this.iconColor = AppColors.textPrimary,
    this.size = 40.0,
    this.iconSize = 22.0,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size),
          onTap: onPressed,
          child: Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}