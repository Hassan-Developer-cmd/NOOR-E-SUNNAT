import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class IslamicEvent {
  final String id;
  final String title;
  final String titleUr;
  final String dateTime;
  final String location;
  final String locationUr;
  final String status;
  final String description;
  final String descriptionUr;
  final List<Color> gradientColors;

  const IslamicEvent({
    required this.id,
    required this.title,
    required this.titleUr,
    required this.dateTime,
    required this.location,
    required this.locationUr,
    required this.status,
    required this.description,
    required this.descriptionUr,
    required this.gradientColors,
  });
}

class MockEventsData {
  static final List<IslamicEvent> events = [
    const IslamicEvent(
      id: '1',
      title: 'Global Milad Gathering 2026',
      titleUr: 'عالمی اجتماعِ میلاد النبی ۲۰۲۶ء',
      dateTime: 'Dec 24, 8:00 PM',
      location: 'Jamia Masjid Al-Aksa, Main Hall',
      locationUr: 'جامع مسجد الاقصیٰ، مرکزی ہال',
      status: 'Featured',
      description: 'Join millions globally in a collective recitation of Durood Shareef leading up to the blessed month of Rabi al-Awwal.',
      descriptionUr: 'ربیع الاول کے مبارک مہینے کی آمد کی خوشی میں دنیا بھر کے لاکھوں مسلمانوں کے ساتھ اجتماعی درود پاک پڑھنے کی محفل میں شرکت فرمائیں۔',
      gradientColors: [AppColors.primaryEmerald, AppColors.emeraldDark],
    ),
    const IslamicEvent(
      id: '2',
      title: 'Weekly Jumu\'ah Durood Majlis',
      titleUr: 'ہفتہ وار جمعۃ المبارک درود مجلس',
      dateTime: 'Every Friday after Asr',
      location: 'Live Stream & Central Masjid',
      locationUr: 'لائیو اسٹریم و مرکزی جامع مسجد',
      status: 'Recurring',
      description: 'Sending special Salawat upon Prophet Muhammad (ﷺ) on the blessed day of Friday.',
      descriptionUr: 'جمعۃ المبارک کے بابرکت دن نمازِ عصر کے بعد نبی کریم صلی اللہ علیہ وآلہ وسلم کی بارگاہ میں خصوصی درود و سلام نذر کرنا۔',
      gradientColors: [Color(0xFF1E5631), Color(0xFF4C9A2A)],
    ),
    const IslamicEvent(
      id: '3',
      title: 'Ramadan Preparation & Durood Drive',
      titleUr: 'استقبالِ رمضان و درود شریف مہم',
      dateTime: 'Mar 15, 6:30 PM',
      location: 'Islamic Cultural Center Auditorium',
      locationUr: 'اسلامک کلچرل سینٹر آڈیٹوریم',
      status: 'Upcoming',
      description: 'Preparing our hearts for Ramadan through Durood, Istighfar, and lectures on Fiqh.',
      descriptionUr: 'درود پاک، استغفار اور فتاویٰ و مسائل کے بیانات کے ذریعے رمضان المبارک کے لیے دلوں کی تیاری۔',
      gradientColors: [Color(0xFF8B6B23), Color(0xFFD4AF37)],
    ),
  ];
}
