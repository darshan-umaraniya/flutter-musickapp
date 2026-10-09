import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String _userName = '';

  String get userName => _userName;

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// Load currently logged-in user's name from Firebase Realtime Database
  Future<void> loadUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        _userName = '';
        debugPrint('❌ No Firebase user logged in');
        return;
      }

      final String currentUid = firebaseUser.uid;

      debugPrint('================================');
      debugPrint('Loading User From Database');
      debugPrint('UID: $currentUid');

      // Your database structure:
      //
      // users
      //   00001
      //      uid
      //      name
      //      email
      //      loginDate
      //
      //   00002
      //      uid
      //      name
      //      email
      //      loginDate

      final DataSnapshot snapshot = await FirebaseDatabase.instance
          .ref('users')
          .orderByChild('uid')
          .equalTo(currentUid)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> users = Map<dynamic, dynamic>.from(
          snapshot.value as Map,
        );

        if (users.isNotEmpty) {
          final Map<dynamic, dynamic> userData = Map<dynamic, dynamic>.from(
            users.values.first as Map,
          );

          _userName = userData['name']?.toString().trim() ?? '';

          debugPrint('Database Name: $_userName');
        }
      }

      debugPrint('Final User Name: $_userName');
      debugPrint('================================');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ UserProvider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUserName(String name) {
    _userName = name.trim();
    notifyListeners();
  }

  void clearUser() {
    _userName = '';
    notifyListeners();
  }
}
