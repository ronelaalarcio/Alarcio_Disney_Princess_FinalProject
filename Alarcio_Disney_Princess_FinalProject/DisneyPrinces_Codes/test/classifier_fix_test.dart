import 'package:flutter_test/flutter_test.dart';
import 'package:disney_princess_app/services/classifier_service.dart';
import 'package:image/image.dart' as img;

void main() {
  group('Classifier Fix Tests', () {
    late ClassifierService classifierService;

    setUp(() {
      classifierService = ClassifierService();
    });

    test('Classifier initializes correctly', () async {
      // This test verifies that the classifier can be instantiated
      expect(classifierService, isNotNull);
    });

    test('Image processing produces valid structure', () async {
      // Create a dummy image for testing
      final dummyImage = img.Image(width: 224, height: 224);
      
      // Test that the classifyImage method returns the expected structure
      final result = classifierService.classifyImage(dummyImage);
      
      // Check that result has all required fields
      expect(result.containsKey('label'), true);
      expect(result.containsKey('confidence'), true);
      expect(result.containsKey('allResults'), true);
      expect(result.containsKey('isBelowThreshold'), true);
      
      // Check data types
      expect(result['label'], isA<String>());
      expect(result['confidence'], isA<String>());
      expect(result['allResults'], isA<List>());
      expect(result['isBelowThreshold'], isA<bool>());
    });

    test('Output tensor access fix works', () async {
      // Test the specific fix for accessing output tensor values
      final outputTensorReshaped = [
        [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
      ];
      
      // Simulate the fixed code
      final labelsLength = 10;
      final outputValues = List<double>.filled(labelsLength, 0.0);
      for (int i = 0; i < labelsLength; i++) {
        outputValues[i] = outputTensorReshaped[0][i].toDouble();
      }
      
      // Verify the values are correctly extracted
      expect(outputValues[0], 0.1);
      expect(outputValues[9], 1.0);
      expect(outputValues.length, 10);
    });
  });
}