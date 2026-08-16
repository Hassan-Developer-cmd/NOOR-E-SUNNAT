import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/daily_content_model.dart';
import '../../../../main.dart';
import '../../../../services/content_service.dart';

class HadithWisdomCard extends StatefulWidget {
  const HadithWisdomCard({super.key});

  @override
  State<HadithWisdomCard> createState() => _HadithWisdomCardState();
}

class _HadithWisdomCardState extends State<HadithWisdomCard> {
  int _selectedTab = 0; // 0 = Daily Hadith, 1 = Daily Ayat, 2 = Topic of the Day
  int _hadithIndex = 0;
  int _ayatIndex = 0;
  int _topicIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _selectedTab == 2
                  ? AppColors.accentGold.withValues(alpha: 0.6)
                  : AppColors.borderLight,
              width: _selectedTab == 2 ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _selectedTab == 2
                    ? AppColors.accentGold.withValues(alpha: 0.12)
                    : AppColors.shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Navigation & Tab Bar ──
              _buildCardHeader(context, isUrdu),

              // ── Tab Segment Selector ──
              _buildSegmentedBar(isUrdu),

              // ── Tab Content Stream ──
              _buildTabContent(isUrdu),
            ],
          ),
        );
      },
    );
  }


  Widget _buildCardHeader(BuildContext context, bool isUrdu) {
    String headerTitle;
    IconData headerIcon;

    if (_selectedTab == 0) {
      headerTitle = isUrdu ? 'روزانہ حدیثِ مبارکہ' : 'DAILY HADITH';
      headerIcon = Icons.menu_book_rounded;
    } else if (_selectedTab == 1) {
      headerTitle = isUrdu ? 'روزانہ آیتِ مبارکہ' : 'DAILY AYAT';
      headerIcon = Icons.auto_stories_rounded;
    } else {
      headerTitle = isUrdu ? 'آج کا موضوع' : 'TOPIC OF THE DAY';
      headerIcon = Icons.star_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: _selectedTab == 2
            ? const LinearGradient(
                colors: [Color(0xFF0F5132), Color(0xFF1E3A2B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [AppColors.primaryEmerald, Color(0xFF0A4D2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(21),
          topRight: Radius.circular(21),
        ),
      ),
      child: Row(
        children: [
          Icon(headerIcon, size: 17, color: AppColors.goldBright),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              headerTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.goldBright,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 20, color: Colors.white),
            tooltip: isUrdu ? 'سابقہ احادیث و آیات' : 'History & Archive',
            onPressed: () => _showHistorySheet(context, isUrdu),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedBar(bool isUrdu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            index: 0,
            label: isUrdu ? 'حدیث شریف' : 'Hadith',
            icon: Icons.format_quote_rounded,
          ),
          const SizedBox(width: 6),
          _buildSegmentButton(
            index: 1,
            label: isUrdu ? 'آیتِ مبارکہ' : 'Ayat',
            icon: Icons.bookmark_added_rounded,
          ),
          const SizedBox(width: 6),
          _buildSegmentButton(
            index: 2,
            label: isUrdu ? 'موضوع' : 'Topic ⭐',
            icon: Icons.star_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (index == 2 ? const Color(0xFFFEF3C7) : AppColors.emeraldContainer)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (index == 2 ? AppColors.accentGold : AppColors.primaryEmerald.withValues(alpha: 0.5))
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? (index == 2 ? const Color(0xFF854D0E) : AppColors.primaryEmerald)
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected
                        ? (index == 2 ? const Color(0xFF854D0E) : AppColors.primaryEmerald)
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isUrdu) {
    if (_selectedTab == 0) {
      return StreamBuilder<List<DailyContentModel>>(
        stream: ContentService.dailyHadithsStream,
        builder: (context, snap) {
          final list = snap.data ?? [ContentService.defaultHadith];
          if (_hadithIndex >= list.length) _hadithIndex = 0;
          final item = list.isNotEmpty ? list[_hadithIndex] : ContentService.defaultHadith;
          return _buildItemCard(
            context: context,
            item: item,
            currentIndex: _hadithIndex,
            totalCount: list.length,
            isUrdu: isUrdu,
            onPrev: () => setState(() => _hadithIndex = (_hadithIndex - 1 + list.length) % list.length),
            onNext: () => setState(() => _hadithIndex = (_hadithIndex + 1) % list.length),
          );
        },
      );
    } else if (_selectedTab == 1) {
      return StreamBuilder<List<DailyContentModel>>(
        stream: ContentService.dailyAyatsStream,
        builder: (context, snap) {
          final list = snap.data ?? [ContentService.defaultAyat];
          if (_ayatIndex >= list.length) _ayatIndex = 0;
          final item = list.isNotEmpty ? list[_ayatIndex] : ContentService.defaultAyat;
          return _buildItemCard(
            context: context,
            item: item,
            currentIndex: _ayatIndex,
            totalCount: list.length,
            isUrdu: isUrdu,
            onPrev: () => setState(() => _ayatIndex = (_ayatIndex - 1 + list.length) % list.length),
            onNext: () => setState(() => _ayatIndex = (_ayatIndex + 1) % list.length),
          );
        },
      );
    } else {
      return StreamBuilder<List<DailyContentModel>>(
        stream: ContentService.topicsOfTheDayStream,
        builder: (context, snap) {
          final list = snap.data ?? [ContentService.defaultHadith, ContentService.defaultAyat];
          if (_topicIndex >= list.length) _topicIndex = 0;
          final item = list.isNotEmpty ? list[_topicIndex] : ContentService.defaultHadith;
          return _buildItemCard(
            context: context,
            item: item,
            currentIndex: _topicIndex,
            totalCount: list.length,
            isUrdu: isUrdu,
            onPrev: () => setState(() => _topicIndex = (_topicIndex - 1 + list.length) % list.length),
            onNext: () => setState(() => _topicIndex = (_topicIndex + 1) % list.length),
          );
        },
      );
    }
  }

  Widget _buildItemCard({
    required BuildContext context,
    required DailyContentModel item,
    required int currentIndex,
    required int totalCount,
    required bool isUrdu,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    final title = item.getTitle(isUrdu);
    final content = item.getContent(isUrdu);
    final citation = item.getCitation(isUrdu);
    final arabic = item.arabicText;
    final imageUrl = item.imageUrl;
    final isTopic = item.isTopicOfTheDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional Image
        if (imageUrl.isNotEmpty) ...[
          ClipRRect(
            child: Image.network(
              imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ],

        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entry Title Bar & Stepper Controls
              Row(
                children: [
                  if (isTopic) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFF854D0E)),
                          const SizedBox(width: 3),
                          Text(
                            item.isAyat
                                ? (isUrdu ? 'آیت موضوع ⭐' : 'AYAT TOPIC ⭐')
                                : (isUrdu ? 'حدیث موضوع ⭐' : 'HADITH TOPIC ⭐'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF854D0E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isTopic ? const Color(0xFF854D0E) : AppColors.primaryEmerald,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (totalCount > 1) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      onPressed: onPrev,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    Text(
                      '${currentIndex + 1}/$totalCount',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      onPressed: onNext,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.primaryEmerald),
                    tooltip: isUrdu ? 'شئیر کریں' : 'Share',
                    onPressed: () => _shareContent(context, title, arabic, content, citation),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 6),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Arabic Calligraphy Text
              if (arabic.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isTopic ? const Color(0xFFFCF9EE) : const Color(0xFFF4F9F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isTopic ? AppColors.accentGold.withValues(alpha: 0.3) : AppColors.emeraldContainer,
                    ),
                  ),
                  child: Text(
                    arabic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryEmerald,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Content / Translation
              Text(
                '"$content"',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 14),

              // Footer: View Archive Button & Citation Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _showHistorySheet(context, isUrdu),
                    icon: const Icon(Icons.collections_bookmark_rounded, size: 14, color: AppColors.primaryEmerald),
                    label: Text(
                      isUrdu ? 'احادیث و آیات کا خزانہ' : 'View Archive',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryEmerald,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isTopic ? const Color(0xFFFEF3C7) : AppColors.emeraldContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isTopic ? AppColors.accentGold.withValues(alpha: 0.5) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        citation,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isTopic ? const Color(0xFF854D0E) : AppColors.primaryEmerald,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHistorySheet(BuildContext context, bool isUrdu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DailyContentArchiveSheet(isUrdu: isUrdu),
    );
  }

  static void _shareContent(BuildContext context, String title, String arabic, String content, String citation) {
    final textToShare = '$title\n\n${arabic.isNotEmpty ? "$arabic\n\n" : ""}"$content"\n\n— $citation\n\nShared via Faizan e Durood App';
    Clipboard.setData(ClipboardData(text: textToShare));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(globalLanguageProvider.isUrdu
            ? 'مواد کلپ بورڈ پر کاپی ہو گیا! واٹس ایپ / سوشل پر شئیر کریں۔'
            : 'Quote copied! Ready to share on WhatsApp & Socials.'),
        backgroundColor: const Color(0xFF0F5132),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _DailyContentArchiveSheet extends StatefulWidget {
  final bool isUrdu;
  const _DailyContentArchiveSheet({required this.isUrdu});

  @override
  State<_DailyContentArchiveSheet> createState() => _DailyContentArchiveSheetState();
}

class _DailyContentArchiveSheetState extends State<_DailyContentArchiveSheet> {
  String _selectedFilter = 'all'; // 'all', 'hadith', 'ayat', 'topics'
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = widget.isUrdu;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (ctx, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Sheet Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.collections_bookmark_rounded, color: AppColors.primaryEmerald, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isUrdu ? 'احادیث و آیات کا خزانہ' : 'Hadith & Ayat Archive',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: isUrdu ? 'تلاش کریں (حدیث، آیت، حوالہ...)' : 'Search by keyword, surah, book...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
              ),
            ),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _filterChip('all', isUrdu ? 'تمام' : 'All'),
                  const SizedBox(width: 8),
                  _filterChip('hadith', isUrdu ? 'احادیث' : 'Hadiths'),
                  const SizedBox(width: 8),
                  _filterChip('ayat', isUrdu ? 'آیات' : 'Ayats'),
                  const SizedBox(width: 8),
                  _filterChip('topics', isUrdu ? 'موضوعات ⭐' : 'Topics ⭐'),
                ],
              ),
            ),
            const Divider(height: 1),

            // Items List
            Expanded(
              child: StreamBuilder<List<DailyContentModel>>(
                stream: ContentService.allDailyContentHistoryStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald));
                  }
                  var history = snap.data ?? [];

                  // Apply Category Filter
                  if (_selectedFilter == 'hadith') {
                    history = history.where((d) => d.isHadith).toList();
                  } else if (_selectedFilter == 'ayat') {
                    history = history.where((d) => d.isAyat).toList();
                  } else if (_selectedFilter == 'topics') {
                    history = history.where((d) => d.isTopicOfTheDay).toList();
                  }

                  // Apply Search Query
                  if (_searchQuery.isNotEmpty) {
                    history = history.where((d) {
                      return d.title.toLowerCase().contains(_searchQuery) ||
                          d.titleUr.toLowerCase().contains(_searchQuery) ||
                          d.content.toLowerCase().contains(_searchQuery) ||
                          d.contentUr.toLowerCase().contains(_searchQuery) ||
                          d.arabicText.toLowerCase().contains(_searchQuery) ||
                          d.citation.toLowerCase().contains(_searchQuery) ||
                          d.citationUr.toLowerCase().contains(_searchQuery);
                    }).toList();
                  }

                  if (history.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              isUrdu ? 'کوئی مواد دستیاب نہیں ہے۔' : 'No entries found.',
                              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      final eTitle = entry.getTitle(isUrdu);
                      final eContent = entry.getContent(isUrdu);
                      final eCit = entry.getCitation(isUrdu);
                      final eArab = entry.arabicText;
                      final isTop = entry.isTopicOfTheDay;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isTop ? const Color(0xFFFDFBF7) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isTop ? AppColors.accentGold.withValues(alpha: 0.6) : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: entry.isAyat ? const Color(0xFFEDE9FE) : AppColors.emeraldContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    entry.isAyat
                                        ? (isUrdu ? 'آیت' : 'AYAT')
                                        : (isUrdu ? 'حدیث' : 'HADITH'),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: entry.isAyat ? const Color(0xFF6D28D9) : AppColors.primaryEmerald,
                                    ),
                                  ),
                                ),
                                if (isTop) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                      isUrdu ? 'موضوع ⭐' : 'TOPIC ⭐',
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF854D0E),
                                      ),
                                    ),
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    eTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isTop ? const Color(0xFF854D0E) : AppColors.primaryEmerald,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined, size: 16, color: Colors.grey),
                                  onPressed: () => _HadithWisdomCardState._shareContent(
                                    context,
                                    eTitle,
                                    eArab,
                                    eContent,
                                    eCit,
                                  ),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            if (eArab.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                eArab,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 16,
                                  color: AppColors.primaryEmerald,
                                  height: 1.6,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '"$eContent"',
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                '— $eCit',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryEmerald : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
