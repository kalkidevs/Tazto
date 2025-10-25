import 'package:flutter/material.dart';

import '../widgets/error_dialog.dart';

/// A reusable helper function to show the animated error dialog.
///
/// [context] - The BuildContext from which to show the dialog.
/// [title] - The title of the dialog (e.g., "Login Failed").
/// [message] - The user-friendly error message to display.
void showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    // Prevents closing the dialog by tapping outside of it
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return ErrorDialog(
        title: title,
        message: message,
      );
    },
  );
}

