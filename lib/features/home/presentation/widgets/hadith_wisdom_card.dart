import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/daily_content_model.dart';
import '../../../../main.dart';
import '../../../../services/content_service.dart';

/// Main container widget rendering the 3 distinct vertically scrolling cards:
/// 1. Daily Hadith Card (Emerald Theme)
/// 2. Daily Ayat Card (Deep Teal Theme)
/// 3. Topic of the Day Card (Gold/Amber Theme)
class HadithWisdomCard extends StatelessWidget {
  const HadithWisdomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final lp = globalLanguageProvider;
        final isUrdu = lp.isUrdu;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card 1: Daily Hadith ──
            DailyHadithCard(isUrdu: isUrdu),
            const SizedBox(height: 16),

            // ── Card 2: Daily Ayat ──
            DailyAyatCard(isUrdu: isUrdu),
            const SizedBox(height: 16),

            // ── Card 3: Topic of the Day ──
            TopicOfTheDayCard(isUrdu: isUrdu),
          ],
        );
      },
    );
  }

  static void showHistorySheet(BuildContext context, bool isUrdu, {String initialFilter = 'all'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DailyContentArchiveSheet(
        isUrdu: isUrdu,
        initialFilter: initialFilter,
      ),
    );
  }

  static void shareContent(
    BuildContext context, {
    required String title,
    required String arabic,
    required String content,
    required String citation,
  }) {
    final isUrdu = globalLanguageProvider.isUrdu;
    final sharedVia = isUrdu ? 'نورِ سنت ایپ کے ذریعے ارسال کردہ' : 'Shared via NOOR E SUNNAT App';
    final textToShare =
        '$title\n\n${arabic.isNotEmpty ? "$arabic\n\n" : ""}"$content"\n\n— $citation\n\n$sharedVia';
    Clipboard.setData(ClipboardData(text: textToShare));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isUrdu
            ? 'مواد کلپ بورڈ پر کاپی ہو گیا! واٹس ایپ / سوشل پر شئیر کریں۔'
            : 'Quote copied! Ready to share on WhatsApp & Socials.'),
        backgroundColor: const Color(0xFF0F5132),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CARD 1: DAILY HADITH CARD (Emerald Theme)
