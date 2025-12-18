import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  AnalyticsService._internal();

  static AnalyticsService get instance => _instance;

  /// Initialize analytics
  Future<void> initialize() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('Firebase not initialized, skipping analytics initialization');
        return;
      }
      
      _analytics = FirebaseAnalytics.instance;
      _isInitialized = true;
      
      // Log app open event
      await logAppOpen();
    } catch (e) {
      print('Analytics initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Log screen views
  Future<void> logScreenView(String screenName) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (e) {
      print('Error logging screen view: $e');
    }
  }

  /// Log camera scan initiated
  Future<void> logCameraScanStarted() async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'camera_scan_started',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging camera scan started: $e');
    }
  }

  /// Log image classified
  Future<void> logImageClassified(String princessName, double confidence) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'image_classified',
        parameters: {
          'princess_name': princessName,
          'confidence': confidence,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging image classified: $e');
    }
  }

  /// Log princess details viewed
  Future<void> logPrincessDetailsViewed(String princessName) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'princess_details_viewed',
        parameters: {
          'princess_name': princessName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging princess details viewed: $e');
    }
  }

  /// Log gallery image selected
  Future<void> logGalleryImageSelected() async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'gallery_image_selected',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging gallery image selected: $e');
    }
  }

  /// Log camera image captured
  Future<void> logCameraImageCaptured() async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'camera_image_captured',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging camera image captured: $e');
    }
  }

  /// Log app open
  Future<void> logAppOpen() async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logAppOpen();
    } catch (e) {
      print('Error logging app open: $e');
    }
  }

  /// Log button tap
  Future<void> logButtonTap(String buttonName) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'button_tapped',
        parameters: {
          'button_name': buttonName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging button tap: $e');
    }
  }

  /// Log classification result viewed
  Future<void> logClassificationResultViewed(String princessName, double confidence) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'classification_result_viewed',
        parameters: {
          'princess_name': princessName,
          'confidence': confidence,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging classification result viewed: $e');
    }
  }

  /// Log princess scan selected
  Future<void> logPrincessScanSelected(String princessName) async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'princess_scan_selected',
        parameters: {
          'princess_name': princessName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging princess scan selected: $e');
    }
  }

  /// Log gallery scan started
  Future<void> logGalleryScanStarted() async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'gallery_scan_started',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging gallery scan started: $e');
    }
  }

  /// Log general scan selected
  Future<void> logGeneralScanSelected() async {
    if (!_isInitialized) return;
    try {
      await _analytics?.logEvent(
        name: 'general_scan_selected',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Error logging general scan selected: $e');
    }
  }
}