import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/aqaid_model.dart';
import '../../../main.dart';
import '../../../services/content_service.dart';
import 'aqaid_detail_screen.dart';

/// Main Islamic Aqaid Screen displaying isolated 2-Column Category Grid.
class AqaidGridScreen extends StatefulWidget {
  const AqaidGridScreen({super.key});

  @override
  State<AqaidGridScreen> createState() => _AqaidGridScreenState();
}

class _AqaidGridScreenState extends State<AqaidGridScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static final List<Map<String, String>> _categories = [
    {
      'id': 'tawheed',
      'en': 'Tawheed',
      'ur': 'عقیدہ توحید',
      'image': 'assets/images/tauheed.png',
      'desc_ur': 'اللہ تعالیٰ کی یکتائی، ذات اور صفات کا بیان',
      'desc_en': 'Oneness and Divine Attributes of Allah',
    },
    {
      'id': 'risalat',
      'en': 'Risalat & Khatm-e-Nabuwwat',
      'ur': 'عقیدہ رسالت و ختم نبوت',
      'image': 'assets/images/risalat.png',
      'desc_ur': 'شانِ رسالت اور عقیدہ ختمِ نبوت کی اہمیت',
      'desc_en': 'Prophethood and Finality of Prophet Muhammad (ﷺ)',
    },
    {
      'id': 'ishq_rasool',
      'en': 'Ishq-e-Rasool ﷺ',
      'ur': 'عشقِ رسول ﷺ',
      'image': 'assets/images/ishq_rasool.png',
      'desc_ur': 'محبت و تعظیمِ مصطفیٰ ﷺ اصلِ ایمان ہے',
      'desc_en': 'Love for the Holy Prophet is the core of Faith',
    },
    {
      'id': 'sahaba_ahlebait',
      'en': 'Sahaba & Ahl-e-Bait',
      'ur': 'صحابہ و اہلِ بیت',
      'image': 'assets/images/sahaba.png',
      'desc_ur': 'صحابہ کرام اور اہلِ بیتِ اطہار کی محبت و تعظیم',
      'desc_en': 'Reverence for Companions and Holy Household',
    },
    {
      'id': 'wilayat',
      'en': 'Wilayat & Awliya',
      'ur': 'مقامِ ولایت و اولیاء',
      'image': 'assets/images/wilayat.png',
      'desc_ur': 'اولیاء اللہ کا بلند مقام، فیض اور کرامات کا ثبوت',
      'desc_en': 'Status and miracles of the Righteous Friends of Allah',
    },
    {
      'id': 'quran',
      'en': 'The Holy Quran',
      'ur': 'قرآنِ پاک',
      'image': 'assets/images/tauheed.png',
      'desc_ur': 'کلامِ الٰہی کا اعجاز، صداقت اور عظمت',
      'desc_en': 'The Divine Miracle and Truth of the Holy Quran',
    },
    {
      'id': 'ahle_sunnat',
      'en': 'Ahle Sunnat wal Jama\'at',
      'ur': 'اہلِ سنت والجماعت',
      'image': 'assets/images/sahaba.png',
      'desc_ur': 'سوادہ اعظم، جمہور صحابہ اور صحیح اسلامی عقائد',
      'desc_en': 'The Main Body of Authentic Islamic Creed',
    },
  ];

  static const List<AqaidItemModel> _fallbackAqaid = [
    AqaidItemModel(
      id: 'aq_1',
      categoryId: 'tawheed',
      title: 'Tawheed: Absolute Oneness of Allah',
      titleUr: 'توحید: اللہ تعالیٰ کی یکتائی اور صفات',
      arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      explanation:
          'Allah Almighty is One in His Being, Attributes, and Actions. He has no partner, equal, or associate. He alone is Eternal, without beginning or end, and all creation is dependent upon Him.',
      explanationUr:
          'اللہ تعالیٰ اپنی ذات، صفات اور افعال میں یکتا و بے مثال ہے۔ اس کا کوئی شریک یا ہمسر نہیں۔ وہ ازلی و ابدی ہے اور تمام کائنات اس کی محتاج ہے۔',
      book: 'Surah Al-Ikhlas (112:1-4)',
      bookUr: 'سورۃ الاخلاص (۱-۴)',
    ),
    AqaidItemModel(
      id: 'aq_2',
      categoryId: 'risalat',
      title: 'Finality of Prophethood (Khatam-an-Nabiyyin)',
      titleUr: 'عقیدہ ختمِ نبوت (خاتم النبیین)',
      arabicText:
          'مَّا كَانَ مُحَمَّدٌ أَبَا أَحَدٍ مِّن رِّجَالِكُمْ وَلَٰكِن رَّسُولَ اللَّهِ وَخَاتَمَ النَّبِيِّينَ',
      explanation:
          'Prophet Muhammad (ﷺ) is the final and ultimate Messenger of Allah. No new prophet will ever come after him until the Day of Judgment. Believing in the finality of his Prophethood is an essential article of Islamic faith.',
      explanationUr:
          'سیدنا محمد رسول اللہ صلی اللہ علیہ وآلہ وسلم اللہ کے آخری نبی ہیں۔ آپ کے بعد قیامت تک کوئی نیا نبی نہیں آ سکتا۔ ختمِ نبوت پر ایمان لانا ہر مسلمان پر فرضِ عین ہے۔',
      book: 'Surah Al-Ahzab (33:40)',
      bookUr: 'سورۃ الاحزاب (۴۰)',
    ),
    AqaidItemModel(
      id: 'aq_3',
      categoryId: 'ahle_sunnat',
      title: 'Love and Reverence for the Noble Ahl al-Bayt and Sahaba',
      titleUr: 'اہل ِ بیتِ اطہار اور صحابہ کرام سے محبت',
      arabicText: 'أَصْحَابِي كَالنُّجُومِ بِأَيِّهِمُ اقْتَدَيْتُمُ اهْتَدَيْتُمْ',
      explanation:
          'The authentic creed of Ahle Sunnat requires profound love and reverence for the pure Ahl al-Bayt (family of the Prophet) and all the noble Sahaba (Companions). Slandering or disrespecting any Companion is strictly prohibited.',
      explanationUr:
          'اہل ِ سنت والجماعت کا عقیدہ ہے کہ تمام صحابہ کرام عادل و باوقار ہیں اور اہلِ بیتِ اطہار سے محبت ایمان کا حصہ ہے۔ کسی بھی صحابی کی تنقیص گمراہی ہے۔',
      book: 'Sharh Al-Aqaid Al-Nasafiyya',
      bookUr: 'شرح العقائد النسفیہ',
    ),
    AqaidItemModel(
      id: 'aq_4',
      categoryId: 'quran',
      title: 'The Holy Quran: Eternal Word of Allah',
      titleUr: 'قرآنِ مجید: اللہ تعالیٰ کا کلامِ غیر مخلوق',
      arabicText: 'وَإِنَّهُ لَتَنزِيلُ رَبِّ الْعَالَمِينَ',
      explanation:
          'The Holy Quran is the literal, eternal, and uncreated Word of Allah (Kalamullah), revealed to the Prophet Muhammad (ﷺ) through Archangel Jibril (AS). It is fully preserved, unaltered, and protected from any addition or omission for all times.',
      explanationUr:
          'قرآنِ مجید اللہ تبارک و تعالیٰ کا کلامِ پاک ہے جو غیر مخلوق اور ازلی ہے۔ یہ سیدنا محمد مصطفیٰ صلی اللہ علیہ وآلہ وسلم پر بذریعہ حضرت جبرائیل علیہ السلام نازل ہوا۔ اس کا ایک ایک حرف قیامت تک ہر قسم کے تغیر و تبدل سے محفوظ ہے۔',
      book: 'Surah Ash-Shu\'ara (26:192) & Surah Al-Hijr (15:9)',
      bookUr: 'سورۃ الشعراء (۱۹۲) اور سورۃ الحجر (۹)',
    ),
    AqaidItemModel(
      id: 'aq_5',
      categoryId: 'quran',
      title: 'Inimitability & Miraculous Nature of the Quran',
      titleUr: 'قرآنِ مجید کا اعجاز اور صداقت',
      arabicText:
          'قُل لَّئِنِ اجْتَمَعَتِ الإِنسُ وَالْجِنُّ عَلَى أَن يَأْتُواْ بِمِثْلِ هَـذَا الْقُرْآنِ لاَ يَأْتُونَ بِمِثْلِهِ',
      explanation:
          'The Quran is a living, everlasting miracle. Neither mankind nor the jinn can produce even a single chapter comparable to its profound wisdom, eloquence, and divine perfection.',
      explanationUr:
          'قرآنِ کریم ایک زندہ و پائندہ معجزہ ہے۔ جن و انس مل کر بھی اس جیسی ایک چھوٹی سے چھوٹی سورت پیش کرنے سے عاجز ہیں۔ اس کا اعجاز اور بلاغت ابدی ہے۔',
      book: 'Surah Al-Isra (17:88)',
      bookUr: 'سورۃ الاسراء (۸۸)',
    ),
    AqaidItemModel(
      id: 'aq_6',
      categoryId: 'sahaba_ahlebait',
      title: 'Status of the Noble Sahaba & Blessed Ahl al-Bayt',
      titleUr: 'صحابہ کرام اور اہلِ بیتِ اطہار کا بلند مقام',
      arabicText:
          'إِنَّمَا يُرِيدُ اللَّهُ لِيُذْهِبَ عَنكُمُ الرِّجْسَ أَهْلَ الْبَيْتِ وَيُطَهِّرَكُمْ تَطْهِيرًا',
      explanation:
          'Love for the pure Ahl al-Bayt and the honourable Sahaba (Companions) is an integral part of faith in Ahle Sunnat wal Jama\'at. Respecting and honoring all of them is an obligation upon every Muslim.',
      explanationUr:
          'اہلِ سنت کا متفقہ عقیدہ ہے کہ تمام صحابہ کرام عادل ہیں اور اہلِ بیتِ اطہار کی محبت جزوِ ایمان ہے۔ ان کی تکریم و تعظیم ہر مسلمان پر لازم ہے۔',
      book: 'Surah Al-Ahzab (33:33)',
      bookUr: 'سورۃ الاحزاب (۳۳)',
    ),
    AqaidItemModel(
      id: 'aq_7',
      categoryId: 'ishq_rasool',
      title: 'Love for the Prophet (ﷺ) is the Core of Faith',
      titleUr: 'عشقِ مصطفیٰ صلی اللہ علیہ وآلہ وسلم: اصلِ ایمان',
      arabicText:
          'لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى أَكُونَ أَحَبَّ إِلَيْهِ مِنْ وَالِدِهِ وَوَلَدِهِ وَالنَّاسِ أَجْمَعِينَ',
      explanation:
          'True Iman is achieved only when the Messenger of Allah (ﷺ) is more beloved to the believer than their parents, children, wealth, and all humanity combined.',
      explanationUr:
          'حضور نبی اکرم صلی اللہ علیہ وآلہ وسلم کی ذاتِ اقدس سے سچی محبت اور والہانہ عشق ہر مسلمان پر اپنی جان، اولاد اور تمام کائنات سے بڑھ کر فرض ہے، یہی ایمان کی روح ہے۔',
      book: 'Sahih al-Bukhari (15)',
      bookUr: 'صحیح البخاری (۱۵)',
    ),
    AqaidItemModel(
      id: 'aq_8',
      categoryId: 'wilayat',
      title: 'Status & Miracles of Awliya Allah (Friends of Allah)',
      titleUr: 'مقامِ ولایت اور اولیاء اللہ کی کرامات کا برحق ہونا',
      arabicText: 'أَلَا إِنَّ أَوْلِيَاءَ اللَّهِ لَا خَوْفٌ عَلَيْهِمْ وَلَا هُمْ يَحْزَنُونَ',
      explanation:
          'The Awliya (righteous saints and friends of Allah) are bestowed with divine closeness, and their karamat (miracles granted by Allah) are authentic and recognized by the creed of Ahle Sunnat.',
      explanationUr:
          'اولیاء اللہ کا وجود، ان کا فیض اور ان کی کرامات برحق ہیں۔ وہ اللہ کے برگزیدہ بندے ہیں جن پر کوئی خوف اور غم نہیں ہوتا۔ ان کا احترام و محبت باعثِ برکت ہے۔',
      book: 'Surah Yunus (10:62)',
      bookUr: 'سورۃ یونس (۶۲)',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getTopicCountForCategory(String categoryId, List<AqaidItemModel> allEntries) {
    return allEntries.where((item) => item.categoryId.toLowerCase() == categoryId.toLowerCase()).length;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: AppColors.primaryEmerald,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
            title: Text(
              isUrdu ? 'اسلامی عقائد' : 'Islamic Aqaid (Creed)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            actions: [
              GestureDetector(
                onTap: () => lp.toggleLanguage(),
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isUrdu ? 'EN' : 'اردو',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: StreamBuilder<List<AqaidItemModel>>(
            stream: ContentService.aqaidStream,
            builder: (context, snapshot) {
              final rawEntries = snapshot.data ?? [];
              final allEntries = rawEntries.isNotEmpty ? rawEntries : _fallbackAqaid;

              final query = _searchQuery.trim().toLowerCase();
              final filteredCategories = _categories.where((cat) {
                if (query.isEmpty) return true;
                final en = cat['en']!.toLowerCase();
                final ur = cat['ur']!.toLowerCase();
                final descEn = (cat['desc_en'] ?? '').toLowerCase();
                final descUr = (cat['desc_ur'] ?? '').toLowerCase();
                return en.contains(query) || ur.contains(query) || descEn.contains(query) || descUr.contains(query);
              }).toList();

              return Column(
                children: [
                  // 1. Search Bar Header
                  Container(
                    color: AppColors.primaryEmerald,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        decoration: InputDecoration(
                          hintText: isUrdu
                              ? 'عقائد کے موضوعات تلاش کریں...'
                              : 'Search Aqaid topics...',
                          hintTextDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryEmerald, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                  ),

                  // 2. Full-Page Scrollable 2-Column Grid View
                  Expanded(
                    child: filteredCategories.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(
                                    isUrdu ? 'کوئی کیٹیگری نہیں ملی' : 'No categories found',
                                    style: AppTypography.headingMedium.copyWith(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.90,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final cat = filteredCategories[index];
                              final count = _getTopicCountForCategory(cat['id']!, allEntries);

                              return _buildCategoryGridCard(
                                key: ValueKey('aqaid_category_${cat['id']}'),
                                category: cat,
                                topicCount: count,
                                isUrdu: isUrdu,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AqaidCategoryDetailScreen(
                                        category: cat,
                                        allEntries: allEntries,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryGridCard({
    Key? key,
    required Map<String, String> category,
    required int topicCount,
    required bool isUrdu,
    required VoidCallback onTap,
  }) {
    final title = isUrdu ? category['ur']! : category['en']!;
    final imagePath = category['image']!;
    final countLabel = isUrdu ? '$topicCount موضوعات' : '$topicCount Topics';

    return Container(
      key: key,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Base Asset Image with graceful gradient fallback
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0F5132), Color(0xFF1E3A2B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.menu_book_rounded, color: Colors.white70, size: 36),
                      ),
                    );
                  },
                ),

                // 2. Dark Gradient Overlay for text contrast
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.25, 0.6, 1.0],
                    ),
                  ),
                ),

                // 3. Top Status / Topic Count Badge
                Positioned(
                  top: 10,
                  right: isUrdu ? null : 10,
                  left: isUrdu ? 10 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      countLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // 4. Bottom Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: isUrdu ? 'UrduFont' : null,
                          height: 1.25,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dedicated Screen displaying the specific articles/beliefs belonging ONLY to the selected category.
class AqaidCategoryDetailScreen extends StatelessWidget {
  final Map<String, String> category;
  final List<AqaidItemModel> allEntries;

  const AqaidCategoryDetailScreen({
    super.key,
    required this.category,
    required this.allEntries,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;

        final catId = category['id']!;
        final catTitle = isUrdu ? category['ur']! : category['en']!;
        final catDesc = isUrdu ? (category['desc_ur'] ?? '') : (category['desc_en'] ?? '');
        final imagePath = category['image']!;

        final categoryItems = allEntries
            .where((item) => item.categoryId.toLowerCase() == catId.toLowerCase())
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: AppColors.primaryEmerald,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
            title: Text(
              catTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            actions: [
              GestureDetector(
                onTap: () => lp.toggleLanguage(),
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isUrdu ? 'EN' : 'اردو',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: categoryItems.isEmpty
              ? _buildEmptyState(context, isUrdu)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                  itemCount: categoryItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Category Hero Header Card
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        constraints: const BoxConstraints(minHeight: 140),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: AppColors.primaryEmerald),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.45),
                                        Colors.black.withValues(alpha: 0.92),
                                      ],
                                      stops: const [0.15, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      catTitle,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: isUrdu ? 'UrduFont' : null,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (catDesc.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        catDesc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final item = categoryItems[index - 1];
                    return _AqaidItemCard(
                      item: item,
                      isUrdu: isUrdu,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AqaidDetailScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isUrdu) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.emeraldContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                size: 40,
                color: AppColors.primaryEmerald,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isUrdu ? 'اس کیٹیگری میں فی الحال کوئی عقیدہ دستیاب نہیں ہے' : 'No topics available in this category yet',
              textAlign: TextAlign.center,
              style: AppTypography.headingMedium.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              isUrdu ? 'نیا مستند مواد جلد شامل کیا جائے گا۔ ان شاء اللہ' : 'New verified content will be added soon. Insha\'Allah.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(isUrdu ? 'واپس جائیں' : 'Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── One Card For Each Aqeeda Article ───────────────────────────────

class _AqaidItemCard extends StatelessWidget {
  final AqaidItemModel item;
  final bool isUrdu;
  final VoidCallback onTap;

  const _AqaidItemCard({
    required this.item,
    required this.isUrdu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.getTitle(isUrdu);
    final explanation = item.getExplanation(isUrdu);
    final book = item.getBook(isUrdu);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primaryEmerald.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryEmerald.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Forward chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: isUrdu ? 'UrduFont' : null,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Arabic Text snippet (if available)
                if (item.arabicText.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F9F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.emeraldContainer),
                    ),
                    child: Text(
                      item.arabicText,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryEmerald,
                        height: 1.6,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Brief Explanation Snippet
                Text(
                  explanation,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Book / Source Reference Footer
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.primaryEmerald),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        book,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryEmerald,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      isUrdu ? 'مکمل پڑھیں ←' : 'Read Full →',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
