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
  static bool _isDialogShowing = false;

  static bool get hasShownInSession => _hasShownInSession;
  static bool get isDialogShowing => _isDialogShowing;

  static void markShownInSession() {
    _hasShownInSession = true;
  }

  static void resetSession() {
    _hasShownInSession = false;
    _isDialogShowing = false;
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

  /// One-shot fetch of the campaign popup configuration from Firestore.
  /// Checks campaigns/active, settings/launch_popup, and app_popups collection for active campaigns.
  static Future<CampaignPopupModel> getCampaignPopup() async {
    try {
      // 1. Check campaigns/active
      final activeCampaignDoc =
          await _firestore.collection('campaigns').doc('active').get();
      if (activeCampaignDoc.exists && activeCampaignDoc.data() != null) {
        final model = CampaignPopupModel.fromMap(
            activeCampaignDoc.id, activeCampaignDoc.data());
        return model;
      }

      // 2. Settings check: settings/launch_popup
      final doc =
          await _firestore.collection(_settingsCollection).doc(_docId).get();
      if (doc.exists && doc.data() != null) {
        final model = CampaignPopupModel.fromMap(doc.id, doc.data());
        if (model.isActive) return model;
      }

      // 3. Fallback check: app_popups/launch_popup
      final fallbackDoc =
          await _firestore.collection(_popupsCollection).doc(_docId).get();
      if (fallbackDoc.exists && fallbackDoc.data() != null) {
        final model =
            CampaignPopupModel.fromMap(fallbackDoc.id, fallbackDoc.data());
        if (model.isActive) return model;
      }

      // 4. Collection query: app_popups where isActive == true
      final activeQuery = await _firestore
          .collection(_popupsCollection)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (activeQuery.docs.isNotEmpty) {
        final activeDoc = activeQuery.docs.first;
        return CampaignPopupModel.fromMap(activeDoc.id, activeDoc.data());
      }

      // 5. If settings doc exists (even if explicitly inactive), return that config
      if (doc.exists && doc.data() != null) {
        return CampaignPopupModel.fromMap(doc.id, doc.data());
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

  /// Checks Firestore on mobile startup and displays the modal once per fresh app session.
  static Future<void> checkAndShowStartupPopup(
    BuildContext context, {
    bool force = false,
  }) async {
    if (_isDialogShowing) return;
    if (!force && _hasShownInSession) return;

    _isDialogShowing = true;
    if (!force) {
      _hasShownInSession = true;
    }

    try {
      final config = await getCampaignPopup();
      if (!config.isActive) return;

      if (!context.mounted) return;
      await CampaignPopupDialog.show(context, config);
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkAndShowStartupPopup: $e');
      }
    } finally {
      _isDialogShowing = false;
    }
  }
}
