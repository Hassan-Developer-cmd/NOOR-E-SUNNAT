import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class BulkChips extends StatelessWidget {
  final Function(int) onAddBulk;
  final VoidCallback onCustomAdd;

  const BulkChips({
    super.key,
    required this.onAddBulk,
    required this.onCustomAdd,
  });

  @override
  Widget build(BuildContext context) {
    const presets = [100, 200, 500, 1000];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('QUICK ADD', style: AppTypography.labelUppercase),
        const SizedBox(height: 10),
        Row(
          children: [
            // Preset chips
            Expanded(
              child: Row(
                children: presets.map((count) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: count != presets.last ? 6 : 0,
                      ),
                      child: _ChipButton(
                        label: '+$count',
                        onTap: () => onAddBulk(count),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 6),
            // Custom add
            GestureDetector(
              onTap: onCustomAdd,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryEmerald,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryEmerald,
            ),
          ),
        ),
      ),
    );
  }
}
