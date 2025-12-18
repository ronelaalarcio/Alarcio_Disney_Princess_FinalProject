import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:disney_princess_app/services/analytics_service.dart';
import 'package:disney_princess_app/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/princess.dart';
import '../widgets/princess_card.dart';
import 'princess_detail_screen.dart';
import 'camera_screen.dart';
import 'analytics_dashboard_screen.dart';
import '../services/classifier_service.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late ClassifierService _classifierService;
  late AnimationController _titleController;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _titleOpacityAnimation;
  
  // Controllers for card entrance animations
  late List<AnimationController> _cardControllers;
  late List<Animation<Offset>> _cardSlideAnimations;
  late List<Animation<double>> _cardOpacityAnimations;
  
  // Sparkle animation controllers
  late List<AnimationController> _sparkleControllers;
  late List<Animation<double>> _sparkleAnimations;
  
  // Floating action button animation
  late AnimationController _fabController;
  late Animation<double> _fabFloatAnimation;

  @override
  void initState() {
    super.initState();
    // Log screen view when homepage is loaded
    AnalyticsService.instance.logScreenView('Homepage');
    
    // Pre-initialize classifier service for faster camera loading
    _classifierService = ClassifierService();
    _preInitializeClassifier();
    
    // Title animation
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutCubic,
    ));
    
    _titleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeIn,
    ));
    
    // Start title animation
    _titleController.forward();
    
    // Initialize card animations
    _initializeCardAnimations();
    
    // Initialize sparkle animations
    _initializeSparkleAnimations();
    
    // Initialize FAB animation
    _fabController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fabFloatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _initializeCardAnimations() {
    // Create controllers and animations for each card
    _cardControllers = List.generate(
      princesses.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );
    
    _cardSlideAnimations = List.generate(
      princesses.length,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardControllers[index],
        curve: Curves.easeOutCubic,
      )),
    );
    
    _cardOpacityAnimations = List.generate(
      princesses.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _cardControllers[index],
        curve: Curves.easeIn,
      )),
    );
    
    // Start card animations with staggered delays
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + (i * 100)), () {
        if (mounted) {
          _cardControllers[i].forward();
        }
      });
    }
  }
  
  void _initializeSparkleAnimations() {
    // Create controllers for sparkle animations
    _sparkleControllers = List.generate(
      4, // Number of sparkles
      (index) => AnimationController(
        duration: Duration(seconds: 3 + index),
        vsync: this,
      )..repeat(reverse: true),
    );
    
    _sparkleAnimations = List.generate(
      4,
      (index) => Tween<double>(
        begin: 0.3 + (index * 0.1),
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _sparkleControllers[index],
        curve: Curves.easeInOut,
      )),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    for (var controller in _sparkleControllers) {
      controller.dispose();
    }
    _fabController.dispose();
    super.dispose();
  }

  // Pre-initialize classifier in background
  Future<void> _preInitializeClassifier() async {
    try {
      // Initialize in background without blocking UI
      await Future.microtask(() => _classifierService.initialize());
      print('Classifier pre-initialized successfully');
    } catch (e) {
      print('Classifier pre-initialization failed (not critical): $e');
    }
  }
  
  // Manual test function to verify Firestore connectivity
  Future<void> _testFirestoreConnectivity() async {
    try {
      print('Manually testing Firestore connectivity...');
      await _firebaseService.testFirestoreConnection();
      print('Manual Firestore connectivity test completed');
      
      // Show a snackbar to indicate success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firestore connection test successful!')),
        );
      }
    } on FirebaseException catch (e) {
      print('Firebase error during Firestore connectivity test: ${e.code} - ${e.message}');
      
      // Show a snackbar to indicate failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase error: ${e.message}')),
        );
      }
    } catch (e) {
      print('Manual Firestore connectivity test failed: $e');
      
      // Show a snackbar to indicate failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manual Firestore connectivity test failed: $e')),
        );
      }
    }
  }
  
  // Manual test function to verify Firebase configuration
  Future<void> _testFirebaseConfiguration() async {
    try {
      print('Manually testing Firebase configuration...');
      await _firebaseService.verifyFirebaseConfiguration();
      print('Manual Firebase configuration test completed');
      
      // Show a snackbar to indicate success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase configuration test successful!')),
        );
      }
    } catch (e) {
      print('Manual Firebase configuration test failed: $e');
      
      // Show a snackbar to indicate failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manual Firebase configuration test failed: $e')),
        );
      }
    }
  }
  
  // Manual test function to write sample data to Firestore
  Future<void> _testWriteSampleData() async {
    try {
      print('Manually testing sample data write...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Create sample data
        final Map<String, dynamic> sampleData = {
          'userId': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'classificationResult': {
            'princess': 'Anna',
            'confidence': 95.5,
          },
          'imageMetadata': {
            'width': 1920,
            'height': 1080,
            'format': 'jpeg',
          },
        };
        
        // Save sample data
        await _firebaseService.savePrincessClassification(currentUser.uid, sampleData);
        print('Sample data written successfully!');
        
        // Show a snackbar to indicate success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sample data written successfully!')),
          );
        }
      } else {
        print('Failed to get current user for sample data test');
        
        // Show a snackbar to indicate failure
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get current user')),
          );
        }
      }
    } catch (e) {
      print('Sample data write test failed: $e');
      
      // Show a snackbar to indicate failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sample data write test failed: $e')),
        );
      }
    }
  }

  // Function to open camera for general scanning (no specific princess)
  void _openCameraForGeneralScan() {
    // Log general scan selection
    AnalyticsService.instance.logGeneralScanSelected();
    
    // Navigate to camera screen without specifying a princess
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
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
                  'Disney Princess Classes',
                  style: GoogleFonts.greatVibes(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                actions: [
                  // Analytics dashboard button
                  IconButton(
                    icon: const Icon(Icons.analytics, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsDashboardScreen(),
                        ),
                      );
                    },
                    tooltip: 'View Analytics Dashboard',
                  ),
                ],
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              // Animated sparkle overlay
              Positioned(
                top: 8,
                right: 80,
                child: FadeTransition(
                  opacity: _sparkleAnimations[0],
                  child: Icon(
                    Icons.star,
                    color: Colors.white.withOpacity(0.3),
                    size: 12,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 100,
                child: FadeTransition(
                  opacity: _sparkleAnimations[1],
                  child: Icon(
                    Icons.star,
                    color: Colors.white.withOpacity(0.2),
                    size: 8,
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 120,
                child: FadeTransition(
                  opacity: _sparkleAnimations[2],
                  child: Icon(
                    Icons.star,
                    color: Colors.white.withOpacity(0.25),
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFFF1D6E6), // Center color
              Color(0xFFFFFFFF), // Outer color
            ],
            center: Alignment(0.0, -0.5), // Position of the radial center
            radius: 1.2, // Radius of the gradient
          ),
        ),
        child: Stack(
          children: [
            // Decorative star diamonds background with animation
            Positioned(
              top: 100,
              right: 30,
              child: Transform.rotate(
                angle: 0.785, // 45 degrees in radians
                child: FadeTransition(
                  opacity: _sparkleAnimations[3],
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E6CB0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 180,
              left: 40,
              child: Transform.rotate(
                angle: 0.785, // 45 degrees in radians
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAA7C4).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              right: 50,
              child: Transform.rotate(
                angle: 0.785, // 45 degrees in radians
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E6CB0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: 60,
              child: Transform.rotate(
                angle: 0.785, // 45 degrees in radians
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAA7C4).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(1.8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and subtitle - animated
                  FadeTransition(
                    opacity: _titleOpacityAnimation,
                    child: SlideTransition(
                      position: _titleSlideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disney Princess Classes',
                            style: GoogleFonts.greatVibes(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8E6CB0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Browse through all the Disney princess classes available for classification',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF616161), // Darker shade for better readability (grey[700])
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Princess Cards Grid - with entrance animations
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: princesses.length,
                      cacheExtent: 1000,
                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final princess = princesses[index];
                        return SlideTransition(
                          position: _cardSlideAnimations[index],
                          child: FadeTransition(
                            opacity: _cardOpacityAnimations[index],
                            child: Hero(
                              tag: 'princess_${princess.id}',
                              child: PrincessCard(
                                princess: princess,
                                onTap: () {
                                  // Log princess selection
                                  AnalyticsService.instance.logPrincessDetailsViewed(princess.name);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PrincessDetailScreen(princess: princess),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_fabFloatAnimation),
        child: FloatingActionButton(
          onPressed: _openCameraForGeneralScan,
          backgroundColor: const Color(0xFF8E6CB0),
          child: const Icon(Icons.camera_alt, color: Colors.white),
        ),
      ),
    );
  }
}