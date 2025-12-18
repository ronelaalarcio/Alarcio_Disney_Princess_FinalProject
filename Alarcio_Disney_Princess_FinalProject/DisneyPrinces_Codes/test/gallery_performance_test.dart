import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

void main() {
  group('Gallery Performance Tests', () {
    test('Image decoding and processing speed', () async {
      // Create a test image (224x224 RGB)
      final image = img.Image(width: 224, height: 224);
      
      // Fill with a simple pattern (gray)
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          image.setPixel(x, y, img.ColorRgb8(128, 128, 128));
        }
      }
      
      // Encode to JPEG bytes (simulating what happens when picking from gallery)
      final stopwatch = Stopwatch()..start();
      final encodedBytes = img.encodeJpg(image);
      stopwatch.stop();
      
      print('Image encoding took: ${stopwatch.elapsedMilliseconds}ms');
      expect(encodedBytes, isNotNull);
      expect(encodedBytes.length, greaterThan(0));
      
      // Decode the image (simulating what happens in _pickImageFromGallery)
      final decodeStopwatch = Stopwatch()..start();
      final decodedImage = img.decodeImage(encodedBytes);
      decodeStopwatch.stop();
      
      print('Image decoding took: ${decodeStopwatch.elapsedMilliseconds}ms');
      expect(decodedImage, isNotNull);
      
      // Orientation fix (simulating img.bakeOrientation)
      final orientationStopwatch = Stopwatch()..start();
      final orientedImage = img.bakeOrientation(decodedImage!);
      orientationStopwatch.stop();
      
      print('Orientation fix took: ${orientationStopwatch.elapsedMilliseconds}ms');
      expect(orientedImage, isNotNull);
    });
    
    test('Tensor conversion performance', () async {
      // Create a test image
      final image = img.Image(width: 224, height: 224);
      
      // Fill with a simple pattern
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          image.setPixel(x, y, img.ColorRgb8(128, 128, 128));
        }
      }
      
      // Simulate the tensor conversion process
      final tensorStopwatch = Stopwatch()..start();
      
      // Resize image
      final resized = img.copyResize(image, width: 224, height: 224);
      
      // Convert to tensor format (similar to _imageToByteListFloat32)
      final convertedBytes = Float32List(1 * 224 * 224 * 3);
      int pixelIndex = 0;
      
      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          // Normalize values (same as in _imageToByteListFloat32)
          convertedBytes[pixelIndex++] = (pixel.r.toDouble() - 127.5) / 127.5;
          convertedBytes[pixelIndex++] = (pixel.g.toDouble() - 127.5) / 127.5;
          convertedBytes[pixelIndex++] = (pixel.b.toDouble() - 127.5) / 127.5;
        }
      }
      
      tensorStopwatch.stop();
      final duration = tensorStopwatch.elapsedMilliseconds;
      
      print('Tensor conversion took: ${duration}ms');
      expect(convertedBytes.length, equals(1 * 224 * 224 * 3));
      
      // With debug prints removed, this should be much faster
      // Expect conversion to be reasonably fast (less than 100ms)
      expect(duration, lessThan(100));
    });
  });
}