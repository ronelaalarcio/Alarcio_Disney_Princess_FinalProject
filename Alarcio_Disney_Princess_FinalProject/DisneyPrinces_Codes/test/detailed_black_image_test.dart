import 'package:flutter_test/flutter_test.dart';
import 'package:disney_princess_app/services/classifier_service.dart';
import 'package:image/image.dart' as img;

void main() {
  group('Detailed Black Image Detection Tests', () {
    late ClassifierService classifierService;

    setUp(() {
      classifierService = ClassifierService();
    });

    test('Create and analyze black image pixel data', () {
      // Create a completely black image
      final blackImage = img.Image(width: 10, height: 10);
      
      // Fill the image with black pixels
      for (int y = 0; y < blackImage.height; y++) {
        for (int x = 0; x < blackImage.width; x++) {
          blackImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      
      // Check each pixel manually
      print('Analyzing black image pixels:');
      bool hasNonBlackPixel = false;
      for (int y = 0; y < blackImage.height; y++) {
        for (int x = 0; x < blackImage.width; x++) {
          final pixel = blackImage.getPixel(x, y);
          print('Pixel ($x,$y): R=${pixel.r}, G=${pixel.g}, B=${pixel.b}');
          if (pixel.r != 0 || pixel.g != 0 || pixel.b != 0) {
            hasNonBlackPixel = true;
          }
        }
      }
      
      expect(hasNonBlackPixel, false, reason: 'Black image should not have non-black pixels');
      
      // Test the isImageCompletelyBlack method
      final isBlack = classifierService.isImageCompletelyBlack(blackImage);
      print('isImageCompletelyBlack result: $isBlack');
      expect(isBlack, true, reason: 'Completely black image should be detected as black');
    });
    
    test('Create and analyze non-black image pixel data', () {
      // Create an image with some colored pixels
      final coloredImage = img.Image(width: 10, height: 10);
      
      // Fill most of the image with black but add some colored pixels
      for (int y = 0; y < coloredImage.height; y++) {
        for (int x = 0; x < coloredImage.width; x++) {
          coloredImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      
      // Add some non-black pixels
      coloredImage.setPixel(5, 5, img.ColorRgb8(255, 255, 255));
      coloredImage.setPixel(7, 7, img.ColorRgb8(128, 64, 32));
      
      // Check each pixel manually
      print('Analyzing colored image pixels:');
      bool hasNonBlackPixel = false;
      for (int y = 0; y < coloredImage.height; y++) {
        for (int x = 0; x < coloredImage.width; x++) {
          final pixel = coloredImage.getPixel(x, y);
          print('Pixel ($x,$y): R=${pixel.r}, G=${pixel.g}, B=${pixel.b}');
          if (pixel.r != 0 || pixel.g != 0 || pixel.b != 0) {
            hasNonBlackPixel = true;
          }
        }
      }
      
      expect(hasNonBlackPixel, true, reason: 'Colored image should have non-black pixels');
      
      // Test the isImageCompletelyBlack method
      final isBlack = classifierService.isImageCompletelyBlack(coloredImage);
      print('isImageCompletelyBlack result: $isBlack');
      expect(isBlack, false, reason: 'Image with colored pixels should not be detected as black');
    });
  });
}