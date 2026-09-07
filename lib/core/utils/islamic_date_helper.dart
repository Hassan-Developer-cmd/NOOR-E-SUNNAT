import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/hijri_date_model.dart';

class IslamicDateHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _settingsCollection = 'settings';
  static const String _hijriDocId = 'hijri_config';

  static const List<String> islamicMonthsEnglish = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Ula',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  static const List<String> islamicMonthsUrdu = [
    'محرم الحرام',
    'صفر المظفر',
    'ربیع الاول',
    'ربیع الثانی',
    'جمادی الاول',
    'جمادی الثانی',
    'رجب المرجب',
    'شعبان المعظم',
    'رمضان المبارک',
    'شوال المکرم',
    'ذوالقعدہ',
    'ذوالحجہ',
  ];

  /// Real-time stream of the day offset (-2 to +2) from Firestore settings
  static Stream<int> get hijriOffsetStream {
    return _firestore
        .collection(_settingsCollection)
        .doc(_hijriDocId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final val = data['dayOffset'] ?? data['offset'] ?? data['hijriOffset'] ?? data['day_offset'];
            if (val is num) return val.toInt().clamp(-2, 2);
          }
          return 0;
        });
  }

  /// One-shot fetch of the current day offset from Firestore
  static Future<int> getHijriOffset() async {
    try {
      final doc = await _firestore.collection(_settingsCollection).doc(_hijriDocId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final val = data['dayOffset'] ?? data['offset'] ?? data['hijriOffset'] ?? data['day_offset'];
        if (val is num) return val.toInt().clamp(-2, 2);
      }
      final altDoc = await _firestore.collection(_settingsCollection).doc('hijri').get();
      if (altDoc.exists && altDoc.data() != null) {
        final data = altDoc.data()!;
        final val = data['dayOffset'] ?? data['offset'] ?? data['hijriOffset'] ?? data['day_offset'];
        if (val is num) return val.toInt().clamp(-2, 2);
      }
    } catch (e) {
      if (kDebugMode) {
        print('IslamicDateHelper.getHijriOffset error: $e');
      }
    }
    return 0;
  }

  /// Saves the moon-sighting day offset to Firestore settings documents for real-time synchronization
  static Future<void> saveHijriOffset(int dayOffset) async {
    final clamped = dayOffset.clamp(-2, 2);
    final data = {
      'dayOffset': clamped,
      'offset': clamped,
      'hijriOffset': clamped,
      'day_offset': clamped,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await Future.wait([
        _firestore.collection(_settingsCollection).doc(_hijriDocId).set(data, SetOptions(merge: true)),
        _firestore.collection(_settingsCollection).doc('hijri').set(data, SetOptions(merge: true)),
        _firestore.collection(_settingsCollection).doc('hijri_adjustment').set(data, SetOptions(merge: true)),
      ]);
    } catch (e) {
      if (kDebugMode) {
        print('IslamicDateHelper.saveHijriOffset error: $e');
      }
      rethrow;
    }
  }

  /// Synchronously calculates the effective Hijri date for the given [gregorianDate] and [dayOffset].
  /// Directly harmonized with the Web Admin "Moon Sighting Adjustment" setting as the single source of truth.
  /// Base is strictly: Standard Hijri Date + Firestore admin offset.
  static HijriDateModel getHijriDateSync({
    DateTime? gregorianDate,
    int? dayOffset,
  }) {
    final baseDate = gregorianDate ?? DateTime.now();
    final offset = dayOffset ?? 0;
    final effectiveDate = baseDate.add(Duration(days: offset));
    return calculateOfflineHijriDate(effectiveDate);
  }

  /// Asynchronously fetches [dayOffset] from Firestore if omitted and returns the harmonized Hijri date.
  static Future<HijriDateModel> getHijriDate({
    DateTime? gregorianDate,
    int? dayOffset,
  }) async {
    final offset = dayOffset ?? await getHijriOffset();
    return getHijriDateSync(gregorianDate: gregorianDate, dayOffset: offset);
  }

  /// Robust algorithmic conversion from Gregorian to Islamic (Hijri) date
  static HijriDateModel calculateOfflineHijriDate(DateTime gregorianDate) {
    int day = gregorianDate.day;
    int month = gregorianDate.month;
    int year = gregorianDate.year;

    int m = month;
    int y = year;
    if (m < 3) {
      y -= 1;
      m += 12;
    }

    int a = (y / 100).floor();
    int b = 2 - a + (a / 4).floor();
    int jd = (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524;

    // Julian Day to Hijri conversion formula
    int z = jd - 1948440 + 10632;
    int n = ((z - 1) / 10631).floor();
    z = z - 10631 * n + 354;
    int j = ((10985 - z) / 5316).floor() * ((50 * z) / 17719).floor() +
        (z / 5670).floor() * ((43 * z) / 15238).floor();
    z = z -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    int mH = ((24 * z) / 709).floor();
    int dH = z - ((709 * mH) / 24).floor();
    int yH = 30 * n + j - 30;

    int clampedMonth = mH.clamp(1, 12);
    int clampedDay = dH.clamp(1, 30);
    int clampedYear = yH;

    return HijriDateModel(
      day: clampedDay,
      month: clampedMonth,
      year: clampedYear,
      monthNameEnglish: islamicMonthsEnglish[clampedMonth - 1],
      monthNameUrdu: islamicMonthsUrdu[clampedMonth - 1],
    );
  }
}
