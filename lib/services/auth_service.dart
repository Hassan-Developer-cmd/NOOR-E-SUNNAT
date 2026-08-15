import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../core/models/app_user.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Auth state stream — use this to reactively route between login/home.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

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
    await _createUserDocIfNeeded(result.user!);
    return result.user;
  }

  /// Sign in with Email and Password.
  static Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    if (credential.user != null) {
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

  static Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
