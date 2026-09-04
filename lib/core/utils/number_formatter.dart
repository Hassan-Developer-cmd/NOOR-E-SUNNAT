/// Utility class for formatting numbers across the app.
class NumberFormatter {
  const NumberFormatter._();

  /// Converts numbers >= 10,000 into standard compact suffixes (K, M, B, T):
  /// - Under 10,000: Full number with commas (e.g., 0, 450, 9,999)
  /// - 10K - 999K: "X.XK" or "XXK" (e.g., 12.5K, 100K)
  /// - 1M - 999M: "X.XM" (e.g., 1.2M)
  /// - 1B - 999B: "X.XB" (e.g., 1.2B)
  /// - 1T+: "X.XT" (e.g., 1.2T)
  static String formatCompact(num value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value < 0) {
      return '-${formatCompact(-value)}';
    }

    if (value < 10000) {
      // Show full integer with commas for values below 10k (e.g. 9,999)
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } else if (value < 1000000) {
      // 10K - 999K
      final double formatted = value / 1000;
      return '${formatted.toStringAsFixed(formatted % 1 == 0 ? 0 : 1)}K';
    } else if (value < 1000000000) {
      // 1M - 999M
      final double formatted = value / 1000000;
      return '${formatted.toStringAsFixed(formatted % 1 == 0 ? 0 : 1)}M';
    } else if (value < 1000000000000) {
      // 1B - 999B
      final double formatted = value / 1000000000;
      return '${formatted.toStringAsFixed(formatted % 1 == 0 ? 0 : 1)}B';
    } else {
      // 1T+
      final double formatted = value / 1000000000000;
      return '${formatted.toStringAsFixed(formatted % 1 == 0 ? 0 : 1)}T';
    }
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
}
