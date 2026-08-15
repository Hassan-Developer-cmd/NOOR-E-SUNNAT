import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/masail_model.dart';
import '../models/aqaid_model.dart';
import '../models/daily_content_model.dart';
import '../models/event_model.dart';

class FirestoreSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks essential Firestore collections (`masail_entries`, `aqaid_entries`, `daily_content`, `events`, `global_counter`).
  ///
  /// If a collection already contains documents (`count > 0`), seeding is skipped for that collection.
  /// If a collection is empty (`count == 0`), default data is safely seeded.
  static Future<Map<String, dynamic>> checkAndSeedFirestore({bool force = false}) async {
    final Map<String, dynamic> results = {
      'masail_entries': {'count': 0, 'seeded': false, 'status': ''},
      'aqaid_entries': {'count': 0, 'seeded': false, 'status': ''},
      'daily_content': {'count': 0, 'seeded': false, 'status': ''},
      'events': {'count': 0, 'seeded': false, 'status': ''},
      'global_counter': {'count': 0, 'seeded': false, 'status': ''},
    };

    try {
      if (kDebugMode) {
        print('===========================================================');
        print('[Seeder] Starting Automated Firestore Collection Inspection');
        print('===========================================================');
      }

      // 1. Check & Seed Masail Entries
      final masailSnap = await _firestore.collection('masail_entries').get();
      final masailCount = masailSnap.docs.length;
      results['masail_entries']['count'] = masailCount;

      if (masailCount > 0 && !force) {
        results['masail_entries']['status'] = 'Skipped (Already has $masailCount docs)';
      } else {
        final batch = _firestore.batch();
        for (var m in _initialMasailSeed) {
          final docRef = _firestore.collection('masail_entries').doc(m.id);
          batch.set(docRef, m.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['masail_entries']['seeded'] = true;
        results['masail_entries']['status'] = 'Seeded ${_initialMasailSeed.length} items';
      }

      // 2. Check & Seed Aqaid Entries
      final aqaidSnap = await _firestore.collection('aqaid_entries').get();
      final aqaidCount = aqaidSnap.docs.length;
      results['aqaid_entries']['count'] = aqaidCount;

      if (aqaidCount > 0 && !force) {
        results['aqaid_entries']['status'] = 'Skipped (Already has $aqaidCount docs)';
      } else {
        final batch = _firestore.batch();
        for (var a in _initialAqaidSeed) {
          final docRef = _firestore.collection('aqaid_entries').doc(a.id);
          batch.set(docRef, a.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['aqaid_entries']['seeded'] = true;
        results['aqaid_entries']['status'] = 'Seeded ${_initialAqaidSeed.length} items';
      }

      // 3. Check & Seed Daily Content
      final dailySnap = await _firestore.collection('daily_content').get();
      final dailyCount = dailySnap.docs.length;
      results['daily_content']['count'] = dailyCount;

      if (dailyCount > 0 && !force) {
        results['daily_content']['status'] = 'Skipped (Already has $dailyCount docs)';
      } else {
        const defaultHadith = DailyContentModel(
          id: 'default_hadith',
          type: 'hadith',
          title: 'Virtue of Sending Durood',
          titleUr: 'درود شریف کی فضیلت',
          arabicText: 'مَنْ صَلَّى عَلَيَّ وَاحِدَةً صَلَّى اللهُ عَلَيْهِ عَشْرًا',
          content:
              'Whoever sends blessings upon me once, Allah will send blessings upon him ten times.',
          contentUr:
              'جو شخص مجھ پر ایک بار درود بھیجتا ہے، اللہ تعالیٰ اس پر دس رحمتیں نازل فرماتا ہے۔',
          citation: 'Sahih Muslim 408',
          citationUr: 'صحیح مسلم ۴۰۸',
          isActive: true,
          isTopicOfTheDay: true,
        );
        await _firestore.collection('daily_content').doc(defaultHadith.id).set(
              defaultHadith.toMap(),
              SetOptions(merge: true),
            );
        results['daily_content']['seeded'] = true;
        results['daily_content']['status'] = 'Seeded default Hadith';
      }

      // 4. Check & Seed Events
      final eventsSnap = await _firestore.collection('events').get();
      final eventsCount = eventsSnap.docs.length;
      results['events']['count'] = eventsCount;

      if (eventsCount > 0 && !force) {
        results['events']['status'] = 'Skipped (Already has $eventsCount docs)';
      } else {
        final batch = _firestore.batch();
        for (var e in _initialEventsSeed) {
          final docRef = _firestore.collection('events').doc(e.id);
          batch.set(docRef, e.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        results['events']['seeded'] = true;
        results['events']['status'] = 'Seeded ${_initialEventsSeed.length} events';
      }

      // 5. Check & Seed Global Counter
      final counterRef = _firestore.collection('global_counter').doc('main');
      final counterSnap = await counterRef.get();
      results['global_counter']['count'] = counterSnap.exists ? 1 : 0;

      if (counterSnap.exists && !force) {
        results['global_counter']['status'] = 'Skipped (Already exists)';
      } else {
        final todayStr = DateTime.now().toIso8601String().split('T').first;
        await counterRef.set({
          'total_count': 125000,
          'today_count': 4820,
          'last_reset_date': todayStr,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        results['global_counter']['seeded'] = true;
        results['global_counter']['status'] = 'Seeded global counter main doc';
      }

      return results;
    } catch (e) {
      if (kDebugMode) print('[Seeder] Firestore inspection error: $e');
      return {'error': e.toString()};
    }
  }

  /// Sets initial baseline starting numbers for global counter.
  static Future<bool> updateGlobalCounterBaseline({
    int totalCount = 125000,
    int todayCount = 4820,
  }) async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      await _firestore.collection('global_counter').doc('main').set({
        'total_count': totalCount,
        'today_count': todayCount,
        'last_reset_date': todayStr,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      if (kDebugMode) print('[Seeder] Error updating global counter baseline: $e');
      return false;
    }
  }

  static Future<bool> seedDefaultDataToFirestore({bool force = false}) async {
    final res = await checkAndSeedFirestore(force: force);
    return !res.containsKey('error');
  }

  // ── Initial Seed Collections ───────────────────────────────────

  static const List<MasailItemModel> _initialMasailSeed = [
    MasailItemModel(
      id: 'namaz_1',
      categoryId: 'namaz',
      question: 'What should one do if Sajda Sahw is forgotten in Salah?',
      questionUr: 'اگر نماز میں سجدہ سہو بھول جائے تو کیا حکم ہے؟',
      answer: 'If the person turned their chest away from the Qibla or spoke after the initial Salam, they must repeat the entire prayer. If they remembered immediately while facing the Qibla, they can perform two Sajdahs, recite Tashahhud, and conclude with Salam.',
      answerUr: 'اگر قبلہ سے سینہ پھر گیا یا کلام کر لیا تو نماز کا اعادہ واجب ہے۔ اگر سلام پھیرنے کے بعد یاد آ جائے اور کوئی منافی عمل نہ کیا ہو تو فورا سجدہ سہو کر کے تشہد پڑھ کر سلام پھیر دے۔',
      book: 'Bahar-e-Shariat, Vol. 1, Page 710',
      bookUr: 'بہارِ شریعت، حصہ ۴، صفحہ ۷۱۰',
    ),
    MasailItemModel(
      id: 'namaz_2',
      categoryId: 'namaz',
      question: 'Is it permissible to perform Salah while wearing socks with moisture or perfume?',
      questionUr: 'کیا عطر یا خوشبو لگی جرابوں پر نماز ادا کی جا سکتی ہے؟',
      answer: 'Yes, as long as the perfume does not contain impure alcohol and the socks are clean (paak). Salah is completely valid.',
      answerUr: 'جی ہاں، اگر عطر یا خوشبو ناپاک الکحل سے پاک ہو اور جرابیں طاہر و پاک ہوں تو نماز بالکل جائز اور درست ہے۔',
      book: 'Fatawa Razawiyyah, Vol. 6, Page 120',
      bookUr: 'فتاویٰ رضویہ، جلد ۶، صفحہ ۱۲۰',
    ),
    MasailItemModel(
      id: 'wuzu_1',
      categoryId: 'wuzu',
      question: 'What are the 4 Fard (obligatory) acts of Wuzu?',
      questionUr: 'وضو کے چار فرائض کون کون سے ہیں؟',
      answer: '1. Washing the face from hairline to below chin and ear to ear.\n2. Washing both arms including elbows.\n3. Masah (wiping) of one-fourth of the head.\n4. Washing both feet including ankles.',
      answerUr: '۱. پیشانی کے بالوں سے ٹھوڑی کے نیچے تک اور ایک کان کی لو سے دوسرے کان تک چہرہ دھونا۔\n۲. دونوں ہاتھوں کو کہنیوں سمیت دھونا۔\n۳. چوتھائی سر کا مسح کرنا۔\n۴. دونوں پاؤں ٹخنوں سمیت دھونا۔',
      book: 'Bahar-e-Shariat, Vol. 1, Page 288',
      bookUr: 'بہارِ شریعت، حصہ ۲، صفحہ ۲۸۸',
    ),
    MasailItemModel(
      id: 'roza_1',
      categoryId: 'roza',
      question: 'Does using an inhaler for asthma invalidate the fast (Sawm)?',
      questionUr: 'کیا دمہ کے مریض کا انہیلر استعمال کرنے سے روزہ ٹوٹ جاتا ہے؟',
      answer: 'Yes, using a medicinal inhaler breaks the fast because medication reaches the stomach/lungs. A Qada fast is required later when health permits.',
      answerUr: 'جی ہاں، انہیلر کے ذریعے دوا کے ذرات پھیپھڑوں اور حلق کے راستے معدے تک پہنچتے ہیں، اس لیے روزہ فاسد ہو جاتا ہے اور بعد میں قضا لازم ہے۔',
      book: 'Fatawa Razawiyyah, Vol. 10, Page 512',
      bookUr: 'فتاویٰ رضویہ، جلد ۱۰، صفحہ ۵۱۲',
    ),
    MasailItemModel(
      id: 'zakat_1',
      categoryId: 'zakat',
      question: 'What is the Nisab of Zakat for Gold and Silver?',
      questionUr: 'سونے اور چاندی پر زکوٰۃ کا نصاب کیا ہے؟',
      answer: 'The Nisab for Gold is 7.5 Tolas (87.48 grams) and for Silver is 52.5 Tolas (612.36 grams). 2.5% of total wealth held for a lunar year is given as Zakat.',
      answerUr: 'سونے کا نصاب ساڑھے سات تولے (۸۷.۴۸ گرام) اور چاندی کا نصاب ساڑھے باون تولے (۶۱۲.۳۶ گرام) ہے۔ مکمل سال گزرنے پر کل مالیت کا ۲.۵ فیصد زکوٰۃ ادا کرنا فرض ہے۔',
      book: 'Bahar-e-Shariat, Vol. 1, Page 875',
      bookUr: 'بہارِ شریعت، حصہ ۵، صفحہ ۸۷۵',
    ),
  ];

  static const List<AqaidItemModel> _initialAqaidSeed = [
    AqaidItemModel(
      id: 'tawheed_1',
      categoryId: 'tawheed',
      title: 'Tawheed: The Oneness of Allah Almighty',
      titleUr: 'عقیدہ توحید: اللہ تعالیٰ کی یکتائی اور وحدانیت',
      arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      explanation: 'Allah is One in His Essence, Attributes, and Actions. He has no partner, no equal, no parents, and no children. He is Eternal and Self-Sufficient.',
      explanationUr: 'اللہ تعالیٰ اپنی ذات، صفات اور افعال میں یکتا ہے۔ اس کا کوئی شریک یا ہمسر نہیں، نہ اس کے کوئی والدین ہیں اور نہ اولاد۔ وہ سدا قائم رہنے والا اور بے نیاز ہے۔',
      book: 'Surah Al-Ikhlas (112:1-4) & Kitab al-Aqaid',
      bookUr: 'سورۃ الاخلاص (۱۱۲:۱-۴) و کتاب العقائد',
    ),
    AqaidItemModel(
      id: 'risalat_1',
      categoryId: 'risalat',
      title: 'Khatm-e-Nubuwwat: Finality of Prophethood',
      titleUr: 'عقیدہ ختمِ نبوت: حضور ﷺ آخری نبی ہیں',
      arabicText: 'مَّا كَانَ مُحَمَّدٌ أَبَا أَحَدٍ مِّن رِّجَالِكُمْ وَلَكِن رَّسُولَ اللَّهِ وَخَاتَمَ النَّبِيِّينَ',
      explanation: 'Prophet Muhammad (ﷺ) is the Last and Final Messenger of Allah. No new prophet will ever come after him. Denying this fundamental belief takes one outside Islam.',
      explanationUr: 'حضرت محمد مصطفیٰ صلی اللہ علیہ وآلہ وسلم اللہ کے آخری نبی اور رسول ہیں۔ آپ کے بعد قیامت تک کوئی نیا نبی نہیں آ سکتا۔ اس عقیدے کا انکار دائرہ اسلام سے خارج کر دیتا ہے۔',
      book: 'Surah Al-Ahzab (33:40) & Sahih Muslim 523',
      bookUr: 'سورۃ الاحزاب (۳۳:۴۰) و صحیح مسلم ۵۲۳',
    ),
    AqaidItemModel(
      id: 'ishq_1',
      categoryId: 'ishq_rasool',
      title: 'Love of the Holy Prophet (ﷺ)',
      titleUr: 'عشقِ رسول ﷺ: ایمان کی اصل اور روح',
      arabicText: 'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى أَكُونَ أَحَبَّ إِلَيْهِ مِنْ وَالِدِهِ وَوَلَدِهِ وَالنَّاسِ أَجْمَعِينَ',
      explanation: 'None of you truly believes until I am more beloved to him than his father, his child, and all of mankind.',
      explanationUr: 'تم میں سے کوئی شخص اس وقت تک سچا مومن نہیں ہو سکتا جب تک کہ میں اس کے نزدیک اس کے والدین، اس کی اولاد اور تمام انسانوں سے زیادہ محبوب نہ ہو جاؤں۔',
      book: 'Sahih al-Bukhari 15 & Sahih Muslim 44',
      bookUr: 'صحیح البخاری ۱۵ و صحیح مسلم ۴۴',
    ),
  ];

  static const List<EventModel> _initialEventsSeed = [
    EventModel(
      id: '1',
      title: 'Global Milad Gathering 2026',
      titleUr: 'عالمی اجتماعِ میلاد النبی ۲۰۲۶ء',
      dateTime: 'Dec 24, 8:00 PM',
      location: 'Jamia Masjid Al-Aksa, Main Hall',
      locationUr: 'جامع مسجد الاقصیٰ، مرکزی ہال',
      status: 'Featured',
      description: 'Join millions globally in a collective recitation of Durood Shareef leading up to the blessed month of Rabi al-Awwal.',
      descriptionUr: 'ربیع الاول کے مبارک مہینے کی آمد کی خوشی میں دنیا بھر کے لاکھوں مسلمانوں کے ساتھ اجتماعی درود پاک پڑھنے کی محفل میں شرکت فرمائیں۔',
    ),
    EventModel(
      id: '2',
      title: 'Weekly Jumu\'ah Durood Majlis',
      titleUr: 'ہفتہ وار جمعۃ المبارک درود مجلس',
      dateTime: 'Every Friday after Asr',
      location: 'Live Stream & Central Masjid',
      locationUr: 'لائیو اسٹریم و مرکزی جامع مسجد',
      status: 'Ongoing',
      description: 'Sending special Salawat upon Prophet Muhammad (ﷺ) on the blessed day of Friday.',
      descriptionUr: 'جمعۃ المبارک کے بابرکت دن نمازِ عصر کے بعد نبی کریم صلی اللہ علیہ وآلہ وسلم کی بارگاہ میں خصوصی درود و سلام نذر کرنا۔',
    ),
    EventModel(
      id: '3',
      title: 'Ramadan Preparation & Durood Drive',
      titleUr: 'استقبالِ رمضان و درود شریف مہم',
      dateTime: 'Mar 15, 6:30 PM',
      location: 'Islamic Cultural Center Auditorium',
      locationUr: 'اسلامک کلچرل سینٹر آڈیٹوریم',
      status: 'Coming Soon',
      description: 'Preparing our hearts for Ramadan through Durood, Istighfar, and lectures on Fiqh.',
      descriptionUr: 'درود پاک، استغفار اور فتاویٰ و مسائل کے بیانات کے ذریعے رمضان المبارک کے لیے دلوں کی تیاری۔',
    ),
  ];
}
