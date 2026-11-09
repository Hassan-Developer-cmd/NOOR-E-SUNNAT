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
          return CampaignPopupModel.defaultConfig(id: _docId, isActive: false);
        });
  }

  /// One-shot fetch of the campaign popup configuration from Firestore.
  /// Checks settings/launch_popup (authoritative admin config), app_popups mirror,
  /// campaigns/active, and queries. Respects explicit inactive status (isActive == false).
  static Future<CampaignPopupModel> getCampaignPopup() async {
    try {
      // 1. Primary check: settings/launch_popup (authoritative config managed by admin)
      try {
        final doc = await _firestore
            .collection(_settingsCollection)
            .doc(_docId)
            .get()
            .timeout(const Duration(seconds: 3));
        if (doc.exists && doc.data() != null) {
          return CampaignPopupModel.fromMap(doc.id, doc.data());
        }
      } catch (e) {
        if (kDebugMode) print('getCampaignPopup settings check error: $e');
      }

      // 2. Secondary check: app_popups/launch_popup (mirrored config)
      try {
        final fallbackDoc = await _firestore
            .collection(_popupsCollection)
            .doc(_docId)
            .get()
            .timeout(const Duration(seconds: 3));
        if (fallbackDoc.exists && fallbackDoc.data() != null) {
          return CampaignPopupModel.fromMap(fallbackDoc.id, fallbackDoc.data());
        }
      } catch (e) {
        if (kDebugMode) print('getCampaignPopup fallback check error: $e');
      }

      // 3. Compatibility check: campaigns/active
      try {
        final activeCampaignDoc = await _firestore
            .collection('campaigns')
            .doc('active')
            .get()
            .timeout(const Duration(seconds: 3));
        if (activeCampaignDoc.exists && activeCampaignDoc.data() != null) {
          return CampaignPopupModel.fromMap(
              activeCampaignDoc.id, activeCampaignDoc.data());
        }
      } catch (e) {
        if (kDebugMode) print('getCampaignPopup campaigns/active check error: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CampaignPopupService.getCampaignPopup error: $e');
      }
    }
    // Safe fallback: when no popup config exists in Firestore, popup must NOT show (isActive: false)
    return CampaignPopupModel.defaultConfig(id: _docId, isActive: false);
  }

  /// Saves & publishes the campaign popup config to Firestore.
  /// Dual-writes to settings/launch_popup, app_popups/launch_popup, and campaigns/active
  /// for universal cross-collection consistency.
  static Future<void> saveCampaignPopup(CampaignPopupModel config) async {
    final data = config.toMap();
    final batch = _firestore.batch();

    final settingsDocRef = _firestore.collection(_settingsCollection).doc(_docId);
    final popupsDocRef = _firestore.collection(_popupsCollection).doc(_docId);
    final campaignsDocRef = _firestore.collection('campaigns').doc('active');

    batch.set(settingsDocRef, data, SetOptions(merge: true));
    batch.set(popupsDocRef, data, SetOptions(merge: true));
    batch.set(campaignsDocRef, data, SetOptions(merge: true));

    await batch.commit();
    if (kDebugMode) {
      print('CampaignPopupService: Campaign popup configuration successfully saved across all collections.');
    }
  }

  /// Toggles the active state of the startup popup across all collections.
  static Future<void> togglePopupStatus(bool isActive) async {
    final updateData = {
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _firestore.batch();
    final settingsDocRef = _firestore.collection(_settingsCollection).doc(_docId);
    final popupsDocRef = _firestore.collection(_popupsCollection).doc(_docId);
    final campaignsDocRef = _firestore.collection('campaigns').doc('active');

    batch.set(settingsDocRef, updateData, SetOptions(merge: true));
    batch.set(popupsDocRef, updateData, SetOptions(merge: true));
    batch.set(campaignsDocRef, updateData, SetOptions(merge: true));

    await batch.commit();
    if (kDebugMode) {
      print('CampaignPopupService: Campaign popup active status toggled to $isActive.');
    }
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
