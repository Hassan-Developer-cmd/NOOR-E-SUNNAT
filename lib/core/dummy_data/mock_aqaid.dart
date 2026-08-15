import 'package:flutter/material.dart';

class AqaidCategory {
  final String id;
  final String title;
  final String titleUr;
  final String arabicTitle;
  final String subtitle;
  final IconData icon;
  final String bgAsset;
  final bool isFullWidth;

  const AqaidCategory({
    required this.id,
    required this.title,
    required this.titleUr,
    required this.arabicTitle,
    required this.subtitle,
    required this.icon,
    required this.bgAsset,
    this.isFullWidth = false,
  });
}

class AqaidItem {
  final String id;
  final String categoryId;
  final String title;
  final String titleUr;
  final String arabicText;
  final String explanation;
  final String explanationUr;
  final String reference;
  final String referenceUr;

  const AqaidItem({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.titleUr,
    required this.arabicText,
    required this.explanation,
    required this.explanationUr,
    required this.reference,
    required this.referenceUr,
  });
}

class MockAqaidData {
  static const List<AqaidCategory> categories = [
    AqaidCategory(
      id: 'tawheed',
      title: 'Tawheed',
      titleUr: 'توحید',
      arabicTitle: 'توحيد',
      subtitle: 'Oneness of Allah (SWT)',
      icon: Icons.auto_awesome,
      bgAsset: 'assets/images/tauheed.png',
    ),
    AqaidCategory(
      id: 'risalat',
      title: 'Risalat',
      titleUr: 'رسالت',
      arabicTitle: 'رسالت',
      subtitle: 'Prophethood of Muhammad (ﷺ)',
      icon: Icons.star,
      bgAsset: 'assets/images/risalat.png',
    ),
    AqaidCategory(
      id: 'sahaba_ahlebait',
      title: 'Sahaba o Ahlebait',
      titleUr: 'صحابہ و اہل بیت',
      arabicTitle: 'صحابہ و اہل بیت',
      subtitle: 'Companions & Blessed Household',
      icon: Icons.shield,
      bgAsset: 'assets/images/sahaba.png',
      isFullWidth: true,
    ),
    AqaidCategory(
      id: 'ishq_rasool',
      title: 'Ishq-e-Rasool',
      titleUr: 'عشقِ رسول',
      arabicTitle: 'عشقِ رسول',
      subtitle: 'Love & Devotion to Prophet (ﷺ)',
      icon: Icons.favorite,
      bgAsset: 'assets/images/ishq_rasool.png',
    ),
    AqaidCategory(
      id: 'wilayat',
      title: 'Wilayat',
      titleUr: 'ولایت',
      arabicTitle: 'ولایت',
      subtitle: 'Sainthood & Spiritual Path',
      icon: Icons.brightness_7,
      bgAsset: 'assets/images/wilayat.png',
    ),
  ];

