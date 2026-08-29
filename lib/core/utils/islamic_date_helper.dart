import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Real-time stream of the day offset (-2 to +2) from Firestore settings/hijri_config
  static Stream<int> get hijriOffsetStream {
    return _firestore
        .collection(_settingsCollection)
        .doc(_hijriDocId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            final val = doc.data()!['dayOffset'];
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
        final val = doc.data()!['dayOffset'];
        if (val is num) return val.toInt().clamp(-2, 2);
      }
    } catch (e) {
      if (kDebugMode) {
        print('IslamicDateHelper.getHijriOffset error: $e');
      }
    }
    return 0;
  }

  /// Saves the moon-sighting day offset to Firestore settings/hijri_config
  static Future<void> saveHijriOffset(int dayOffset) async {
    final clamped = dayOffset.clamp(-2, 2);
    await _firestore.collection(_settingsCollection).doc(_hijriDocId).set({
      'dayOffset': clamped,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Calculates the effective Hijri date for the given [gregorianDate] and [dayOffset].
  /// Uses Aladhan API when available, and falls back to offline algorithmic calculation.
  static Future<HijriDateModel> getHijriDate({
    DateTime? gregorianDate,
    int? dayOffset,
  }) async {
    final baseDate = gregorianDate ?? DateTime.now();
    final offset = dayOffset ?? await getHijriOffset();
    final effectiveDate = baseDate.add(Duration(days: offset));

    // 1. Try local cache first for instant UI response
    final cached = await _getCachedHijriDate(effectiveDate);
    if (cached != null) {
      // Background sync with API
      _syncWithAladhanApi(effectiveDate).catchError((_) {});
      return cached;
    }

    // 2. Try fetching from Aladhan API
    try {
      final apiModel = await _fetchFromAladhanApi(effectiveDate);
      if (apiModel != null) {
        await _cacheHijriDate(effectiveDate, apiModel);
        return apiModel;
      }
    } catch (_) {}

    // 3. Robust offline fallback
    final offlineModel = calculateOfflineHijriDate(effectiveDate);
    await _cacheHijriDate(effectiveDate, offlineModel);
    return offlineModel;
  }

  /// Fetches Hijri date from Aladhan API (https://api.aladhan.com/v1/gToH?date=DD-MM-YYYY)
  static Future<HijriDateModel?> _fetchFromAladhanApi(DateTime date) async {
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    final url = Uri.parse('https://api.aladhan.com/v1/gToH?date=$formattedDate');

    final response = await http.get(url).timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['code'] == 200 && json['data'] != null) {
        final hijri = json['data']['hijri'];
        final day = int.tryParse(hijri['day']?.toString() ?? '') ?? date.day;
        final monthNum = (hijri['month']?['number'] as num?)?.toInt() ?? 1;
        final year = int.tryParse(hijri['year']?.toString() ?? '') ?? 1448;

        final clampedMonth = monthNum.clamp(1, 12);
        return HijriDateModel(
          day: day,
          month: clampedMonth,
          year: year,
          monthNameEnglish: islamicMonthsEnglish[clampedMonth - 1],
          monthNameUrdu: islamicMonthsUrdu[clampedMonth - 1],
        );
      }
    }
    return null;
  }

  /// Background sync to update local cache
  static Future<void> _syncWithAladhanApi(DateTime date) async {
    try {
      final apiModel = await _fetchFromAladhanApi(date);
      if (apiModel != null) {
        await _cacheHijriDate(date, apiModel);
      }
    } catch (_) {}
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

  // ── Local SharedPreferences Cache ──────────────────────────────────

  static String _cacheKey(DateTime date) => 'hijri_${date.year}_${date.month}_${date.day}';

  static Future<HijriDateModel?> _getCachedHijriDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cacheKey(date));
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return HijriDateModel.fromMap(map);
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _cacheHijriDate(DateTime date, HijriDateModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(model.toMap());
      await prefs.setString(_cacheKey(date), jsonStr);
    } catch (_) {}
  }
}
