import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:musicapp/Screens/homescreen.dart';
import 'package:musicapp/Screens/GoogleSignInScreen.dart';
import '../theme/app_theme.dart';
import '../widgets/google_signin_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter email and password')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful')));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signed in as ${googleUser.email}')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, String label, {Widget? suffixIcon}) {
    final subtitleColor = AppTheme.subtitleColor(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: subtitleColor),
      filled: true,
      fillColor: AppTheme.card(context),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: AppTheme.radius12, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radius12, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.radius12,
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.text(context);
    final subtitleColor = AppTheme.subtitleColor(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient(context)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(gradient: AppTheme.albumGradient, shape: BoxShape.circle),
                      child: const Icon(Icons.music_note, color: Colors.white, size: 56),
                    ),
                    const SizedBox(height: 12),
                    Text("Welcome Back", style: AppTheme.heading.copyWith(color: textColor)),
                    const SizedBox(height: 6),
                    Text("Login to continue listening", style: AppTheme.subtitle.copyWith(color: subtitleColor)),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor),
                      decoration: _fieldDecoration(context, 'Email'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      style: TextStyle(color: textColor),
                      decoration: _fieldDecoration(
                        context,
                        'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: subtitleColor),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
                        ),
                        child: const Text('Login', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: subtitleColor.withOpacity(.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("or", style: TextStyle(color: subtitleColor)),
                        ),
                        Expanded(child: Divider(color: subtitleColor.withOpacity(.3))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GoogleSignInButton(isLoading: _isLoading, onPressed: _signInWithGoogle),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GoogleSignInScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: subtitleColor),
                          children: const [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