  static const List<AqaidItem> items = [
    // ── TAWHEED AQAID ──────────────────────────────────────────────
    AqaidItem(
      id: 't1',
      categoryId: 'tawheed',
      title: 'The Absolute Oneness & Uniqueness of Allah',
      titleUr: 'کمالِ توحید و وحدانیتِ الٰہی',
      arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      explanation: 'Allah is Supreme, Absolute, and Unique. He has no partner, spouse, or child. He is free from time, place, physical shape, or weakness. He alone is worthy of worship and ultimate devotion.',
      explanationUr: 'اللہ تعالیٰ واحد و یکتا ہے، بے نیاز ہے، نہ اس کی کوئی اولاد ہے اور نہ وہ کسی کی اولاد ہے، اور کوئی اس کا ہمسر نہیں۔ وہ زمان و مکان، جسمانیت اور عیب سے پاک ہے اور صرف وہی عبادت کا مستحق ہے۔',
      reference: 'Surah Al-Ikhlas (112:1-4)',
      referenceUr: 'سورۃ الاخلاص (۱۱۲:۱-۴)',
    ),
    AqaidItem(
      id: 't2',
      categoryId: 'tawheed',
      title: 'Attributes of Allah (Sifat-e-Ilahiyyah)',
      titleUr: 'صفاتِ باری تعالیٰ کا عقیدہ',
      arabicText: 'لَيْسَ كَمِثْلِهِ شَيْءٌ ۖ وَهُوَ السَّمِيعُ الْبَصِيرُ',
      explanation: 'Allah\'s attributes are eternal (Qadeem) and inherent to His Being. He is All-Knowing, All-Seeing, All-Hearing, and All-Powerful. Nothing in creation resembles His Divine Essence.',
      explanationUr: 'اللہ تعالیٰ کی صفات قدیم اور اس کی ذات کے ساتھ قائم ہیں۔ وہ علیم، بصیر، سمیع اور قدیر ہے۔ کائنات میں کوئی چیز اس کی ذات و صفات کے مثل نہیں۔',
      reference: 'Surah Ash-Shura (42:11)',
      referenceUr: 'سورۃ الشوریٰ (۴۲:۱۱)',
    ),
    AqaidItem(
      id: 't3',
      categoryId: 'tawheed',
      title: 'Belief in Divine Decree and Fate (Qadr)',
      titleUr: 'عقیدہ تقدیر و مشیتِ الٰہی',
      arabicText: 'إِنَّا كُلَّ شَيْءٍ خَلَقْنَاهُ بِقَدَرٍ',
      explanation: 'Everything that happens in the universe occurs by Allah\'s divine knowledge, absolute decree, and eternal wisdom.',
      explanationUr: 'بے شک ہم نے ہر چیز کو ایک اندازے (تقدیر) کے ساتھ پیدا فرمایا ہے۔ خیر و شر سب اللہ کے علم و مشیت کے تحت ہے۔',
      reference: 'Surah Al-Qamar (54:49)',
      referenceUr: 'سورۃ القمر (۵۴:۴۹)',
    ),

    // ── RISALAT AQAID ──────────────────────────────────────────────
    AqaidItem(
      id: 'r1',
      categoryId: 'risalat',
      title: 'Finality of Prophethood (Khatam-an-Nabiyyin)',
      titleUr: 'عقیدہ ختمِ نبوت (خاتم النبیینﷺ)',
      arabicText: 'مَّا كَانَ مُحَمَّدٌ أَبَا أَحَدٍ مِّن رِّجَالِكُمْ وَلَٰكِن رَّسُولَ اللَّهِ وَخَاتَمَ النَّبِيِّينَ',
      explanation: 'Prophet Muhammad (ﷺ) is the Last and Final Messenger of Allah. The chain of prophethood is completed through Him, and anyone claiming prophethood after Him is outside Islam.',
      explanationUr: 'حضرت محمد مصطفیٰ (صلی اللہ علیہ وآلہ وسلم) تمام کائنات کے لیے آخری اور خاتم النبیین ہیں۔ نبوت کا سلسلہ آپ پر مکمل ہو چکا ہے اور آپ کے بعد کوئی نیا نبی ہرگز نہیں آ سکتا۔',
      reference: 'Surah Al-Ahzab (33:40)',
      referenceUr: 'سورۃ الاحزاب (۳۳:۴۰)',
    ),
    AqaidItem(
      id: 'r2',
      categoryId: 'risalat',
      title: 'The Intercession (Shafa\'at) of the Holy Prophet (ﷺ)',
      titleUr: 'مقامِ شفاعتِ عظمیٰ اور رحمتِ عالميانﷺ',
      arabicText: 'وَمَا أَرْسَلْنَاكَ إِلَّا رَحْمَةً لِّلْعَالَمِينَ',
      explanation: 'Allah has granted Prophet Muhammad (ﷺ) the Station of Praise (Maqam-e-Mahmood) and supreme power of intercession (Shafa\'at-e-Kubra) for sinners on the Day of Judgment.',
      explanationUr: 'اللہ تعالیٰ نے سرکارِ دو عالم (صلی اللہ علیہ وسلم) کو مقامِ محمود اور قیامت کے دن گنہگاروں کی شفاعتِ عظمیٰ کا عظیم مقام عطا فرمایا ہے۔ آپ تمام جہانوں کے لیے رحمت ہیں۔',
      reference: 'Surah Al-Anbiya (21:107) & Sahih Muslim',
      referenceUr: 'سورۃ الانبیاء (۲۱:۱۰۷) و صحیح مسلم',
    ),
    AqaidItem(
      id: 'r3',
      categoryId: 'risalat',
      title: 'The Divine Light (Noor) & Human Excellence of the Prophet (ﷺ)',
      titleUr: 'نورِ محمدی (ﷺ) اور بشریتِ مطہرہ کا عقیدہ',
      arabicText: 'قَدْ جَاءَكُم مِّنَ اللَّهِ نُورٌ وَكِتَابٌ مُّبِينٌ',
      explanation: 'The Prophet (ﷺ) possesses both luminous spiritual reality (Noor) and perfect holy physical creation (Bashar-e-Athar). He is the supreme creation of Allah.',
      explanationUr: 'بے شک تمہارے پاس اللہ کی طرف سے ایک عظیم نور (رسول اکرم ﷺ) اور روشن کتاب آئی ہے۔ آپ نورانیت اور مطہر بشریت دونوں کا جامع ہیں۔',
      reference: 'Surah Al-Ma\'idah (5:15)',
      referenceUr: 'سورۃ المائدة (۵:۱۵)',
    ),

    // ── SAHABA O AHLEBAIT AQAID ────────────────────────────────────
    AqaidItem(
      id: 's1',
      categoryId: 'sahaba_ahlebait',
      title: 'Veneration of Sahaba & Blessed Family (Ahl al-Bayt)',
      titleUr: 'عظمت و محبتِ صحابہ کرام و اہل بیت اطہار',
      arabicText: 'قُل لَّا أَسْأَلُكُمْ عَلَيْهِ أَجْرًا إِلَّا الْمَوَدَّةَ فِي الْقُرْبَىٰ',
      explanation: 'Reverence for the Blessed Household (Ahl al-Bayt) and all Noble Companions (Sahaba) of the Holy Prophet (ﷺ) is an imperative requirement of true faith in Ahle Sunnat creed.',
      explanationUr: 'سرکارِ دو عالم (صلی اللہ علیہ وسلم) کی پاک آل (اہل بیت) اور تمام صحابہ کرام (رضی اللہ عنہم) کی محبت و تعظیم جزوِ ایمان ہے اور ہدایت کا راستہ ہے۔',
      reference: 'Surah Ash-Shura (42:23)',
      referenceUr: 'سورۃ الشوریٰ (۴۲:۲۳)',
    ),
    AqaidItem(
      id: 's2',
      categoryId: 'sahaba_ahlebait',
      title: 'The Caliphate of Khulafa-e-Rashideen',
      titleUr: 'عقیدہ خلافتِ راشدہ اور چاروں خلفاء کی فضیلت',
      arabicText: 'وَالسَّابِقُونَ الْأَوَّلُونَ مِنَ الْمُهَاجِرِينَ وَالْأَنصَارِ وَالَّذِينَ اتَّبَعُوهُم بِإِحْسَانٍ رَّضِيَ اللَّهُ عَنْهُمْ وَرَضُوا عَنْهُ',
      explanation: 'The rightful succession of the Khulafa-e-Rashideen (Abu Bakr, Umar, Uthman, Ali - may Allah be pleased with them) is in order of their spiritual excellence.',
      explanationUr: 'خلفائے راشدین (سیدنا ابو بکر، عمر، عثمان، علی رضی اللہ عنہم) کی خلافت برحق ہے اور ان کی فضیلت اسی ترتیب سے ہے۔',
      reference: 'Surah At-Tawbah (9:100)',
      referenceUr: 'سورۃ التوبہ (۹:۱۰۰)',
    ),

    // ── ISHQ-E-RASOOL AQAID ────────────────────────────────────────
    AqaidItem(
      id: 'i1',
      categoryId: 'ishq_rasool',
      title: 'Love of the Holy Prophet (ﷺ) Above All Creation',
      titleUr: 'مقامِ عشقِ رسول (صلی اللہ علیہ وسلم)',
      arabicText: 'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى أَكُونَ أَحَبَّ إِلَيْهِ مِنْ وَالِدِهِ وَوَلَدِهِ وَالنَّاسِ أَجْمَعِينَ',
      explanation: 'None of you truly believes until I become more beloved to him than his father, his children, and all mankind combined.',
      explanationUr: 'تم میں سے کوئی شخص اس وقت تک کامل مومن نہیں ہو سکتا جب تک کہ میں اس کے نزدیک اس کے والد، اس کی اولاد اور تمام انسانوں سے زیادہ محبوب نہ ہو جاؤں۔',
      reference: 'Sahih Bukhari & Sahih Muslim',
      referenceUr: 'صحیح البخاری و صحیح مسلم',
    ),
    AqaidItem(
      id: 'i2',
      categoryId: 'ishq_rasool',
      title: 'Sending Durood & Salam Upon the Blessed Prophet (ﷺ)',
      titleUr: 'درود و سلام بھیجنے کی فرضیت و فضیلت',
      arabicText: 'إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ۚ يَا أَيُّهَا الَّذِينَ آمَنُوا صَلُّوا عَلَيْهِ وَسَلِّمُوا تَسْلِيمًا',
      explanation: 'Sending Durood and Salam upon the Prophet (ﷺ) is a Divine command that brings immense spiritual elevation and forgiveness of sins.',
      explanationUr: 'بے شک اللہ اور اس کے فرشتے نبی پر درود بھیجتے ہیں۔ اے ایمان والو! تم بھی ان پر درود اور سلام بھیجو۔',
      reference: 'Surah Al-Ahzab (33:56)',
      referenceUr: 'سورۃ الاحزاب (۳۳:۵۶)',
    ),

    // ── WILAYAT AQAID ──────────────────────────────────────────────
    AqaidItem(
      id: 'w1',
      categoryId: 'wilayat',
      title: 'The Reality of Wilayat and Awliya-Allah',
      titleUr: 'مقامِ ولایت و کرامتِ اولیاء اللہ',
      arabicText: 'أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ',
      explanation: 'Unquestionably, for the allies and close friends of Allah (Awliya), there will be no fear concerning them, nor will they grieve.',
      explanationUr: 'خبردار! بے شک اللہ کے ولیوں پر نہ کوئی خوف ہے اور نہ وہ غمگین ہوں گے۔',
      reference: 'Surah Yunus (10:62)',
      referenceUr: 'سورۃ یونس (۱۰:۶۲)',
    ),
    AqaidItem(
      id: 'w2',
      categoryId: 'wilayat',
      title: 'Miracles of Saints (Karamat-e-Awliya)',
      titleUr: 'کرامتِ اولیاء کا شرعی ثبوت',
      arabicText: 'كُلَّمَا دَخَلَ عَلَيْهَا مِحْرَابَ زَكَرِيَّا وَجَدَ عِندَهَا رِزْقًا',
      explanation: 'Extraordinary miraculous deeds (Karamat) manifested at the hands of righteous pious Awliya are true and proven by Quran and Sunnah.',
      explanationUr: 'اولیاءِ کرام کے ہاتھوں سے ظاہر ہونے والی خلافِ عادت کرامات برحق ہیں اور قرآن و سنت سے ثابت ہیں۔',
      reference: 'Surah Aal-e-Imran (3:37)',
      referenceUr: 'سورۃ آل عمران (۳:۳۷)',
    ),
  ];
}
