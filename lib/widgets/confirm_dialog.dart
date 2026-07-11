import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows a Yes/No dialog styled to match the app theme.
/// Returns `true` if the user confirmed, `false` otherwise.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = "Confirm",
  Color confirmColor = AppTheme.error,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.card(dialogContext),
      shape: RoundedRectangleBorder(borderRadius: AppTheme.radius18),
      title: Text(title, style: TextStyle(color: AppTheme.text(dialogContext))),
      content: Text(
        message,
        style: TextStyle(color: AppTheme.subtitleColor(dialogContext)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            "Cancel",
            style: TextStyle(color: AppTheme.subtitleColor(dialogContext)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmText, style: TextStyle(color: confirmColor)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
