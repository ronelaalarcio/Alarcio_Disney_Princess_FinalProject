import 'package:flutter_test/flutter_test.dart';
import 'package:disney_princess_app/services/classifier_service.dart';
import 'package:image/image.dart' as img;

void main() {
  group('Black Image Detection Tests', () {
    late ClassifierService classifierService;

    setUp(() {
      classifierService = ClassifierService();
    });

    test('Completely black image returns zero confidence', () {
      // Create a completely black image
      final blackImage = img.Image(width: 224, height: 224);
      
      // Fill the image with black pixels
      for (int y = 0; y < blackImage.height; y++) {
        for (int x = 0; x < blackImage.width; x++) {
          blackImage.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      
      // Test the isImageCompletelyBlack helper method
      final isBlack = classifierService.isImageCompletelyBlack(blackImage);
      expect(isBlack, true, reason: 'Completely black image should be detected as black');
    });
    
    test('Non-black image is not detected as black', () {
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
      
      // Test the isImageCompletelyBlack helper method
      final isBlack = classifierService.isImageCompletelyBlack(coloredImage);
      expect(isBlack, false, reason: 'Image with colored pixels should not be detected as black');
    });
    
    test('Empty image is handled gracefully', () {
      // Create an empty image
      final emptyImage = img.Image(width: 0, height: 0);
      
      // This should not throw an exception
      expect(() => classifierService.isImageCompletelyBlack(emptyImage), returnsNormally);
    });
  });
}