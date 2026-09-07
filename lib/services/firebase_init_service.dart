import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/firestore_seeder.dart';

class FirebaseInitService {
  /// Ensures initial Firestore collections exist and are seeded safely
  /// without disrupting any existing user authentication sessions.
  static Future<void> seedInitialDatabase() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Perform automated Firestore collection inspection and safe seeding
      await FirestoreSeeder.checkAndSeedFirestore();

      // Ensure admin roles and metadata are registered in Firestore
      await _ensureAdminMetadataInFirestore(firestore);

      if (kDebugMode) {
        print('FirebaseInitService: Successfully verified initial Firestore collections.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseInitService seed error: $e');
      }
    }
  }

  /// Writes default admin role configuration to Firestore safely
  /// WITHOUT touching FirebaseAuth.instance sessions or signing out active users.
  static Future<void> _ensureAdminMetadataInFirestore(FirebaseFirestore firestore) async {
    const adminEmails = [
      'admin@nooresunnat.com',
      'admin.portal@nooresunnat.com',
    ];

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      // Only execute if the currently authenticated user is an admin candidate.
      // Regular users and guests do not have permission to query /users collection.
      if (currentUser == null) return;
      final email = currentUser.email?.toLowerCase().trim();
      if (email == null || !adminEmails.contains(email)) return;

      final docRef = firestore.collection('users').doc(currentUser.uid);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final data = docSnap.data();
        if (data?['is_admin'] != true) {
          await docRef.set({'is_admin': true}, SetOptions(merge: true));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseInitService _ensureAdminMetadataInFirestore notice: $e');
      }
    }
  }
}

