import 'package:flutter/material.dart';

class MasailCategory {
  final String id;
  final String title;
  final String titleUr;
  final String arabicTitle;
  final IconData icon;
  final String? badge;

  const MasailCategory({
    required this.id,
    required this.title,
    required this.titleUr,
    required this.arabicTitle,
    required this.icon,
    this.badge,
  });
}

class MasailItem {
  final String id;
  final String categoryId;
  final String question;
  final String questionUr;
  final String answer;
  final String answerUr;
  final String citation;
  final String citationUr;
  final String referenceBook;
  final String referenceBookUr;

  const MasailItem({
    required this.id,
    required this.categoryId,
    required this.question,
    required this.questionUr,
    required this.answer,
    required this.answerUr,
    required this.citation,
    required this.citationUr,
    required this.referenceBook,
    required this.referenceBookUr,
  });
}

class MockMasailData {
  static const List<MasailCategory> categories = [
    MasailCategory(id: 'namaz', title: 'Namaz', titleUr: 'نماز', arabicTitle: 'نماز', icon: Icons.mosque_rounded),
    MasailCategory(id: 'wuzu', title: 'Wazu', titleUr: 'وضو', arabicTitle: 'وضو', icon: Icons.water_drop_rounded),
    MasailCategory(id: 'roza', title: 'Roza', titleUr: 'روزہ', arabicTitle: 'روزہ', icon: Icons.wb_sunny_rounded),
    MasailCategory(id: 'zakat', title: 'Zakat', titleUr: 'زکوۃ', arabicTitle: 'زكٰوة', icon: Icons.account_balance_wallet_rounded, badge: 'Updated'),
    MasailCategory(id: 'nikah', title: 'Nikah', titleUr: 'نکاح', arabicTitle: 'نکاح', icon: Icons.favorite_rounded),
    MasailCategory(id: 'hajj', title: 'Hajj', titleUr: 'حج', arabicTitle: 'حج', icon: Icons.landscape_rounded),
    MasailCategory(id: 'taharat', title: 'Taharat', titleUr: 'طہارت', arabicTitle: 'طہارت', icon: Icons.cleaning_services_rounded),
    MasailCategory(id: 'miras', title: 'Miras', titleUr: 'وراثت', arabicTitle: 'وراثت', icon: Icons.account_balance_rounded),
  ];

