import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/google_signin_button.dart';
import '../Screens/homescreen.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  // =========================================================
  // FIREBASE
  // =========================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =========================================================
  // GOOGLE SIGN IN
  // =========================================================

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // =========================================================
  // TEXT CONTROLLERS
  // =========================================================

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  // =========================================================
  // UI STATE
  // =========================================================

  bool _isLoading = false;

  bool _isPasswordVisible = false;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _initializeGoogleSignIn();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // =========================================================
  // INITIALIZE GOOGLE SIGN IN
  // =========================================================

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize();

      debugPrint('Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    }
  }

  // =========================================================
  // GENERATE NEXT STRESA USER ID
  //
  // 1       -> 00001
  // 2       -> 00002
  // 10      -> 00010
  // 100     -> 00100
  // 1000    -> 01000
  // 10000   -> 10000
  //
  // Firestore:
  //
  // counters
  //    └── users
  //         └── lastId: 1
  //
  // =========================================================

  Future<String> _getNextUserId() async {
    final DocumentReference counterReference = _firestore
        .collection('counters')
        .doc('users');

    return await _firestore.runTransaction<String>((transaction) async {
      final DocumentSnapshot snapshot = await transaction.get(counterReference);

      int lastId = 0;

      if (snapshot.exists) {
        final dynamic rawData = snapshot.data();

        if (rawData is Map<String, dynamic>) {
          final dynamic storedLastId = rawData['lastId'];

          if (storedLastId is int) {
            lastId = storedLastId;
          } else if (storedLastId is num) {
            lastId = storedLastId.toInt();
          }
        }
      }

      final int nextId = lastId + 1;

      transaction.set(counterReference, {
        'lastId': nextId,
      }, SetOptions(merge: true));

      final String formattedUid = nextId.toString().padLeft(5, '0');

      debugPrint('Generated Stresa UID: $formattedUid');

      return formattedUid;
    });
  }

  // =========================================================
  // CREATE ACCOUNT WITH EMAIL + PASSWORD
  // =========================================================

  Future<void> _createAccount() async {
    if (_isLoading) return;

    final String name = _nameController.text.trim();

    final String email = _emailController.text.trim();

    final String password = _passwordController.text.trim();

    // -------------------------------------------------------
    // VALIDATION
    // -------------------------------------------------------

    if (name.isEmpty) {
      _showMessage('Please enter your name.');
      return;
    }

    if (email.isEmpty) {
      _showMessage('Please enter your email.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter your password.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // -----------------------------------------------------
      // CREATE FIREBASE AUTH ACCOUNT
      // -----------------------------------------------------

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('User account could not be created.');
      }

      debugPrint('Firebase Auth UID: ${firebaseUser.uid}');

      // -----------------------------------------------------
      // SAVE NAME IN FIREBASE AUTH
      // -----------------------------------------------------

      await firebaseUser.updateDisplayName(name);

      // -----------------------------------------------------
      // GENERATE STRESA UID
      //
      // Example:
      // 00001
      // 00002
      // 00003
      // -----------------------------------------------------

      final String numericUid = await _getNextUserId();

      debugPrint('Stresa UID: $numericUid');

      // -----------------------------------------------------
      // SAVE USER IN FIRESTORE
      // -----------------------------------------------------

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': numericUid,
        'name': name,
        'email': email,
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      debugPrint('Email user created successfully.');

      debugPrint('Stresa UID: $numericUid');

      // -----------------------------------------------------
      // GO TO HOME
      // -----------------------------------------------------

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
    // -------------------------------------------------------
    // FIREBASE AUTH ERRORS
    // -------------------------------------------------------
    on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: ${e.code}');

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'weak-password':
          message = 'Password is too weak.';
          break;

        case 'network-request-failed':
          message = 'Please check your internet connection.';
          break;

        case 'operation-not-allowed':
          message = 'Email/password authentication is disabled.';
          break;

        default:
          message = e.message ?? 'Account creation failed.';
      }

      _showMessage(message);
    }
    // -------------------------------------------------------
    // OTHER ERRORS
    // -------------------------------------------------------
    catch (e) {
      debugPrint('Account creation error: $e');

      _showMessage('Account creation failed: $e');
    }
    // -------------------------------------------------------
    // STOP LOADING
    // -------------------------------------------------------
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // GOOGLE SIGN IN
  // =========================================================

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // -----------------------------------------------------
      // AUTHENTICATE WITH GOOGLE
      // -----------------------------------------------------

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      debugPrint('Google account: ${googleUser.email}');

      // -----------------------------------------------------
      // GET GOOGLE AUTHENTICATION
      // -----------------------------------------------------

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Google ID token is null.');
      }

      // -----------------------------------------------------
      // CREATE FIREBASE CREDENTIAL
      // -----------------------------------------------------

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // -----------------------------------------------------
      // SIGN IN TO FIREBASE
      // -----------------------------------------------------

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase user could not be created.');
      }

      debugPrint('Firebase Auth UID: ${firebaseUser.uid}');

      // -----------------------------------------------------
      // CREATE / UPDATE FIRESTORE USER
      // -----------------------------------------------------

      await _createGoogleUserInFirestore(firebaseUser, googleUser);

      // -----------------------------------------------------
      // GO TO HOME
      // -----------------------------------------------------

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
    // -------------------------------------------------------
    // GOOGLE SIGN-IN ERROR
    // -------------------------------------------------------
    on GoogleSignInException catch (e) {
      debugPrint('Google Sign-In error: $e');

      if (!mounted) return;

      _showMessage(
        'Google Sign-In failed: '
        '${e.description ?? e.code}',
      );
    }
    // -------------------------------------------------------
    // FIREBASE AUTH ERROR
    // -------------------------------------------------------
    on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth error: $e');

      if (!mounted) return;

      _showMessage(
        'Firebase authentication failed: '
        '${e.message ?? e.code}',
      );
    }
    // -------------------------------------------------------
    // OTHER ERROR
    // -------------------------------------------------------
    catch (e) {
      debugPrint('Google Sign-In failed: $e');

      if (!mounted) return;

      _showMessage('Sign-in failed: $e');
    }
    // -------------------------------------------------------
    // STOP LOADING
    // -------------------------------------------------------
    finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // CREATE / UPDATE GOOGLE USER IN FIRESTORE
  //
  // IMPORTANT:
  //
  // Firebase UID:
  // a5HVfSDPGYMKxPi2lZcudgfmU1E3
  //
  // remains the Firestore document ID.
  //
  // Stresa UID:
  // 00001
  //
  // is stored inside the document.
  //
  // =========================================================

  Future<void> _createGoogleUserInFirestore(
    User firebaseUser,
    GoogleSignInAccount googleUser,
  ) async {
    final DocumentReference userReference = _firestore
        .collection('users')
        .doc(firebaseUser.uid);

    // -------------------------------------------------------
    // CHECK WHETHER USER ALREADY EXISTS
    // -------------------------------------------------------

    final DocumentSnapshot userSnapshot = await userReference.get();

    // =======================================================
    // NEW GOOGLE USER
    // =======================================================

    if (!userSnapshot.exists) {
      // -----------------------------------------------------
      // GENERATE NEW STRESA UID
      // -----------------------------------------------------

      final String numericUid = await _getNextUserId();

      // -----------------------------------------------------
      // CREATE FIRESTORE DOCUMENT
      // -----------------------------------------------------

      await userReference.set({
        'uid': numericUid,
        'name': firebaseUser.displayName ?? googleUser.displayName ?? '',
        'email': firebaseUser.email ?? googleUser.email,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      debugPrint('New Google user created.');

      debugPrint('Stresa UID: $numericUid');

      return;
    }

    // =======================================================
    // EXISTING GOOGLE USER
    // =======================================================

    final dynamic rawData = userSnapshot.data();

    final Map<String, dynamic> data = rawData is Map<String, dynamic>
        ? rawData
        : <String, dynamic>{};

    final dynamic existingUid = data['uid'];

    // -------------------------------------------------------
    // CHECK IF UID IS ALREADY 5 DIGIT
    //
    // Valid:
    //
    // 00001
    // 00002
    // 00125
    // 10000
    //
    // Invalid:
    //
    // Firebase UID
    // 1
    // 123
    // abc123
    // -------------------------------------------------------

    final bool hasValidStresaUid =
        existingUid is String && RegExp(r'^\d{5}$').hasMatch(existingUid);

    String numericUid;

    // -------------------------------------------------------
    // EXISTING USER ALREADY HAS 5 DIGIT UID
    // -------------------------------------------------------

    if (hasValidStresaUid) {
      numericUid = existingUid;

      debugPrint('Existing Stresa UID found: $numericUid');
    }
    // -------------------------------------------------------
    // OLD USER NEEDS MIGRATION
    // -------------------------------------------------------
    else {
      debugPrint('Old UID found: $existingUid');

      debugPrint('Generating new Stresa UID...');

      numericUid = await _getNextUserId();

      debugPrint('New Stresa UID: $numericUid');
    }

    // -------------------------------------------------------
    // UPDATE EXISTING USER
    //
    // photoUrl is explicitly deleted.
    // -------------------------------------------------------

    await userReference.update({
      'uid': numericUid,

      'name': firebaseUser.displayName ?? googleUser.displayName ?? '',

      'email': firebaseUser.email ?? googleUser.email,

      'provider': 'google',

      'lastLogin': FieldValue.serverTimestamp(),

      // REMOVE OLD GOOGLE PHOTO URL
      'photoUrl': FieldValue.delete(),
    });

    debugPrint('Existing Google user updated.');

    debugPrint('Stresa UID: $numericUid');
  }

  // =========================================================
  // SHOW MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // =========================================================
  // BUILD
  // =========================================================

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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: _signUpView(textColor, subtitleColor),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SIGN UP UI
  // =========================================================

  Widget _signUpView(Color textColor, Color subtitleColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        // ===================================================
        // MUSIC ICON
        // ===================================================
        Container(
          padding: const EdgeInsets.all(20),

          decoration: const BoxDecoration(
            gradient: AppTheme.albumGradient,

            shape: BoxShape.circle,
          ),

          child: const Icon(Icons.music_note, color: Colors.white, size: 56),
        ),

        const SizedBox(height: 24),

        // ===================================================
        // TITLE
        // ===================================================
        Text(
          'Create your account',

          textAlign: TextAlign.center,

          style: AppTheme.heading.copyWith(color: textColor),
        ),

        const SizedBox(height: 10),

        // ===================================================
        // SUBTITLE
        // ===================================================
        Text(
          'Create an account to continue\n'
          'using Stresa',

          textAlign: TextAlign.center,

          style: TextStyle(color: subtitleColor, fontSize: 14, height: 1.4),
        ),

        const SizedBox(height: 30),

        // ===================================================
        // NAME
        // ===================================================
        TextField(
          controller: _nameController,

          keyboardType: TextInputType.name,

          textInputAction: TextInputAction.next,

          style: TextStyle(color: textColor),

          decoration: InputDecoration(
            hintText: 'Enter your name',

            labelText: 'Name',

            prefixIcon: const Icon(Icons.person_outline),

            border: OutlineInputBorder(borderRadius: AppTheme.radius12),

            enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radius12),

            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.radius12,

              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ===================================================
        // EMAIL
        // ===================================================
        TextField(
          controller: _emailController,

          keyboardType: TextInputType.emailAddress,

          textInputAction: TextInputAction.next,

          style: TextStyle(color: textColor),

          decoration: InputDecoration(
            hintText: 'Enter your email',

            labelText: 'Email',

            prefixIcon: const Icon(Icons.email_outlined),

            border: OutlineInputBorder(borderRadius: AppTheme.radius12),

            enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radius12),

            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.radius12,

              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ===================================================
        // PASSWORD
        // ===================================================
        TextField(
          controller: _passwordController,

          obscureText: !_isPasswordVisible,

          textInputAction: TextInputAction.done,

          style: TextStyle(color: textColor),

          decoration: InputDecoration(
            hintText: 'Enter your password',

            labelText: 'Password',

            prefixIcon: const Icon(Icons.lock_outline),

            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },

              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
            ),

            border: OutlineInputBorder(borderRadius: AppTheme.radius12),

            enabledBorder: OutlineInputBorder(borderRadius: AppTheme.radius12),

            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.radius12,

              borderSide: BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),

          onSubmitted: (_) {
            _createAccount();
          },
        ),

        const SizedBox(height: 24),

        // ===================================================
        // CREATE ACCOUNT BUTTON
        // ===================================================
        SizedBox(
          width: double.infinity,
          height: 52,

          child: ElevatedButton(
            onPressed: _isLoading ? null : _createAccount,

            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,

              foregroundColor: Colors.white,

              shape: RoundedRectangleBorder(borderRadius: AppTheme.radius12),
            ),

            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,

                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Create Account',

                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // ===================================================
        // OR DIVIDER
        // ===================================================
        Row(
          children: [
            Expanded(child: Divider(color: subtitleColor.withOpacity(0.3))),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),

              child: Text(
                'OR',

                style: TextStyle(color: subtitleColor, fontSize: 13),
              ),
            ),

            Expanded(child: Divider(color: subtitleColor.withOpacity(0.3))),
          ],
        ),

        const SizedBox(height: 20),

        // ===================================================
        // GOOGLE SIGN-IN BUTTON
        // ===================================================
        GoogleSignInButton(
          isLoading: _isLoading,

          onPressed: _handleGoogleSignIn,
        ),
      ],
    );
  }
}
