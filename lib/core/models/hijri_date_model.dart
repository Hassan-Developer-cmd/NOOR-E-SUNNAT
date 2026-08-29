class HijriDateModel {
  final int day;
  final int month;
  final int year;
  final String monthNameEnglish;
  final String monthNameUrdu;

  const HijriDateModel({
    required this.day,
    required this.month,
    required this.year,
    required this.monthNameEnglish,
    required this.monthNameUrdu,
  });

  /// Formatted English representation (e.g. "13 Rabi' al-Awwal 1448 AH")
  String get formattedEnglish => '$day $monthNameEnglish $year AH';

  /// Formatted Urdu representation (e.g. "13 ربیع الاول 1448ھ")
  String get formattedUrdu => '$day $monthNameUrdu $yearھ';

  String getFormatted(bool isUrdu) => isUrdu ? formattedUrdu : formattedEnglish;

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'monthNameEnglish': monthNameEnglish,
      'monthNameUrdu': monthNameUrdu,
    };
  }

  factory HijriDateModel.fromMap(Map<String, dynamic> map) {
    return HijriDateModel(
      day: (map['day'] as num?)?.toInt() ?? 1,
      month: (map['month'] as num?)?.toInt() ?? 1,
      year: (map['year'] as num?)?.toInt() ?? 1448,
      monthNameEnglish: map['monthNameEnglish'] as String? ?? "Rabi' al-Awwal",
      monthNameUrdu: map['monthNameUrdu'] as String? ?? 'ربیع الاول',
    );
  }
}
