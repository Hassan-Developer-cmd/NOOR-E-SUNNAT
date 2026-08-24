import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:islamic_app/core/utils/image_compression_helper.dart';

void main() {
  group('ImageCompressionHelper Automated Canvas Compression Tests', () {
    test('Compresses high-resolution image down to 1024px and guarantees < 200KB', () async {
      // Create a 2400x1600 synthetic RGB test image
      final highResImage = img.Image(width: 2400, height: 1600);
      for (int y = 0; y < 1600; y++) {
        for (int x = 0; x < 2400; x++) {
          highResImage.setPixelRgb(x, y, (x * 3) % 256, (y * 7) % 256, ((x + y) * 11) % 256);
        }
      }
      final rawPngBytes = Uint8List.fromList(img.encodePng(highResImage));
      expect(rawPngBytes.isNotEmpty, isTrue);

      // Run automated compression
      final result = await ImageCompressionHelper.compressImageBytes(
        rawPngBytes,
        maxWidth: 1024,
        maxHeight: 1024,
        initialQuality: 70,
        maxSizeKb: 200,
      );

      // Verify dimensions: max width is scaled to 1024px while keeping aspect ratio
      expect(result.width, equals(1024));
      expect(result.height, closeTo(683, 2));

      // Verify payload is well under 200 KB
      expect(result.sizeKb, lessThanOrEqualTo(200));
      expect(result.base64String.isNotEmpty, isTrue);

      // Decode compressed output to verify valid JPEG
      final decodedBytes = base64Decode(result.base64String);
      final decoded = img.decodeJpg(decodedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1024));
    });

    test('Preserves images that are already smaller than 1024px without upscaling', () async {
      final smallImage = img.Image(width: 400, height: 300);
      for (int y = 0; y < 300; y++) {
        for (int x = 0; x < 400; x++) {
          smallImage.setPixelRgb(x, y, 120, 180, 240);
        }
      }
      final rawBytes = Uint8List.fromList(img.encodePng(smallImage));

      final result = await ImageCompressionHelper.compressImageBytes(
        rawBytes,
        maxWidth: 1024,
        maxHeight: 1024,
        initialQuality: 70,
        maxSizeKb: 200,
      );

      expect(result.width, equals(400));
      expect(result.height, equals(300));
      expect(result.sizeKb, lessThanOrEqualTo(200));
    });

    test('Throws informative exception when invalid image bytes are provided', () async {
      final corruptBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      expect(
        () async => await ImageCompressionHelper.compressImageBytes(corruptBytes),
        throwsA(isA<Exception>()),
      );
    });
  });
}
