import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../main.dart';
import '../../../../services/counter_service.dart';

class DuroodSummaryCard extends StatelessWidget {
  final CounterService counterService;
  final VoidCallback onSendSalawat;

  const DuroodSummaryCard({
    super.key,
    required this.counterService,
    required this.onSendSalawat,
  });

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(lp.tr('durood_count_summary'), style: AppTypography.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.emeraldContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      lp.tr('live_updates'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryEmerald,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  lp.tr('global_total'),
                  _fmt(counterService.snapshot.globalTotal),
                  Icons.public_rounded,
                  AppColors.primaryEmerald,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: AppColors.borderLight,
              ),
              Expanded(
                child: _buildStat(
                  lp.tr('my_today'),
                  _fmt(counterService.snapshot.personalToday),
                  Icons.today_rounded,
                  AppColors.accentGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTypography.statLabel,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: AppTypography.statValue),
        ),
      ],
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