// ══════════════════════════════════════════════════════════════════════════════
class DailyHadithCard extends StatelessWidget {
  final bool isUrdu;
  const DailyHadithCard({super.key, required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryEmerald.withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryEmerald.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A4D2E), Color(0xFF0F5132)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 18, color: AppColors.goldBright),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu ? 'روز کی حدیث مبارکہ' : 'DAILY HADITH',
                    style: const TextStyle(
                      fontSize: 13,
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
                  tooltip: isUrdu ? 'حدیث آرکائیو / تمام دیکھیں' : 'History & Archive',
                  onPressed: () => HadithWisdomCard.showHistorySheet(context, isUrdu, initialFilter: 'hadith'),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ],
            ),
          ),

          // Content Stream
          StreamBuilder<List<DailyContentModel>>(
            stream: ContentService.dailyHadithsStream,
            builder: (context, snap) {
              final list = (snap.data != null && snap.data!.isNotEmpty)
                  ? snap.data!
                  : [ContentService.defaultHadith];
              final item = list.first;

              final title = item.getTitle(isUrdu);
              final content = item.getContent(isUrdu);
              final citation = item.getCitation(isUrdu);
              final arabic = item.arabicText;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge & Share
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.format_quote_rounded,
                                  size: 13,
                                  color: AppColors.primaryEmerald,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryEmerald,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: isUrdu ? 'شئیر کریں' : 'Share',
                          child: InkWell(
                            onTap: () => HadithWisdomCard.shareContent(
                              context,
                              title: title,
                              arabic: arabic,
                              content: content,
                              citation: citation,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldContainer.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.share_rounded,
                                size: 15,
                                color: AppColors.primaryEmerald,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Arabic Text
                    if (arabic.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F9F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.emeraldContainer),
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
                    ],

                    const SizedBox(height: 12),

                    // Translation
                    Text(
                      '"$content"',
                      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: isUrdu ? 14.5 : 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: isUrdu ? 1.6 : 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reference Chip
                    if (citation.isNotEmpty) ...[
                      Align(
                        alignment: isUrdu ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            citation,
                            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
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
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CARD 2: DAILY AYAT CARD (Deep Teal Theme)
// ══════════════════════════════════════════════════════════════════════════════
class DailyAyatCard extends StatelessWidget {
  final bool isUrdu;
  const DailyAyatCard({super.key, required this.isUrdu});

  @override
  Widget build(BuildContext context) {
    const tealPrimary = Color(0xFF0D5C75);
    const tealLight = Color(0xFFF0F9FF);
    const tealBorder = Color(0xFFBAE6FD);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tealPrimary.withValues(alpha: 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: tealPrimary.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B4659), Color(0xFF0D5C75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF7DD3FC)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu ? 'روز کی آیتِ مبارکہ' : 'DAILY AYAT',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE0F2FE),
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded, size: 20, color: Colors.white),
                  tooltip: isUrdu ? 'آیات آرکائیو / تمام دیکھیں' : 'History & Archive',
                  onPressed: () => HadithWisdomCard.showHistorySheet(context, isUrdu, initialFilter: 'ayat'),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ],
            ),
          ),

          // Content Stream
          StreamBuilder<List<DailyContentModel>>(
            stream: ContentService.dailyAyatsStream,
            builder: (context, snap) {
              final list = (snap.data != null && snap.data!.isNotEmpty)
                  ? snap.data!
                  : [ContentService.defaultAyat];
              final item = list.first;

              final title = item.getTitle(isUrdu);
              final content = item.getContent(isUrdu);
              final citation = item.getCitation(isUrdu);
              final arabic = item.arabicText;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge & Share
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: tealBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bookmark_added_rounded,
                                  size: 13,
                                  color: tealPrimary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: tealPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: isUrdu ? 'شئیر کریں' : 'Share',
                          child: InkWell(
                            onTap: () => HadithWisdomCard.shareContent(
                              context,
                              title: title,
                              arabic: arabic,
                              content: content,
                              citation: citation,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE).withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.share_rounded,
                                size: 15,
                                color: tealPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Arabic Text
                    if (arabic.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: tealLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: tealBorder),
                        ),
                        child: Text(
                          arabic,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: tealPrimary,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Translation
                    Text(
                      '"$content"',
                      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: isUrdu ? 14.5 : 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: isUrdu ? 1.6 : 1.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reference Chip
                    if (citation.isNotEmpty) ...[
                      Align(
                        alignment: isUrdu ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: tealBorder.withValues(alpha: 0.6)),
                          ),
                          child: Text(
                            citation,
                            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tealPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CARD 3: TOPIC OF THE DAY CARD (Gold / Amber Theme)
// ══════════════════════════════════════════════════════════════════════════════
class TopicOfTheDayCard extends StatefulWidget {
  final bool isUrdu;
  const TopicOfTheDayCard({super.key, required this.isUrdu});

  @override
  State<TopicOfTheDayCard> createState() => _TopicOfTheDayCardState();
}

class _TopicOfTheDayCardState extends State<TopicOfTheDayCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isUrdu = widget.isUrdu;
    const goldPrimary = Color(0xFF854D0E);
    const goldLight = Color(0xFFFEF3C7);
    const goldBorder = Color(0xFFFDE68A);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF78350F), Color(0xFF92400E), Color(0xFFB45309)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, size: 19, color: Color(0xFFFEF08A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu ? 'آج کا اہم موضوع' : 'TOPIC OF THE DAY',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFEF3C7),
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded, size: 20, color: Colors.white),
                  tooltip: isUrdu ? 'تمام موضوعات دیکھیں' : 'History & Archive',
                  onPressed: () => HadithWisdomCard.showHistorySheet(context, isUrdu, initialFilter: 'topics'),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ],
            ),
          ),

          // Content Stream
          StreamBuilder<List<DailyContentModel>>(
            stream: ContentService.topicsOfTheDayStream,
            builder: (context, snap) {
              final list = (snap.data != null && snap.data!.isNotEmpty)
                  ? snap.data!
                  : [ContentService.defaultTopicOfTheDay];
              final item = list.first;

              final title = item.getTitle(isUrdu);
              final content = item.getContent(isUrdu);
              final citation = item.getCitation(isUrdu);
              final arabic = item.arabicText;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge & Share
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: goldLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: goldBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_stories_rounded,
                                  size: 13,
                                  color: goldPrimary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: goldPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: isUrdu ? 'شئیر کریں' : 'Share',
                          child: InkWell(
                            onTap: () => HadithWisdomCard.shareContent(
                              context,
                              title: title,
                              arabic: arabic,
                              content: content,
                              citation: citation,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: goldLight.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.share_rounded,
                                size: 15,
                                color: goldPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Arabic Text (if any)
                    if (arabic.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCF9EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: goldBorder),
                        ),
                        child: Text(
                          arabic,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: goldPrimary,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Content / Explanation with Expandable Support
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Text(
                        content,
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isUrdu ? 14.5 : 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: isUrdu ? 1.6 : 1.5,
                        ),
                      ),
                      secondChild: Text(
                        content,
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                        style: TextStyle(
                          fontSize: isUrdu ? 14.5 : 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          height: isUrdu ? 1.6 : 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bottom Row: Learn More button & Citation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Expand / Learn More Button
                        InkWell(
                          onTap: () => setState(() => _isExpanded = !_isExpanded),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded
                                      ? (isUrdu ? 'کم دکھائیں' : 'Show Less')
                                      : (isUrdu ? 'مزید پڑھیں' : 'Learn More'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: goldPrimary,
                                  ),
                                ),
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: goldPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Reference Chip
                        if (citation.isNotEmpty) ...[
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: goldLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: goldBorder),
                              ),
                              child: Text(
                                citation,
                                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: goldPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ARCHIVE & HISTORY BOTTOM SHEET MODAL
// ══════════════════════════════════════════════════════════════════════════════
class _DailyContentArchiveSheet extends StatefulWidget {
  final bool isUrdu;
  final String initialFilter;
  const _DailyContentArchiveSheet({required this.isUrdu, this.initialFilter = 'all'});

  @override
  State<_DailyContentArchiveSheet> createState() => _DailyContentArchiveSheetState();
}

class _DailyContentArchiveSheetState extends State<_DailyContentArchiveSheet> {
  late String _selectedFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

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
                      const Icon(Icons.collections_bookmark_rounded,
                          color: AppColors.primaryEmerald, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isUrdu ? 'حدیث و حکمت آرکائیو' : 'Hadith & Wisdom Archive',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald),
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
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                decoration: InputDecoration(
                  hintText: isUrdu
                      ? 'تلاش کریں (حدیث، آیت، حوالہ...)'
                      : 'Search by keyword, surah, book...',
                  hintTextDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
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
                  _filterChip('hadith', isUrdu ? 'احادیث مبارکہ' : 'Hadiths'),
                  const SizedBox(width: 8),
                  _filterChip('ayat', isUrdu ? 'آیات مبارکہ' : 'Ayats'),
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
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryEmerald));
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
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.textSecondary),
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
                            color: isTop
                                ? AppColors.accentGold.withValues(alpha: 0.6)
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  margin: const EdgeInsetsDirectional.only(end: 6),
                                  decoration: BoxDecoration(
                                    color: entry.isAyat
                                        ? const Color(0xFFEDE9FE)
                                        : (entry.isTopicOfTheDay
                                            ? const Color(0xFFFEF3C7)
                                            : AppColors.emeraldContainer),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    entry.isAyat
                                        ? (isUrdu ? 'آیت مبارکہ' : 'AYAT')
                                        : (entry.isTopicOfTheDay
                                            ? (isUrdu ? 'خاص موضوع ⭐' : 'TOPIC ⭐')
                                            : (isUrdu ? 'حدیث مبارکہ' : 'HADITH')),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: entry.isAyat
                                          ? const Color(0xFF6D28D9)
                                          : (entry.isTopicOfTheDay
                                              ? const Color(0xFF854D0E)
                                              : AppColors.primaryEmerald),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    eTitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isTop
                                          ? const Color(0xFF854D0E)
                                          : AppColors.primaryEmerald,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: isUrdu ? 'شئیر کریں' : 'Share',
                                  child: IconButton(
                                    icon: const Icon(Icons.share_outlined,
                                        size: 16, color: Colors.grey),
                                    onPressed: () => HadithWisdomCard.shareContent(
                                      context,
                                      title: eTitle,
                                      arabic: eArab,
                                      content: eContent,
                                      citation: eCit,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            if (eArab.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                eArab,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
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
                              textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                              style: TextStyle(
                                fontSize: isUrdu ? 14 : 13,
                                color: AppColors.textPrimary,
                                height: isUrdu ? 1.6 : 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                '— $eCit',
                                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
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
