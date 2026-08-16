import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/aqaid_model.dart';
import '../../../main.dart';
import '../../../services/content_service.dart';
import 'aqaid_detail_screen.dart';

/// Screen displaying individual cards for each Aqeeda with category filters and search.
class AqaidGridScreen extends StatefulWidget {
  const AqaidGridScreen({super.key});

  @override
  State<AqaidGridScreen> createState() => _AqaidGridScreenState();
}

class _AqaidGridScreenState extends State<AqaidGridScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categoryFilters = [
    {'id': 'all', 'en': 'All Topics', 'ur': 'تمام موضوعات'},
    {'id': 'tawheed', 'en': 'Tawheed', 'ur': 'توحید'},
    {'id': 'risalat', 'en': 'Risalat', 'ur': 'رسالت'},
    {'id': 'ahle_sunnat', 'en': 'Ahle Sunnat', 'ur': 'اہلِ سنت'},
    {'id': 'quran', 'en': 'Quran', 'ur': 'قرآن پاک'},
    {'id': 'sahaba_ahlebait', 'en': 'Sahaba o Ahlebait', 'ur': 'صحابہ و اہل بیت'},
    {'id': 'ishq_rasool', 'en': 'Ishq-e-Rasool', 'ur': 'عشقِ رسول'},
    {'id': 'wilayat', 'en': 'Wilayat', 'ur': 'ولایت'},
  ];

  static const List<AqaidItemModel> _fallbackAqaid = [
    AqaidItemModel(
      id: 'aq_1',
      categoryId: 'tawheed',
      title: 'Tawheed: Absolute Oneness of Allah',
      titleUr: 'توحید: اللہ تعالیٰ کی یکتائی اور صفات',
      arabicText: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
      explanation: 'Allah Almighty is One in His Being, Attributes, and Actions. He has no partner, equal, or associate. He alone is Eternal, without beginning or end, and all creation is dependent upon Him.',
      explanationUr: 'اللہ تعالیٰ اپنی ذات، صفات اور افعال میں یکتا و بے مثال ہے۔ اس کا کوئی شریک یا ہمسر نہیں۔ وہ ازلی و ابدی ہے اور تمام کائنات اس کی محتاج ہے۔',
      book: 'Surah Al-Ikhlas (112:1-4)',
      bookUr: 'سورۃ الاخلاص (۱-۴)',
    ),
    AqaidItemModel(
      id: 'aq_2',
      categoryId: 'risalat',
      title: 'Finality of Prophethood (Khatam-an-Nabiyyin)',
      titleUr: 'عقیدہ ختمِ نبوت (خاتم النبیین)',
      arabicText: 'مَّا كَانَ مُحَمَّدٌ أَبَا أَحَدٍ مِّن رِّجَالِكُمْ وَلَٰكِن رَّسُولَ اللَّهِ وَخَاتَمَ النَّبِيِّينَ',
      explanation: 'Prophet Muhammad (ﷺ) is the final and ultimate Messenger of Allah. No new prophet will ever come after him until the Day of Judgment. Believing in the finality of his Prophethood is an essential article of Islamic faith.',
      explanationUr: 'سیدنا محمد رسول اللہ صلی اللہ علیہ وآلہ وسلم اللہ کے آخری نبی ہیں۔ آپ کے بعد قیامت تک کوئی نیا نبی نہیں آ سکتا۔ ختمِ نبوت پر ایمان لانا ہر مسلمان پر فرضِ عین ہے۔',
      book: 'Surah Al-Ahzab (33:40)',
      bookUr: 'سورۃ الاحزاب (۴۰)',
    ),
    AqaidItemModel(
      id: 'aq_3',
      categoryId: 'ahle_sunnat',
      title: 'Love and Reverence for the Noble Ahl al-Bayt and Sahaba',
      titleUr: 'اہل ِ بیتِ اطہار اور صحابہ کرام سے محبت',
      arabicText: 'أَصْحَابِي كَالنُّجُومِ بِأَيِّهِمُ اقْتَدَيْتُمُ اهْتَدَيْتُمْ',
      explanation: 'The authentic creed of Ahle Sunnat requires profound love and reverence for the pure Ahl al-Bayt (family of the Prophet) and all the noble Sahaba (Companions). Slandering or disrespecting any Companion is strictly prohibited.',
      explanationUr: 'اہل ِ سنت والجماعت کا عقیدہ ہے کہ تمام صحابہ کرام عادل و باوقار ہیں اور اہلِ بیتِ اطہار سے محبت ایمان کا حصہ ہے۔ کسی بھی صحابی کی تنقیص گمراہی ہے۔',
      book: 'Sharh Al-Aqaid Al-Nasafiyya',
      bookUr: 'شرح العقائد النسفیہ',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              final filteredAqaid = allEntries.where((item) {
                final matchesCat = _selectedCategory == 'all' ||
                    item.categoryId.toLowerCase() == _selectedCategory.toLowerCase();

                final titleEn = item.title.toLowerCase();
                final titleUr = item.titleUr.toLowerCase();
                final explEn = item.explanation.toLowerCase();
                final explUr = item.explanationUr.toLowerCase();

                final matchesQuery = query.isEmpty ||
                    titleEn.contains(query) ||
                    titleUr.contains(query) ||
                    explEn.contains(query) ||
                    explUr.contains(query);

                return matchesCat && matchesQuery;
              }).toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: isUrdu
                              ? 'عقائد و موضوعات میں تلاش کریں...'
                              : 'Search Islamic beliefs & topics...',
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
                    const SizedBox(height: 14),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _categoryFilters.map((cat) {
                          final isSelected = _selectedCategory == cat['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              selectedColor: AppColors.primaryEmerald,
                              backgroundColor: AppColors.bgOffWhite,
                              label: Text(
                                isUrdu ? cat['ur']! : cat['en']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? cat['id']! : 'all';
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Count Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isUrdu
                              ? '${filteredAqaid.length} عقائد دستیاب ہیں'
                              : 'Showing ${filteredAqaid.length} Belief${filteredAqaid.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Individual Aqeeda Cards ──
                    if (filteredAqaid.isEmpty)
                      _buildEmptyState(isUrdu)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredAqaid.length,
                        itemBuilder: (context, index) {
                          final aqaidItem = filteredAqaid[index];
                          return _AqaidItemCard(
                            item: aqaidItem,
                            isUrdu: isUrdu,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AqaidDetailScreen(item: aqaidItem),
                                ),
                              );
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // ── Did You Know? Informative Banner ──
                    const _DidYouKnowBanner(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isUrdu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.emeraldContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, size: 36, color: AppColors.primaryEmerald),
          ),
          const SizedBox(height: 16),
          Text(
            isUrdu ? 'کوئی عقیدہ نہیں ملا' : 'No Aqaid Found',
            style: AppTypography.headingMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            isUrdu
                ? 'براہ کرم سرچ کیورڈ تبدیل کریں یا تمام موضوعات منتخب کریں۔'
                : 'Try adjusting your search query or selecting another category.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'all';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryEmerald),
            label: Text(
              isUrdu ? 'فلٹرز ختم کریں' : 'Reset Filters',
              style: const TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── One Card For Each Aqeeda ───────────────────────────────────────

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
    final categoryTitle = _getCategoryTitle(item.categoryId, isUrdu);

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
                // Top Category & Icon Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, size: 12, color: AppColors.primaryEmerald),
                          const SizedBox(width: 5),
                          Text(
                            categoryTitle.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryEmerald,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
                const SizedBox(height: 12),

                // Aqeeda Title
                Text(
                  title,
                  style: AppTypography.headingMedium.copyWith(
                    fontSize: 16,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),

                // Arabic Text Excerpt preview (if present)
                if (item.arabicText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      item.arabicText,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.arabicText.copyWith(fontSize: 16, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],

                // Brief Explanation Excerpt
                const SizedBox(height: 10),
                Text(
                  explanation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.borderLight),
                const SizedBox(height: 12),

                // Card Footer with Reference and Clear Interactive Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (book.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.accentGold),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                book,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),

                    // Clear interactive CTA
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isUrdu ? 'مکمل تفصیل پڑھیں' : 'Read Full Content',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryEmerald,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isUrdu ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppColors.primaryEmerald,
                          ),
                        ],
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

  String _getCategoryTitle(String categoryId, bool isUrdu) {
    final cat = AqaidCategory.defaultCategories.firstWhere(
      (c) => c.id.toLowerCase() == categoryId.toLowerCase(),
      orElse: () => AqaidCategory(
        id: categoryId,
        title: categoryId.toUpperCase(),
        titleUr: categoryId,
        arabicTitle: '',
        subtitle: '',
        icon: Icons.auto_awesome,
      ),
    );
    return isUrdu && cat.titleUr.isNotEmpty ? cat.titleUr : cat.title;
  }
}

// ── Did You Know Banner ────────────────────────────────────────────

class _DidYouKnowBanner extends StatelessWidget {
  const _DidYouKnowBanner();

  @override
  Widget build(BuildContext context) {
    final isUrdu = globalLanguageProvider.isUrdu;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), AppColors.primaryEmerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryEmerald.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.goldBright, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'کیا آپ جانتے ہیں؟' : 'Did You Know?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUrdu
                      ? 'صحیح اسلامی عقائد کا جاننا اور ان پر ثابت قدم رہنا ہر مسلمان کی نجات اور ایمان کی بنیاد ہے۔'
                      : 'Understanding and adhering to the authentic creed of Ahle Sunnat Wal Jama\'at is the foundation of faith and salvation.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
