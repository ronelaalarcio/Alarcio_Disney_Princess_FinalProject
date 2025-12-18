import 'package:flutter_test/flutter_test.dart';
import 'package:disney_princess_app/services/classifier_service.dart';
import 'package:image/image.dart' as img;

void main() {
  group('Camera and Gallery Black Image Handling Tests', () {
    late ClassifierService classifierService;

    setUp(() {
      classifierService = ClassifierService();
    });

    test('Black image detection works for both camera and gallery', () {
      // Create a completely black image
      final blackImage = img.Image(width: 224, height: 224);
      
      // Fill the image with black pixels
      for (int y = 0; y < blackImage.height; y++) {
        for (int x = 0; x < blackImage.width; x++) {
          blackImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      
      // Test the isImageCompletelyBlack method
      final isBlack = classifierService.isImageCompletelyBlack(blackImage);
      expect(isBlack, true, reason: 'Completely black image should be detected as black');
      
      // Test the _isImageVeryDark method
      final isVeryDark = classifierService._isImageVeryDark(blackImage);
      expect(isVeryDark, true, reason: 'Completely black image should be detected as very dark');
    });
    
    test('Non-black image detection works correctly', () {
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
      
      // Test the isImageCompletelyBlack method
      final isBlack = classifierService.isImageCompletelyBlack(coloredImage);
      expect(isBlack, false, reason: 'Image with colored pixels should not be detected as black');
      
      // Test the _isImageVeryDark method
      final isVeryDark = classifierService._isImageVeryDark(coloredImage);
      expect(isVeryDark, false, reason: 'Image with bright pixels should not be detected as very dark');
    });
    
    test('Very dark image detection works correctly', () {
      // Create an image that's very dark but not completely black
      final darkImage = img.Image(width: 224, height: 224);
      
      // Fill the image with very dark pixels (but not black)
      for (int y = 0; y < darkImage.height; y++) {
        for (int x = 0; x < darkImage.width; x++) {
          darkImage.setPixel(x, y, img.ColorRgb8(5, 5, 5)); // Very dark gray
        }
      }
      
      // Test the isImageCompletelyBlack method
      final isBlack = classifierService.isImageCompletelyBlack(darkImage);
      expect(isBlack, false, reason: 'Very dark image should not be detected as completely black');
      
      // Test the _isImageVeryDark method
      final isVeryDark = classifierService._isImageVeryDark(darkImage);
      expect(isVeryDark, true, reason: 'Very dark image should be detected as very dark');
    });
  });
}