import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/dummy_data/mock_aqaid.dart';
import '../../../core/models/aqaid_model.dart';
import '../../../main.dart';
import '../../../services/content_service.dart';

class AqaidDetailScreen extends StatefulWidget {
  final AqaidCategory category;
  final String localizedTitle;

  const AqaidDetailScreen({
    super.key,
    required this.category,
    required this.localizedTitle,
  });

  @override
  State<AqaidDetailScreen> createState() => _AqaidDetailScreenState();
}

class _AqaidDetailScreenState extends State<AqaidDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

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
        final catTitle = isUrdu ? widget.category.titleUr : widget.category.title;
        final categoryName = isUrdu ? widget.category.titleUr : widget.category.title;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: AppColors.primaryEmerald,
            elevation: 0,
            title: Text(
              catTitle.isNotEmpty ? catTitle : widget.localizedTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
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
      body: Column(
        children: [
          // ── Sleek Rounded Search Bar ─────────────────────────────────
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
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: isUrdu ? 'تلاش کریں...' : 'Search in $categoryName...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryEmerald,
                    size: 22,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),

          // ── Main Content Stream & List ────────────────────────────────
          Expanded(
            child: StreamBuilder<List<AqaidItemModel>>(
              stream: ContentService.aqaidStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryEmerald,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final allEntries = snapshot.data ?? [];
                final categoryEntries = ContentService.getAqaidByCategory(allEntries, widget.category.id);

                // Real-time filtering logic
                final q = _searchQuery.trim().toLowerCase();
                final filteredSubAqaid = categoryEntries.where((entry) {
                  if (q.isEmpty) return true;
                  final titleMatch = entry.getTitle(isUrdu).toLowerCase().contains(q);
                  final bodyMatch = entry.getExplanation(isUrdu).toLowerCase().contains(q);
                  return titleMatch || bodyMatch;
                }).toList();

                if (filteredSubAqaid.isEmpty) {
                  return _buildEmptyState(context, isUrdu, _searchQuery);
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSubAqaid.length,
                  itemBuilder: (context, index) {
                    final item = filteredSubAqaid[index];
                    return _SubAqaidCard(
                      item: item,
                      categoryName: widget.localizedTitle,
                      isUrdu: isUrdu,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }


  Widget _buildEmptyState(BuildContext context, bool isUrdu, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.emeraldContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.primaryEmerald,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isUrdu ? 'کوئی عقیدہ نہیں ملا' : 'No sub-Aqaid found matching \'$query\'',
              textAlign: TextAlign.center,
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isUrdu
                  ? 'برائے مہربانی مختلف الفاظ کے ساتھ تلاش کریں'
                  : 'Try searching with different keywords or check spelling.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubAqaidCard extends StatelessWidget {
  final AqaidItemModel item;
  final String categoryName;
  final bool isUrdu;

  const _SubAqaidCard({
    required this.item,
    required this.categoryName,
    required this.isUrdu,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = item.getTitle(isUrdu);
    final bodyText = item.getExplanation(isUrdu);
    final bookText = item.getBook(isUrdu);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              categoryName.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryEmerald,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            titleText,
            style: AppTypography.headingMedium.copyWith(
              fontSize: 16,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Arabic Text if present
          if (item.arabicText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                item.arabicText,
                textAlign: TextAlign.center,
                style: AppTypography.arabicText.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Body Content / Explanation
          Text(
            bodyText,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),

          // Book / Reference
          if (bookText.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 15, color: AppColors.accentGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${isUrdu ? "کتاب / حوالہ" : "Book"}: $bookText',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}
