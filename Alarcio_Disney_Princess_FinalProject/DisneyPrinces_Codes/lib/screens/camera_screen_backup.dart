import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:disney_princess_app/services/analytics_service.dart';
import '../services/classifier_service.dart';
import '../utils/memory_manager.dart';
import '../models/princess.dart';
import 'princess_detail_screen.dart';
import 'classification_result_screen.dart';

class CameraScreen extends StatefulWidget {
  final Princess? selectedPrincess;

  const CameraScreen({super.key, this.selectedPrincess});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _classifierService = ClassifierService();
    
    // Initialize camera with optimized settings
    _initializeCameraOptimized();
    
    // Log screen view
    AnalyticsService.instance.logScreenView('CameraScreen');
  }

  // Optimized camera initialization
  void _initializeCameraOptimized() {
    setState(() {
      _initializeCameraFuture = _setupCameraOptimized();
    });
  }

  // Ultra-fast camera setup
  Future<void> _setupCameraOptimized() async {
    if (_isDisposed) return;
    
    try {
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        throw Exception('No cameras available');
      }
      
      // Select front camera if available, otherwise use first camera
      _selectedCameraIndex = 0;
      for (int i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == CameraLensDirection.front) {
          _selectedCameraIndex = i;
          break;
        }
      }
      
      // Dispose existing controller if needed
      await _disposeCurrentController();
      
      // Create new controller with minimal settings for fastest init
      // Remove enableFlipHorizontal parameter to ensure compatibility with camera package version
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.low, // Lowest resolution for fastest init
        enableAudio: false, // Disable audio for faster init
        imageFormatGroup: ImageFormatGroup.yuv420, // Efficient format
      );
      
      // Initialize with minimal configuration
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 15), // Increased timeout
      );
      _isCameraInitialized = true;
      _retryCount = 0; // Reset retry count on successful initialization
      
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print('Camera setup error: $e');
      if (mounted) {
        // Try to reinitialize if this is not the max retry attempt
        if (_retryCount < MAX_RETRY_ATTEMPTS) {
          _retryCount++;
          print('Retrying camera initialization (attempt $_retryCount)');
          await Future.delayed(const Duration(milliseconds: 500));
          _initializeCameraOptimized();
          return;
        }
        
        setState(() {
          _errorMessage = 'Camera setup failed: ${e.toString()}. Please restart the app.';
        });
      }
      rethrow;
    }
  }
  
  // Properly dispose current controller
  Future<void> _disposeCurrentController() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
        }
      } catch (e) {
        print('Error disposing camera controller: $e');
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

  Future<void> _stopCamera() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.stopImageStream();
      } catch (e) {
        // Ignore errors when stopping
      }
    }
  }

  Future<void> _restartCamera() async {
    if (_isDisposed) return;
    
    try {
      // Use optimized initialization
      _initializeCameraOptimized();
    } catch (e) {
      print('Error restarting camera: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to restart camera. Please try again.';
        });
      }
    }
  }

  // Update the _toggleCamera method to use optimized approach
  Future<void> _toggleCamera() async {
    if (_isDisposed || _cameras.isEmpty) return;
    
    try {
      // Properly dispose of the current controller
      await _disposeCurrentController();
      
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      
      // Create new controller with optimized settings
      // Remove enableFlipHorizontal parameter to ensure compatibility with camera package version
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.low, // Keep low resolution for speed
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      // Initialize quickly
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 15), // Increased timeout
      );
      _isCameraInitialized = true;
      
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      print('Camera toggle error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to switch camera. Please try again.';
        });
      }
    }
  }

  Future<void> _captureAndClassify() async {
    // Prevent multiple concurrent capture attempts
    if (_isCapturing || _isClassifying || _cameraController == null || !_cameraController!.value.isInitialized || _isDisposed) {
      // If camera is not ready, try to reinitialize
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        _initializeCameraOptimized();
        // Wait a bit for initialization
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return;
    }
    
    // Set capturing flag
    _isCapturing = true;
    
    // Log camera scan started
    AnalyticsService.instance.logCameraScanStarted();
    
    // Check for camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Camera permission denied. Please enable camera permission in Settings.';
        _isClassifying = false;
        _isCapturing = false;
      });
      return;
    }

    setState(() {
      _isClassifying = true;
      _errorMessage = null;
    });

    try {
      // Log camera image captured
      AnalyticsService.instance.logCameraImageCaptured();
      
      // Add timeout to image capture with retry mechanism
      int captureAttempts = 0;
      const maxCaptureAttempts = 3;
      XFile? image;
      
      while (captureAttempts < maxCaptureAttempts && image == null) {
        try {
          captureAttempts++;
          print('Capture attempt $captureAttempts');
          // Ensure camera is still initialized before capture
          if (_cameraController == null || !_cameraController!.value.isInitialized) {
            throw CameraException('CAMERA_NOT_INITIALIZED', 'Camera is not initialized');
          }
          
          image = await _cameraController!.takePicture().timeout(
            const Duration(seconds: 10), // Increased timeout
          );
        } on TimeoutException catch (e) {
          print('Capture timeout on attempt $captureAttempts: $e');
          if (captureAttempts >= maxCaptureAttempts) {
            rethrow; // Re-throw if we've exhausted attempts
          }
          await Future.delayed(const Duration(milliseconds: 500));
        } on CameraException catch (e) {
          print('Camera exception on attempt $captureAttempts: $e');
          if (captureAttempts >= maxCaptureAttempts) {
            rethrow; // Re-throw if we've exhausted attempts
          }
          // For camera-specific errors, try reinitializing
          if (e.code == 'CAMERA_ERROR' || e.code == 'CAMERA_NOT_INITIALIZED') {
            _initializeCameraOptimized();
            await Future.delayed(const Duration(milliseconds: 1000)); // Longer delay for reinit
          } else {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      
      if (image == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to capture image after $maxCaptureAttempts attempts. Please try again.';
          _isClassifying = false;
          _isCapturing = false;
        });
        return;
      }
      
      final imageBytes = await image.readAsBytes();
      
      // Process image in a microtask to prevent UI blocking
      final result = await Future.microtask(() async {
        final decodedImage = img.decodeImage(imageBytes);
        
        if (decodedImage != null) {
          // Ensure correct orientation
          final orientedImage = img.bakeOrientation(decodedImage);
          return await _classifierService.classifyImage(orientedImage);
        }
        return null;
      });
      
      if (result == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to decode image';
          _isCapturing = false;
        });
        return;
      }
      
      // Extract results properly
      final detectedLabel = result['label'].toString().toLowerCase();
      final confidenceStr = result['confidence'].toString();
      final confidence = double.tryParse(confidenceStr) ?? 0.0;
      final allResults = (result['allResults'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      final isBelowThreshold = result['isBelowThreshold'] as bool? ?? true;

      // Also check if the detected label is actually one of our known princesses
      final isValidPrincess = princesses.any((princess) => princess.name.toLowerCase() == detectedLabel);
      
      // If we have a selected princess, check if it matches
      if (widget.selectedPrincess != null) {
        // If the selected princess doesn't match the detected one, show a message
        if (widget.selectedPrincess!.name.toLowerCase() != detectedLabel) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'This doesn\'t appear to be ${widget.selectedPrincess!.name}. Detected: ${result['label']}';
            _isClassifying = false;
            _isCapturing = false;
          });
          return;
        }
      }
      
      // If confidence is below threshold or not a valid princess, show appropriate message
      if (isBelowThreshold || !isValidPrincess || detectedLabel == 'unknown') {
        // Show a message indicating no princess was detected
        if (!mounted) return;
        setState(() {
          _errorMessage = 'No Disney princess detected in the image. Please try another image.';
          _isClassifying = false;
          _isCapturing = false;
        });
        return;
      }
      
      final detectedPrincess = princesses.firstWhere(
        (princess) => princess.name.toLowerCase() == detectedLabel,
        orElse: () => princesses[0],
      );

      // Log image classified
      AnalyticsService.instance.logImageClassified(detectedPrincess.name, confidence);
      
      if (!mounted) return;
      
      // Navigate to classification result screen to show confidence
      // Log classification result viewed
      AnalyticsService.instance.logClassificationResultViewed(detectedPrincess.name, confidence);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ClassificationResultScreen(
            princess: detectedPrincess,
            confidence: confidence,
            allResults: allResults,
          ),
        ),
      );
    } on TimeoutException catch (e) {
      print('Timeout during image capture: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Timeout capturing image. Please try again.';
        _isClassifying = false;
        _isCapturing = false;
      });
    } on CameraException catch (e) {
      print('Camera exception during capture: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Camera error: ${e.description}. Please try again.';
        _isClassifying = false;
        _isCapturing = false;
      });
    } on OutOfMemoryError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Not enough memory to process the image. Please restart the app and try again.';
        _isCapturing = false;
      });
    } catch (e) {
      print('Image capture error: $e');
      if (!mounted) return;
      if (e.toString().contains('permissions') || e.toString().contains('Permission')) {
        setState(() {
          _errorMessage = 'Camera permission denied. Please enable camera permission in Settings.';
          _isCapturing = false;
        });
      } else if (e.toString().contains('Out of memory') || e.toString().contains('memory')) {
        setState(() {
          _errorMessage = 'Not enough memory to process the image. Please close other apps and try again.';
          _isCapturing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error capturing image. Please try again.';
          _isCapturing = false;
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isClassifying = false;
        _isCapturing = false;
      });
    }
  }
  
  // Move image processing to a separate isolate to prevent UI blocking
  static Future<Map<String, dynamic>> _processImage(Map<String, dynamic> params) async {
    try {
      final imagePath = params['imagePath'] as String;
      // Note: We can't directly pass the classifier service or selected princess to the isolate
      // So we'll need to recreate them or handle differently
      
      // For simplicity in this example, we'll just return an error
      // In a real implementation, you would process the image here
      return {'error': 'Image processing not implemented in isolate'};
    } catch (e) {
      return {'error': 'Error processing image: $e'};
    }
  }

  Future<void> _pickAndClassifyImage() async {
    if (_isClassifying || _isDisposed) return;
    
    // Log gallery scan started
    AnalyticsService.instance.logGalleryScanStarted();
    
    setState(() {
      _isClassifying = true;
      _errorMessage = null;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        final decodedImage = img.decodeImage(imageBytes);
        
        if (decodedImage != null) {
          // Ensure correct orientation
          final orientedImage = img.bakeOrientation(decodedImage);
          
          try {
            final result = await _classifierService.classifyImage(orientedImage);
            
            // Check if the confidence is below threshold
            final isBelowThreshold = result['isBelowThreshold'] as bool? ?? false;
            
            // Also check if the detected label is actually one of our known princesses
            final detectedLabel = result['label'].toString().toLowerCase();
            final isValidPrincess = princesses.any((princess) => princess.name.toLowerCase() == detectedLabel);
            
            // If we have a selected princess, check if it matches
            if (widget.selectedPrincess != null) {
              // If the selected princess doesn't match the detected one, show a message
              if (widget.selectedPrincess!.name.toLowerCase() != detectedLabel) {
                if (!mounted) return;
                setState(() {
                  _errorMessage = 'This doesn\'t appear to be ${widget.selectedPrincess!.name}. Detected: ${result['label']}';
                  _isClassifying = false;
                });
                return;
              }
            }
            
            // If confidence is below threshold or not a valid princess, show appropriate message
            if (isBelowThreshold || !isValidPrincess || detectedLabel == 'unknown') {
              // Show a message indicating no princess was detected
              if (!mounted) return;
              setState(() {
                _errorMessage = 'No Disney princess detected in the image. Please try another image.';
                _isClassifying = false;
              });
              return;
            }
            
            final detectedPrincess = princesses.firstWhere(
              (princess) => princess.name.toLowerCase() == detectedLabel,
              orElse: () => princesses[0],
            );
            
            final confidence = double.tryParse(result['confidence'].toString()) ?? 0.0;
            final allResults = List<Map<String, dynamic>>.from(result['allResults']);
            
            // Log image classified
            AnalyticsService.instance.logImageClassified(detectedPrincess.name, confidence);
            
            if (!mounted) return;
            
            // Navigate to classification result screen to show confidence
            // Log classification result viewed
            AnalyticsService.instance.logClassificationResultViewed(detectedPrincess.name, confidence);
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ClassificationResultScreen(
                  princess: detectedPrincess,
                  confidence: confidence,
                  allResults: allResults,
                ),
              ),
            );
          } catch (classificationError) {
            if (!mounted) return;
            
            // Show error message instead of fallback to random princess
            setState(() {
              _errorMessage = 'Unable to classify the image. Please try another image.';
              _isClassifying = false;
            });
          }
        } else {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Failed to decode image. Please try another image.';
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
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Not enough memory to process the image. Please restart the app and try again.';
      });
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        setState(() {
          _errorMessage = 'Permission denied. Please grant gallery access in Settings.';
        });
      } else if (e.toString().contains('Out of memory') || e.toString().contains('memory')) {
        setState(() {
          _errorMessage = 'Not enough memory to process the image. Please close other apps and try again.';
        });
      } else {
        setState(() {
          _errorMessage = 'Error picking image. Please try again.';
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isClassifying = false;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeCurrentController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.selectedPrincess != null 
          ? Text('${widget.selectedPrincess!.name} Scanner')
          : const Text('Princess Classifier'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8E6CB0),
                Color(0xFFEAA7C4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeCameraFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Camera Initialization Failed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Please check camera permissions in Settings.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initializeCameraFuture = _setupCameraOptimized();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            return Stack(
              children: [
                Positioned.fill(
                  child: _cameraController == null ? Container() : CameraPreview(_cameraController!),
                ),
                if (widget.selectedPrincess != null)
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(widget.selectedPrincess!.imageUrl),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Scanning for ${widget.selectedPrincess!.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8E6CB0),
                              ),
                              overflow: TextOverflow.ellipsis,
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
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Gallery button (left)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8E6CB0),
                                  Color(0xFFEAA7C4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: FloatingActionButton(
                              onPressed: _isClassifying ? null : _pickAndClassifyImage,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Image.asset(
                                'assets/icons/cinderella.jpg',
                                width: 24,
                                height: 24,
                                color: Colors.white,
                                colorBlendMode: BlendMode.srcIn,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // Camera capture button (center)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8E6CB0),
                                  Color(0xFFEAA7C4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8E6CB0).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: FloatingActionButton(
                              onPressed: _isClassifying ? null : _captureAndClassify,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: _isClassifying
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/icons/belle.jpg',
                                      width: 24,
                                      height: 24,
                                      color: Colors.white,
                                      colorBlendMode: BlendMode.srcIn,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                          // Camera toggle button (right)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8E6CB0),
                                  Color(0xFFEAA7C4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: FloatingActionButton(
                              onPressed: _toggleCamera,
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              child: Image.asset(
                                'assets/icons/anna.jpg',
                                width: 24,
                                height: 24,
                                color: Colors.white,
                                colorBlendMode: BlendMode.srcIn,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  Positioned(
                    top: widget.selectedPrincess != null ? 80 : 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF9AA2),
                            Color(0xFFFFB7B2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _initializeCameraFuture = _setupCameraOptimized();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}