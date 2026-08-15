import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/daily_content_model.dart';
import '../../../../main.dart';
import '../../../../services/content_service.dart';

class HadithWisdomCard extends StatelessWidget {
  const HadithWisdomCard({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    return StreamBuilder<DailyContentModel?>(
      stream: ContentService.dailyContentStream,
      builder: (context, snapshot) {
        final item = snapshot.data;
        final title = item != null ? item.getTitle(isUrdu) : lp.tr('hadith_wisdom_title');
        final content = item != null ? item.getContent(isUrdu) : lp.tr('hadith_quote');
        final citation = item != null ? item.getCitation(isUrdu) : lp.tr('hadith_citation');
        final arabic = item?.arabicText ?? '';
        final imageUrl = item?.imageUrl ?? '';
        final isTopic = item?.isTopicOfTheDay ?? false;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isTopic ? AppColors.accentGold.withValues(alpha: 0.6) : AppColors.borderLight,
              width: isTopic ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isTopic ? AppColors.accentGold.withValues(alpha: 0.12) : AppColors.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isTopic
                      ? const LinearGradient(
                          colors: [Color(0xFF0F5132), Color(0xFF1E3A2B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [AppColors.primaryEmerald, Color(0xFF0A4D2E)],
                        ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(19),
                    topRight: Radius.circular(19),
                  ),
                ),
                child: Row(
                  children: [
                    if (isTopic) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Colors.black),
                            const SizedBox(width: 3),
                            Text(
                              isUrdu ? 'آج کا موضوع' : 'TOPIC OF THE DAY',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.goldBright),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldBright,
                          letterSpacing: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history_rounded, size: 18, color: Colors.white70),
                      tooltip: isUrdu ? 'سابقہ احادیث و آیات' : 'History & Archive',
                      onPressed: () => _showHistorySheet(context, isUrdu),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.goldBright),
                      tooltip: isUrdu ? 'شئیر کریں' : 'Share Quote',
                      onPressed: () => _shareContent(context, title, arabic, content, citation),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

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

              // Body
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (arabic.isNotEmpty) ...[
                      Center(
                        child: Text(
                          arabic,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      '"$content"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showHistorySheet(context, isUrdu),
                          icon: const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.primaryEmerald),
                          label: Text(
                            isUrdu ? 'تمام احادیث و آیات دیکھیں' : 'View Archive',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
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
                              color: AppColors.emeraldContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              citation,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryEmerald,
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
          ),
        );
      },
    );
  }

  void _showHistorySheet(BuildContext context, bool isUrdu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
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
              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUrdu ? 'احادیث و آیات کا خزانہ' : 'Hadith & Ayat Archive',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // List of historical items
              Expanded(
                child: StreamBuilder<List<DailyContentModel>>(
                  stream: ContentService.allDailyContentHistoryStream,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald));
                    }
                    final history = snap.data ?? [];
                    if (history.isEmpty) {
                      return Center(
                        child: Text(isUrdu ? 'کوئی سابقہ مواد موجود نہیں ہے۔' : 'No historical content found.'),
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
                            color: isTop ? const Color(0xFFFBF8EE) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isTop ? AppColors.accentGold.withValues(alpha: 0.5) : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isTop) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentGold,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'TOPIC ⭐',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
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
                                    onPressed: () => _shareContent(context, eTitle, eArab, eContent, eCit),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              if (eArab.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  eArab,
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 16,
                                    color: AppColors.primaryEmerald,
                                    height: 1.5,
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
      ),
    );
  }

  void _shareContent(BuildContext context, String title, String arabic, String content, String citation) {
    final textToShare = '$title\n\n${arabic.isNotEmpty ? "$arabic\n\n" : ""}"$content"\n\n— $citation\n\nShared via Faizan e Durood App';
    Clipboard.setData(ClipboardData(text: textToShare));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(globalLanguageProvider.isUrdu
            ? 'حدیث مبارکہ کاپی ہو گئی! واٹس ایپ / سوشل پر شئیر کریں۔'
            : 'Quote copied! Ready to share on WhatsApp & Socials.'),
        backgroundColor: const Color(0xFF0F5132),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
