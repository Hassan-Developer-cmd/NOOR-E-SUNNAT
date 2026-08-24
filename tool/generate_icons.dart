// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final sourceFile = File('assets/images/NOOR E SUNNAT.jpeg');
  if (!sourceFile.existsSync()) {
    print('Source file does not exist: ${sourceFile.path}');
    exit(1);
  }

  final bytes = sourceFile.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Failed to decode image.');
    exit(1);
  }

  print('Original image dimensions: ${image.width}x${image.height}');

  // 1. Assets Image: app_logo.png
  final appLogoPng = img.encodePng(image);
  File('assets/images/app_logo.png').writeAsBytesSync(appLogoPng);
  print('Saved assets/images/app_logo.png');

  // Helper function to resize and save PNG
  void saveResizedPng(String outputPath, int width, int height) {
    final resized = img.copyResize(image, width: width, height: height, interpolation: img.Interpolation.cubic);
    final pngBytes = img.encodePng(resized);
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(pngBytes);
    print('Saved $outputPath (${width}x$height)');
  }

  // 2. Web Icons
  saveResizedPng('web/favicon.png', 64, 64);
  saveResizedPng('web/icons/Icon-192.png', 192, 192);
  saveResizedPng('web/icons/Icon-512.png', 512, 512);
  saveResizedPng('web/icons/Icon-maskable-192.png', 192, 192);
  saveResizedPng('web/icons/Icon-maskable-512.png', 512, 512);

  // 3. Android Mipmap Icons
  saveResizedPng('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48, 48);
  saveResizedPng('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72, 72);
  saveResizedPng('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96, 96);
  saveResizedPng('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144, 144);
  saveResizedPng('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192, 192);

  // 4. iOS AppIcon set
  final iosPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  saveResizedPng('$iosPath/Icon-App-20x20@1x.png', 20, 20);
  saveResizedPng('$iosPath/Icon-App-20x20@2x.png', 40, 40);
  saveResizedPng('$iosPath/Icon-App-20x20@3x.png', 60, 60);
  saveResizedPng('$iosPath/Icon-App-29x29@1x.png', 29, 29);
  saveResizedPng('$iosPath/Icon-App-29x29@2x.png', 58, 58);
  saveResizedPng('$iosPath/Icon-App-29x29@3x.png', 87, 87);
  saveResizedPng('$iosPath/Icon-App-40x40@1x.png', 40, 40);
  saveResizedPng('$iosPath/Icon-App-40x40@2x.png', 80, 80);
  saveResizedPng('$iosPath/Icon-App-40x40@3x.png', 120, 120);
  saveResizedPng('$iosPath/Icon-App-60x60@2x.png', 120, 120);
  saveResizedPng('$iosPath/Icon-App-60x60@3x.png', 180, 180);
  saveResizedPng('$iosPath/Icon-App-76x76@1x.png', 76, 76);
  saveResizedPng('$iosPath/Icon-App-76x76@2x.png', 152, 152);
  saveResizedPng('$iosPath/Icon-App-83.5x83.5@2x.png', 167, 167);
  saveResizedPng('$iosPath/Icon-App-1024x1024@1x.png', 1024, 1024);

  // 5. Windows icon
  try {
    final icoFile = File('windows/runner/resources/app_icon.ico');
    if (icoFile.parent.existsSync()) {
      final icoEncoder = img.IcoEncoder();
      final img16 = img.copyResize(image, width: 16, height: 16);
      final img32 = img.copyResize(image, width: 32, height: 32);
      final img48 = img.copyResize(image, width: 48, height: 48);
      final img256 = img.copyResize(image, width: 256, height: 256);
      final icoBytes = icoEncoder.encodeImages([img16, img32, img48, img256]);
      icoFile.writeAsBytesSync(icoBytes);
      print('Saved windows/runner/resources/app_icon.ico');
    }
  } catch (e) {
    print('Windows ICO generation optional note: $e');
  }

  print('\nAll mobile and web app icons updated successfully!');
}
