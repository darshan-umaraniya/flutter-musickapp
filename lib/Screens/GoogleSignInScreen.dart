import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _currentUser;
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      setState(() => _currentUser = account);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _currentUser == null
                  ? _buildSignInView(textColor, subtitleColor)
                  : _buildProfileView(textColor, subtitleColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInView(Color textColor, Color subtitleColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.albumGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.music_note, color: Colors.white, size: 56),
        ),
        const SizedBox(height: 24),
        Text(
          "Sign in to continue",
          style: AppTheme.heading.copyWith(color: textColor),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _handleSignIn,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
              side: BorderSide(color: subtitleColor.withOpacity(.3)),
            ),
            icon: _isLoading
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
              _isLoading ? 'Signing in...' : 'Sign in with Google',
              style: TextStyle(color: textColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView(Color textColor, Color subtitleColor) {
    final user = _currentUser!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName ?? 'No name',
          style: AppTheme.heading.copyWith(color: textColor),
        ),
        const SizedBox(height: 4),
        Text(user.email, style: TextStyle(color: subtitleColor)),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSignOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
            ),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }
}
