import 'package:flutter_test/flutter_test.dart';
import 'package:disney_princess_app/services/classifier_service.dart';
import 'package:image/image.dart' as img;

void main() {
  group('Comprehensive Black Image Detection Tests', () {
    late ClassifierService classifierService;

    setUp(() {
      classifierService = ClassifierService();
    });

    test('Black image detection at different stages', () {
      // Create a completely black image
      final blackImage = img.Image(width: 224, height: 224);
      
      // Fill the image with black pixels
      for (int y = 0; y < blackImage.height; y++) {
        for (int x = 0; x < blackImage.width; x++) {
          blackImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      
      print('Testing black image detection...');
      
      // Test detection on original image
      final isBlackOriginal = classifierService.isImageCompletelyBlack(blackImage);
      expect(isBlackOriginal, true, reason: 'Original black image should be detected as black');
      
      // Test the full classification pipeline would return zero confidence
      // Note: We can't fully test this without a real model, but we can verify the logic
      print('Black image detection working correctly');
    });
    
    test('Non-black image detection', () {
      // Create an image with some colored pixels
      final coloredImage = img.Image(width: 224, height: 224);
      
      // Fill most of the image with black but add some colored pixels
      for (int y = 0; y < coloredImage.height; y++) {
        for (int x = 0; x < coloredImage.width; x++) {
          coloredImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      
      // Add some non-black pixels
      coloredImage.setPixel(100, 100, img.ColorRgb8(255, 255, 255));
      coloredImage.setPixel(150, 150, img.ColorRgb8(128, 64, 32));
      
      // Test detection
      final isBlack = classifierService.isImageCompletelyBlack(coloredImage);
      expect(isBlack, false, reason: 'Image with colored pixels should not be detected as black');
    });
    
    test('Edge case: Nearly black image', () {
      // Create an image that's mostly black but with very dim pixels
      final nearlyBlackImage = img.Image(width: 224, height: 224);
      
      // Fill most of the image with black
      for (int y = 0; y < nearlyBlackImage.height; y++) {
        for (int x = 0; x < nearlyBlackImage.width; x++) {
          nearlyBlackImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      
      // Add some very dim pixels (near black)
      nearlyBlackImage.setPixel(100, 100, img.ColorRgb8(1, 1, 1));
      nearlyBlackImage.setPixel(150, 150, img.ColorRgb8(2, 2, 2));
      
      // This should still be detected as black since the pixels are nearly black
      final isBlack = classifierService.isImageCompletelyBlack(nearlyBlackImage);
      // Note: Depending on implementation, this might return true or false
      print('Nearly black image detection result: $isBlack');
    });
  });
}