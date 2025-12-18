import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute;
import 'dart:async' show TimeoutException;
import 'dart:typed_data' show Uint8List;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:disney_princess_app/services/analytics_service.dart';
import '../services/classifier_service.dart';
import '../utils/memory_manager.dart';
import '../models/princess.dart' show Princess, princesses;
import 'princess_detail_screen.dart';
import 'classification_result_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  Future<void>? _initializeCameraFuture;
  late ClassifierService _classifierService;
  bool _isClassifying = false;
  String? _errorMessage;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isDisposed = false;
  bool _isCameraInitialized = false;
  int _retryCount = 0;
  static const int MAX_RETRY_ATTEMPTS = 3;
  bool _isCapturing = false;
  Uint8List? _capturedImageBytes;
  
  // Animation controllers
  late AnimationController _shutterController;
  late Animation<double> _shutterAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _classifierService = ClassifierService();

    _classifierService.initialize();

    // Initialize camera with optimized settings
    _initializeCamera();
    
    // Initialize animations
    _shutterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _shutterAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _shutterController,
      curve: Curves.easeInOut,
    ));

    // Log screen view
    AnalyticsService.instance.logScreenView('CameraScreen');
  }

  // Improved camera initialization with better error handling
  void _initializeCamera() {
    setState(() {
      _initializeCameraFuture = _setupCamera();
    });
  }

  // Enhanced camera setup with better error handling
  Future<void> _setupCamera() async {
    if (_isDisposed) return;

    try {
      // Request camera permission first
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Camera permission denied. Please enable camera permission in Settings.';
          });
        }
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Select back camera as default, otherwise use first camera
      _selectedCameraIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.back) {
          _selectedCameraIndex = i;
          break;
        }
      }

      // Dispose existing controller if needed
      await _disposeCurrentController();

      // Add a small delay to ensure resources are fully released
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new controller with appropriate settings
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high, // Use high resolution for better quality
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      // Initialize with proper error handling and timeout
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 15), // Increased timeout
      );

      // Set flash mode to off for better performance
      try {
        await _cameraController?.setFlashMode(FlashMode.off);
      } catch (e) {
        // print('Warning: Could not set flash mode: $e');
      }

      // Set focus mode to auto for better image quality
      try {
        await _cameraController?.setFocusMode(FocusMode.auto);
      } catch (e) {
        // print('Warning: Could not set focus mode: $e');
      }

      // Unlock capture orientation for better flexibility
      try {
        await _cameraController?.unlockCaptureOrientation();
      } catch (e) {
        // print('Warning: Could not unlock capture orientation: $e');
      }

      _isCameraInitialized = true;
      _retryCount = 0; // Reset retry count on successful initialization

      if (!mounted) return;
      setState(() {});
    } on CameraException catch (e) {
      // print('Camera exception: $e');
      if (mounted) {
        // Try to reinitialize if this is not the max retry attempt
        if (_retryCount < MAX_RETRY_ATTEMPTS) {
          _retryCount++;
          // print('Retrying camera initialization (attempt $_retryCount)');
          await Future.delayed(const Duration(milliseconds: 500));
          _initializeCamera();
          return;
        }

        setState(() {
          _errorMessage = 'Camera error: ${e.description}. Please restart the app.';
        });
      }
    } catch (e) {
      // print('Camera setup error: $e');
      if (mounted) {
        // Try to reinitialize if this is not the max retry attempt
        if (_retryCount < MAX_RETRY_ATTEMPTS) {
          _retryCount++;
          // print('Retrying camera initialization (attempt $_retryCount)');
          await Future.delayed(const Duration(milliseconds: 500));
          _initializeCamera();
          return;
        }

        setState(() {
          _errorMessage = 'Camera setup failed: ${e.toString()}. Please restart the app.';
        });
      }
    }
  }

  // Properly dispose current controller with better error handling
  Future<void> _disposeCurrentController() async {
    if (_cameraController != null) {
      try {
        // Check if controller is initialized before disposing
        if (_cameraController!.value.isInitialized) {
          // Stop any active image stream first
          try {
            await _cameraController!.stopImageStream();
          } catch (e) {
            // print('Error stopping image stream: $e');
          }

          // Dispose the controller
          await _cameraController!.dispose();
        }
      } catch (e) {
        // print('Error disposing camera controller: $e');
      }
      _cameraController = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to properly manage camera resources
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused) {
      // App is going to background, stop the camera
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground, restart the camera
      _restartCamera();
    }
  }

  // Stop camera when app goes to background
  void _stopCamera() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          _cameraController!.stopImageStream();
        }
      } catch (e) {
        // print('Error stopping image stream: $e');
      }
      try {
        _cameraController!.pausePreview();
      } catch (e) {
        // print('Error pausing preview: $e');
      }
    }
  }

  // Restart camera when app comes to foreground
  void _restartCamera() async {
    if (_isDisposed) return;

    try {
      // Always re-initialize camera when app resumes to avoid buffer issues
      await _disposeCurrentController();

      // Add a delay to ensure resources are fully released
      await Future.delayed(const Duration(milliseconds: 300));

      // Re-initialize camera
      _initializeCamera();
    } catch (e) {
      // print('Error restarting camera: $e');
      // If restart fails, re-initialize
      _initializeCamera();
    }
  }

  // Toggle between front and back camera
  Future<void> _toggleCamera() async {
    if (_cameras.length <= 1) return;

    try {
      // Switch to the other camera
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;

      // Dispose current controller
      await _disposeCurrentController();

      // Add a delay to ensure resources are fully released
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new controller with optimized settings
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high, // Use high resolution for better quality
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      // Initialize with timeout
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 15), // Increased timeout
      );
      _isCameraInitialized = true;

      if (!mounted) return;
      setState(() {});
    } on CameraException catch (e) {
      // print('Camera toggle exception: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera error: ${e.description}';
        });
      }
    } catch (e) {
      // print('Camera toggle error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to switch camera. Please try again.';
        });
      }
    }
  }

  Future<void> _captureAndClassify() async {
    // Prevent multiple concurrent capture attempts
    if (_isCapturing ||
        _isClassifying ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isDisposed) {
      // If camera is not ready, try to reinitialize
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        _initializeCamera();
        // Wait a bit for initialization
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return;
    }

    // Set capturing flag
    _isCapturing = true;
    
    // Play shutter animation
    _shutterController.forward().then((_) {
      _shutterController.reverse();
    });

    // Log camera scan started
    AnalyticsService.instance.logCameraScanStarted();

    setState(() {
      _isClassifying = true;
      _errorMessage = null;
    });

    try {
      // Log camera image captured
      AnalyticsService.instance.logCameraImageCaptured();

      XFile? image;

      // Add timeout to image capture with retry mechanism
      int captureAttempts = 0;
      const maxCaptureAttempts = 3;

      while (captureAttempts < maxCaptureAttempts && image == null) {
        try {
          captureAttempts++;
          // print('Capture attempt $captureAttempts');
          // Ensure camera is still initialized before capture
          if (_cameraController == null || !_cameraController!.value.isInitialized) {
            throw CameraException('CAMERA_NOT_INITIALIZED', 'Camera is not initialized');
          }

          image = await _cameraController!.takePicture().timeout(
            const Duration(seconds: 10), // Increased timeout
          );
        } on TimeoutException catch (e) {
          // print('Capture timeout on attempt $captureAttempts: $e');
          if (captureAttempts >= maxCaptureAttempts) {
            rethrow; // Re-throw if we've exhausted attempts
          }
          await Future.delayed(const Duration(milliseconds: 500));
        } on CameraException catch (e) {
          // print('Camera exception on attempt $captureAttempts: $e');
          if (captureAttempts >= maxCaptureAttempts) {
            rethrow; // Re-throw if we've exhausted attempts
          }
          // For camera-specific errors, try reinitializing
          if (e.code == 'CAMERA_ERROR' || e.code == 'CAMERA_NOT_INITIALIZED') {
            _initializeCamera();
            await Future.delayed(const Duration(milliseconds: 1000)); // Longer delay for reinit
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (image == null) {
        if (!mounted) return;
        _showZeroConfidenceResult('Failed to capture image after $maxCaptureAttempts attempts');
        return;
      }

      // Read image bytes with error handling
      Uint8List? imageBytes;
      try {
        imageBytes = await image.readAsBytes();
      } catch (e) {
        // print('Error reading image bytes: $e');
        if (!mounted) return;
        _showZeroConfidenceResult('Failed to read image');
        return;
      }

      if (imageBytes == null || imageBytes.isEmpty) {
        if (!mounted) return;
        _showZeroConfidenceResult('Image data is empty');
        return;
      }

      // Store captured image for preview
      if (mounted) {
        setState(() {
          _capturedImageBytes = imageBytes;
        });
      }

      // Process image directly on main thread instead of using isolate
      Map<String, dynamic>? result;
      try {
        // Removed debug prints for performance
        // print('Starting image processing on main thread');
        // print('Image bytes length: ${imageBytes.length}');
        
        // Ensure classifier is ready before processing
        // print('Checking if classifier is ready...');
        final isReady = await _ensureClassifierReady();
        if (!isReady) {
          // print('Classifier is not ready, cannot process image');
          throw Exception('Classifier is not ready for image processing');
        }
        
        final decodedImage = img.decodeImage(imageBytes);

        if (decodedImage != null) {
          // print('Image decoded successfully: ${decodedImage.width}x${decodedImage.height}');
          
          // Ensure correct orientation using EXIF data
          final orientedImage = img.bakeOrientation(decodedImage);
          // print('Image orientation fixed');
          
          // Process image with the initialized classifier
          // print('Processing image with classifier');
          result = _classifierService.classifyImage(orientedImage);
          // print('Classifier returned result: $result');
        } else {
          // print('Failed to decode image');
          throw Exception('Failed to decode image');
        }
      } catch (e) {
        // print('Error processing image: $e');
        if (!mounted) return;
        _showZeroConfidenceResult('Failed to process image');
        return;
      }

      if (result == null) {
        if (!mounted) return;
        _showZeroConfidenceResult('Failed to process image');
        return;
      }

      // Navigate to results screen
      if (!mounted) return;

      // Extract results
      final detectedLabel = result['label'] as String? ?? 'unknown';
      final confidence = result['confidence'] as String? ?? '0.00';
      final allResults =
          (result['allResults'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      final isBelowThreshold = result['isBelowThreshold'] as bool? ?? true;
      final confidenceMessage = result['confidenceMessage'] as String? ?? '';

      // Find matching princess based on model prediction
      Princess? detectedPrincess;
      if (detectedLabel != 'unknown') {
        try {
          detectedPrincess = princesses.firstWhere(
            (princess) => princess.name.toLowerCase() == detectedLabel.toLowerCase(),
            orElse: () => princesses[0],
          );
        } catch (e) {
          // print('Error finding princess: $e');
          detectedPrincess = princesses[0];
        }
      } else {
        // If detection failed, use first princess as fallback
        detectedPrincess = princesses[0];
      }

      final capturedImageToPass = _capturedImageBytes;

      setState(() {
        _capturedImageBytes = null;
      });

      // Navigate to classification result screen and wait for result
      final resultFromDetails = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassificationResultScreen(
            princess: detectedPrincess ?? princesses[0],
            confidence: double.tryParse(confidence) ?? 0.0,
            allResults: allResults,
            capturedImage: capturedImageToPass,
          ),
        ),
      );

      // Check if user wants to retake the photo
      if (resultFromDetails != null && resultFromDetails is Map && resultFromDetails['retake'] == true) {
        // User wants to retake, reset state and keep camera ready
        if (mounted) {
          setState(() {
            _isClassifying = false;
            _isCapturing = false;
            _errorMessage = null;
          });
        }
        // Camera should remain initialized and ready for another capture
        return;
      }

      // Normal navigation back, reset state
      if (mounted) {
        setState(() {
          _isClassifying = false;
          _isCapturing = false;
          _errorMessage = null;
        });
      }
    } on CameraException catch (e) {
      // print('Camera exception during capture: $e');
      if (!mounted) return;
      
      // Show zero confidence result instead of error message
      _showZeroConfidenceResult('Camera error occurred');
    } on TimeoutException catch (e) {
      // print('Timeout during image capture: $e');
      if (!mounted) return;
      
      // Show zero confidence result instead of error message
      _showZeroConfidenceResult('Timeout capturing image');
    } on OutOfMemoryError catch (e) {
      // print('Out of memory error: $e');
      if (!mounted) return;
      
      // Show zero confidence result instead of error message
      _showZeroConfidenceResult('Not enough memory to process image');
    } catch (e) {
      // print('Image capture error: $e');
      if (!mounted) return;
      
      // Show zero confidence result instead of error message
      _showZeroConfidenceResult('Error processing image');
    } finally {
      // Always reset capturing flag
      _isCapturing = false;
    }
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    if (_isClassifying || _isDisposed) return;

    setState(() {
      _isClassifying = true;
      _errorMessage = null;
      _capturedImageBytes = null;
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        Uint8List? imageBytes;
        try {
          imageBytes = await pickedFile.readAsBytes();
        } catch (e) {
          // print('Error reading gallery image bytes: $e');
          if (!mounted) return;
          _showZeroConfidenceResult('Failed to read selected image');
          return;
        }

        if (imageBytes == null || imageBytes.isEmpty) {
          if (!mounted) return;
          _showZeroConfidenceResult('Selected image is empty');
          return;
        }

        // Store captured image for preview
        if (mounted) {
          setState(() {
            _capturedImageBytes = imageBytes;
          });
        }

        // Process image directly on main thread instead of using isolate
        Map<String, dynamic>? result;
        try {
          // Removed debug prints for performance
          // print('Starting gallery image processing on main thread');
          // print('Image bytes length: ${imageBytes.length}');
          
          // Ensure classifier is ready before processing
          // print('Checking if classifier is ready for gallery image...');
          final isReady = await _ensureClassifierReady();
          if (!isReady) {
            // print('Classifier is not ready, cannot process gallery image');
            throw Exception('Classifier is not ready for image processing');
          }
          
          final decodedImage = img.decodeImage(imageBytes);

          if (decodedImage != null) {
            // print('Gallery image decoded successfully: ${decodedImage.width}x${decodedImage.height}');
            
            // Ensure correct orientation using EXIF data
            final orientedImage = img.bakeOrientation(decodedImage);
            // print('Gallery image orientation fixed');
            
            // Process image with the initialized classifier
            // print('Processing gallery image with classifier');
            result = _classifierService.classifyImage(orientedImage);
            // print('Classifier returned result: $result');
          } else {
            // print('Failed to decode gallery image');
            throw Exception('Failed to decode gallery image');
          }
        } catch (e) {
          // print('Error processing gallery image: $e');
          if (!mounted) return;
          _showZeroConfidenceResult('Failed to process selected image');
          return;
        }

        if (result == null) {
          if (!mounted) return;
          _showZeroConfidenceResult('Failed to process selected image');
          return;
        }

        if (!mounted) return;

        // Extract results
        final detectedLabel = result['label'] as String? ?? 'unknown';
        final confidence = result['confidence'] as String? ?? '0.00';
        final allResults =
            (result['allResults'] as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
        final isBelowThreshold = result['isBelowThreshold'] as bool? ?? true;

        // Find matching princess based on model prediction
        Princess? detectedPrincess;
        if (detectedLabel != 'unknown') {
          try {
            detectedPrincess = princesses.firstWhere(
              (princess) => princess.name.toLowerCase() == detectedLabel.toLowerCase(),
              orElse: () => princesses[0],
            );
          } catch (e) {
            // print('Error finding princess: $e');
            detectedPrincess = princesses[0];
          }
        } else {
          // If detection failed, use first princess as fallback
          detectedPrincess = princesses[0];
        }

        final capturedImageToPass = _capturedImageBytes;

        setState(() {
          _capturedImageBytes = null;
        });

        // Navigate to classification result screen and wait for result
        final resultFromDetails = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassificationResultScreen(
              princess: detectedPrincess ?? princesses[0],
              confidence: double.tryParse(confidence) ?? 0.0,
              allResults: allResults,
              capturedImage: capturedImageToPass,
            ),
          ),
        );

        // Check if user wants to retake the photo
        if (resultFromDetails != null && resultFromDetails is Map && resultFromDetails['retake'] == true) {
          // User wants to retake, reset state and keep camera ready
          if (mounted) {
            setState(() {
              _isClassifying = false;
              _errorMessage = null;
            });
          }
          // Camera should remain initialized and ready for another capture
          return;
        }

        // Normal navigation back, reset state
        if (mounted) {
          setState(() {
            _isClassifying = false;
            _errorMessage = null;
          });
        }
      } else {
        // User canceled the image picker
        if (!mounted) return;
        setState(() {
          _errorMessage = null; // Clear any previous error when user cancels
        });
      }
    } on OutOfMemoryError catch (e) {
      // print('Out of memory error in gallery pick: $e');
      if (!mounted) return;
      
      // Show zero confidence result instead of error message
      _showZeroConfidenceResult('Not enough memory to process image');
    } catch (e) {
      // print('Gallery pick error: $e');
      if (!mounted) return;
      
      // Show zero confidence result instead of error message
      _showZeroConfidenceResult('Error processing image');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCurrentController();
    _shutterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8E6EC8), // New purple color
                Color(0xFFE3A7C7), // New pink color
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // AppBar content
              AppBar(
                title: Text(
                  'Princess Classifier',
                  style: GoogleFonts.greatVibes(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              // Subtle sparkle overlay
              Positioned(
                top: 8,
                right: 80,
                child: Icon(
                  Icons.star,
                  color: Colors.white.withOpacity(0.3),
                  size: 12,
                ),
              ),
              Positioned(
                top: 12,
                left: 100,
                child: Icon(
                  Icons.star,
                  color: Colors.white.withOpacity(0.2),
                  size: 8,
                ),
              ),
              Positioned(
                bottom: 10,
                right: 120,
                child: Icon(
                  Icons.star,
                  color: Colors.white.withOpacity(0.25),
                  size: 10,
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeCameraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Initializing camera...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Camera Initialization Failed',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(snapshot.error.toString()),
                  const SizedBox(height: 10),
                  const Text(
                    'Please check camera permissions in Settings.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeCamera();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData || _isCameraInitialized) {
            return Stack(
              children: [
                // Enhanced camera preview with better aspect ratio handling
                Positioned.fill(
                  child: _cameraController == null ||
                          !_cameraController!.value.isInitialized ||
                          _isDisposed
                      ? Container()
                      : ScaleTransition(
                          scale: _shutterAnimation,
                          child: AspectRatio(
                            aspectRatio: _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                ),
                // Overlay for focus indicator
                if (!_isClassifying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                if (_isClassifying && _capturedImageBytes != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Container(
                          width: 280,
                          height: 380,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Image.memory(
                              _capturedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isClassifying)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_capturedImageBytes != null)
                            const SizedBox(height: 200),
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E6CB0)),
                            strokeWidth: 4,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Analyzing image...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Updated banner to show general scanning message when no princess is selected
                if (!_isClassifying)
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFF8E6CB0)),
                            SizedBox(width: 10),
                            Text(
                              'Point camera at a Disney Princess',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E6CB0),
                              ),
                            ),
                          ],
                        ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, size: 30, color: Color(0xFF8E6CB0)),
                            onPressed: _isClassifying ? null : _pickImageFromGallery,
                          ),
                          FloatingActionButton(
                            backgroundColor: const Color(0xFF8E6CB0),
                            onPressed: _isClassifying ? null : _captureAndClassify,
                            child: _isClassifying
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.cameraswitch,
                              size: 30,
                              color: Color(0xFF8E6CB0),
                            ),
                            onPressed: (_isClassifying || _cameras.length <= 1)
                                ? null
                                : _toggleCamera,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null && !_isClassifying)
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          } else {
            // Fallback case - show retry option
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Camera not initialized',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeCamera();
                      });
                    },
                    child: const Text('Initialize Camera'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Separate classifier initialization with better error handling
  Future<void> _initializeClassifier() async {
    try {
      // print('Initializing classifier service...');
      await _classifierService.initialize();
      // print('Classifier service initialized successfully');
      
      // Check if classifier is actually working
      if (_classifierService.isWorking()) {
        // print('Classifier is working properly');
        final diagnostics = _classifierService.getDiagnostics();
        // print('Classifier diagnostics: $diagnostics');
      } else {
        // print('WARNING: Classifier reports as initialized but is not working properly');
        final diagnostics = _classifierService.getDiagnostics();
        // print('Classifier diagnostics: $diagnostics');
      }
    } catch (e, stackTrace) {
      // print('Error initializing classifier service: $e');
      // print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize image classifier. Some features may not work properly.';
        });
      }
    }
  }
  
  // Method to ensure classifier is ready before processing
  Future<bool> _ensureClassifierReady() async {
    // print('Ensuring classifier is ready...');
    
    // Check if already initialized and working
    if (_classifierService.isWorking()) {
      // print('Classifier is already ready and working');
      return true;
    }
    
    // If not initialized, try to initialize
    if (!_classifierService.isInitialized) {
      // print('Classifier not initialized, attempting to initialize...');
      try {
        await _classifierService.initialize();
        // print('Classifier initialization completed');
      } catch (e) {
        // print('Failed to initialize classifier: $e');
        return false;
      }
    }
    
    // Check if it's working now
    if (_classifierService.isWorking()) {
      // print('Classifier is now ready and working');
      return true;
    } else {
      // print('Classifier is initialized but not working properly');
      final diagnostics = _classifierService.getDiagnostics();
      // print('Classifier diagnostics: $diagnostics');
      return false;
    }
  }
  
  /// Show zero confidence result when there's an error
  void _showZeroConfidenceResult(String errorMessage) {
    if (!mounted) return;
    
    // Use the first princess as fallback
    final fallbackPrincess = princesses[0];
    
    // Navigate to classification result screen with zero confidence
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassificationResultScreen(
          princess: fallbackPrincess,
          confidence: 0.0,
          allResults: [],
          capturedImage: _capturedImageBytes,
        ),
      ),
    ).then((resultFromDetails) {
      // Check if user wants to retake the photo
      if (resultFromDetails != null && resultFromDetails is Map && resultFromDetails['retake'] == true) {
        // User wants to retake, reset state and keep camera ready
        if (mounted) {
          setState(() {
            _isClassifying = false;
            _isCapturing = false;
            _capturedImageBytes = null;
            _errorMessage = null;
          });
        }
        // Camera should remain initialized and ready for another capture
        return;
      }

      // Reset state after navigation
      if (mounted) {
        setState(() {
          _isClassifying = false;
          _isCapturing = false;
          _capturedImageBytes = null;
          _errorMessage = null;
        });
      }
    });
  }
}