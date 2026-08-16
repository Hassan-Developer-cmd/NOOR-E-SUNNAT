import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../core/models/app_user.dart';

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
  static Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    if (result.user != null) {
      await _saveSessionLocally(result.user!);
      await _createUserDocIfNeeded(result.user!);
    }
    return result.user;
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
  static Future<void> _createUserDocIfNeeded(User firebaseUser, {String? customName}) async {
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

  /// Explicitly signs out of Firebase Auth and clears local session persistence.
  static Future<void> signOut() async {
    await _clearLocalSession();
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
