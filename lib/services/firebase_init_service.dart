import 'package:cloud_firestore/cloud_firestore.dart';
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
      await FirestoreSeeder.updateGlobalCounterBaseline(totalCount: 125000, todayCount: 4820);

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
      'admin@faizanedurood.com',
      'admin.portal@faizanedurood.com',
    ];

    try {
      for (final email in adminEmails) {
        final query = await firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          if (doc.data()['is_admin'] != true) {
            await doc.reference.set({'is_admin': true}, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseInitService _ensureAdminMetadataInFirestore notice: $e');
      }
    }
  }
}
