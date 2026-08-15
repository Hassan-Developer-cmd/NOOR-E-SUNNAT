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

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.primaryEmerald,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        size: 18, color: AppColors.goldBright),
                    const SizedBox(width: 8),
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
                      icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.goldBright),
                      tooltip: lp.isUrdu ? 'شئیر کریں' : 'Share Quote',
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (arabic.isNotEmpty) ...[
                      Text(
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
