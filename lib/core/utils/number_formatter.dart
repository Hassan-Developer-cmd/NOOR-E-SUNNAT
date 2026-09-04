/// Utility class for formatting numbers across the app.
class NumberFormatter {
  const NumberFormatter._();

  /// Formats a number with compact representation:
  /// - < 10,000: Full number with commas (e.g., 0, 450, 9,842)
  /// - 10,000 to < 1,000,000: "X.X K" or "XX K" (e.g., 12.5 K, 100 K)
  /// - 1,000,000 to < 1,000,000,000: "X.X M" (e.g., 1.2 M)
  /// - 1,000,000,000 to < 1,000,000,000,000: "X.X B" (e.g., 1.2 B)
  /// - 1,000,000,000,000+: "X.X T" (e.g., 1.2 T)
  static String formatCompact(num value) {
    if (value.isNaN || value.isInfinite) return '0';
    final isNegative = value < 0;
    final absVal = value.abs();

    if (absVal < 10000) {
      final formatted = formatWithCommas(absVal.truncate());
      return isNegative ? '-$formatted' : formatted;
    }

    String formatted;
    if (absVal < 1000000) {
      formatted = _formatCompactUnit(absVal / 1000, 'K');
    } else if (absVal < 1000000000) {
      formatted = _formatCompactUnit(absVal / 1000000, 'M');
    } else if (absVal < 1000000000000) {
      formatted = _formatCompactUnit(absVal / 1000000000, 'B');
    } else {
      formatted = _formatCompactUnit(absVal / 1000000000000, 'T');
    }

    return isNegative ? '-$formatted' : formatted;
  }

  /// Formats an integer or number with commas (e.g., 125,000).
  static String formatWithCommas(num value) {
    if (value.isNaN || value.isInfinite) return '0';
    final isNegative = value < 0;
    final intPart = value.abs().truncate().toString();
    final formatted = intPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return isNegative ? '-$formatted' : formatted;
  }

  static String _formatCompactUnit(double number, String unit) {
    final fixed = number.toStringAsFixed(1);
    if (fixed.endsWith('.0')) {
      return '${fixed.substring(0, fixed.length - 2)} $unit';
    }
    return '$fixed $unit';
  }
}
