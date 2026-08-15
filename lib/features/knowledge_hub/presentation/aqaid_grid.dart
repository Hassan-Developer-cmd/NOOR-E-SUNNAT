import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/dummy_data/mock_aqaid.dart';
import '../../../core/models/aqaid_model.dart';
import '../../../main.dart';
import '../../../services/content_service.dart';
import 'aqaid_detail_screen.dart';

class AqaidGridScreen extends StatefulWidget {
  const AqaidGridScreen({super.key});

  @override
  State<AqaidGridScreen> createState() => _AqaidGridScreenState();
}

class _AqaidGridScreenState extends State<AqaidGridScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;

    final allCategories = ContentService.getAqaidCategories();
    final filteredCategories = allCategories.where((cat) {
      final title = cat.title.toLowerCase();
      final titleUr = cat.titleUr.toLowerCase();
      final q = _searchQuery.toLowerCase();
      return title.contains(q) || titleUr.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryEmerald,
        elevation: 0,
        title: Text(
          lp.isUrdu ? 'اسلامی عقائد' : 'Aqaid (Beliefs)',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<AqaidItemModel>>(
        stream: ContentService.aqaidStream,
        builder: (context, snapshot) {
          final allEntries = snapshot.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: lp.isUrdu ? 'عقائد کے موضوعات تلاش کریں...' : 'Search belief topics...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Custom Layout for Aqaid Cards ──
                _buildAqaidCards(context, filteredCategories, lp.isUrdu, allEntries),
                const SizedBox(height: 24),

                // ── Did You Know? Card ──
                const _DidYouKnowBanner(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAqaidCards(
      BuildContext context, List<AqaidCategory> categories, bool isUrdu, List<AqaidItemModel> allEntries) {
    // Separate categories into row groups
    final topTwo = categories.where((c) => !c.isFullWidth).take(2).toList();
    final fullWidth = categories.where((c) => c.isFullWidth).toList();
    final bottomTwo = categories.where((c) => !c.isFullWidth).skip(2).toList();

    return Column(
      children: [
        // Row 1 (Top 2 cards side by side)
        if (topTwo.isNotEmpty)
          Row(
            children: topTwo.map((cat) {
              final count = ContentService.getAqaidByCategory(allEntries, cat.id).length;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6, left: 6, bottom: 12),
                  child: _AqaidImageCard(
                    cat: cat,
                    isUrdu: isUrdu,
                    itemCount: count,
                    onTap: () => _openAqaidDetail(context, cat),
                  ),
                ),
              );
            }).toList(),
          ),

        // Row 2 (Full Width Card)
        if (fullWidth.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _AqaidImageCard(
              cat: fullWidth.first,
              isUrdu: isUrdu,
              itemCount: ContentService.getAqaidByCategory(allEntries, fullWidth.first.id).length,
              height: 120,
              onTap: () => _openAqaidDetail(context, fullWidth.first),
            ),
          ),
        const SizedBox(height: 8),

        // Row 3 (Bottom 2 cards side by side)
        if (bottomTwo.isNotEmpty)
          Row(
            children: bottomTwo.map((cat) {
              final count = ContentService.getAqaidByCategory(allEntries, cat.id).length;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6, left: 6, top: 4),
                  child: _AqaidImageCard(
                    cat: cat,
                    isUrdu: isUrdu,
                    itemCount: count,
                    onTap: () => _openAqaidDetail(context, cat),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _openAqaidDetail(BuildContext context, AqaidCategory cat) {
    final localizedTitle = globalLanguageProvider.isUrdu ? cat.titleUr : cat.title;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AqaidDetailScreen(category: cat, localizedTitle: localizedTitle),
      ),
    );
  }
}

class _AqaidImageCard extends StatelessWidget {
  final AqaidCategory cat;
  final bool isUrdu;
  final int itemCount;
  final double height;
  final VoidCallback onTap;

  const _AqaidImageCard({
    required this.cat,
    required this.isUrdu,
    required this.itemCount,
    this.height = 140,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.asset(
                cat.bgAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF0F5132),
                ),
              ),

              // Gradient Overlay for readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Text Overlay
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (isUrdu ? cat.titleUr : cat.title).isNotEmpty
                          ? (isUrdu ? cat.titleUr : cat.title)
                          : cat.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUrdu ? '$itemCount موضوعات' : '$itemCount Topics',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DidYouKnowBanner extends StatelessWidget {
  const _DidYouKnowBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFD97706),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Did you know?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Authentic Aqaid (beliefs) are the foundation of a Muslim\'s faith, based on the Quran and Sunnah as understood by the righteous predecessors.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.5,
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
