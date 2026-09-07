import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../main.dart';
import '../../../services/counter_service.dart';
import 'widgets/stat_card.dart';
import 'widgets/counter_button.dart';
import 'widgets/bulk_chips.dart';

class CounterScreen extends StatefulWidget {
  final CounterService counterService;

  const CounterScreen({super.key, required this.counterService});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final bool _hapticsEnabled = true;
  int _dailyTargetGoal = 500;


  void _confirmBulkAddDialog(BuildContext context, int amount) {
    final lp = globalLanguageProvider;
    final isUrdu = lp.isUrdu;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.emeraldContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.primaryEmerald,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUrdu ? 'درود پاک کے شمار کی تصدیق' : 'Confirm Durood Addition',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0A3A2A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isUrdu
              ? 'کیا آپ واقعی $amount بار درود پاک شامل کرنا چاہتے ہیں؟'
              : 'Are you sure to add $amount Durood?',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF334155),
            height: 1.4,
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderLight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(
              isUrdu ? 'منسوخ' : 'Cancel',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A3A2A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              if (_hapticsEnabled) HapticFeedback.mediumImpact();
              widget.counterService.addBulkDurood(amount);
            },
            child: Text(
              isUrdu ? 'تصدیق کریں' : 'Confirm',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomAddDialog(BuildContext context) {
    final lp = globalLanguageProvider;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lp.tr('bulk_add_recitations'), style: AppTypography.headingMedium),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: lp.tr('enter_count_hint'),
            prefixIcon: const Icon(Icons.format_list_numbered_rounded,
                color: AppColors.primaryEmerald, size: 18),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(lp.tr('cancel'),
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text);
              Navigator.of(context, rootNavigator: true).pop();
              if (count != null && count > 0) {
                _confirmBulkAddDialog(context, count);
              }
            },
            child: Text(lp.tr('add_recitations')),
          ),
        ],
      ),
    );
  }

  void _showSetGoalDialog(BuildContext context) {
    final lp = globalLanguageProvider;
    final controller = TextEditingController(text: _dailyTargetGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          lp.isUrdu ? 'روزانہ کا ہدف مقرر کریں' : 'Set Daily Durood Goal',
          style: AppTypography.titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 100, 500, 1000',
                prefixIcon: const Icon(Icons.flag_rounded, color: AppColors.primaryEmerald),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [100, 300, 500, 1000, 5000].map((goal) {
                return ActionChip(
                  label: Text('$goal'),
                  onPressed: () {
                    controller.text = goal.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(lp.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0) {
                setState(() => _dailyTargetGoal = goal);
              }
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(lp.isUrdu ? 'محفوظ کریں' : 'Save Goal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = globalLanguageProvider;
    final screenWidth = MediaQuery.of(context).size.width;
    final statCrossAxisCount = screenWidth >= 600 ? 4 : 2;

    return ListenableBuilder(
      listenable: globalLanguageProvider,
      builder: (context, _) => StreamBuilder<CounterSnapshot>(
        stream: widget.counterService.snapshotStream,
        initialData: widget.counterService.snapshot,
        builder: (context, snapshot) {
          final snap = snapshot.data ?? widget.counterService.snapshot;

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
            stream: widget.counterService.userCounterStream,
            builder: (context, userSnap) {
              final userData = userSnap.data?.data();
              final int? cloudMyTotal = (userData?['myTotal'] as num?)?.toInt();
              final int effectiveMyTotal = (cloudMyTotal != null)
                  ? math.max(snap.personalTotal, cloudMyTotal + widget.counterService.pendingBuffer)
                  : snap.personalTotal;

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                stream: widget.counterService.userDailyStatsStream,
                builder: (context, dailySnap) {
                  final dailyData = dailySnap.data?.data();
                  final int? cloudMyToday = ((dailyData?['myToday'] ?? dailyData?['todayCount']) as num?)?.toInt();
                  final int effectiveMyToday = (cloudMyToday != null)
                      ? math.max(snap.personalToday, cloudMyToday + widget.counterService.pendingBuffer)
                      : snap.personalToday;

                  final double goalProgress = (_dailyTargetGoal > 0)
                      ? (effectiveMyToday / _dailyTargetGoal).clamp(0.0, 1.0)
                      : 0.0;
                  final int percentVal = (goalProgress * 100).toInt();

                  return Scaffold(
                    backgroundColor: AppColors.bgPrimary,
                    appBar: AppBar(
                      centerTitle: true,
                      title: Text(
                        lp.tr('durood_counter'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      actions: [
                        // Language toggle button
                        GestureDetector(
                          onTap: () => lp.toggleLanguage(),
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              lp.isUrdu ? 'EN' : 'اردو',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    body: SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 32 > 0 ? constraints.maxHeight - 32 : 500,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // ── Responsive Stats Grid ──
                                  GridView.count(
                                    crossAxisCount: statCrossAxisCount,
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: screenWidth >= 600 ? 2.2 : 1.6,
                                    children: [
                                      StatCard(
                                        title: lp.tr('global_total'),
                                        value: NumberFormatter.formatCompact(snap.globalTotal),
                                        icon: Icons.public_rounded,
                                      ),
                                      StatCard(
                                        title: lp.tr('global_today'),
                                        value: NumberFormatter.formatCompact(snap.globalToday),
                                        icon: Icons.today_rounded,
                                        iconColor: AppColors.accentGold,
                                      ),
                                      StatCard(
                                        title: lp.tr('my_total'),
                                        value: NumberFormatter.formatCompact(effectiveMyTotal),
                                        icon: Icons.account_circle_rounded,
                                      ),
                                      StatCard(
                                        title: lp.tr('my_today'),
                                        value: NumberFormatter.formatCompact(effectiveMyToday),
                                        icon: Icons.timer_rounded,
                                        iconColor: AppColors.accentGold,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // ── Target Goal Tracker Card ──
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.borderLight),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.flag_rounded, color: AppColors.accentGold, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  lp.isUrdu ? 'روزانہ کا ہدف' : 'Daily Goal Target',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: InkWell(
                                                onTap: () => _showSetGoalDialog(context),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.emeraldContainer,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _formatCount(_dailyTargetGoal),
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.primaryEmerald,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Icon(Icons.edit_rounded, size: 12, color: AppColors.primaryEmerald),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Progress Bar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: LinearProgressIndicator(
                                            value: goalProgress,
                                            backgroundColor: AppColors.bgOffWhite,
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryEmerald),
                                            minHeight: 8,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Goal Progress text
                                        Align(
                                          alignment: AlignmentDirectional.centerEnd,
                                          child: Text(
                                            '$percentVal% ${lp.isUrdu ? 'مکمل' : 'Completed'}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // ── Counter Button Centered ──
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: CounterButton(
                                      onTap: () {
                                        if (_hapticsEnabled) {
                                          HapticFeedback.selectionClick();
                                        }
                                        widget.counterService.increment(1);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // ── Bulk Chips ──
                                  BulkChips(
                                    onAddBulk: (amount) {
                                      _confirmBulkAddDialog(context, amount);
                                    },
                                    onCustomAdd: () => _showCustomAddDialog(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatCount(int val) => NumberFormatter.formatCompact(val);
}
