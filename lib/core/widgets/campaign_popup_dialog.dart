import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/campaign_popup_model.dart';
import '../../main.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/counter/presentation/counter_screen.dart';
import '../../features/knowledge_hub/presentation/aqaid_grid.dart';
import '../../features/knowledge_hub/presentation/masail_grid.dart';
import '../../features/knowledge_hub/presentation/qa_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../services/counter_service.dart';

class CampaignPopupDialog extends StatelessWidget {
  final CampaignPopupModel config;
  final bool isPreview;
  final bool? previewLanguageUrdu;

  const CampaignPopupDialog({
    super.key,
    required this.config,
    this.isPreview = false,
    this.previewLanguageUrdu,
  });

  /// Static helper to trigger the dialog with smooth scale and fade transition
  static Future<void> show(BuildContext context, CampaignPopupModel config) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      barrierLabel: 'Dismiss Campaign Popup',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return PopScope(
          canPop: true,
          child: CampaignPopupDialog(config: config),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  void _handleActionClick(BuildContext context) {
    if (isPreview) return;

    // First dismiss dialog
    Navigator.of(context, rootNavigator: true).pop();

    final target = config.targetRoute.toLowerCase().trim();

    if (target.contains('event')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpcomingEventsScreen()),
      );
    } else if (target.contains('counter') ||
        target.contains('durood') ||
        target.isEmpty ||
        target == '/home' ||
        target == 'home') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CounterScreen(counterService: CounterService()),
        ),
      );
    } else if (target.contains('aqaid')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AqaidGridScreen()),
      );
    } else if (target.contains('masail')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MasailGridScreen()),
      );
    } else if (target.contains('qa') || target.contains('question')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QAScreen()),
      );
    } else if (target.contains('profile')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(counterService: CounterService()),
        ),
      );
    } else {
      // Attempt generic named route navigation if defined, fallback to Counter
      try {
        Navigator.of(context).pushNamed(config.targetRoute);
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CounterScreen(counterService: CounterService()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) {
        final isUrdu = previewLanguageUrdu ?? globalLanguageProvider.isUrdu;
        final title = config.getTitle(isUrdu);
        final details = config.getDetails(isUrdu);
        final buttonText = config.getButtonText(isUrdu);
        final showBtn = config.showActionButton;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: isPreview ? double.infinity : 340,
              constraints: const BoxConstraints(maxWidth: 360),
              margin: EdgeInsets.symmetric(
                horizontal: isPreview ? 0 : 24,
                vertical: isPreview ? 0 : 20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF063B26), // Deep rich Islamic Emerald
                    Color(0xFF084B30), // Vibrant Forest Emerald
                    Color(0xFF042416), // Dark Midnight Emerald base
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.45),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.primaryEmerald.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Directionality(
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                child: Stack(
                  children: [
                    // Main Scrollable Content Layout
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Top Media / Banner Artwork (Top Section)
                          _buildTopGraphic(context),

                          // 2. Middle Content Section (Title, Divider & Body)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              22,
                              18,
                              22,
                              showBtn ? 16 : 24,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Campaign Title
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isUrdu ? 23 : 22,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    fontFamily: isUrdu
                                        ? AppTypography.urduFontFamily
                                        : AppTypography.englishFontFamily,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                      Shadow(
                                        color: const Color(0xFFFDE047).withValues(alpha: 0.25),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Subtle Decorative Gold Accent Divider
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 1.5,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            AppColors.accentGold.withValues(alpha: 0.8),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(
                                        Icons.auto_awesome,
                                        size: 13,
                                        color: AppColors.accentGold,
                                      ),
                                    ),
                                    Container(
                                      height: 1.5,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.accentGold.withValues(alpha: 0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Campaign Details / Body Text
                                Text(
                                  details,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: isUrdu ? 15 : 14,
                                    fontWeight: FontWeight.w400,
                                    height: 1.5,
                                    fontFamily: isUrdu
                                        ? AppTypography.urduFontFamily
                                        : AppTypography.englishFontFamily,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Bottom Action CTA Area
                          if (showBtn) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
                              child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4A017), // Rich Royal Gold
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: Colors.black45,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  onPressed: () => _handleActionClick(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        buttonText,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                          fontFamily: isUrdu
                                              ? AppTypography.urduFontFamily
                                              : AppTypography.englishFontFamily,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isUrdu
                                            ? Icons.arrow_back_rounded
                                            : Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  if (!isPreview) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                  }
                                },
                                child: Text(
                                  isUrdu ? 'بعد میں دیکھیں' : 'Maybe Later',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: isUrdu
                                        ? AppTypography.urduFontFamily
                                        : AppTypography.englishFontFamily,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  if (!isPreview) {
                                    Navigator.of(context, rootNavigator: true).pop();
                                  }
                                },
                                child: Text(
                                  isUrdu ? 'بند کریں' : 'Dismiss',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: isUrdu
                                        ? AppTypography.urduFontFamily
                                        : AppTypography.englishFontFamily,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),

                    // Floating Close 'X' Button at Top Corner (Top-Right in LTR / Top-Left in RTL)
                    PositionedDirectional(
                      top: 12,
                      end: 12,
                      child: GestureDetector(
                        onTap: () {
                          if (!isPreview) {
                            Navigator.of(context, rootNavigator: true).pop();
                          }
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the top half media banner with rounded top corners and a smooth bottom blend
  Widget _buildTopGraphic(BuildContext context) {
    final imageType = config.imageType;
    final imageUrl = config.imageUrl;
    final imageBase64 = config.imageBase64;

    Widget imageContent;

    // 1. Base64 Image
    if (imageType == CampaignPopupModel.imageTypeBase64 &&
        imageBase64 != null &&
        imageBase64.trim().isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64.trim());
        imageContent = Image.memory(
          bytes,
          width: double.infinity,
          height: 185,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultSpiritualBanner(),
        );
      } catch (_) {
        imageContent = _buildDefaultSpiritualBanner();
      }
    }
    // 2. Network Image URL
    else if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      imageContent = Image.network(
        imageUrl.trim(),
        width: double.infinity,
        height: 185,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 185,
            decoration: const BoxDecoration(color: Color(0xFF052B1B)),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentGold,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildDefaultSpiritualBanner(),
      );
    }
    // 3. High Quality Default Spiritual Graphic Banner
    else {
      imageContent = _buildDefaultSpiritualBanner();
    }

    return SizedBox(
      height: 185,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The Media Image
          imageContent,

          // Bottom Gradient Scrim (Smooth Transition into Card Body)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFF063B26),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSpiritualBanner() {
    return Container(
      width: double.infinity,
      height: 185,
      decoration: const BoxDecoration(
        color: Color(0xFF052B1B),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Masjid Nabawi background asset
          Image.asset(
            'assets/images/masjid_nabawi_header.jpeg',
            width: double.infinity,
            height: 185,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
          // Dark glass gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF063B26).withValues(alpha: 0.45),
                  const Color(0xFF084B30).withValues(alpha: 0.75),
                  const Color(0xFF063B26).withValues(alpha: 0.95),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Center Gumbad & Spiritual Embellishment
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A017).withValues(alpha: 0.22),
                  border: Border.all(color: const Color(0xFFFDE047), width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFDE047).withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: Color(0xFFFDE047),
                  size: 40,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD4A017).withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'صلوات و سلام',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
