import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../main.dart';

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

                      // Salawat Quote Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'اللَّهُمَّ صَلِّ عَلَى سَيِّدِنَا مُحَمَّدٍ وَعَلَى آلِ سَيِّدِنَا مُحَمَّدٍ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldDark,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lp.tr('about_app_desc'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.grey.shade800,
                                fontFamily: isUrdu ? AppTypography.urduFontFamily : AppTypography.englishFontFamily,
                              ),
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
                            child: const Icon(Icons.groups_rounded, color: AppColors.primaryEmerald, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lp.tr('our_team_title'),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.emeraldDeep),
                                ),
                                Text(
                                  lp.tr('our_team_subtitle'),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Team Members 2-Column Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.60,
                        children: [
                          _buildTeamGridCard(
                            context: ctx,
                            name: 'Hassan Awan',
                            role: lp.tr('App Developer'),
                            desc: 'Leading mobile app architecture, cloud integrations, and core feature development for Noor e Sunnat.',
                            imagePath: 'assets/images/team_hassan.jpeg',
                            fallbackIcon: Icons.code_rounded,
                            badgeColor: const Color(0xFF0284C7),
                          ),
                          _buildTeamGridCard(
                            context: ctx,
                            name: lp.tr('team_member_2_name'),
                            role: lp.tr('team_scholar_role'),
                            desc: lp.tr('team_scholar_desc'),
                            imagePath: null, // Placeholder: e.g. 'assets/images/team_scholar.png' or URL
                            fallbackIcon: Icons.menu_book_rounded,
                            badgeColor: AppColors.primaryEmerald,
                          ),
                          _buildTeamGridCard(
                            context: ctx,
                            name: lp.tr('team_member_3_name'),
                            role: lp.tr('team_design_role'),
                            desc: lp.tr('team_design_desc'),
                            imagePath: null, // Placeholder: e.g. 'assets/images/team_design.png' or URL
                            fallbackIcon: Icons.palette_rounded,
                            badgeColor: const Color(0xFFD97706),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Contact Support Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgOffWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline_rounded, color: AppColors.primaryEmerald, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lp.tr('contact_support'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    lp.tr('contact_email_label'),
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  static Widget _buildTeamGridCard({
    required BuildContext context,
    required String name,
    required String role,
    String? desc,
    String? imagePath,
    required IconData fallbackIcon,
    required Color badgeColor,
  }) {
    final lp = globalLanguageProvider;
    final bool hasImage = imagePath != null && imagePath.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMemberDetailSheet(
          context,
          name: name,
          role: role,
          desc: desc,
          imagePath: imagePath,
          fallbackIcon: fallbackIcon,
          badgeColor: badgeColor,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Avatar with Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeColor.withValues(alpha: 0.12),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasImage
                          ? (imagePath.startsWith('http')
                              ? Image.network(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  errorBuilder: (_, _, _) => _buildAvatarFallback(fallbackIcon, badgeColor, name, size: 22),
                                )
                              : Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  width: 56,
                                  height: 56,
                                  errorBuilder: (_, _, _) => _buildAvatarFallback(fallbackIcon, badgeColor, name, size: 22),
                                ))
                          : _buildAvatarFallback(fallbackIcon, badgeColor, name, size: 22),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(fallbackIcon, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Member Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),

              // Role Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              if (desc != null && desc.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
                Expanded(
                  child: Text(
                    desc,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 4),

              // Detail Arrow Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lp.tr('team_view_details'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 9,
                      color: badgeColor,
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

  /// Displays the full untruncated profile & bio for a team member
  static void _showMemberDetailSheet(
    BuildContext context, {
    required String name,
    required String role,
    String? desc,
    String? imagePath,
    required IconData fallbackIcon,
    required Color badgeColor,
  }) {
    final lp = globalLanguageProvider;
    final bool hasImage = imagePath != null && imagePath.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
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
              const SizedBox(height: 20),

              // Large Member Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badgeColor.withValues(alpha: 0.12),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.45), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: hasImage
                          ? (imagePath.startsWith('http')
                              ? Image.network(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  width: 76,
                                  height: 76,
                                  errorBuilder: (_, _, _) => _buildAvatarFallback(fallbackIcon, badgeColor, name, size: 30),
                                )
                              : Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  width: 76,
                                  height: 76,
                                  errorBuilder: (_, _, _) => _buildAvatarFallback(fallbackIcon, badgeColor, name, size: 30),
                                ))
                          : _buildAvatarFallback(fallbackIcon, badgeColor, name, size: 30),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(fallbackIcon, size: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              // Role Badge Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Full Untruncated Description Box
              if (desc != null && desc.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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

  static Widget _buildAvatarFallback(IconData icon, Color color, String name, {double size = 22}) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
        : '';

    if (initials.isNotEmpty && initials.length <= 2 && RegExp(r'^[A-Z0-9]+$').hasMatch(initials)) {
      return Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }

    return Center(
      child: Icon(icon, color: color, size: size + 4),
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
}
