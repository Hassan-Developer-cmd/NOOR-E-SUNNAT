import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/team_member.dart';
import '../../../../main.dart';
import '../../../../services/auth_service.dart';

class ProfileSettingsSheets {
  // Official Play Store URL & Intent URI
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.nooresunnat.islamic_app';
  static const String playStoreMarketUri =
      'market://details?id=com.nooresunnat.islamic_app';

  /// Directly launch Google Play Store App / URL
  static Future<void> openPlayStore() async {
    try {
      final marketUri = Uri.parse(playStoreMarketUri);
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    try {
      final webUri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Trigger Native System Share Sheet with Play Store Link
  static Future<void> shareApp(BuildContext context) async {
    final lp = globalLanguageProvider;
    final message = lp.tr('share_app_msg');

    try {
      await Share.share(
        message,
        subject: 'NOOR E SUNNAT',
      );
    } catch (_) {
      // Fallback to clipboard if native share sheet is unavailable
      await Clipboard.setData(ClipboardData(text: message));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lp.tr('invitation_copied')),
            backgroundColor: const Color(0xFF064E3B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── 1. About Us Modal Sheet ─────────────────────────────────────────
  static void showAboutUsSheet(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Directionality(
          textDirection: lp.textDirection,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Icon Badge
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.emeraldDeep, AppColors.primaryEmerald],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: AppColors.goldBright, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.shield_moon_rounded,
                              color: AppColors.goldBright,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        lp.tr('about_app_title'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldDeep,
                          fontFamily: isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        lp.tr('about_app_subtitle'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Version Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryEmerald.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          lp.tr('app_version_label'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // About Us Content Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: isUrdu
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          color: AppColors.primaryEmerald, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ہمارے بارے میں',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.emeraldDeep,
                                          fontFamily: AppTypography.urduFontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        height: 1.75,
                                        color: const Color(0xFF334155),
                                        fontFamily: AppTypography.urduFontFamily,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'نورِ سنت ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: 'ایک ڈیجیٹل پلیٹ فارم ہے جس کا مقصد جدید ٹیکنالوجی کے ذریعے مستند اسلامی علم کو عام لوگوں، خصوصاً مسلم نوجوانوں تک آسان انداز میں پہنچانا ہے۔\n\n'
                                              'ہماری کوشش ہے کہ صارفین ',
                                        ),
                                        TextSpan(
                                          text: 'اسلام کے بنیادی عقائد اور ضروری تعلیمات ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: 'کو سمجھیں اور ہمارے پیارے نبی محمد مصطفیٰ ﷺ کی سنتوں کو اپنی روزمرہ زندگی کا حصہ بنائیں۔\n\n'
                                              'ایپ میں ',
                                        ),
                                        TextSpan(
                                          text: 'درود و سلام، اسلامی عقائد، ضروری اسلامی رہنمائی اور روزمرہ مسائل کے جوابات ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: 'سمیت مختلف اسلامی سہولیات اور مواد فراہم کیا جاتا ہے۔\n\n'
                                              'ہمارا اسلامی مواد ',
                                        ),
                                        TextSpan(
                                          text: 'مستند اسلامی ماخذ اور اہلِ سنت کی معتبر کتب ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: 'سے اخذ کیا گیا ہے اور اسے علمائے کرام کی رہنمائی و نگرانی میں مرتب کیا جاتا ہے۔\n\n'
                                              'نورِ سنت کے ذریعے ہمارا مقصد ٹیکنالوجی کو ',
                                        ),
                                        TextSpan(
                                          text: 'اسلام کی خدمت، نفع بخش علم کی اشاعت اور ہمارے پیارے نبی محمد مصطفیٰ ﷺ کی محبت کو دلوں میں مضبوط کرنے ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: 'کا ذریعہ بنانا ہے۔',
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          color: AppColors.primaryEmerald, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'About Us',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.emeraldDeep,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text.rich(
                                    const TextSpan(
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.6,
                                        color: Color(0xFF334155),
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Noor-e-Sunnat ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: 'is a digital platform dedicated to making authentic Islamic knowledge accessible through modern technology, especially for Muslim youth.\n\n'
                                              'Our mission is to help users understand the ',
                                        ),
                                        TextSpan(
                                          text: 'fundamental beliefs and essential teachings of Islam ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: 'and bring the Sunnahs of our beloved Prophet Muhammad ﷺ into their daily lives.\n\n'
                                              'The app offers ',
                                        ),
                                        TextSpan(
                                          text: 'Durood & Salawat, Islamic beliefs, essential Islamic guidance, and answers to everyday questions',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: '.\n\nOur content is carefully prepared from ',
                                        ),
                                        TextSpan(
                                          text: 'authentic Islamic sources and recognized books of Ahl al-Sunnah',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: ', under the guidance and supervision of Islamic scholars.\n\n'
                                              'Through Noor-e-Sunnat, we strive to use technology as a means to ',
                                        ),
                                        TextSpan(
                                          text: 'serve Islam, spread beneficial knowledge, and strengthen the love for our beloved Prophet Muhammad ﷺ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emeraldDark),
                                        ),
                                        TextSpan(
                                          text: '.',
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Key Features Section
                      Align(
                        alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                        child: Text(
                          lp.tr('about_key_features'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildFeatureTile(Icons.countertops_rounded, lp.tr('about_feat_1')),
                      _buildFeatureTile(Icons.auto_stories_rounded, lp.tr('about_feat_2')),
                      _buildFeatureTile(Icons.menu_book_rounded, lp.tr('about_feat_3')),
                      _buildFeatureTile(Icons.question_answer_rounded, lp.tr('about_feat_4')),
                      _buildFeatureTile(Icons.military_tech_rounded, lp.tr('about_feat_5')),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(lp.tr('close'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureTile(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryEmerald),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Our Team Modal Sheet ──────────────────────────────────────────
  static void showOurTeamSheet(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: Directionality(
            textDirection: lp.textDirection,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: AppColors.primaryEmerald,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lp.tr('our_team_title'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.emeraldDeep,
                                  ),
                                ),
                                Text(
                                  lp.tr('our_team_subtitle'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Section 1: IT TEAM
                      _buildTeamSection(
                        context: ctx,
                        categoryTitle: isUrdu ? 'آئی ٹی ٹیم' : 'IT TEAM',
                        members: TeamMember.itTeam,
                        isUrdu: isUrdu,
                      ),
                      const SizedBox(height: 24),

                      // Section 2: ISLAMIC RESEARCH TEAM
                      _buildTeamSection(
                        context: ctx,
                        categoryTitle: isUrdu ? 'اسلامک ریسرچ ٹیم' : 'ISLAMIC RESEARCH TEAM',
                        members: TeamMember.islamicResearchTeam,
                        isUrdu: isUrdu,
                      ),
                      const SizedBox(height: 24),

                      // Contact Support Box
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final uri = Uri(
                              scheme: 'mailto',
                              path: 'nooresunnatinfo@gmail.com',
                              query: 'subject=NOOR E SUNNAT App Feedback & Support',
                            );
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              debugPrint('Failed to launch email: $e');
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.emeraldContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mail_outline_rounded,
                                    color: AppColors.primaryEmerald,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lp.tr('contact_support'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        lp.tr('contact_email_label'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primaryEmerald,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    lp.tr('close'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

  /// Builds a section with a Teal pill header, vertical timeline line, and member cards
  static Widget _buildTeamSection({
    required BuildContext context,
    required String categoryTitle,
    required List<TeamMember> members,
    required bool isUrdu,
  }) {
    return Column(
      children: [
        // Section Header Pill
        _buildSectionHeaderPill(categoryTitle),
        const SizedBox(height: 14),

        // Timeline layout: Vertical line on side + List of member cards wrapped in IntrinsicHeight
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vertical accent timeline line dynamically sized without overflow
              Container(
                width: 3.5,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A6C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Member cards
              Expanded(
                child: Column(
                  children: members
                      .map((member) => _buildTeamMemberCard(context, member, isUrdu))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section Header Pill matching the provided visual design
  static Widget _buildSectionHeaderPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF007A6C),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007A6C).withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  /// Individual Member Card Container with tap interaction to open full detail modal
  static Widget _buildTeamMemberCard(
    BuildContext context,
    TeamMember member,
    bool isUrdu,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMemberDetailDialog(context, member, isUrdu),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Circular Avatar (Image or Initial Fallback)
                _buildMemberAvatar(member),
                const SizedBox(width: 14),

                // Member Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        isUrdu ? member.nameUr : member.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          letterSpacing: isUrdu ? 0 : 0.4,
                          fontFamily: isUrdu ? AppTypography.urduFontFamily : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Role
                      Text(
                        isUrdu ? member.roleUr : member.role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                          letterSpacing: isUrdu ? 0 : 0.3,
                          fontFamily: isUrdu ? AppTypography.urduFontFamily : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Mini Pill Tag (Matching screenshot [TEAL] SUB-ROLE)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007A6C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isUrdu ? 'شعبہ' : 'DEPARTMENT',
                              maxLines: 1,
                              softWrap: false,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: isUrdu ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                isUrdu ? member.tagUr : member.tag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF007A6C),
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isUrdu ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Full Product / Team Member detail card with image preview, tags, description & action button
  static void _showMemberDetailDialog(
    BuildContext context,
    TeamMember member,
    bool isUrdu,
  ) {
    final lp = globalLanguageProvider;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Directionality(
            textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Image Banner / Preview (height: 190, fit: BoxFit.cover)
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 190,
                        color: const Color(0xFF0F172A),
                        child: member.imagePath != null && member.imagePath!.isNotEmpty
                            ? Image.asset(
                                member.imagePath!,
                                width: double.infinity,
                                height: 190,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: double.infinity,
                                  height: 190,
                                  color: const Color(0xFF007A6C),
                                  alignment: Alignment.center,
                                  child: Text(
                                    member.name.isNotEmpty ? member.name[0] : 'NS',
                                    style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                height: 190,
                                color: const Color(0xFF007A6C),
                                alignment: Alignment.center,
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0] : 'NS',
                                  style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                      // Top gradient scrim for readability of close button
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black54, Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Floating Close button
                      PositionedDirectional(
                        top: 12,
                        end: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 2. Member Info (Name, Role, Tags, Description & Actions)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007A6C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isUrdu ? 'شعبہ' : (member.category == 'IT TEAM' ? 'IT TEAM' : 'RESEARCH'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007A6C).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isUrdu ? member.tagUr : member.tag,
                                  style: const TextStyle(
                                    color: Color(0xFF007A6C),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Name
                        Text(
                          isUrdu ? member.nameUr : member.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                            fontFamily: isUrdu ? AppTypography.urduFontFamily : null,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Role
                        Text(
                          isUrdu ? member.roleUr : member.role,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                            fontFamily: isUrdu ? AppTypography.urduFontFamily : null,
                          ),
                        ),

                        // Description
                        if (member.description != null && member.description!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              isUrdu ? (member.descriptionUr ?? member.description!) : member.description!,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: const Color(0xFF334155),
                                fontFamily: isUrdu ? AppTypography.urduFontFamily : null,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007A6C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              lp.tr('close'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Circular Member Avatar with fallback handling
  static Widget _buildMemberAvatar(TeamMember member) {
    final initials = member.name.trim().isNotEmpty
        ? member.name
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
        : 'NS';

    final hasImage = member.imagePath != null && member.imagePath!.trim().isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F5F9),
        border: Border.all(
          color: const Color(0xFF007A6C).withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.asset(
                member.imagePath!.trim(),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Team image load failed for ${member.name} (${member.imagePath}): $error');
                  return _buildAvatarFallback(initials);
                },
              )
            : _buildAvatarFallback(initials),
      ),
    );
  }

  static Widget _buildAvatarFallback(String initials) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF007A6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 17,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── 3. Rate App Dialog ───────────────────────────────────────────────
  static void showRateAppDialog(BuildContext context) {
    final lp = globalLanguageProvider;
    int selectedRating = 5;
    final Set<String> selectedTags = {};
    final commentController = TextEditingController();

    final tags = [
      lp.tr('rate_tag_easy'),
      lp.tr('rate_tag_spiritual'),
      lp.tr('rate_tag_design'),
      lp.tr('rate_tag_authentic'),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(20),
          content: Directionality(
            textDirection: lp.textDirection,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lp.tr('rate_app_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lp.tr('rate_question'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // 5 Star Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        iconSize: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        icon: Icon(
                          starIndex <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        onPressed: () {
                          setDialogState(() => selectedRating = starIndex);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 14),

                  // Tag Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: tags.map((t) {
                      final isSelected = selectedTags.contains(t);
                      return FilterChip(
                        label: Text(t, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
                        selected: isSelected,
                        selectedColor: AppColors.primaryEmerald,
                        backgroundColor: AppColors.bgOffWhite,
                        checkmarkColor: Colors.white,
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedTags.add(t);
                            } else {
                              selectedTags.remove(t);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Optional Comment Field
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: lp.tr('rate_feedback_hint'),
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      filled: true,
                      fillColor: AppColors.bgOffWhite,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  const SizedBox(height: 18),

                  // Direct Play Store Rating Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        foregroundColor: AppColors.goldBright,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        await openPlayStore();
                      },
                      icon: const Icon(Icons.shop_rounded, size: 20),
                      label: Text(lp.tr('rate_on_playstore'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: Text(lp.tr('cancel')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFDE047), size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        lp.tr('rate_thank_you'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF064E3B),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                          child: Text(lp.tr('rate_submit_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 5. Terms and Privacy Policy Modal Sheet ───────────────────────────
  static void showTermsAndPolicySheet(BuildContext context) {
    final lp = globalLanguageProvider;
    int activeTab = 0; // 0: Terms, 1: Privacy

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Directionality(
            textDirection: lp.textDirection,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  lp.tr('terms_policy_title'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.emeraldDeep),
                ),
                const SizedBox(height: 14),

                // Segment Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.bgOffWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: activeTab == 0 ? AppColors.primaryEmerald : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lp.tr('terms_tab_label'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: activeTab == 0 ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: activeTab == 1 ? AppColors.primaryEmerald : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              lp.tr('privacy_tab_label'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: activeTab == 1 ? Colors.white : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Tab Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: activeTab == 0
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Text(
                                  lp.tr('terms_intro'),
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildPolicyPoint(Icons.verified_rounded, lp.tr('terms_point_1')),
                              const SizedBox(height: 10),
                              _buildPolicyPoint(Icons.favorite_rounded, lp.tr('terms_point_2')),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  lp.tr('privacy_intro'),
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildPolicyPoint(Icons.security_rounded, lp.tr('privacy_point_1')),
                              const SizedBox(height: 10),
                              _buildPolicyPoint(Icons.block_rounded, lp.tr('privacy_point_2')),
                              const SizedBox(height: 10),
                              _buildPolicyPoint(Icons.lock_outline_rounded, lp.tr('privacy_point_3')),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(lp.tr('close'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPolicyPoint(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryEmerald),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the Delete Account confirmation dialog.
  static void showDeleteAccountDialog(BuildContext context) {
    final lp = globalLanguageProvider;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lp.tr('delete_account_confirm_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          lp.tr('delete_account_confirm_msg'),
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF4B5563),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              lp.tr('cancel'),
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await executeAccountDeletion(context);
            },
            child: Text(lp.tr('delete_account_action')),
          ),
        ],
      ),
    );
  }

  /// Executes full account deletion, Firestore purge, SharedPreferences wipe, dialog dismiss, and navigation reset.
  static Future<void> executeAccountDeletion(BuildContext context, {String? reauthPassword}) async {
    final lp = globalLanguageProvider;
    final rootNav = Navigator.of(context, rootNavigator: true);
    bool dialogPopped = false;

    void dismissLoadingDialog() {
      if (!dialogPopped) {
        dialogPopped = true;
        if (rootNav.canPop()) {
          rootNav.pop();
        } else if (context.mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
    }

    // Show loading indicator dialog explicitly on rootNavigator
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  lp.tr('deleting_account'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await AuthService.deleteAccount(reauthPassword: reauthPassword);

      // 1. Pop the active loading dialog explicitly using rootNavigator BEFORE navigation
      dismissLoadingDialog();

      // 2. Navigate and reset stack only after the dialog has popped
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'اکاؤنٹ اور تمام ڈیٹا کامیابی سے ختم کر دیا گیا ہے / Account and all associated data deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 1. Dismiss the "Deleting Account..." dialog before handling error or showing security reauth dialog
      dismissLoadingDialog();

      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lp.isUrdu ? 'سیکیورٹی تصدیق' : 'Security Verification',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'For security, please log out and log in again before deleting your account. / سیکیورٹی کی تصدیق کے لیے اکاؤنٹ ختم کرنے سے پہلے دوبارہ لاگ ان کریں۔',
                style: TextStyle(fontSize: 13.5, height: 1.45),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(lp.tr('cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  child: Text(lp.isUrdu ? 'لاگ آؤٹ کریں' : 'Log Out Now'),
                ),
              ],
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deletion error: ${e.message ?? e.code}'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    } catch (e) {
      dismissLoadingDialog();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      // 3. Ensure the dismiss statement runs inside a finally block so it always closes whether deletion succeeds or fails
      dismissLoadingDialog();
    }
  }
}
