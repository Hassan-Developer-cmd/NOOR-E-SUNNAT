import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/firestore_seeder.dart';

class FirebaseInitService {
  /// Ensures initial Firestore collections exist and are seeded.
  static Future<void> seedInitialDatabase() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Perform automated Firestore collection inspection and safe seeding
      await FirestoreSeeder.checkAndSeedFirestore();
      await FirestoreSeeder.updateGlobalCounterBaseline(totalCount: 125000, todayCount: 4820);

      // Ensure default admin account exists in Firebase Auth + Firestore
      await _ensureDefaultAdminAccount(firestore);

      if (kDebugMode) {
        print('FirebaseInitService: Successfully verified initial Firestore collections.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseInitService seed error: $e');
      }
    }
  }

  /// Creates the default admin account in Firebase Auth (if not already registered)
  /// Creates default admin accounts in Firebase Auth (if not already registered)
  /// and writes is_admin:true to the users collection in Firestore.
  static Future<void> _ensureDefaultAdminAccount(FirebaseFirestore firestore) async {
    const adminAccounts = [
      {'email': 'admin@faizanedurood.com', 'pass': 'Admin@123456'},
      {'email': 'admin.portal@faizanedurood.com', 'pass': 'Admin@123456'},
    ];

    for (var acc in adminAccounts) {
      final email = acc['email']!;
      final pass = acc['pass']!;

      try {
        UserCredential cred;
        try {
          cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: pass,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: email,
              password: pass,
            );
          } else {
            continue;
          }
        }

        final uid = cred.user?.uid;
        if (uid != null) {
          await firestore.collection('users').doc(uid).set({
            'userId': uid,
            'email': email,
            'username': 'Super Admin',
            'is_admin': true,
            'created_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        await FirebaseAuth.instance.signOut();
      } catch (e) {
        if (kDebugMode) print('FirebaseInitService admin error for $email: $e');
      }
    }
  }
}

