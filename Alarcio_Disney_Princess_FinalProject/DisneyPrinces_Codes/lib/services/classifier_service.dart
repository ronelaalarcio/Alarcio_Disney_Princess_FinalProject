import 'dart:typed_data' show Uint8List, Float32List;
import 'dart:math' as Math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../utils/memory_manager.dart';

class ClassifierService {
  static final ClassifierService _instance = ClassifierService._internal();
  
  Interpreter? _interpreter;
  late List<String> labels;
  bool isInitialized = false;
  bool _isInitializing = false;
  static Uint8List? _modelData;
  bool _initializationAttempted = false;

  ClassifierService._internal();

  factory ClassifierService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }
    
    if (_isInitializing) {
      try {
        await Future.any([
          _waitForInitialization(),
          Future.delayed(const Duration(seconds: 5)),
        ]);
      } catch (e) {
        // Waiting for classifier initialization timed out
      }
      return;
    }
    
    if (_initializationAttempted && !isInitialized) {
      // Reset state to allow retry
      _initializationAttempted = false;
    }
    
    _isInitializing = true;
    _initializationAttempted = true;
    
    try {
      // Optimize interpreter options for faster initialization
      final options = InterpreterOptions()
        ..threads = MemoryManager.getOptimalThreadCount();
      
      if (_modelData == null) {
        // Load model from assets
        final modelFile = await rootBundle.load('assets/model_unquant.tflite');
        _modelData = modelFile.buffer.asUint8List();
      }
      
      // Initialize interpreter
      _interpreter = await Interpreter.fromBuffer(
        _modelData!,
        options: options,
      );
      
      // Load labels from assets
      labels = await _loadLabels('assets/labels.txt') ?? [];
      
      if (labels.isEmpty) {
        throw Exception('No labels loaded from assets');
      }
      
      isInitialized = true;
    } catch (e) {
      // Reset initialization state so we can try again
      _cleanup();
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }
  
  // Helper method to cleanup resources
  void _cleanup() {
    _interpreter?.close();
    _interpreter = null;
    isInitialized = false;
    _isInitializing = false;
    // Don't reset _initializationAttempted here to prevent infinite retries
  }
  
  // Improved waitForInitialization with better error handling
  Future<void> _waitForInitialization() async {
    int attempts = 0;
    const maxAttempts = 50; // 5 seconds with 100ms delays
    while (_isInitializing && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    if (_isInitializing) {
      throw Exception('Classifier initialization timeout');
    }
  }

  Future<List<String>?> _loadLabels(String labelsPath) async {
    try {
      final labelData = await rootBundle.loadString(labelsPath);
      return labelData.split('\n').where((line) => line.isNotEmpty).map((line) {
        final parts = line.split(' ');
        return parts.length > 1 ? parts.sublist(1).join(' ') : line;
      }).toList();
    } catch (e) {
      // print('Error loading labels: $e');
      return [];
    }
  }

  Map<String, dynamic> classifyImage(img.Image image) {
    // Removed debug prints for performance
    // print('Starting classifyImage method');
    // print('Classifier state - Initialized: $isInitialized, Interpreter: ${_interpreter != null}');
    
    if (!isInitialized || _interpreter == null) {
      // print('Classifier not initialized or interpreter is null');
      // print('Initialized: $isInitialized, Interpreter: ${_interpreter != null}');
      return {
        'label': 'unknown',
        'confidence': 0.0,
        'allResults': <Map<String, dynamic>>[],
        'isBelowThreshold': true,
      };
    }

    /*try {
      print('Getting model shape information');
      final inputShapes = _interpreter!.getInputTensors()[0].shape;
      final outputShapes = _interpreter!.getOutputTensors()[0].shape;
      print('Model input shape: $inputShapes');
      print('Model output shape: $outputShapes');
      print('Expected labels count: ${labels.length}');
      
      if (outputShapes.length > 1 && outputShapes[1] != labels.length) {
        print('WARNING: Model output shape does not match labels count!');
        print('Output shape index 1: ${outputShapes[1]}, Labels count: ${labels.length}');
      }
    } catch (e) {
      print('Error getting model shapes: $e');
    }*/

    // NOTE: We moved black image detection to after image processing to ensure
    // we're checking the actual image that will be sent to the model

    try {
      // Use adaptive image size based on device capabilities for better performance
      final imageSize = MemoryManager.getImageProcessingSize();
      
      // Removed debug prints for performance
      // print('Processing image: ${image.width}x${image.height} -> ${imageSize}x${imageSize}');
      
      // print('Baking image orientation');
      final orientedImage = img.bakeOrientation(image);
      
      // print('Resizing image');
      img.Image? resized;
      try {
        resized = img.copyResize(
          orientedImage,
          width: imageSize,
          height: imageSize,
          interpolation: img.Interpolation.cubic,
        );
        // print('Image resized successfully');
      } catch (e) {
        // print('Error resizing image: $e');
        return {
          'label': 'unknown',
          'confidence': 0.0,
          'allResults': <Map<String, dynamic>>[],
          'isBelowThreshold': true,
        };
      }
      
      if (resized == null) {
        // print('Resized image is null');
        return {
          'label': 'unknown',
          'confidence': 0.0,
          'allResults': <Map<String, dynamic>>[],
          'isBelowThreshold': true,
        };
      }
      
      // Check if resized image is completely black
      // Removed debug prints for performance
      // print('Starting black image detection on resized image');
      bool isCompletelyBlack = isImageCompletelyBlack(resized);
      // print('Black image detection result: $isCompletelyBlack');
      
      // Additional check for very dark images that might appear black
      bool isVeryDarkImage = _isImageVeryDark(resized);
      // print('Very dark image detection result: $isVeryDarkImage');
      
      if (isCompletelyBlack || isVeryDarkImage) {
        // print('Detected black or very dark image - returning zero confidence');
        return {
          'label': 'unknown',
          'confidence': 0.0,
          'allResults': <Map<String, dynamic>>[],
          'isBelowThreshold': true,
          'confidenceMessage': isCompletelyBlack ? 'Black image detected' : 'Very dark image detected',
        };
      }
      
      // Removed debug prints for performance
      // print('Converting image to byte list');
      List<double> input;
      try {
        input = _imageToByteListFloat32(resized, imageSize, 127.5, 127.5);
        // print('Image converted to tensor, length: ${input.length}');
      } catch (e) {
        // print('Error converting image to byte list: $e');
        return {
          'label': 'unknown',
          'confidence': 0.0,
          'allResults': <Map<String, dynamic>>[],
          'isBelowThreshold': true,
        };
      }
      
      final expectedInputSize = imageSize * imageSize * 3;
      if (input.length != expectedInputSize) {
        // print('WARNING: Input tensor size mismatch. Expected: $expectedInputSize, Got: ${input.length}');
      }
      
      // Additional check: if all input values are the same (likely all zeros for black image),
      // treat as black image
      if (input.isNotEmpty) {
        double firstValue = input[0];
        bool allSame = true;
        for (int i = 1; i < input.length && i < 100; i++) { // Check first 100 values for performance
          if (input[i] != firstValue) {
            allSame = false;
            break;
          }
        }
        
        // If all values are the same and that value is the normalized black value
        // (which would be -mean/std = -127.5/127.5 = -1.0)
        if (allSame && firstValue == -1.0) {
          // print('Detected normalized black image tensor - returning zero confidence');
          return {
            'label': 'unknown',
            'confidence': 0.0,
            'allResults': <Map<String, dynamic>>[],
            'isBelowThreshold': true,
            'confidenceMessage': 'Black image detected',
          };
        }
      }
      
      // Removed debug prints for performance
      // print('Creating input tensor with shape [1, $imageSize, $imageSize, 3]');
      // Create input tensor with proper shape [1, 224, 224, 3]
      var inputTensor = List.generate(1, (i) => 
        List.generate(imageSize, (j) => 
          List.generate(imageSize, (k) => 
            List.generate(3, (l) => 0.0)
          )
        )
      );
      
      // print('Populating input tensor');
      int idx = 0;
      for (int y = 0; y < imageSize; y++) {
        for (int x = 0; x < imageSize; x++) {
          inputTensor[0][y][x][0] = input[idx++];
          inputTensor[0][y][x][1] = input[idx++];
          inputTensor[0][y][x][2] = input[idx++];
        }
      }
      
      // print('Creating output tensor with shape [1, ${labels.length}]');
      // Create output tensor with proper shape
      var outputTensor = List.generate(1, (i) => 
        List.generate(labels.length, (j) => 0.0)
      );
      
      // Removed debug prints for performance
      // print('Running inference with input shape: [1, $imageSize, $imageSize, 3]');
      // print('Output tensor shape: [1, ${labels.length}]');

      try {
        // print('Executing model inference');
        _interpreter!.run(inputTensor, outputTensor);
        // print('Model inference completed successfully');
      } catch (e) {
        // print('Error running inference: $e');
        return {
          'label': 'unknown',
          'confidence': 0.0,
          'allResults': <Map<String, dynamic>>[],
          'isBelowThreshold': true,
        };
      }
      
      // Removed debug prints for performance
      // print('Processing output values');
      // Use raw model output directly - model already returns normalized probabilities
      var outputValues = outputTensor[0];
      // print('Raw model output values: $outputValues');
      
      // DO NOT apply softmax - model already outputs normalized probabilities
      // outputValues = _applySoftmax(outputValues);  // REMOVED
      // print('Using raw model output (no additional normalization)');

      /*print('Raw output values from model:');
      for (int i = 0; i < outputValues.length && i < labels.length; i++) {
        print('  ${labels[i]}: ${outputValues[i]}');
      }*/

      // Final safeguard: if all output values are very small, treat as black image
      bool allVerySmall = true;
      for (int i = 0; i < outputValues.length; i++) {
        if (outputValues[i] > 0.01) { // More than 1%
          allVerySmall = false;
          break;
        }
      }
      
      if (allVerySmall) {
        // print('All model outputs are very small - treating as black image');
        return {
          'label': 'unknown',
          'confidence': 0.0,
          'allResults': <Map<String, dynamic>>[],
          'isBelowThreshold': true,
          'confidenceMessage': 'Black or invalid image detected',
        };
      }

      // print('Finding maximum confidence');
      int maxIndex = 0;
      double maxConfidence = 0.0;

      for (int i = 0; i < outputValues.length; i++) {
        if (outputValues[i] > maxConfidence) {
          maxConfidence = outputValues[i];
          maxIndex = i;
        }
      }
      // print('Max confidence: $maxConfidence at index $maxIndex');

      // Handle case where all confidences are zero or negative
      if (maxConfidence <= 0.0) {
        // print('No valid classification found - all confidences are zero or negative');
        return {
          'label': 'unknown',
          'confidence': 0.0,
          'allResults': <Map<String, dynamic>>[],
          'isBelowThreshold': true,
        };
      }

      if (labels.isEmpty || maxIndex >= labels.length) {
        // print('Invalid classification result - labels empty or index out of bounds');
        // print('Labels count: ${labels.length}, Max index: $maxIndex');
        return {
          'label': 'unknown',
          'confidence': 0.0,
          'allResults': <Map<String, dynamic>>[],
          'isBelowThreshold': true,
        };
      }

      // Use a reasonable threshold for valid detection
      const confidenceThreshold = 0.01; // 1% threshold
      
      final formattedConfidence = (maxConfidence * 100).toStringAsFixed(2);
      
      // Removed debug prints for performance
      // print('Classification results:');
      // print('- Max confidence: $maxConfidence');
      // print('- Formatted confidence: $formattedConfidence');
      // print('- Max index: $maxIndex');
      // print('- Label: ${labels[maxIndex]}');
      
      // Get all 10 results for display
      // print('Getting all 10 results');
      final allResults = _getTopResults(outputValues, 10);
      // print('All 10 princess probabilities:');
      /*for (var result in allResults) {
        print('  ${result['label']}: ${result['confidence']}%');
      }*/
      
      final isBelowThreshold = maxConfidence < confidenceThreshold;
      // print('Is below threshold ($confidenceThreshold): $isBelowThreshold');
      
      return {
        'label': labels[maxIndex],
        'confidence': formattedConfidence,
        'allResults': allResults,
        'isBelowThreshold': isBelowThreshold,
      };
    } catch (e, stackTrace) {
      // Removed debug prints for performance
      // print('Classification error: $e');
      // print('Stack trace: $stackTrace');
      return {
        'label': 'unknown',
        'confidence': 0.0,
        'allResults': <Map<String, dynamic>>[],
        'isBelowThreshold': true,
      };
    }
  }

  List<double> _imageToByteListFloat32(
    img.Image image,
    int inputSize,
    double mean,
    double std,
  ) {
    final convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    if (image.width == 0 || image.height == 0) {
      return convertedBytes.toList();
    }

    // Pre-calculate normalization factors for better performance
    final double normFactor = 1.0 / std;
    final double normMean = mean * normFactor;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        
        // Direct conversion without exception handling for better performance
        final double r = pixel.r.toDouble();
        final double g = pixel.g.toDouble();
        final double b = pixel.b.toDouble();
        
        // Optimized normalization using pre-calculated factors
        convertedBytes[pixelIndex++] = r * normFactor - normMean;
        convertedBytes[pixelIndex++] = g * normFactor - normMean;
        convertedBytes[pixelIndex++] = b * normFactor - normMean;
      }
    }

    return convertedBytes.toList();
  }

  List<double> _applySoftmax(List<double> input) {
    if (input.isEmpty) {
      // print('Warning: Empty input to softmax function');
      return input;
    }
    
    // Find max value for numerical stability
    double maxValue = input.reduce((a, b) => a > b ? a : b);
    // print('Max value for softmax: $maxValue');
    
    final expValues = input.map((x) {
      try {
        // For numerical stability, subtract max value
        final result = Math.exp(x - maxValue);
        return result.isFinite ? result : 0.0;
      } catch (e) {
        // print('Error in exp calculation for value $x: $e');
        return 0.0;
      }
    }).toList();
    
    double sum = expValues.fold(0.0, (prev, element) => prev + element);
    // print('Sum of exp values: $sum');
    
    if (sum == 0.0 || !sum.isFinite) {
      // print('Warning: Invalid sum in softmax, returning uniform distribution');
      return List<double>.filled(input.length, 1.0 / input.length);
    }
    
    final result = expValues.map((x) => x / sum).toList();
    // print('Softmax result: $result');
    return result;
  }
  
  // Alternative method that doesn't use softmax for higher confidence scores
  List<double> _normalizeToMax(List<double> input) {
    if (input.isEmpty) {
      // print('Warning: Empty input to normalizeToMax function');
      return input;
    }
    
    // print('Normalizing raw outputs without softmax: $input');
    
    // Find max value
    double maxValue = input.reduce((a, b) => a > b ? a : b);
    // print('Max raw value: $maxValue');
    
    // If all values are negative or zero, shift them to positive range
    double minValue = input.reduce((a, b) => a < b ? a : b);
    // print('Min raw value: $minValue');
    
    if (minValue < 0) {
      // Shift all values to make them positive
      final shiftedValues = input.map((x) => x - minValue).toList();
      // print('Shifted values: $shiftedValues');
      
      // Find new max
      double newMax = shiftedValues.reduce((a, b) => a > b ? a : b);
      if (newMax > 0) {
        final normalized = shiftedValues.map((x) => x / newMax).toList();
        // print('Normalized values (shifted): $normalized');
        return normalized;
      } else {
        return List<double>.filled(input.length, 1.0 / input.length);
      }
    } else if (maxValue > 0) {
      // Normalize by max value
      final normalized = input.map((x) => x / maxValue).toList();
      // print('Normalized values (by max): $normalized');
      return normalized;
    } else {
      // All values are zero
      return List<double>.filled(input.length, 1.0 / input.length);
    }
  }

  List<Map<String, dynamic>> _getTopResults(List<double> confidences, int topK) {
    final sorted = List<int>.generate(confidences.length, (i) => i);
    sorted.sort((a, b) => confidences[b].compareTo(confidences[a]));

    // Return up to topK results, or all results if there are fewer than topK
    final actualCount = Math.min(topK, confidences.length);
    return sorted.take(actualCount).map((index) {
      return {
        'label': labels[index],
        'confidence': confidences[index] * 100,
      };
    }).toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    isInitialized = false;
    
    // Clear cached model data to free memory
    _modelData = null;
    
    MemoryManager.cleanup();
  }
  
  // Method to test if the classifier is working properly
  bool isWorking() {
    return isInitialized && _interpreter != null && labels.isNotEmpty;
  }
  
  // Method to get diagnostic information
  Map<String, dynamic> getDiagnostics() {
    return {
      'isInitialized': isInitialized,
      'hasInterpreter': _interpreter != null,
      'labelsCount': labels.length,
      'labels': labels,
      'modelDataLoaded': _modelData != null,
      'modelDataSize': _modelData?.length ?? 0,
    };
  }
  
  // Helper method to check if an image is completely black
  bool isImageCompletelyBlack(img.Image image) {
    try {
      // For performance, check only a subset of pixels
      int sampleSize = 5;
      int widthStep = (image.width / sampleSize).ceil();
      int heightStep = (image.height / sampleSize).ceil();
      
      // Ensure steps are at least 1
      widthStep = widthStep > 0 ? widthStep : 1;
      heightStep = heightStep > 0 ? heightStep : 1;
      
      // Check sampled pixels for non-black values
      for (int y = 0; y < image.height; y += heightStep) {
        for (int x = 0; x < image.width; x += widthStep) {
          final pixel = image.getPixel(x, y);
          // If any pixel has non-zero RGB values, it's not completely black
          if (pixel.r != 0 || pixel.g != 0 || pixel.b != 0) {
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      return false; // Default to false to avoid false positives
    }
  }
  
  // Helper method to check if an image is very dark (could appear black due to lighting conditions)
  bool _isImageVeryDark(img.Image image) {
    try {
      // Removed debug prints for performance
      // print('Checking if image is very dark: ${image.width}x${image.height}');
      
      // Sample pixels to calculate average brightness
      int sampleSize = 20;
      int widthStep = (image.width / sampleSize).ceil();
      int heightStep = (image.height / sampleSize).ceil();
      
      // Ensure steps are at least 1
      widthStep = widthStep > 0 ? widthStep : 1;
      heightStep = heightStep > 0 ? heightStep : 1;
      
      int totalBrightness = 0;
      int pixelCount = 0;
      
      for (int y = 0; y < image.height; y += heightStep) {
        for (int x = 0; x < image.width; x += widthStep) {
          final pixel = image.getPixel(x, y);
          // Calculate brightness using luminance formula
          final brightness = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).toInt();
          totalBrightness += brightness;
          pixelCount++;
        }
      }
      
      if (pixelCount == 0) return false;
      
      final averageBrightness = totalBrightness / pixelCount;
      // print('Average brightness: $averageBrightness');
      
      // If average brightness is very low, consider it a dark image
      // Threshold of 10 is quite low - most images should be brighter than this
      return averageBrightness < 10;
    } catch (e) {
      // print('Error checking if image is very dark: $e');
      return false; // Default to false to avoid false positives
    }
  }
}