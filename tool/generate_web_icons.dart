import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final logoFile = File('assets/images/NOOR E SUNNAT.jpeg');
  if (!logoFile.existsSync()) {
    print('Error: assets/images/NOOR E SUNNAT.jpeg not found!');
    exit(1);
  }

  final bytes = logoFile.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Error: Failed to decode image!');
    exit(1);
  }

  print('Original image decoded: ${image.width}x${image.height}');

  // 1. Favicon (64x64 PNG)
  final favicon = img.copyResize(image, width: 64, height: 64, interpolation: img.Interpolation.cubic);
  File('web/favicon.png').writeAsBytesSync(img.encodePng(favicon));
  print('Generated web/favicon.png (64x64)');

  // 2. Icon-192 (192x192 PNG)
  final icon192 = img.copyResize(image, width: 192, height: 192, interpolation: img.Interpolation.cubic);
  File('web/icons/Icon-192.png').writeAsBytesSync(img.encodePng(icon192));
  File('web/icons/Icon-maskable-192.png').writeAsBytesSync(img.encodePng(icon192));
  print('Generated web/icons/Icon-192.png & Icon-maskable-192.png (192x192)');

  // 3. Icon-512 (512x512 PNG)
  final icon512 = img.copyResize(image, width: 512, height: 512, interpolation: img.Interpolation.cubic);
  File('web/icons/Icon-512.png').writeAsBytesSync(img.encodePng(icon512));
  File('web/icons/Icon-maskable-512.png').writeAsBytesSync(img.encodePng(icon512));
  print('Generated web/icons/Icon-512.png & Icon-maskable-512.png (512x512)');

  print('All web icons successfully generated from NOOR E SUNNAT brand asset!');
}
