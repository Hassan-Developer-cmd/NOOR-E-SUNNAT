import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../main.dart';

class KnowledgeDetailView extends StatelessWidget {
  final String title;
  final String category;
  final String? arabicCalligraphy;
  final String bodyContent;
  final String book;

  const KnowledgeDetailView({
    super.key,
    required this.title,
    required this.category,
    this.arabicCalligraphy,
    required this.bodyContent,
    required this.book,
    String? citation,
    String? referenceBook,
  });

  String get citation => book;
  String get referenceBook => book;

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;

    return Scaffold(
      backgroundColor: AppColors.bgOffWhite,
      appBar: AppBar(
        title: Text(category),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emeraldContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryEmerald,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title Question
            Text(
              title,
              style: AppTypography.headingLarge,
            ),
            const SizedBox(height: 16),
            // Arabic calligraphy card if present
            if (arabicCalligraphy != null && arabicCalligraphy!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    arabicCalligraphy!,
                    textAlign: TextAlign.center,
                    style: AppTypography.arabicText,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Answer Body Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notes, color: AppColors.primaryEmerald, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        lp.tr('detailed_answer_title'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.borderLight),
                  Text(
                    bodyContent,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Book & Reference Card
            if (book.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: AppColors.accentGold, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lp.tr('book_label'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            book,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
