import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:math';

void main() {
  group('Performance Tests', () {
    test('Image processing speed test', () async {
      // Create a test image
      final image = img.Image(width: 224, height: 224);
      
      // Fill with random colors to simulate a real image
      final rand = Random();
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final r = rand.nextInt(256);
          final g = rand.nextInt(256);
          final b = rand.nextInt(256);
          image.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
      
      // Measure processing time
      final stopwatch = Stopwatch()..start();
      
      // Simulate image processing (resize, convert to tensor, etc.)
      final resized = img.copyResize(image, width: 224, height: 224);
      expect(resized, isNotNull);
      
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      
      // This should be fast now that we've removed debug prints
      print('Image processing took ${duration}ms');
      
      // Expect processing to be reasonably fast (less than 500ms)
      expect(duration, lessThan(500));
    });
    
    test('Tensor conversion speed test', () async {
      // Create a test image
      final image = img.Image(width: 224, height: 224);
      
      // Fill with a simple pattern
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          image.setPixel(x, y, img.ColorRgb8(128, 128, 128));
        }
      }
      
      // Measure tensor conversion time
      final stopwatch = Stopwatch()..start();
      
      // Convert to tensor format (simulating what _imageToByteListFloat32 does)
      final convertedBytes = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = image.getPixel(x, y);
          // Normalize values (same as in _imageToByteListFloat32)
          convertedBytes[pixelIndex++] = (pixel.r.toDouble() - 127.5) / 127.5;
          convertedBytes[pixelIndex++] = (pixel.g.toDouble() - 127.5) / 127.5;
          convertedBytes[pixelIndex++] = (pixel.b.toDouble() - 127.5) / 127.5;
        }
      }
      
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      
      print('Tensor conversion took ${duration}ms');
      
      // Expect conversion to be reasonably fast (less than 200ms)
      expect(duration, lessThan(200));
    });
  });
}