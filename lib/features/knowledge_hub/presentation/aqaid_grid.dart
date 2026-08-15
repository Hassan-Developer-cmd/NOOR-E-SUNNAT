import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
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
      },
    );
  }

  Widget _buildAqaidCards(
      BuildContext context, List<AqaidCategory> categories, bool isUrdu, List<AqaidItemModel> allEntries) {
    final List<Widget> rows = [];
    int i = 0;
    while (i < categories.length) {
      final cat = categories[i];
      if (cat.isFullWidth) {
        final count = ContentService.getAqaidByCategory(allEntries, cat.id).length;
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: _AqaidImageCard(
              cat: cat,
              isUrdu: isUrdu,
              itemCount: count,
              height: 120,
              onTap: () => _openAqaidDetail(context, cat),
            ),
          ),
        );
        i++;
      } else if (i + 1 < categories.length && !categories[i + 1].isFullWidth) {
        final cat1 = categories[i];
        final cat2 = categories[i + 1];
        final count1 = ContentService.getAqaidByCategory(allEntries, cat1.id).length;
        final count2 = ContentService.getAqaidByCategory(allEntries, cat2.id).length;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _AqaidImageCard(
                      cat: cat1,
                      isUrdu: isUrdu,
                      itemCount: count1,
                      onTap: () => _openAqaidDetail(context, cat1),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _AqaidImageCard(
                      cat: cat2,
                      isUrdu: isUrdu,
                      itemCount: count2,
                      onTap: () => _openAqaidDetail(context, cat2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        i += 2;
      } else {
        final count = ContentService.getAqaidByCategory(allEntries, cat.id).length;
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: _AqaidImageCard(
              cat: cat,
              isUrdu: isUrdu,
              itemCount: count,
              height: 120,
              onTap: () => _openAqaidDetail(context, cat),
            ),
          ),
        );
        i++;
      }
    }

    return Column(children: rows);
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
