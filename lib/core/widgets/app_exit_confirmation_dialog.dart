import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../main.dart';

class AppExitConfirmationDialog extends StatelessWidget {
  const AppExitConfirmationDialog({super.key});

  /// Static helper to display the exit confirmation dialog and return true if confirmed.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AppExitConfirmationDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    return Directionality(
      textDirection: lp.textDirection,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 12,
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon Badge with Emerald & Gold Glow
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emeraldContainer,
                    border: Border.all(
                      color: AppColors.primaryEmerald.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      size: 32,
                      color: AppColors.primaryEmerald,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Dialog Title
                Text(
                  lp.tr('exit_app_title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: isUrdu
                        ? AppTypography.urduFontFamily
                        : AppTypography.englishFontFamily,
                    fontSize: isUrdu ? 20 : 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emeraldDeep,
                    height: isUrdu ? 1.4 : 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                // Dialog Message Body
                Text(
                  lp.tr('exit_app_msg'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: isUrdu
                        ? AppTypography.urduFontFamily
                        : AppTypography.englishFontFamily,
                    fontSize: isUrdu ? 14.5 : 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: isUrdu ? 1.65 : 1.45,
                  ),
                ),
                const SizedBox(height: 28),

                // Action Buttons (Cancel & Exit)
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          backgroundColor: const Color(0xFFF3F4F6),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          lp.tr('exit_app_cancel'),
                          style: TextStyle(
                            fontFamily: isUrdu
                                ? AppTypography.urduFontFamily
                                : AppTypography.englishFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Exit App Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: AppColors.primaryEmerald.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.exit_to_app_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                lp.tr('exit_app_action'),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: isUrdu
                                      ? AppTypography.urduFontFamily
                                      : AppTypography.englishFontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
