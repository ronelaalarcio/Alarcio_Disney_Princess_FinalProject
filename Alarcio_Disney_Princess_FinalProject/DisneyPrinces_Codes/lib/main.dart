import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:disney_princess_app/services/analytics_service.dart';
import 'package:disney_princess_app/services/firebase_service.dart';
import 'screens/homepage_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optimize memory usage
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  
  // Initialize Firebase with enhanced error handling
  bool firebaseInitialized = false;
  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp();
    firebaseInitialized = true;
    print('Firebase initialized successfully');
    
    // Enhanced Firebase connection test with timeout
    print('Testing Firebase connection...');
    try {
      // Test Firestore connection with timeout
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      // Enable offline persistence to handle connectivity issues gracefully
      firestore.settings = const Settings(
        persistenceEnabled: true,
        sslEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      // Test Auth connection
      final FirebaseAuth auth = FirebaseAuth.instance;
      print('Firestore instance: $firestore');
      print('Auth instance: $auth');
      
      // Test writing a simple document to Firestore with timeout
      print('Testing Firestore write operation...');
      final testDoc = await firestore.collection('test').add({
        'test': 'connection',
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      print('Test document created with ID: ${testDoc.id}');
      
      // Clean up test document
      await testDoc.delete();
      print('Test document deleted successfully');
      
      // Test anonymous authentication
      print('Testing anonymous authentication...');
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously()
          .timeout(const Duration(seconds: 10));
        User? user = userCredential.user;
        print('Anonymous sign-in successful. User ID: ${user?.uid}');
        
        // Sign out after testing
        await FirebaseAuth.instance.signOut();
        print('Signed out after testing');
      } on FirebaseAuthException catch (e) {
        print('Firebase Auth error during test: ${e.code} - ${e.message}');
        if (e.code == 'CONFIGURATION_NOT_FOUND') {
          print('CRITICAL: CONFIGURATION_NOT_FOUND error detected!');
          print('Possible causes:');
          print('1. Anonymous sign-in not enabled in Firebase Console');
          print('2. Incorrect google-services.json file');
          print('3. Network issues preventing Firebase configuration download');
        }
      } on TimeoutException catch (e) {
        print('Firebase Auth test timed out: $e');
        print('This may indicate network connectivity issues');
      }
      
    } catch (testError) {
      print('Firebase connection test failed: $testError');
      if (testError is TimeoutException) {
        print('Connection test timed out - likely a network connectivity issue');
      }
    }
  } on FirebaseException catch (e) {
    print('Firebase initialization error: ${e.code} - ${e.message}');
    if (e.code == 'CONFIGURATION_NOT_FOUND') {
      print('CRITICAL: CONFIGURATION_NOT_FOUND during Firebase initialization!');
      print('Please check:');
      print('1. google-services.json file is in android/app/ directory');
      print('2. Package name matches exactly');
      print('3. Internet connection is available');
      print('4. Firebase project exists and is properly configured');
      print('5. Anonymous sign-in is enabled in Firebase Authentication');
    }
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue without Firebase if initialization fails
  }
  
  // Initialize Analytics only if Firebase was successfully initialized
  if (firebaseInitialized) {
    try {
      await AnalyticsService.instance.initialize();
    } catch (e) {
      print('Analytics initialization error: $e');
    }
  }
  
  runApp(const DisneyPrincessApp());
}

class DisneyPrincessApp extends StatelessWidget {
  const DisneyPrincessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disney Princess App',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomepageScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}