  static const List<MasailItem> items = [
    // ── NAMAZ MASAIL ───────────────────────────────────────────────
    MasailItem(
      id: 'n1',
      categoryId: 'namaz',
      question: 'What are the essential Farz components of Salah?',
      questionUr: 'نماز کے فرائض (شرائط و ارکان) کون سے ہیں؟',
      answer: 'There are 7 outer conditions (Sharaiz) and 6 inner compulsory acts (Arkan) of Salah.\n'
          'Sharaiz: 1. Taharah of body, 2. Taharah of clothes, 3. Taharah of place, 4. Satr-e-Aurah, 5. Facing Qiblah, 6. Proper Time, 7. Niyyah.\n'
          'Arkan: 1. Takbeer-e-Tahrima, 2. Qiyam, 3. Qira\'at, 4. Ruku, 5. Sujood, 6. Qa\'dah Akhirah.',
      answerUr: 'نماز میں ۷ بیرونِ نماز شرائط اور ۶ اندرونِ نماز ارکان فرض ہیں۔\n'
          'شرائط: ۱۔ طہارتِ بدن، ۲۔ طہارتِ لباس، ۳۔ طہارتِ مکان، ۴۔ سترِ عورت، ۵۔ استقبالِ قبلہ، ۶۔ وقتِ نماز، ۷۔ نیت۔\n'
          'ارکان: ۱۔ تکبیرِ تحریمہ، ۲۔ قیام، ۳۔ قرآت، ۴۔ رکوع، ۵۔ سجود، ۶۔ قعدہ اخیرہ۔',
      citation: 'Bahar-e-Shariat, Vol. 1, Page 450-465',
      citationUr: 'بہارِ شریعت، حصہ ۳، صفحہ ۴۵۰-۴۶۵',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),
    MasailItem(
      id: 'n2',
      categoryId: 'namaz',
      question: 'What is the rule if one forgets a Wajib act in Salah?',
      questionUr: 'اگر نماز میں کوئی واجب چھوٹ جائے تو کیا حکم ہے؟',
      answer: 'If a Wajib act is accidentally omitted or delayed, performing Sajda-e-Sahw (two prostrations after Salaam on right side) makes the Salah valid. If omitted intentionally, repeating the Salah becomes Wajib.',
      answerUr: 'اگر بھولے سے کوئی واجب چھوٹ جائے یا تاخیر ہو جائے تو سجدہ سہو کرنے سے نماز درست ہو جاتی ہے۔ اگر قصداً واجب چھوڑا جائے تو نماز کا اعادہ (دوبارہ پڑھنا) واجب ہے۔',
      citation: 'Fatawa Ridawiyyah, Vol. 6, Page 210',
      citationUr: 'فتاویٰ رضویہ، جلد ۶، صفحہ ۲۱۰',
      referenceBook: 'Fatawa Ridawiyyah',
      referenceBookUr: 'فتاویٰ رضویہ',
    ),
    MasailItem(
      id: 'n3',
      categoryId: 'namaz',
      question: 'How should Qaza (missed) Salah be offered?',
      questionUr: 'قضا نمازیں ادا کرنے کا شرعی طریقہ کیا ہے؟',
      answer: 'Qaza Salah must be offered as soon as possible. Niyyah should specify the earliest unoffered prayer (e.g. "My earliest unoffered Fajr"). Only Farz and Witr prayers have Qaza.',
      answerUr: 'قضا نمازیں جلد از جلد ادا کرنا لازم ہے۔ نیت یوں کی جائے: "میرا سب سے پہلا جو فجر قضا ہوا اس کی نیت کرتا ہوں"۔ صرف فرائض اور وتر کی قضا ہوتی ہے۔',
      citation: 'Durr-e-Mukhtar & Bahar-e-Shariat',
      citationUr: 'درِ مختار و بہارِ شریعت',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),
    MasailItem(
      id: 'n4',
      categoryId: 'namaz',
      question: 'What are the invalidators (Mufsidat) of Salah?',
      questionUr: 'نماز کو فاسد کر دینے والے امور کون سے ہیں؟',
      answer: 'Speaking words, crying out loud due to worldly distress, eating/drinking, turning chest away from Qiblah, laughing out loud, or breaking Wuzu invalidates Salah immediately.',
      answerUr: 'نماز میں بات چیت کرنا، دنیوی تکلیف پر آہ و زاری، کچھ کھانا پینا، سینہ قبلہ سے پھیرنا، قہقہہ لگانا، یا وضو ٹوٹ جانا نماز کو باطل و فاسد کر دیتا ہے۔',
      citation: 'Fatawa Alamgiri, Vol. 1',
      citationUr: 'فتاویٰ عالمگیری، جلد ۱',
      referenceBook: 'Fatawa Alamgiri',
      referenceBookUr: 'فتاویٰ عالمگیری',
    ),
    MasailItem(
      id: 'n5',
      categoryId: 'namaz',
      question: 'What is the minimum distance for Qasr (traveler\'s prayer)?',
      questionUr: 'مسافر نماز (قصر) کے لیے کم از کم مسافت کتنی ہے؟',
      answer: 'A journey of 3 Shar\'i days (approx 57.5 miles / 92 km) qualifies a person as a Musafir. A traveler shortens 4-Rak\'at Farz prayers to 2 Rak\'at.',
      answerUr: 'تقریباً ساڑھے ستاون شرعی میل (۹۲ کلومیٹر) کی مسافت سے بندہ مسافر بن جاتا ہے۔ مسافر ۴ رکعت والے فرائض کو قصر کر کے ۲ رکعت پڑھے گا۔',
      citation: 'Bahar-e-Shariat, Vol. 1, Page 740',
      citationUr: 'بہارِ شریعت، حصہ ۴، صفحہ ۷۴۰',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),

    // ── WUZU MASAIL ────────────────────────────────────────────────
    MasailItem(
      id: 'w1',
      categoryId: 'wuzu',
      question: 'What are the 4 obligatory (Farz) acts in Wuzu?',
      questionUr: 'وضو میں کون سے ۴ امور فرض ہیں؟',
      answer: '1. Washing the entire face once from top of forehead to under chin and earlobe to earlobe.\n'
          '2. Washing both arms including elbows once.\n'
          '3. Wiping (Masah) over at least one-quarter of head once.\n'
          '4. Washing both feet including ankles once.',
      answerUr: '۱۔ پیشانی کے بالوں سے ٹھوڑی کے نیچے تک اور ایک کان کی لو سے دوسرے کان کی لو تک پورا منہ ایک بار دھونا۔\n'
          '۲۔ دونوں ہاتھ کہنیوں سمیت ایک بار دھونا۔\n'
          '۳۔ چوتھائی سر کا ایک بار مسح کرنا۔\n'
          '۴۔ دونوں پاؤں ٹخنوں سمیت ایک بار دھونا۔',
      citation: 'Surah Al-Ma\'idah (5:6) & Bahar-e-Shariat',
      citationUr: 'سورۃ المائدة (۵:۶) و بہارِ شریعت',
      referenceBook: 'Quran & Bahar-e-Shariat',
      referenceBookUr: 'قرآن و بہارِ شریعت',
    ),
    MasailItem(
      id: 'w2',
      categoryId: 'wuzu',
      question: 'What matters nullify and break Wuzu (Nawaqiz-e-Wuzu)?',
      questionUr: 'وضو توڑنے والے امور (نواقضِ وضو) کون سے ہیں؟',
      answer: '1. Discharge of anything from private parts.\n'
          '2. Flowing of blood or pus from any part of body.\n'
          '3. Vomiting a mouthful.\n'
          '4. Sleeping while lying down or leaning heavily.\n'
          '5. Laughing aloud in a prayer having Ruku and Sujood.',
      answerUr: '۱۔ سبیلین (پیشاب، پاخانہ وغیرہ) سے کسی چیز کا نکلنا۔\n'
          '۲۔ جسم کے کسی مقام سے خون یا پیپ کا بہہ نکلنا۔\n'
          '۳۔ منہ بھر کر قے آنا۔\n'
          '۴۔ ٹیک لگا کر یا لیٹ کر سو جانا۔\n'
          '۵۔ رکوع و سجدے والی نماز میں قہقہہ لگانا۔',
      citation: 'Al-Hedaya & Bahar-e-Shariat',
      citationUr: 'الہدایہ و بہارِ شریعت',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),
    MasailItem(
      id: 'w3',
      categoryId: 'wuzu',
      question: 'Is reciting Bismillah before Wuzu Sunnah?',
      questionUr: 'کیا وضو سے پہلے بسم اللہ پڑھنا سنت ہے؟',
      answer: 'Yes, reciting "Bismillahi wal-Hamdulillah" before starting Wuzu is Sunnah. As long as Wuzu remains, angels continue writing good deeds for the person.',
      answerUr: 'جی ہاں، وضو شروع کرتے وقت "بسم الله والحمد لله" پڑھنا سنت ہے۔ جب تک وضو قائم رہتا ہے فرشتے نیکیاں لکھتے رہتے ہیں۔',
      citation: 'Tabarani & Fatawa Ridawiyyah',
      citationUr: 'طبرانی و فتاویٰ رضویہ',
      referenceBook: 'Fatawa Ridawiyyah',
      referenceBookUr: 'فتاویٰ رضویہ',
    ),
    MasailItem(
      id: 'w4',
      categoryId: 'wuzu',
      question: 'What is the duration for wiping (Masah) over leather socks (Khuffayn)?',
      questionUr: 'موزوں (خفین) پر مسح کی شرعی مدت کتنی ہے؟',
      answer: 'A resident (Muqeem) may wipe over Khuffayn for 24 hours, and a traveler (Musafir) for 72 hours (3 days and nights), starting from the first Wuzu invalidation after wearing them in state of purity.',
      answerUr: 'مقیم کے لیے موزوں پر مسح کی مدت ۱ دن رات (۲۴ گھنٹے) اور مسافر کے لیے ۳ دن رات (۷۲ گھنٹے) ہے۔ مدت وضو ٹوٹنے کے وقت سے شروع ہوتی ہے۔',
      citation: 'Fatawa Alamgiri, Vol. 1',
      citationUr: 'فتاویٰ عالمگیری، جلد ۱',
      referenceBook: 'Fatawa Alamgiri',
      referenceBookUr: 'فتاویٰ عالمگیری',
    ),

    // ── TAYAMUM MASAIL ─────────────────────────────────────────────
    MasailItem(
      id: 't1',
      categoryId: 'tayamum',
      question: 'What are the essential Farz acts in Tayamum?',
      questionUr: 'تیمم کے فرائض کون سے ہیں؟',
      answer: 'There are 3 Farz acts in Tayamum:\n'
          '1. Niyyah (Intention of attaining purity for Salah).\n'
          '2. Striking clean earth and wiping the entire face.\n'
          '3. Striking clean earth and wiping both arms including elbows.',
      answerUr: 'تیمم میں ۳ امور فرض ہیں:\n'
          '۱۔ پاکی حاصل کرنے کی نیت کرنا۔\n'
          '۲۔ پاک مٹی پر ہاتھ مار کر پورے چہرے کا مسح کرنا۔\n'
          '۳۔ دوبارہ ہاتھ مار کر دونوں ہاتھوں کا کہنیوں سمیت مسح کرنا۔',
      citation: 'Bahar-e-Shariat, Vol. 1, Page 350',
      citationUr: 'بہارِ شریعت، حصہ ۲، صفحہ ۳۵۰',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),
    MasailItem(
      id: 't2',
      categoryId: 'tayamum',
      question: 'Under what conditions is Tayamum permissible?',
      questionUr: 'تیمم کن حالات میں جائز ہوتا ہے؟',
      answer: 'Tayamum is permissible when water is unavailable within 1 Shar\'i Mile (approx 1.8km), or when using water would exacerbate illness, or when water is needed for drinking survival.',
      answerUr: 'تیمم اس وقت جائز ہے جب ۱ شرعی میل (تقریباً ۱.۸ کلومیٹر) تک پانی نہ ملے، یا بیماری بڑھنے کا خدشہ ہو، یا پانی صرف پینے کے لیے ہی دستیاب ہو۔',
      citation: 'Fatawa Alamgiri, Vol. 1',
      citationUr: 'فتاویٰ عالمگیری، جلد ۱',
      referenceBook: 'Fatawa Alamgiri',
      referenceBookUr: 'فتاویٰ عالمگیری',
    ),

    // ── ROZA MASAIL ────────────────────────────────────────────────
    MasailItem(
      id: 'r1',
      categoryId: 'roza',
      question: 'Does using eye drops or applying Surma break the fast?',
      questionUr: 'کیا آنکھ میں ڈراپس یا سرما لگانے سے روزہ ٹوٹ جاتا ہے؟',
      answer: 'According to Hanafi Fiqh, applying Surma or putting drops into eyes does NOT break the fast, even if color or taste is felt in throat.',
      answerUr: 'فقہ حنفی کے مطابق آنکھ میں دوا/ڈراپس ڈالنے یا سرمہ لگانے سے روزہ نہیں ٹوٹتا، خواہ اس کا اثر یا ذائقہ حلق میں محسوس ہو۔',
      citation: 'Al-Hedaya & Bahar-e-Shariat',
      citationUr: 'الہدایہ و بہارِ شریعت',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),
    MasailItem(
      id: 'r2',
      categoryId: 'roza',
      question: 'What invalidates the fast requiring only Qaza vs Kaffarah?',
      questionUr: 'روزہ ٹوٹنے پر کب صرف قضا اور کب کفارہ دونوں واجب ہوتے ہیں؟',
      answer: 'Inhaling medicine intentionally, eating due to misunderstanding time requires Qaza. Intentionally eating/drinking or marital relations without valid Shar\'i reason during Ramadan requires both Qaza and Kaffarah (fasting 60 consecutive days).',
      answerUr: 'غلط فہمی یا بھول کر قصداً کھانے پر صرف قضا لازم ہے۔ رمضان کے روزے میں بغیر عذرِ شرعی قصداً کھانے پینے یا ہمبستری سے قضا اور کفارہ (۶۰ مسلسل روزے) دونوں واجب ہوتے ہیں۔',
      citation: 'Fatawa Ridawiyyah, Vol. 10',
      citationUr: 'فتاویٰ رضویہ، جلد ۱۰',
      referenceBook: 'Fatawa Ridawiyyah',
      referenceBookUr: 'فتاویٰ رضویہ',
    ),
    MasailItem(
      id: 'r3',
      categoryId: 'roza',
      question: 'Does unintentional eating due to forgetfulness break the fast?',
      questionUr: 'کیا بھول کر کچھ کھا پی لینے سے روزہ ٹوٹ جاتا ہے؟',
      answer: 'No, eating or drinking out of forgetfulness does NOT break the fast. The Prophet (ﷺ) said: "Allah fed him and gave him drink."',
      answerUr: 'جی نہیں، بھول کر کھا پی لینے سے روزہ نہیں ٹوٹتا۔ حدیث مبارکہ ہے: "اللہ نے اسے کھلایا اور پلایا"۔ یاد آتے ہی فوراً رک جانا چاہیے۔',
      citation: 'Sahih Bukhari & Sahih Muslim',
      citationUr: 'صحیح البخاری و صحیح مسلم',
      referenceBook: 'Sahih Muslim',
      referenceBookUr: 'صحیح مسلم',
    ),

    // ── ZAKAT MASAIL ───────────────────────────────────────────────
    MasailItem(
      id: 'z1',
      categoryId: 'zakat',
      question: 'What is the Nisab threshold for Gold and Silver?',
      questionUr: 'سونا اور چاندی پر زکوۃ کا نصاب کیا ہے؟',
      answer: 'The Nisab for Gold is 7.5 Tolas (87.48 grams) and for Silver is 52.5 Tolas (612.36 grams). If a person possesses wealth equal to silver Nisab for 1 lunar year, 2.5% Zakat is obligatory.',
      answerUr: 'سونے کا نصاب ساڑھے سات (7.5) تولے اور چاندی کا نصاب ساڑھے باون (52.5) تولے ہے۔ اگر سال بھر یہ مالیت رہے تو کل رقم پر ۲.۵ فیصد زکوۃ فرض ہے۔',
      citation: 'Fatawa Alamgiri, Vol. 1',
      citationUr: 'فتاویٰ عالمگیری، جلد ۱',
      referenceBook: 'Fatawa Alamgiri',
      referenceBookUr: 'فتاویٰ عالمگیری',
    ),
    MasailItem(
      id: 'z2',
      categoryId: 'zakat',
      question: 'Who are ineligible to receive Zakat funds?',
      questionUr: 'کن لوگوں کو زکوۃ دینا جائز نہیں ہے؟',
      answer: 'Zakat cannot be given to:\n1. Parents, grandparents, children, grandchildren, or spouse.\n2. Wealthy individuals (Sahib-e-Nisab).\n3. Hashimi / Sayyid family descendants.\n4. Non-Muslims or for constructing mosque buildings.',
      answerUr: 'زکوۃ درج ذیل کو نہیں دی جا سکتی:\n۱۔ والدین، دادا دادی، اولاد، پوتے پوتیاں، اور شوہر/بیوی۔\n۲۔ صاحبِ نصاب مالدار شخص۔\n۳۔ ساداتِ کرام (بنو ہاشم)۔\n۴۔ غیر مسلم یا مسجد و سڑک کی تعمیر میں۔',
      citation: 'Bahar-e-Shariat, Vol. 1, Page 925',
      citationUr: 'بہارِ شریعت، حصہ ۵، صفحہ ۹۲۵',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),

    // ── NIKAH MASAIL ───────────────────────────────────────────────
    MasailItem(
      id: 'nk1',
      categoryId: 'nikah',
      question: 'What are the essential Shar\'i requirements for Nikah?',
      questionUr: 'نکاح کے انعقاد کے لیے شرعی شرائط کون سی ہیں؟',
      answer: 'Nikah requires Ijab (Proposal) and Qubool (Acceptance) in the same sitting in the presence of at least 2 sane, adult Muslim male witnesses (or 1 male and 2 female witnesses). Mahr (dower) is compulsory.',
      answerUr: 'نکاح کے لیے ایک ہی مجلس میں ایجاب و قبول اور کم از کم ۲ عاقل بالغ مسلمان مرد گواہوں (یا ۱ مرد اور ۲ عورتوں) کی موجودگی فرض و شرط ہے۔ مہر مقرر کرنا واجب ہے۔',
      citation: 'Bahar-e-Shariat, Vol. 2, Page 5',
      citationUr: 'بہارِ شریعت، حصہ ۷، صفحہ ۵',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),

    // ── HAJJ MASAIL ────────────────────────────────────────────────
    MasailItem(
      id: 'h1',
      categoryId: 'hajj',
      question: 'What are the 3 obligatory (Farz) rituals of Hajj?',
      questionUr: 'حج کے ۳ اہم ترین فرائض کون سے ہیں؟',
      answer: 'The 3 Farz acts of Hajj are:\n'
          '1. Entering Ihram with intention (Niyyah).\n'
          '2. Wuquf-e-Arafat (Staying at Arafat between Zohal of 9th Dhul Hijjah to Fajr of 10th).\n'
          '3. Tawaf-al-Ziyarah (Tawaf-e-Ifadah performed between 10th and 12th Dhul Hijjah).',
      answerUr: 'حج کے ۳ بنیادی فرائض درج ذیل ہیں:\n'
          '۱۔ نیت کے ساتھ احرام باندھنا۔\n'
          '۲۔ وقوفِ عرفات (۹ ذوالحجہ کے زوال سے ۱۰ ذوالحجہ کے طلوعِ فجر کے درمیان عرفات میں ٹھہرنا)۔\n'
          '۳۔ طوافِ زیارت کرنا (۱۰ سے ۱۲ ذوالحجہ کے درمیان)۔',
      citation: 'Bahar-e-Shariat, Vol. 1, Page 1020',
      citationUr: 'بہارِ شریعت، حصہ ۶، صفحہ ۱۰۲۰',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),

    // ── TAHARAT MASAIL ─────────────────────────────────────────────
    MasailItem(
      id: 'th1',
      categoryId: 'taharat',
      question: 'What are the 3 obligatory (Farz) acts of Ghusl (Bath)?',
      questionUr: 'غسل میں کون سے ۳ امور فرض ہیں؟',
      answer: '1. Rinsing the mouth thoroughly up to the throat (Gargara if not fasting).\n'
          '2. Rinsing the nose up to the soft bone.\n'
          '3. Washing the entire body once from head to toe so not a single hair remains dry.',
      answerUr: 'غسل میں ۳ امور فرض ہیں:\n'
          '۱۔ منہ بھر کر کلی کرنا (روزہ نہ ہو تو غرغرہ کرنا)۔\n'
          '۲۔ ناک کی نرم ہڈی تک پانی پہنچانا۔\n'
          '۳۔ پورے جسم پر اس طرح پانی بہانا کہ ایک بال برابر جگہ بھی سوکھی نہ رہے۔',
      citation: 'Bahar-e-Shariat, Vol. 1, Page 310',
      citationUr: 'بہارِ شریعت، حصہ ۲، صفحہ ۳۱۰',
      referenceBook: 'Bahar-e-Shariat',
      referenceBookUr: 'بہارِ شریعت',
    ),

    // ── MIRAS MASAIL ───────────────────────────────────────────────
    MasailItem(
      id: 'mr1',
      categoryId: 'miras',
      question: 'How is inheritance (Miras) distributed in Islam?',
      questionUr: 'اسلام میں ترکہ و میراث کی تقسیم کا بنیادی اصول کیا ہے؟',
      answer: 'After paying funeral costs, debts, and valid wills (up to 1/3), the remaining wealth must be distributed strictly according to Quranic shares among prescribed heirs (parents, spouse, children, siblings).',
      answerUr: 'میراث کی تقسیم سے پہلے تدفین کے اخراجات، دیون (قرضے) اور جائز وصیت (تہائی مال تک) کی ادائیگی لازم ہے۔ اس کے بعد بقایا مال قرآن مجید (سورۃ النساء) کی طے شدہ حدود کے مطابق ورثاء میں تقسیم ہوگا۔',
      citation: 'Surah An-Nisa (4:11-12) & Al-Sirajiyyah',
      citationUr: 'سورۃ النساء (۴:۱۱-۱۲) و السراجیہ',
      referenceBook: 'Quran & Fatawa Ridawiyyah',
      referenceBookUr: 'قرآن و فتاویٰ رضویہ',
    ),
  ];
}
