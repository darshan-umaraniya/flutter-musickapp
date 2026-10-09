import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:musicapp/Screens/AdminDashboard.dart';
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
  // ============================================================

  // CONTROLLERS

  // ============================================================

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  // ============================================================

  // FIREBASE

  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================

  // GOOGLE SIGN-IN

  // ============================================================

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ============================================================

  // VARIABLES

  // ============================================================

  bool _obscureText = true;

  bool _isLoading = false;

  // ============================================================

  // ADMIN EMAIL

  //

  // IMPORTANT:

  // The password is NOT stored here.

  // Firebase Authentication handles the password.

  // ============================================================

  static const String adminEmail = 'admin@gmail.com';

  // ============================================================

  // INIT STATE

  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeGoogleSignIn();
  }

  // ============================================================

  // INITIALIZE GOOGLE SIGN-IN

  // ============================================================

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();

      debugPrint('Google Sign-In initialized');
    } catch (e) {
      debugPrint('Google Sign-In initialization error: $e');
    }
  }

  // ============================================================

  // DISPOSE

  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================

  // EMAIL + PASSWORD LOGIN

  // ============================================================

  Future<void> _login() async {
    final String email = _emailController.text.trim();

    final String password = _passwordController.text;

    // ----------------------------------------------------------

    // VALIDATION

    // ----------------------------------------------------------

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );

      return;
    }

    // ----------------------------------------------------------

    // EMAIL VALIDATION

    // ----------------------------------------------------------

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================

      // FIREBASE EMAIL/PASSWORD LOGIN

      // ========================================================

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase user not found.');
      }

      debugPrint('Firebase login successful');

      debugPrint('UID: ${user.uid}');

      // ========================================================

      // UPDATE LAST LOGIN

      // ========================================================

      await _updateUserAfterLogin(user);

      if (!mounted) return;

      // ========================================================

      // CHECK ADMIN

      // ========================================================

      if ((user.email ?? '').toLowerCase() == adminEmail.toLowerCase()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Admin login successful')));

        Navigator.pushReplacement(
          context,

          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else {
        // ======================================================

        // NORMAL USER

        // ======================================================

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful')));

        Navigator.pushReplacement(
          context,

          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
    // ==========================================================
    // FIREBASE AUTH ERRORS
    // ==========================================================
    on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-credential':
          message = 'Invalid email or password.';

          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';

          break;

        case 'user-not-found':
          message = 'No account found with this email.';

          break;

        case 'wrong-password':
          message = 'Incorrect password.';

          break;

        case 'user-disabled':
          message = 'This account has been disabled.';

          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';

          break;

        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';

          break;

        default:
          message = e.message ?? 'Login failed.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    // ==========================================================
    // OTHER ERRORS
    // ==========================================================
    catch (e) {
      debugPrint('Login error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
    // ==========================================================
    // STOP LOADING
    // ==========================================================
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================

  // GOOGLE LOGIN

  // ============================================================

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================

      // GOOGLE AUTHENTICATION

      // ========================================================

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      debugPrint('Google account: ${googleUser.email}');

      // ========================================================

      // GET GOOGLE AUTHENTICATION

      //

      // IMPORTANT:

      // No await here in Google Sign-In 7.x

      // ========================================================

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // ========================================================

      // CHECK ID TOKEN

      // ========================================================

      if (googleAuth.idToken == null) {
        throw Exception('Google ID token is null.');
      }

      // ========================================================

      // FIREBASE CREDENTIAL

      // ========================================================

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // ========================================================

      // FIREBASE LOGIN

      // ========================================================

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase user could not be created.');
      }

      debugPrint('Google Firebase login successful');

      debugPrint('UID: ${user.uid}');

      // ========================================================

      // CREATE / UPDATE FIRESTORE USER

      // ========================================================

      await _createOrUpdateGoogleUser(user, googleUser);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In successful')),
      );

      // ========================================================

      // GOOGLE USERS → HOME

      // ========================================================

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
    // ==========================================================
    // GOOGLE SIGN-IN ERROR
    // ==========================================================
    on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In failed: '
            '${e.description ?? e.code}',
          ),
        ),
      );
    }
    // ==========================================================
    // FIREBASE ERROR
    // ==========================================================
    on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google Auth error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Firebase authentication failed.')),
      );
    }
    // ==========================================================
    // OTHER ERROR
    // ==========================================================
    catch (e) {
      debugPrint('Google login error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google login failed: $e')));
    }
    // ==========================================================
    // STOP LOADING
    // ==========================================================
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================

  // UPDATE USER AFTER EMAIL LOGIN

  // ============================================================

  Future<void> _updateUserAfterLogin(User user) async {
    final DocumentReference userRef = _firestore
        .collection('users')
        .doc(user.uid);

    final DocumentSnapshot snapshot = await userRef.get();

    if (snapshot.exists) {
      await userRef.update({'lastLogin': FieldValue.serverTimestamp()});
    } else {
      await userRef.set({
        'uid': user.uid,

        'name': user.displayName ?? '',

        'email': user.email ?? '',

        'photoUrl': user.photoURL,

        'provider': 'email',

        'createdAt': FieldValue.serverTimestamp(),

        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============================================================

  // CREATE / UPDATE GOOGLE USER

  // ============================================================

  Future<void> _createOrUpdateGoogleUser(
    User user,

    GoogleSignInAccount googleUser,
  ) async {
    final DocumentReference userRef = _firestore
        .collection('users')
        .doc(user.uid);

    final DocumentSnapshot snapshot = await userRef.get();

    // ----------------------------------------------------------

    // NEW GOOGLE USER

    // ----------------------------------------------------------

    if (!snapshot.exists) {
      await userRef.set({
        'uid': user.uid,

        'name': user.displayName ?? googleUser.displayName ?? '',

        'email': user.email ?? googleUser.email,

        'photoUrl': user.photoURL ?? googleUser.photoUrl,

        'provider': 'google',

        'createdAt': FieldValue.serverTimestamp(),

        'lastLogin': FieldValue.serverTimestamp(),
      });

      debugPrint('New Google user created.');
    }
    // ----------------------------------------------------------
    // EXISTING GOOGLE USER
    // ----------------------------------------------------------
    else {
      await userRef.update({
        'name': user.displayName ?? googleUser.displayName ?? '',

        'email': user.email ?? googleUser.email,

        'photoUrl': user.photoURL ?? googleUser.photoUrl,

        'lastLogin': FieldValue.serverTimestamp(),
      });

      debugPrint('Google user updated.');
    }
  }

  // ============================================================

  // INPUT DECORATION

  // ============================================================

  InputDecoration _fieldDecoration(
    BuildContext context,

    String label, {

    Widget? suffixIcon,
  }) {
    final Color subtitleColor = AppTheme.subtitleColor(context);

    return InputDecoration(
      labelText: label,

      labelStyle: TextStyle(color: subtitleColor),

      filled: true,

      fillColor: AppTheme.card(context),

      suffixIcon: suffixIcon,

      border: OutlineInputBorder(
        borderRadius: AppTheme.radius12,

        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: AppTheme.radius12,

        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.radius12,

        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }

  // ============================================================

  // BUILD

  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppTheme.text(context);

    final Color subtitleColor = AppTheme.subtitleColor(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient(context),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),

            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    // ==================================================

                    // LOGO

                    // ==================================================
                    Container(
                      padding: const EdgeInsets.all(20),

                      decoration: const BoxDecoration(
                        gradient: AppTheme.albumGradient,

                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.music_note,

                        color: Colors.white,

                        size: 56,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================

                    // TITLE

                    // ==================================================
                    Text(
                      'Welcome Back',

                      style: AppTheme.heading.copyWith(color: textColor),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Login to continue listening',

                      style: AppTheme.subtitle.copyWith(color: subtitleColor),
                    ),

                    const SizedBox(height: 32),

                    // ==================================================

                    // EMAIL

                    // ==================================================
                    TextField(
                      controller: _emailController,

                      keyboardType: TextInputType.emailAddress,

                      enabled: !_isLoading,

                      style: TextStyle(color: textColor),

                      decoration: _fieldDecoration(context, 'Email'),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================

                    // PASSWORD

                    // ==================================================
                    TextField(
                      controller: _passwordController,

                      obscureText: _obscureText,

                      enabled: !_isLoading,

                      style: TextStyle(color: textColor),

                      decoration: _fieldDecoration(
                        context,

                        'Password',

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,

                            color: subtitleColor,
                          ),

                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================

                    // LOGIN BUTTON

                    // ==================================================
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 14.0),

                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.radius12,
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                                height: 20,

                                width: 20,

                                child: CircularProgressIndicator(
                                  strokeWidth: 2,

                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',

                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================

                    // OR

                    // ==================================================
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: subtitleColor.withOpacity(.3)),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),

                          child: Text(
                            'or',

                            style: TextStyle(color: subtitleColor),
                          ),
                        ),

                        Expanded(
                          child: Divider(color: subtitleColor.withOpacity(.3)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ==================================================

                    // GOOGLE SIGN-IN

                    // ==================================================
                    GoogleSignInButton(
                      isLoading: _isLoading,

                      onPressed: _signInWithGoogle,
                    ),

                    const SizedBox(height: 20),

                    // ==================================================

                    // SIGN UP

                    // ==================================================
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GoogleSignInScreen(),
                                ),
                              );
                            },

                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",

                          style: TextStyle(color: subtitleColor),

                          children: const [
                            TextSpan(
                              text: 'Sign Up',

                              style: TextStyle(
                                color: AppTheme.primary,

                                fontWeight: FontWeight.w600,
                              ),
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
