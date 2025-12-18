import 'package:flutter/material.dart';
import 'dart:typed_data' show Uint8List;
import 'package:disney_princess_app/services/analytics_service.dart';
import 'package:disney_princess_app/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/princess.dart' show Princess, princesses;
import 'princess_detail_screen.dart';

class ClassificationResultScreen extends StatefulWidget {
  final Princess princess;
  final double confidence;
  final List<Map<String, dynamic>> allResults;
  final Uint8List? capturedImage;

  const ClassificationResultScreen({
    super.key,
    required this.princess,
    required this.confidence,
    required this.allResults,
    this.capturedImage,
  });

  @override
  State<ClassificationResultScreen> createState() => _ClassificationResultScreenState();
}

class _ClassificationResultScreenState extends State<ClassificationResultScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Animation controllers
  late AnimationController _entranceController;
  late Animation<double> _imageScaleAnimation;
  late Animation<double> _imageOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _buttonOpacityAnimation;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView('ClassificationResult_${widget.princess.name}');
    
    // Initialize entrance animations
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Image animations
    _imageScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    ));
    
    _imageOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    ));
    
    // Text animations
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    ));
    
    // Button animations
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    ));
    
    _buttonOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    ));
    
    // Start animations with slight delays
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
    
    _testFirebaseConnection();
    
    _saveClassificationToFirestore();
  }
  
  Future<void> _testFirebaseConnection() async {
    try {
      // print('Testing Firebase connection from ClassificationResultScreen');
      await _firebaseService.testFirestoreConnection();
    } catch (e) {
      // print('Firebase connection test failed in ClassificationResultScreen: $e');
    }
  }
  
  Future<void> _saveClassificationToFirestore() async {
    try {
      // print('Attempting to save classification to Firestore');
      
      User? currentUser = FirebaseAuth.instance.currentUser;
      // print('Current user: $currentUser');
      
      if (currentUser == null) {
        // print('No current user, attempting anonymous sign in');
        try {
          // print('Attempting anonymous sign-in...');
          UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
          currentUser = userCredential.user;
          // print('Anonymous sign in successful: ${currentUser?.uid}');
          
          if (currentUser != null) {
            // print('Adding user to Firestore users collection');
            await _firebaseService.addUser(currentUser);
            // print('User added to Firestore successfully');
          } else {
            // print('Anonymous sign in succeeded but user is null');
            return;
          }
        } on FirebaseAuthException catch (authError) {
          // print('Firebase Auth error during anonymous sign-in: ${authError.code} - ${authError.message}');
          
          if (authError.code == 'CONFIGURATION_NOT_FOUND') {
            // print('CONFIGURATION_NOT_FOUND: This usually means there is an issue with your google-services.json file or Firebase project setup.');
            // print('Please verify that:');
            // print('1. Your google-services.json file is in the correct location (android/app/)');
            // print('2. The package name in google-services.json matches your app (com.example.disney_princess_app)');
            // print('3. Anonymous sign-in is enabled in your Firebase Authentication settings');
          }
          return;
        } catch (authError) {
          // print('Anonymous sign-in failed: $authError');
          return;
        }
      }
      
      if (currentUser != null) {
        // print('Preparing data to save to classifications collection');
        
        // Convert allResults to ensure proper data types
        final List<Map<String, dynamic>> sanitizedResults = widget.allResults.map((result) {
          final confidenceValue = result['confidence'];
          double confidence = 0.0;
          if (confidenceValue is double) {
            confidence = confidenceValue;
          } else if (confidenceValue is int) {
            confidence = confidenceValue.toDouble();
          } else if (confidenceValue is String) {
            try {
              confidence = double.parse(confidenceValue);
            } catch (e) {
              confidence = 0.0;
            }
          }
          
          return {
            'label': result['label'],
            'confidence': confidence,
          };
        }).toList();
        
        final data = {
          'princessName': widget.princess.name,
          'confidence': widget.confidence,
          'allResults': sanitizedResults,
          'timestamp': DateTime.now(),
        };
        
        // print('Data being sent to Firestore:');
        // print('- Princess Name: ${widget.princess.name}');
        // print('- Confidence: ${widget.confidence}');
        // print('- All Results Length: ${sanitizedResults.length}');
        // print('- Current User ID: ${currentUser.uid}');
        
        // for (int i = 0; i < sanitizedResults.length; i++) {
        //   final result = sanitizedResults[i];
        //   print('Result $i: label=${result['label']}, confidence=${result['confidence']}');
        // }
        
        // print('Saving classification data to Firestore');
        await _firebaseService.savePrincessClassification(currentUser.uid, data);
        // print('Classification saved to Firestore for user: ${currentUser.uid}');
      } else {
        // print('No user available to save classification');
      }
    } on FirebaseException catch (e) {
      // print('Firebase error saving classification to Firestore: ${e.code} - ${e.message}');
    } catch (e, stackTrace) {
      // print('Error saving classification to Firestore: $e');
      // print('Stack trace: $stackTrace');
    }
  }

  String _formatConfidence(double value) {
    final clampedValue = value.clamp(0.0, 100.0);
    return clampedValue.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _entranceController.dispose();
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
                  'Classification Result',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.capturedImage != null) ...[
                ScaleTransition(
                  scale: _imageScaleAnimation,
                  child: FadeTransition(
                    opacity: _imageOpacityAnimation,
                    child: Container(
                      height: 300,
                      width: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          widget.capturedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
              
              SlideTransition(
                position: _textSlideAnimation,
                child: FadeTransition(
                  opacity: _textOpacityAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Classification Result',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E6CB0),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_formatConfidence(widget.confidence)}%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8E6CB0),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Special message for black images
                        if (widget.confidence == 0.0) ...[
                          const Text(
                            'Black image detected - Please try again with a clearer photo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Animated gradient progress bar
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: (widget.confidence / 100).clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, value, child) {
                            return LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8E6CB0)),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            );
                          },
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.coronavirus,
                              color: Color(0xFF8E6CB0),
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Identified as: ${widget.princess.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (widget.confidence == 0.0) ...[
                          const SizedBox(height: 20),
                          const Text(
                            '🚫 No Valid Classification 🚫',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Black or invalid image detected. Please try again with a clearer photo.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else if (widget.confidence >= 30.0 && widget.allResults.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            '🌸 All Princess Probabilities 🌸',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8E6CB0),
                            ),
                          ),
                          const Text(
                            'Result is based on highest probability',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Beautiful bar chart with princess emojis
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFFEAA7C4).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: widget.allResults.asMap().entries.map((entry) {
                                final index = entry.key;
                                final result = entry.value;
                                final label = result['label'] ?? 'Unknown';
                                // Safely convert confidence to double
                                final confidenceValue = result['confidence'];
                                double confidence = 0.0;
                                if (confidenceValue is double) {
                                  confidence = confidenceValue;
                                } else if (confidenceValue is int) {
                                  confidence = confidenceValue.toDouble();
                                } else if (confidenceValue is String) {
                                  try {
                                    confidence = double.parse(confidenceValue);
                                  } catch (e) {
                                    confidence = 0.0;
                                  }
                                }
                                final percentage = confidence.clamp(0.0, 100.0);
                                
                                // Find the corresponding princess to get the image URL
                                final princess = princesses.firstWhere(
                                  (p) => p.name.toLowerCase() == label.toLowerCase(),
                                  orElse: () => princesses[0], // Default to first princess if not found
                                );
                                
                                // Check if this is the top result
                                final isTopResult = index == 0;
                                
                                return Container(
                                  decoration: isTopResult ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF8E6CB0),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8E6CB0).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ) : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        // Princess icon
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFEAA7C4).withOpacity(0.2),
                                          ),
                                          child: ClipOval(
                                            child: Image.asset(
                                              princess.imageUrl,
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.contain,
                                              filterQuality: FilterQuality.high,
                                              errorBuilder: (context, error, stackTrace) {
                                                // Fallback to a default icon if image fails to load
                                                return const Icon(
                                                  Icons.account_circle,
                                                  color: Color(0xFF8E6CB0),
                                                  size: 20,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Label name
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF8E6CB0),
                                            ),
                                          ),
                                        ),
                                        // Percentage value
                                        Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF8E6CB0),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Bar chart
                                        Expanded(
                                          flex: 5,
                                          child: Container(
                                            height: 20,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              color: Colors.grey[300], // Lighter background for all bars
                                            ),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                width: percentage > 0 
                                                    ? MediaQuery.of(context).size.width * (percentage / 100) * 0.4 
                                                    : 0, // No width for 0% bars
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  gradient: percentage > 0 
                                                      ? const LinearGradient(
                                                          colors: [
                                                            Color(0xFF8E6CB0), // Purple
                                                            Color(0xFFEAA7C4), // Pink
                                                          ],
                                                          begin: Alignment.centerLeft,
                                                          end: Alignment.centerRight,
                                                        )
                                                      : null, // No gradient for 0% bars
                                                  color: percentage > 0 
                                                      ? null 
                                                      : Colors.transparent, // Transparent for 0% bars
                                                  boxShadow: percentage > 0 
                                                      ? [
                                                          BoxShadow(
                                                            color: const Color(0xFF8E6CB0).withOpacity(0.2),
                                                            blurRadius: 2,
                                                            offset: const Offset(0, 1),
                                                          ),
                                                        ]
                                                      : null, // No shadow for 0% bars
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              SlideTransition(
                position: _buttonSlideAnimation,
                child: FadeTransition(
                  opacity: _buttonOpacityAnimation,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AnalyticsService.instance.logButtonTap('Retake Photo');
                            // Pop back to camera screen with a result indicating retake
                            Navigator.pop(context, {'retake': true});
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(15),
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.grey[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            fixedSize: const Size.fromHeight(50),
                          ),
                          child: const Text(
                            'Retake Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.confidence > 0.0 ? () {
                            AnalyticsService.instance.logButtonTap('View Details');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrincessDetailScreen(princess: widget.princess),
                              ),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(15),
                            backgroundColor: widget.confidence > 0.0 
                              ? const Color(0xFF8E6CB0) 
                              : Colors.grey[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            fixedSize: const Size.fromHeight(50),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}