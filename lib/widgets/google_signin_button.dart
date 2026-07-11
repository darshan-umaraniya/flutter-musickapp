import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The "Sign in with Google" outlined button, with its loading state.
/// Used on both the Login screen and the Google Sign-In screen so the
/// icon/spinner/label logic isn't duplicated.
class GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const GoogleSignInButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
          side: BorderSide(color: subtitleColor.withOpacity(.3)),
        ),
        icon: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.network(
                'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
                height: 22,
              ),
        label: Text(
          isLoading ? 'Signing in...' : 'Sign in with Google',
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}
