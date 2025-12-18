import 'package:flutter_test/flutter_test.dart';
import 'package:disney_princess_app/services/classifier_service.dart';
import 'package:image/image.dart' as img;

void main() {
  group('Classifier All Results Tests', () {
    late ClassifierService classifierService;

    setUp(() {
      classifierService = ClassifierService();
    });

    test('Classifier returns all 10 princess probabilities', () async {
      // Create a dummy image for testing
      final dummyImage = img.Image(width: 224, height: 224);
      
      // Test that the classifyImage method returns all 10 results
      final result = classifierService.classifyImage(dummyImage);
      
      // Check that allResults contains exactly 10 items (all princesses)
      final allResults = result['allResults'] as List;
      expect(allResults.length, 10, 
        reason: 'Should return probabilities for all 10 princesses');
      
      // Check that each result has the expected structure
      for (var resultItem in allResults) {
        expect(resultItem, isA<Map>());
        expect(resultItem.containsKey('label'), true);
        expect(resultItem.containsKey('confidence'), true);
        expect(resultItem['label'], isA<String>());
        expect(resultItem['confidence'], isA<String>());
      }
    });
    
    test('_getTopResults returns correct number of results', () {
      // Mock confidences for 10 princesses
      final confidences = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
      
      // Manually set labels to match our princesses
      classifierService.labels = [
        'anna', 'belle', 'ariel', 'cinderella', 'jasmine',
        'mulan', 'rapunzel', 'moana', 'elsa', 'merida'
      ];
      
      // Test getting top 10 results
      final topResults = classifierService._getTopResults(confidences, 10);
      expect(topResults.length, 10);
      
      // Check that confidence values are formatted with 1 decimal place
      final firstResult = topResults[0];
      final confidenceStr = firstResult['confidence'] as String;
      expect(confidenceStr.contains('.'), true, reason: 'Should contain decimal point');
      expect(confidenceStr.endsWith('%'), true, reason: 'Should end with %');
      
      // Test getting top 5 results (should still work)
      final topFiveResults = classifierService._getTopResults(confidences, 5);
      expect(topFiveResults.length, 5);
      
      // Test requesting more results than available (should return all available)
      final tooManyResults = classifierService._getTopResults(confidences, 15);
      expect(tooManyResults.length, 10); // Still only 10 because that's all we have
    });
  });
}