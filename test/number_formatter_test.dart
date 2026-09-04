import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_app/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatter.formatCompact', () {
    test('formats numbers < 10,000 with commas', () {
      expect(NumberFormatter.formatCompact(0), '0');
      expect(NumberFormatter.formatCompact(450), '450');
      expect(NumberFormatter.formatCompact(1234), '1,234');
      expect(NumberFormatter.formatCompact(9842), '9,842');
      expect(NumberFormatter.formatCompact(9999), '9,999');
    });

    test('formats thousands (10k to < 1M) with K', () {
      expect(NumberFormatter.formatCompact(10000), '10 K');
      expect(NumberFormatter.formatCompact(12500), '12.5 K');
      expect(NumberFormatter.formatCompact(100000), '100 K');
      expect(NumberFormatter.formatCompact(999900), '999.9 K');
    });

    test('formats millions with M', () {
      expect(NumberFormatter.formatCompact(1000000), '1 M');
      expect(NumberFormatter.formatCompact(1200000), '1.2 M');
      expect(NumberFormatter.formatCompact(15000000), '15 M');
      expect(NumberFormatter.formatCompact(250400000), '250.4 M');
    });

    test('formats billions with B', () {
      expect(NumberFormatter.formatCompact(1000000000), '1 B');
      expect(NumberFormatter.formatCompact(1200000000), '1.2 B');
      expect(NumberFormatter.formatCompact(10000000000), '10 B');
    });

    test('formats trillions with T', () {
      expect(NumberFormatter.formatCompact(1000000000000), '1 T');
      expect(NumberFormatter.formatCompact(1200000000000), '1.2 T');
    });

    test('handles negative and zero numbers safely', () {
      expect(NumberFormatter.formatCompact(-12500), '-12.5 K');
      expect(NumberFormatter.formatCompact(-9842), '-9,842');
      expect(NumberFormatter.formatCompact(-0), '0');
    });
  });

  group('NumberFormatter.formatWithCommas', () {
    test('formats standard numbers with commas', () {
      expect(NumberFormatter.formatWithCommas(0), '0');
      expect(NumberFormatter.formatWithCommas(125000), '125,000');
      expect(NumberFormatter.formatWithCommas(123456789), '123,456,789');
    });
  });
}
