import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/masail_model.dart';
import '../../../main.dart';
import '../../../services/content_service.dart';
import 'ask_question_sheet.dart';
import 'my_questions_screen.dart';

class MasailGridScreen extends StatefulWidget {
  const MasailGridScreen({super.key});

  @override
  State<MasailGridScreen> createState() => _MasailGridScreenState();
}

class _MasailGridScreenState extends State<MasailGridScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth >= 1024 ? 4 : (screenWidth >= 600 ? 3 : 2);

        final categories = ContentService.getCategories();
        final filteredCategories = categories.where((cat) {
          final title = cat.title.toLowerCase();
          final titleUr = cat.titleUr.toLowerCase();
          final arabic = cat.arabicTitle.toLowerCase();
          final q = _searchQuery.trim().toLowerCase();
          if (q.isEmpty) return true;
          return title.contains(q) || titleUr.contains(q) || arabic.contains(q);
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: AppColors.primaryEmerald,
            elevation: 0,
            title: Text(
              lp.isUrdu ? 'مسائل و فتاویٰ' : 'Masail (Fiqh)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.forum_outlined, color: Colors.white),
                tooltip: lp.isUrdu ? 'میرے سوالات' : 'My Questions',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyQuestionsScreen()),
                  );
                },
              ),
              GestureDetector(
                onTap: () => lp.toggleLanguage(),
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    lp.isUrdu ? 'EN' : 'اردو',
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
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primaryEmerald,
            foregroundColor: Colors.white,
            onPressed: () => AskQuestionSheet.show(context),
            icon: const Icon(Icons.add_comment_rounded),
            label: Text(lp.isUrdu ? 'سوال پوچھیں' : 'Ask Question'),
          ),
          body: StreamBuilder<List<MasailItemModel>>(
            stream: ContentService.masailStream,
            builder: (context, snapshot) {
              final allEntries = snapshot.data ?? [];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ask a Question Quick Action Banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), AppColors.primaryEmerald],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.live_help_rounded,
                              color: AppColors.goldBright,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lp.isUrdu ? 'کوئی شرعی مسئلہ درپیش ہے؟' : 'Have an Islamic Question?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  lp.isUrdu
                                      ? 'مفتی / ایڈمن سے پوچھیں، 24 گھنٹے میں جواب حاصل کریں۔'
                                      : 'Ask admin team & get a verified reply within 24h.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldBright,
                              foregroundColor: AppColors.emeraldDeep,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => AskQuestionSheet.show(context),
                            child: Text(
                              lp.isUrdu ? 'پوچھیں' : 'Ask Now',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating Search Container
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
                          hintText: lp.isUrdu
                              ? 'نماز، وضو، زکوۃ کے مسائل تلاش کریں...'
                              : 'Search namaz, zakat, nikah rules...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Categories Grid ──
                    if (filteredCategories.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Text(
                          lp.tr('no_masail_found'),
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCategories.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final localizedTitle = lp.isUrdu ? cat.titleUr : cat.title;
                          final itemCount = ContentService.getMasailByCategory(allEntries, cat.id).length;
                          return _CategoryCard(
                            cat: cat,
                            displayTitle: localizedTitle,
                            itemCount: itemCount,
                            onTap: () => _openMasailList(context, cat, localizedTitle),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // ── Hadith of Wisdom Banner ──
                    const _HadithWisdomBanner(),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openMasailList(
      BuildContext context, MasailCategory category, String localizedTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _MasailListScreen(category: category, localizedTitle: localizedTitle),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final MasailCategory cat;
  final String displayTitle;
  final int itemCount;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.cat,
    required this.displayTitle,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isGoldAccent = cat.badge != null;
    final accentColor = isGoldAccent ? const Color(0xFFEAB308) : const Color(0xFF0D9488);
    final isUrdu = globalLanguageProvider.isUrdu;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                // Top Accent Line
                Container(
                  height: 4,
                  width: double.infinity,
                  color: accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Emblem
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat.icon, color: const Color(0xFF059669), size: 20),
                        ),
                        const SizedBox(height: 6),

                        // Arabic Title
                        Text(
                          cat.arabicTitle.isNotEmpty ? cat.arabicTitle : cat.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),

                        // English / Localized Title
                        Text(
                          displayTitle.isNotEmpty ? displayTitle : cat.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Dynamic Item Count Subtitle
                        Text(
                          isUrdu ? '$itemCount مسائل' : '$itemCount Masail',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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

class _HadithWisdomBanner extends StatelessWidget {
  const _HadithWisdomBanner();

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3E8D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: Color(0xFFB45309), size: 18),
              const SizedBox(width: 8),
              Text(
                lp.isUrdu ? 'فرمانِ مصطفیٰ ﷺ' : 'Hadith of Wisdom',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lp.isUrdu
                ? 'علمِ دین حاصل کرنا ہر مسلمان مرد اور عورت پر فرض ہے۔'
                : 'Seeking sacred Islamic knowledge is an obligation upon every Muslim.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              lp.isUrdu ? '— سنن ابن ماجہ' : '— Sunan Ibn Majah',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFF78350F),
              ),
            ),
          ),

        ],
      ),
    );
  }
}

class _MasailListScreen extends StatelessWidget {
  final MasailCategory category;
  final String localizedTitle;

  const _MasailListScreen({
    required this.category,
    required this.localizedTitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;
        final title = isUrdu ? category.titleUr : category.title;

        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          appBar: AppBar(
            title: Text(title.isNotEmpty ? title : localizedTitle),
            elevation: 0,
            backgroundColor: AppColors.primaryEmerald,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              GestureDetector(
                onTap: () => lp.toggleLanguage(),
                child: Container(
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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
          body: StreamBuilder<List<MasailItemModel>>(
            stream: ContentService.masailStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryEmerald,
                    strokeWidth: 2,
                  ),
                );
              }
              final all = snapshot.data ?? [];
              final filtered = ContentService.getMasailByCategory(all, category.id);
              if (filtered.isEmpty) {
                return Center(child: Text(lp.tr('no_masail_found')));
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  final qText = item.getQuestion(isUrdu);
                  final aText = item.getAnswer(isUrdu);
                  final bookText = item.getBook(isUrdu);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.emeraldContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.help_outline_rounded,
                            color: AppColors.primaryEmerald,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          qText,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Text(
                                  aText,
                                  style: AppTypography.bodyMedium.copyWith(
                                    height: 1.6,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                if (bookText.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.primaryEmerald),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '${isUrdu ? "کتاب / حوالہ" : "Book"}: $bookText',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.emeraldDeep,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
}
