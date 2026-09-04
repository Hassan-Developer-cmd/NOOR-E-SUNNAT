import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../core/models/app_user.dart';
import 'counter_service.dart';

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
  static final Set<String> _ensuredUids = {};

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Auth state stream — use this to reactively route between login/home.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Resolves the current authenticated user safely on startup,
  /// immediately returning cached currentUser without blocking network round-trips.
  static Future<User?> resolveCurrentUser({Duration timeout = const Duration(milliseconds: 300)}) async {
    if (_auth.currentUser != null) {
      _saveSessionLocally(_auth.currentUser!).catchError((_) {});
      return _auth.currentUser;
    }

    try {
      final user = await _auth.authStateChanges().first.timeout(timeout);
      if (user != null) {
        _saveSessionLocally(user).catchError((_) {});
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
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) => snap.exists ? AppUser.fromMap({'user_id': snap.id, ...snap.data()!}) : null);
    });
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
    if (_ensuredUids.contains(firebaseUser.uid)) return;
    _ensuredUids.add(firebaseUser.uid);
    try {
      await _createUserDocIfNeeded(firebaseUser);
    } catch (_) {}
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

  /// Updates user profile image as Base64 in Firestore ('users/{uid}').
  static Future<void> updateProfileImageBase64(String base64Image) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set({
      'profileImageBase64': base64Image,
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (kDebugMode) print('AuthService: Profile image Base64 updated for ${user.uid}');
  }

  /// Removes custom profile image from Firestore.
  static Future<void> removeProfileImageBase64() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');

    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set({
      'profileImageBase64': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (kDebugMode) print('AuthService: Profile image Base64 removed for ${user.uid}');
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

  /// Permanently purges ALL user data from Firestore (user doc, subcollections, questions, notifications),
  /// clears all device storage (SharedPreferences), resets in-memory counter state, disconnects Google session,
  /// and deletes the Firebase Auth account.
  static Future<void> deleteAccount({String? reauthPassword}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found');
    final uid = user.uid;
    final email = user.email ?? '';

    // 1. Comprehensive Firestore data purge BEFORE Auth deletion (while still authenticated)
    try {
      final List<DocumentReference> docsToDelete = [];

      // A. Main user document: users/{uid}
      final userDocRef = _firestore.collection('users').doc(uid);
      docsToDelete.add(userDocRef);

      // B. Subcollections under users/{uid}: daily_stats, history, queries, notifications, streak_history, bookmarks
      final subcollections = [
        'daily_stats',
        'history',
        'queries',
        'notifications',
        'streak_history',
        'bookmarks',
      ];
      for (final subcol in subcollections) {
        try {
          final subSnap = await userDocRef.collection(subcol).get();
          for (final doc in subSnap.docs) {
            docsToDelete.add(doc.reference);
          }
        } catch (e) {
          if (kDebugMode) print('deleteAccount subcollection $subcol error: $e');
        }
      }

      // C. Remove user-specific questions/inquiries (user_questions and questions)
      for (final col in ['user_questions', 'questions']) {
        try {
          final snap1 = await _firestore.collection(col).where('user_id', isEqualTo: uid).get();
          for (final doc in snap1.docs) {
            docsToDelete.add(doc.reference);
          }

          final snap2 = await _firestore.collection(col).where('userId', isEqualTo: uid).get();
          for (final doc in snap2.docs) {
            docsToDelete.add(doc.reference);
          }

          if (email.isNotEmpty) {
            final snap3 = await _firestore.collection(col).where('userEmail', isEqualTo: email).get();
            for (final doc in snap3.docs) {
              docsToDelete.add(doc.reference);
            }

            final snap4 = await _firestore.collection(col).where('email', isEqualTo: email).get();
            for (final doc in snap4.docs) {
              docsToDelete.add(doc.reference);
            }
          }
        } catch (e) {
          if (kDebugMode) print('deleteAccount $col error: $e');
        }
      }

      // D. Remove user-specific notifications
      try {
        final notifSnap1 = await _firestore.collection('notifications').where('target', isEqualTo: uid).get();
        for (final doc in notifSnap1.docs) {
          docsToDelete.add(doc.reference);
        }

        final notifSnap2 = await _firestore.collection('notifications').where('userId', isEqualTo: uid).get();
        for (final doc in notifSnap2.docs) {
          docsToDelete.add(doc.reference);
        }

        final notifSnap3 = await _firestore.collection('notifications').where('user_id', isEqualTo: uid).get();
        for (final doc in notifSnap3.docs) {
          docsToDelete.add(doc.reference);
        }
      } catch (e) {
        if (kDebugMode) print('deleteAccount notifications error: $e');
      }

      // Deduplicate document references by path
      final uniqueRefs = <String, DocumentReference>{};
      for (final ref in docsToDelete) {
        uniqueRefs[ref.path] = ref;
      }

      // Execute atomic batched deletions (chunked up to 400 operations per batch)
      const int batchLimit = 400;
      final refList = uniqueRefs.values.toList();
      for (int i = 0; i < refList.length; i += batchLimit) {
        final end = (i + batchLimit < refList.length) ? i + batchLimit : refList.length;
        final chunk = refList.sublist(i, end);
        final batch = _firestore.batch();
        for (final ref in chunk) {
          batch.delete(ref);
        }
        await batch.commit();
      }
    } catch (e) {
      if (kDebugMode) print('AuthService.deleteAccount Firestore cleanup warning: $e');
    }

    // 2. Clear all device storage: wipe all streak, points, daily Durood caches, and tokens
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      if (kDebugMode) print('AuthService.deleteAccount prefs.clear error: $e');
    }

    // 3. Reset in-memory CounterService state
    try {
      CounterService().resetLocalState();
    } catch (_) {}

    // 4. Disconnect Google Sign-In session explicitly so it doesn't auto-link old tokens
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (_) {}

    _ensuredUids.clear();

    // 5. Delete the Firebase Auth User
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (reauthPassword != null && reauthPassword.isNotEmpty) {
          await reauthenticateUser(password: reauthPassword);
          await _auth.currentUser?.delete();
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Explicitly signs out of Firebase Auth and clears local session persistence.
  static Future<void> signOut() async {
    await _clearLocalSession();
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
