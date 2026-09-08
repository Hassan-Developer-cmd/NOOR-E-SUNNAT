import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/widgets/terms_acceptance_dialog.dart';

class TermsAcceptanceService {
  static const String localTermsKey = 'has_accepted_terms_v1';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isShowingDialog = false;

  static bool get isShowingDialog => _isShowingDialog;

  /// Checks whether terms have been accepted locally or in Firestore.
  /// 1. Fast check in SharedPreferences: if true, returns true immediately.
  /// 2. If false/null, checks Firestore `users/{uid}` -> `hasAcceptedTerms == true`.
  ///    If true in Firestore, caches true in SharedPreferences and returns true.
  /// 3. Returns false if terms have not been accepted yet.
  static Future<bool> hasUserAcceptedTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localAccepted = prefs.getBool(localTermsKey) ?? false;
      if (localAccepted) {
        return true;
      }

      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final docSnap = await _firestore.collection('users').doc(user.uid).get();
          if (docSnap.exists) {
            final data = docSnap.data();
            final cloudAccepted = data?['hasAcceptedTerms'] == true ||
                data?['has_accepted_terms'] == true ||
                data?['has_accepted_terms_v1'] == true;
            if (cloudAccepted) {
              await prefs.setBool(localTermsKey, true);
              return true;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TermsAcceptanceService.hasUserAcceptedTerms error: $e');
      }
    }
    return false;
  }

  /// Sets terms acceptance status both locally and on Firestore.
  static Future<void> acceptTerms() async {
    try {
      // 1. Set local preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(localTermsKey, true);

      // 2. Update Firestore users/{uid}
      if (Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'hasAcceptedTerms': true,
            'termsAcceptedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      if (kDebugMode) {
        print('TermsAcceptanceService: Terms successfully accepted and persisted.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TermsAcceptanceService.acceptTerms error: $e');
      }
    }
  }

  /// Checks if terms must be shown, and if so, displays the blocking modal dialog.
  /// Returns true if accepted or already accepted, false if unable to show.
  static Future<bool> checkAndShowTerms(BuildContext context) async {
    if (_isShowingDialog) return false;

    final accepted = await hasUserAcceptedTerms();
    if (accepted) return true;

    if (!context.mounted) return false;

    _isShowingDialog = true;
    try {
      await TermsAcceptanceDialog.show(context);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('TermsAcceptanceService.checkAndShowTerms error: $e');
      }
      return false;
    } finally {
      _isShowingDialog = false;
    }
  }

  /// Helper for testing to reset local acceptance flag
  @visibleForTesting
  static Future<void> resetLocalTermsFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(localTermsKey);
  }
}
