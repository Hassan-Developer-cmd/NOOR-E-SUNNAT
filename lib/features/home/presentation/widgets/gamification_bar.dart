import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../main.dart';

class GamificationBar extends StatelessWidget {
  final int streakDays;
  final int duroodPoints;

  const GamificationBar({
    super.key,
    required this.streakDays,
    required this.duroodPoints,
  });

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: lp.tr('current_streak'),
            value: '$streakDays ${lp.tr('streak_days')}',
            iconWidget: const Icon(Icons.local_fire_department_rounded,
                size: 20, color: Color(0xFFEA580C)),
            accentColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFED7AA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            label: lp.tr('durood_points'),
            value: '$duroodPoints',
            iconWidget: const Icon(Icons.star_rounded,
                size: 20, color: AppColors.accentGold),
            accentColor: AppColors.goldLight,
            borderColor: const Color(0xFFF5D77E),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget iconWidget;
  final Color accentColor;
  final Color borderColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.iconWidget,
    required this.accentColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    label,
                    style: AppTypography.caption,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
