import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../core/models/app_user.dart';

class GoogleSignInResult {
  final User? user;
  final bool isNewUser;

  const GoogleSignInResult({
    required this.user,
    required this.isNewUser,
  });
}

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  static const String _keySessionActive = 'auth_session_active';
  static const String _keyUserUid = 'auth_session_uid';
  static const String _keyUserEmail = 'auth_session_email';

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Auth state stream — use this to reactively route between login/home.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Resolves the current authenticated user safely on startup,
  /// awaiting token hydration from local storage if needed.
  static Future<User?> resolveCurrentUser({Duration timeout = const Duration(milliseconds: 2000)}) async {
    if (_auth.currentUser != null) {
      await _saveSessionLocally(_auth.currentUser!);
      return _auth.currentUser;
    }

    try {
      final user = await _auth.authStateChanges().first.timeout(timeout);
      if (user != null) {
        await _saveSessionLocally(user);
      }
      return user ?? _auth.currentUser;
    } catch (_) {
      return _auth.currentUser;
    }
  }

  /// Checks if a valid persistent session flag exists in local preferences.
  static Future<bool> isSessionPersisted() async {
    if (_auth.currentUser != null) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keySessionActive) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the AppUser doc for the given uid from Firestore.
  static Future<AppUser?> getAppUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return AppUser.fromMap(doc.data()!);
    } catch (e) {
      if (kDebugMode) print('AuthService.getAppUser error: $e');
    }
    return null;
  }

  /// Stream of the current user's Firestore doc.
  static Stream<AppUser?> get currentUserStream {
    final uid = currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.exists ? AppUser.fromMap(snap.data()!) : null);
  }

  /// Sign in with Google. Creates Firestore user doc on first sign-in.
  /// Returns a [GoogleSignInResult] indicating the user and whether it is a new registration.
  static Future<GoogleSignInResult> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return const GoogleSignInResult(user: null, isNewUser: false);

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    bool isNew = result.additionalUserInfo?.isNewUser ?? false;
    if (result.user != null) {
      await _saveSessionLocally(result.user!);
      final wasCreated = await _createUserDocIfNeeded(result.user!);
      if (wasCreated) isNew = true;
    }
    return GoogleSignInResult(user: result.user, isNewUser: isNew);
  }

  /// Sign in with Email and Password.
  static Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (credential.user != null) {
      await _saveSessionLocally(credential.user!);
      await _createUserDocIfNeeded(credential.user!);
    }
    return credential.user;
  }

  /// Sign up with Email, Password, and optional Display Name.
  static Future<User?> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (credential.user != null) {
      await _saveSessionLocally(credential.user!);
      if (username != null && username.trim().isNotEmpty) {
        await credential.user!.updateDisplayName(username.trim());
      }
      await _createUserDocIfNeeded(credential.user!, customName: username?.trim());
    }
    return credential.user;
  }

  /// Sign in anonymously for guest users.
  static Future<User?> signInAnonymously() async {
    final result = await _auth.signInAnonymously();
    if (result.user != null) {
      await _saveSessionLocally(result.user!);
    }
    return result.user;
  }

  /// Public helper to check and safely ensure user doc exists without overwriting existing counts.
  static Future<void> ensureUserDocExists([User? user]) async {
    final firebaseUser = user ?? currentUser;
    if (firebaseUser == null) return;
    await _createUserDocIfNeeded(firebaseUser);
  }

  /// Creates the Firestore user doc only if it doesn't exist yet.
  /// If doc already exists, preserves existing Durood totals and updates metadata using SetOptions(merge: true).
  /// Returns true if newly created, false if already existed.
  static Future<bool> _createUserDocIfNeeded(User firebaseUser, {String? customName}) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      final name = (customName != null && customName.isNotEmpty)
          ? customName
          : (firebaseUser.displayName?.isNotEmpty == true
              ? firebaseUser.displayName!
              : (firebaseUser.email?.isNotEmpty == true
                  ? firebaseUser.email!.split('@').first
                  : 'User'));
      final newUser = AppUser(
        userId: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: name,
        photoUrl: firebaseUser.photoURL ?? '',
        personalTotalDurood: 0,
        personalTodayDurood: 0,
      );
      await docRef.set(newUser.toInitialMap(), SetOptions(merge: true));
      if (kDebugMode) print('AuthService: New user doc created for ${firebaseUser.uid}');
      return true;
    } else {
      // Document ALREADY exists: DO NOT overwrite existing Durood numbers!
      final data = snap.data() ?? {};
      final Map<String, dynamic> updates = {};
      if (customName != null && customName.isNotEmpty) {
        updates['username'] = customName;
      } else if (!data.containsKey('username') || (data['username'] as String).isEmpty) {
        if (firebaseUser.displayName?.isNotEmpty == true) {
          updates['username'] = firebaseUser.displayName;
        }
      }
      if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
        if (!data.containsKey('email') || (data['email'] as String).isEmpty) {
          updates['email'] = firebaseUser.email;
        }
      }
      if (updates.isNotEmpty) {
        await docRef.set(updates, SetOptions(merge: true));
      }
      if (kDebugMode) print('AuthService: Existing user doc preserved for ${firebaseUser.uid}');
      return false;
    }
  }

  static Future<void> _saveSessionLocally(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySessionActive, true);
      await prefs.setString(_keyUserUid, user.uid);
      if (user.email != null) {
        await prefs.setString(_keyUserEmail, user.email!);
      }
    } catch (e) {
      if (kDebugMode) print('AuthService._saveSessionLocally error: $e');
    }
  }

  static Future<void> _clearLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySessionActive, false);
      await prefs.remove(_keyUserUid);
      await prefs.remove(_keyUserEmail);
    } catch (e) {
      if (kDebugMode) print('AuthService._clearLocalSession error: $e');
    }
  }

  /// Returns whether the current user is authenticated via Google.
  static bool get isGoogleUser =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  /// Updates user display name in Firebase Auth and Firestore ('users/{uid}').
  static Future<void> updateUserProfileName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) throw Exception('Name cannot be empty');

    // 1. Update Firebase Auth profile
    await user.updateDisplayName(trimmedName);

    // 2. Update Firestore user document
    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set({
      'name': trimmedName,
      'username': trimmedName,
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (kDebugMode) print('AuthService: Profile display name updated to "$trimmedName"');
  }

  /// Re-authenticates the current user using either Google Sign-In or Email/Password credentials.
  static Future<void> reauthenticateUser({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    if (isGoogleUser) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google re-authentication cancelled');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    } else {
      if (password == null || password.isEmpty) {
        throw Exception('Password is required for re-authentication');
      }
      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('User email not found for re-authentication');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// Permanently deletes user data documents from Firestore and deletes the Firebase Auth account.
  /// Handles cleanup of 'users/{uid}', questions submitted by user, and user notifications.
  static Future<void> deleteAccount({String? reauthPassword}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    final uid = user.uid;

    // 1. Clean up Firestore user records
    try {
      final batch = _firestore.batch();

      // Delete user document
      final userDocRef = _firestore.collection('users').doc(uid);
      batch.delete(userDocRef);

      // Query and delete user questions
      final questionsSnap = await _firestore
          .collection('user_questions')
          .where('user_id', isEqualTo: uid)
          .get();
      for (final doc in questionsSnap.docs) {
        batch.delete(doc.reference);
      }

      // Query and delete targeted notifications
      final notificationsSnap = await _firestore
          .collection('notifications')
          .where('target', isEqualTo: uid)
          .get();
      for (final doc in notificationsSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) print('AuthService.deleteAccount Firestore cleanup warning: $e');
    }

    // 2. Delete Firebase Auth user (with re-auth handling if required)
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (kDebugMode) print('AuthService.deleteAccount: requires-recent-login, attempting re-auth');
        await reauthenticateUser(password: reauthPassword);
        // Retry delete after successful re-auth
        await _auth.currentUser?.delete();
      } else {
        rethrow;
      }
    }

    // 3. Clear local session cache
    await _clearLocalSession();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Explicitly signs out of Firebase Auth and clears local session persistence.
  static Future<void> signOut() async {
    await _clearLocalSession();
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
