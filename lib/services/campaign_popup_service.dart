import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/models/campaign_popup_model.dart';
import '../core/widgets/campaign_popup_dialog.dart';

class CampaignPopupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _settingsCollection = 'settings';
  static const String _docId = 'launch_popup';
  static const String _popupsCollection = 'app_popups';

  /// Session guard: tracks if the launch popup was already displayed during the current app session.
  static bool _hasShownInSession = false;

  static bool get hasShownInSession => _hasShownInSession;

  static void markShownInSession() {
    _hasShownInSession = true;
  }

  static void resetSession() {
    _hasShownInSession = false;
  }

  /// Real-time stream of the active campaign popup configuration.
  static Stream<CampaignPopupModel> get campaignPopupStream {
    return _firestore
        .collection(_settingsCollection)
        .doc(_docId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return CampaignPopupModel.fromMap(doc.id, doc.data());
          }
          return CampaignPopupModel.defaultConfig(id: _docId);
        });
  }

  /// One-shot fetch of the campaign popup configuration.
  static Future<CampaignPopupModel> getCampaignPopup() async {
    try {
      final doc = await _firestore.collection(_settingsCollection).doc(_docId).get();
      if (doc.exists && doc.data() != null) {
        return CampaignPopupModel.fromMap(doc.id, doc.data());
      }
      // Fallback check on app_popups collection
      final fallbackDoc = await _firestore.collection(_popupsCollection).doc(_docId).get();
      if (fallbackDoc.exists && fallbackDoc.data() != null) {
        return CampaignPopupModel.fromMap(fallbackDoc.id, fallbackDoc.data());
      }
    } catch (e) {
      if (kDebugMode) {
        print('CampaignPopupService.getCampaignPopup error: $e');
      }
    }
    return CampaignPopupModel.defaultConfig(id: _docId);
  }

  /// Saves & publishes the campaign popup config to Firestore.
  /// Dual-writes to settings/launch_popup and app_popups/launch_popup for universal schema compatibility.
  static Future<void> saveCampaignPopup(CampaignPopupModel config) async {
    final data = config.toMap();
    final batch = _firestore.batch();

    final settingsDocRef = _firestore.collection(_settingsCollection).doc(_docId);
    final popupsDocRef = _firestore.collection(_popupsCollection).doc(_docId);

    batch.set(settingsDocRef, data, SetOptions(merge: true));
    batch.set(popupsDocRef, data, SetOptions(merge: true));

    await batch.commit();
    if (kDebugMode) {
      print('CampaignPopupService: Campaign popup configuration successfully saved.');
    }
  }

  /// Toggles the active state of the startup popup.
  static Future<void> togglePopupStatus(bool isActive) async {
    final updateData = {
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _firestore.batch();
    final settingsDocRef = _firestore.collection(_settingsCollection).doc(_docId);
    final popupsDocRef = _firestore.collection(_popupsCollection).doc(_docId);

    batch.set(settingsDocRef, updateData, SetOptions(merge: true));
    batch.set(popupsDocRef, updateData, SetOptions(merge: true));

    await batch.commit();
  }

  /// Checks Firestore on mobile startup and displays the modal if active.
  static Future<void> checkAndShowStartupPopup(
    BuildContext context, {
    bool force = false,
  }) async {
    if (!force && _hasShownInSession) {
      return;
    }

    try {
      final config = await getCampaignPopup();
      if (!config.isActive) return;

      if (!context.mounted) return;

      // Mark as shown in session so user is not interrupted repeatedly
      markShownInSession();

      await CampaignPopupDialog.show(context, config);
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkAndShowStartupPopup: $e');
      }
    }
  }
}
